const { getFirebaseMessaging } = require("../config/firebase");
const OwnerDevice = require("../models/OwnerDevice");
const NotificationLog = require("../models/NotificationLog");

const INVALID_TOKEN_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered"
]);

function summarizeOrder(order) {
  return order.items
    .slice(0, 3)
    .map((item) => `${item.quantity} x ${item.name}`)
    .join(", ");
}

async function logNotification({ shopId, orderId, channel, status, providerMessageId = "", error = "" }) {
  await NotificationLog.create({
    shopId,
    orderId,
    channel,
    status,
    providerMessageId,
    error
  });
}

async function sendNewOrderNotification(order, shop) {
  const messaging = getFirebaseMessaging();

  if (!messaging) {
    await logNotification({
      shopId: order.shopId,
      orderId: order._id,
      channel: "fcm",
      status: "skipped",
      error: "Firebase is not configured"
    });

    return {
      status: "skipped",
      messageId: ""
    };
  }

  const devices = await OwnerDevice.find({
    shopId: shop._id,
    isActive: true
  }).select("fcmToken");

  const tokens = devices.map((device) => device.fcmToken).filter(Boolean);

  if (!tokens.length) {
    await logNotification({
      shopId: order.shopId,
      orderId: order._id,
      channel: "fcm",
      status: "skipped",
      error: "No active owner devices"
    });

    return {
      status: "skipped",
      messageId: ""
    };
  }

  try {
    const customerName = order.customer?.name || "Customer";
    const orderSummary = summarizeOrder(order);
    const body = `${customerName}: ${orderSummary} - Rs. ${order.totalAmount}`;

    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: "New Order",
        body
      },
      data: {
        type: "NEW_ORDER",
        orderId: String(order._id),
        shopId: String(shop._id),
        orderNumber: order.orderNumber,
        customerName,
        orderSummary,
        address: order.customer?.address || "",
        totalAmount: String(order.totalAmount),
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      },
      android: {
        priority: "high",
        ttl: 60 * 60 * 1000,
        notification: {
          channelId: "orders_alerts",
          sound: "default",
          priority: "max",
          visibility: "public",
          defaultSound: true,
          defaultVibrateTimings: true
        }
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            contentAvailable: true
          }
        }
      },
      webpush: {
        notification: {
          title: "New Order",
          body,
          icon: "/favicon.svg",
          badge: "/favicon.svg",
          requireInteraction: true,
          tag: `order-${order._id}`
        },
        fcmOptions: {
          link: "/dashboard"
        }
      }
    });

    const invalidTokens = [];

    response.responses.forEach((item, index) => {
      if (!item.success && item.error && INVALID_TOKEN_CODES.has(item.error.code)) {
        invalidTokens.push(tokens[index]);
      }
    });

    if (invalidTokens.length) {
      await OwnerDevice.updateMany(
        { fcmToken: { $in: invalidTokens } },
        { $set: { isActive: false } }
      );
    }

    const status = response.failureCount === 0 ? "sent" : response.successCount > 0 ? "partial" : "failed";

    await logNotification({
      shopId: order.shopId,
      orderId: order._id,
      channel: "fcm",
      status,
      providerMessageId: `success:${response.successCount};failure:${response.failureCount}`,
      error: response.failureCount ? "One or more FCM sends failed" : ""
    });

    return {
      status,
      messageId: `success:${response.successCount};failure:${response.failureCount}`
    };
  } catch (error) {
    await logNotification({
      shopId: order.shopId,
      orderId: order._id,
      channel: "fcm",
      status: "failed",
      error: error.message
    });

    return {
      status: "failed",
      messageId: "",
      error: error.message
    };
  }
}

async function sendCustomerOrderUpdateNotification(order, shop, message, status = "") {
  const messaging = getFirebaseMessaging();
  const token = order.customer?.fcmToken;

  if (!message || !message.trim()) {
    return {
      status: "failed",
      messageId: "",
      error: "Message is required"
    };
  }

  if (!messaging) {
    await logNotification({
      shopId: order.shopId,
      orderId: order._id,
      channel: "fcm",
      status: "skipped",
      error: "Firebase is not configured"
    });

    return {
      status: "skipped",
      messageId: "",
      error: "Firebase is not configured"
    };
  }

  if (!token) {
    await logNotification({
      shopId: order.shopId,
      orderId: order._id,
      channel: "fcm",
      status: "skipped",
      error: "Customer has not enabled push notifications"
    });

    return {
      status: "skipped",
      messageId: "",
      error: "Customer has not enabled push notifications. Use WhatsApp fallback."
    };
  }

  try {
    const response = await messaging.send({
      token,
      notification: {
        title: "Order Update",
        body: message.trim()
      },
      data: {
        type: "ORDER_UPDATE",
        orderId: String(order._id),
        orderNumber: order.orderNumber,
        shopId: String(shop._id),
        shopName: shop.name || "",
        status: status || order.status || ""
      },
      android: {
        priority: "high",
        notification: {
          channelId: "orders_alerts",
          sound: "default",
          priority: "high"
        }
      },
      apns: {
        payload: {
          aps: {
            sound: "default"
          }
        }
      },
      webpush: {
        notification: {
          title: "Order Update",
          body: message.trim(),
          icon: "/favicon.svg",
          badge: "/favicon.svg",
          requireInteraction: true,
          tag: `order-update-${order._id}`
        },
        fcmOptions: {
          link: `/shop/${shop.slug}`
        }
      }
    });

    await logNotification({
      shopId: order.shopId,
      orderId: order._id,
      channel: "fcm",
      status: "sent",
      providerMessageId: response
    });

    return {
      status: "sent",
      messageId: response
    };
  } catch (error) {
    if (INVALID_TOKEN_CODES.has(error.code)) {
      order.customer.fcmToken = "";
      await order.save();
    }

    await logNotification({
      shopId: order.shopId,
      orderId: order._id,
      channel: "fcm",
      status: "failed",
      error: error.message
    });

    return {
      status: "failed",
      messageId: "",
      error: error.message
    };
  }
}

module.exports = {
  sendNewOrderNotification,
  sendCustomerOrderUpdateNotification
};
