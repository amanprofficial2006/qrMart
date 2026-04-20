const ApiError = require("../utils/ApiError");
const Shop = require("../models/Shop");
const Product = require("../models/Product");
const Order = require("../models/Order");
const OwnerDevice = require("../models/OwnerDevice");
const { toDataUrl } = require("../services/qr.service");
const { emitOrderUpdated } = require("../services/realtime.service");
const { sendCustomerOrderUpdateNotification } = require("../services/notification.service");
const buildShopUrl = require("../utils/shopUrl");

const allowedStatuses = new Set([
  "placed",
  "seen",
  "accepted",
  "rejected",
  "preparing",
  "ready",
  "completed",
  "cancelled"
]);

function fileUrl(file) {
  if (!file) {
    return "";
  }

  if (file.buffer && file.mimetype) {
    return `data:${file.mimetype};base64,${file.buffer.toString("base64")}`;
  }

  const relativePath = file.path.replace(/\\/g, "/").replace(/^.*uploads\//, "/uploads/");
  return relativePath.startsWith("/uploads/") ? relativePath : `/uploads/${file.filename}`;
}

function parseBoolean(value, fallback = true) {
  if (value === undefined || value === null || value === "") {
    return fallback;
  }

  return value === true || value === "true";
}

function parsePrice(value) {
  const price = Number(value);

  if (!Number.isFinite(price) || price < 0) {
    throw new ApiError(400, "Product price must be a valid number");
  }

  return price;
}

function parseMoney(value, fieldName) {
  const amount = Number(value);

  if (!Number.isFinite(amount) || amount < 0) {
    throw new ApiError(400, `${fieldName} must be a valid non-negative number`);
  }

  return amount;
}

async function getProfile(req, res) {
  const shop = await Shop.findById(req.shopId);

  res.json({
    success: true,
    data: {
      owner: req.owner,
      shop
    }
  });
}

async function updateProfile(req, res) {
  const allowed = ["name", "ownerName", "phone", "whatsappNumber", "address", "description"];
  const updates = {};

  for (const key of allowed) {
    if (req.body[key] !== undefined) {
      updates[key] = req.body[key];
    }
  }

  if (req.body.deliveryCharge !== undefined) {
    updates["settings.deliveryCharge"] = parseMoney(req.body.deliveryCharge, "Delivery charge");
  }

  if (req.body.settings?.deliveryCharge !== undefined) {
    updates["settings.deliveryCharge"] = parseMoney(req.body.settings.deliveryCharge, "Delivery charge");
  }

  if (req.body.upiId !== undefined) {
    updates["payment.upiId"] = req.body.upiId;
  }

  if (req.body.payment?.upiId !== undefined) {
    updates["payment.upiId"] = req.body.payment.upiId;
  }

  const shop = await Shop.findByIdAndUpdate(req.shopId, updates, {
    new: true,
    runValidators: true
  });

  if (!shop) {
    throw new ApiError(404, "Shop not found");
  }

  res.json({
    success: true,
    data: shop
  });
}

async function uploadPaymentQr(req, res) {
  if (!req.file) {
    throw new ApiError(400, "Please upload a payment QR image");
  }

  const shop = await Shop.findByIdAndUpdate(
    req.shopId,
    { "payment.qrCodeUrl": fileUrl(req.file) },
    { new: true }
  );

  res.json({
    success: true,
    data: shop
  });
}

async function uploadLogo(req, res) {
  if (!req.file) {
    throw new ApiError(400, "Please upload a logo image");
  }

  const shop = await Shop.findByIdAndUpdate(
    req.shopId,
    { logoUrl: fileUrl(req.file) },
    { new: true }
  );

  res.json({
    success: true,
    data: shop
  });
}

async function listProducts(req, res) {
  const products = await Product.find({ shopId: req.shopId }).sort({
    sortOrder: 1,
    createdAt: -1
  });

  res.json({
    success: true,
    data: products
  });
}

async function createProduct(req, res) {
  const { name, description = "", category = "General", sortOrder = 0 } = req.body;

  if (!name || req.body.price === undefined) {
    throw new ApiError(400, "Product name and price are required");
  }

  const product = await Product.create({
    shopId: req.shopId,
    name,
    description,
    price: parsePrice(req.body.price),
    imageUrl: fileUrl(req.file) || req.body.imageUrl || "",
    category,
    sortOrder: Number(sortOrder) || 0,
    isAvailable: parseBoolean(req.body.isAvailable, true)
  });

  res.status(201).json({
    success: true,
    data: product
  });
}

async function updateProduct(req, res) {
  const product = await Product.findOne({
    _id: req.params.productId,
    shopId: req.shopId
  });

  if (!product) {
    throw new ApiError(404, "Product not found");
  }

  const fields = ["name", "description", "category", "sortOrder"];

  for (const field of fields) {
    if (req.body[field] !== undefined) {
      product[field] = req.body[field];
    }
  }

  if (req.body.price !== undefined) {
    product.price = parsePrice(req.body.price);
  }

  if (req.body.isAvailable !== undefined) {
    product.isAvailable = parseBoolean(req.body.isAvailable, true);
  }

  if (req.file) {
    product.imageUrl = fileUrl(req.file);
  } else if (req.body.imageUrl !== undefined) {
    product.imageUrl = req.body.imageUrl;
  }

  await product.save();

  res.json({
    success: true,
    data: product
  });
}

async function deleteProduct(req, res) {
  const product = await Product.findOneAndDelete({
    _id: req.params.productId,
    shopId: req.shopId
  });

  if (!product) {
    throw new ApiError(404, "Product not found");
  }

  res.json({
    success: true,
    message: "Product deleted"
  });
}

async function listOrders(req, res) {
  const query = { shopId: req.shopId };

  if (req.query.status && req.query.status !== "all") {
    query.status = req.query.status;
  }

  const orders = await Order.find(query)
    .sort({ createdAt: -1 })
    .limit(100)
    .select("orderNumber customer items pricing payment totalAmount status notification createdAt updatedAt");

  res.json({
    success: true,
    data: orders
  });
}

async function getOrder(req, res) {
  const order = await Order.findOne({
    _id: req.params.orderId,
    shopId: req.shopId
  });

  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  res.json({
    success: true,
    data: order
  });
}

async function updateOrderStatus(req, res) {
  const { status } = req.body;

  if (!allowedStatuses.has(status)) {
    throw new ApiError(400, "Invalid order status");
  }

  const order = await Order.findOne({
    _id: req.params.orderId,
    shopId: req.shopId
  });

  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  order.status = status;
  order.timeline.push({
    status,
    by: "owner"
  });
  await order.save();
  emitOrderUpdated(order);

  res.json({
    success: true,
    data: order
  });
}

async function getQr(req, res) {
  const shop = await Shop.findById(req.shopId);

  if (!shop) {
    throw new ApiError(404, "Shop not found");
  }

  const qrUrl = shop.qrUrl || buildShopUrl(shop.slug);
  const qrDataUrl = await toDataUrl(qrUrl);

  res.json({
    success: true,
    data: {
      qrUrl,
      qrDataUrl
    }
  });
}

async function refreshQr(req, res) {
  const shop = await Shop.findById(req.shopId);

  if (!shop) {
    throw new ApiError(404, "Shop not found");
  }

  let qrUrl;

  try {
    qrUrl = buildShopUrl(shop.slug, req.body.baseUrl || req.get("origin"));
  } catch (_error) {
    throw new ApiError(400, "Invalid shop domain for QR code");
  }

  shop.qrUrl = qrUrl;
  await shop.save();

  const qrDataUrl = await toDataUrl(qrUrl);

  res.json({
    success: true,
    data: {
      qrUrl,
      qrDataUrl
    }
  });
}

async function registerDevice(req, res) {
  const { platform = "web", fcmToken } = req.body;

  if (!fcmToken) {
    throw new ApiError(400, "fcmToken is required");
  }

  await OwnerDevice.findOneAndUpdate(
    { fcmToken },
    {
      shopId: req.shopId,
      ownerId: req.owner._id,
      platform,
      fcmToken,
      isActive: true,
      lastSeenAt: new Date()
    },
    {
      upsert: true,
      new: true,
      setDefaultsOnInsert: true
    }
  );

  res.json({
    success: true,
    message: "Device registered"
  });
}

async function sendOrderNotification(req, res) {
  const { orderId, message, status = "" } = req.body;
  const cleanMessage = String(message || "").trim();

  if (!orderId) {
    throw new ApiError(400, "orderId is required");
  }

  if (!cleanMessage) {
    throw new ApiError(400, "Message should not be empty");
  }

  if (cleanMessage.length > 300) {
    throw new ApiError(400, "Message should be 300 characters or less");
  }

  const order = await Order.findOne({
    _id: orderId,
    shopId: req.shopId
  });

  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  const shop = await Shop.findById(req.shopId);
  const result = await sendCustomerOrderUpdateNotification(order, shop, cleanMessage, status);

  res.json({
    success: true,
    data: {
      sent: result.status === "sent",
      status: result.status,
      message: result.error || "Notification sent to customer",
      providerMessageId: result.messageId
    }
  });
}

module.exports = {
  getProfile,
  updateProfile,
  uploadLogo,
  uploadPaymentQr,
  listProducts,
  createProduct,
  updateProduct,
  deleteProduct,
  listOrders,
  getOrder,
  updateOrderStatus,
  getQr,
  refreshQr,
  registerDevice,
  sendOrderNotification
};
