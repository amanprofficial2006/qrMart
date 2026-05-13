const mongoose = require("mongoose");
const ApiError = require("../utils/ApiError");
const Shop = require("../models/Shop");
const Product = require("../models/Product");
const Order = require("../models/Order");
const Customer = require("../models/Customer");
const { buildWhatsAppOrderUrl } = require("./whatsapp.service");
const { sendNewOrderNotification } = require("./notification.service");
const { emitNewOrder } = require("./realtime.service");

function generateOrderNumber() {
  const now = new Date();
  const date = now.toISOString().slice(0, 10).replace(/-/g, "");
  const suffix = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`.toUpperCase();
  return `ORD-${date}-${suffix}`;
}

function mergeOrderItems(items) {
  const map = new Map();

  for (const item of items || []) {
    if (!mongoose.Types.ObjectId.isValid(item.productId)) {
      throw new ApiError(400, "Invalid product id in order");
    }

    const quantity = Number(item.quantity);

    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 99) {
      throw new ApiError(400, "Quantity must be between 1 and 99");
    }

    const key = String(item.productId);
    map.set(key, (map.get(key) || 0) + quantity);
  }

  return Array.from(map.entries()).map(([productId, quantity]) => ({
    productId,
    quantity
  }));
}

function buildMapsUrl(location) {
  const latitude = Number(location?.latitude);
  const longitude = Number(location?.longitude);

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    return "";
  }

  return `https://www.google.com/maps?q=${latitude},${longitude}`;
}

function resolvePaymentMethod(payload, shop) {
  const requested = String(payload.payment?.method || "").trim().toLowerCase();

  if (requested === "cash" || requested === "cod") {
    return "cash";
  }

  if (requested === "upi" || requested === "online") {
    return "upi";
  }

  return shop.payment?.upiId || shop.payment?.qrCodeUrl ? "upi" : "cash";
}

function resolveProductPrice(product, paymentMethod) {
  if (paymentMethod === "cash") {
    return Number(product.codPrice || product.price || product.onlinePrice || 0);
  }

  return Number(product.onlinePrice || product.price || product.codPrice || 0);
}

async function createOrderForShop(slug, payload, customerSession = null) {
  const shop = await Shop.findOne({ slug, isActive: true });

  if (!shop) {
    throw new ApiError(404, "Shop not found or inactive");
  }

  const mergedItems = mergeOrderItems(payload.items);

  if (!mergedItems.length) {
    throw new ApiError(400, "Please select at least one product");
  }

  if (!customerSession?.id || !customerSession?.phone) {
    throw new ApiError(401, "Please verify your phone with OTP before placing the order");
  }

  const address = String(payload.customer?.address || "").trim();

  if (!address) {
    throw new ApiError(400, "Delivery address is required");
  }

  const productIds = mergedItems.map((item) => item.productId);
  const products = await Product.find({
    _id: { $in: productIds },
    shopId: shop._id,
    isAvailable: true
  });

  if (products.length !== productIds.length) {
    throw new ApiError(400, "One or more products are unavailable");
  }

  const productById = new Map(products.map((product) => [String(product._id), product]));
  const paymentMethod = resolvePaymentMethod(payload, shop);

  const orderItems = mergedItems.map((item) => {
    const product = productById.get(String(item.productId));
    const price = resolveProductPrice(product, paymentMethod);
    const subtotal = price * item.quantity;

    return {
      productId: product._id,
      name: product.name,
      imageUrl: product.imageUrl || "",
      price,
      quantity: item.quantity,
      subtotal
    };
  });

  const itemTotal = orderItems.reduce((sum, item) => sum + item.subtotal, 0);
  const deliveryCharge = Number(shop.settings?.deliveryCharge || 0);
  const totalAmount = itemTotal + deliveryCharge;
  const mapsUrl = buildMapsUrl(payload.customer?.location);
  const upiId = shop.payment?.upiId || "";
  const paymentClaimed = paymentMethod === "upi" && Boolean(payload.payment?.declaredPaid);
  const initialStatus = paymentClaimed ? "payment_claimed" : "placed";

  const order = await Order.create({
    shopId: shop._id,
    orderNumber: generateOrderNumber(),
    customer: {
      accountId: customerSession.id,
      isVerified: true,
      name: payload.customer?.name || customerSession.name || "",
      phone: customerSession.phone,
      address,
      note: payload.customer?.note || "",
      location: {
        latitude: payload.customer?.location?.latitude,
        longitude: payload.customer?.location?.longitude,
        mapsUrl
      }
    },
    items: orderItems,
    totalAmount,
    pricing: {
      itemTotal,
      deliveryCharge,
      finalTotal: totalAmount
    },
    payment: {
      method: paymentMethod,
      declaredPaid: paymentClaimed,
      upiId
    },
    status: initialStatus,
    notification: {
      fcmStatus: "pending",
      whatsappFallbackUrl: ""
    },
    timeline: [
      {
        status: initialStatus,
        by: "customer"
      }
    ]
  });

  await Customer.findByIdAndUpdate(customerSession.id, {
    ...(payload.customer?.name ? { name: String(payload.customer.name).trim() } : {}),
    address
  });

  const whatsappFallbackUrl = buildWhatsAppOrderUrl(order, shop);
  const fcmResult = await sendNewOrderNotification(order, shop);

  order.notification.whatsappFallbackUrl = whatsappFallbackUrl;
  order.notification.fcmStatus = fcmResult.status;
  order.notification.fcmMessageId = fcmResult.messageId || "";
  order.notification.lastTriedAt = new Date();
  await order.save();
  emitNewOrder(order);

  return order;
}

module.exports = {
  createOrderForShop
};
