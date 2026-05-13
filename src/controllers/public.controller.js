const jwt = require("jsonwebtoken");
const env = require("../config/env");
const Shop = require("../models/Shop");
const Product = require("../models/Product");
const Order = require("../models/Order");
const Customer = require("../models/Customer");
const CustomerRecentShop = require("../models/CustomerRecentShop");
const { createOrderForShop } = require("../services/order.service");
const { uploadImage } = require("../services/media.service");
const ApiError = require("../utils/ApiError");

const STATIC_CUSTOMER_OTP = "142006";

function normalizePhone(phone) {
  return String(phone || "").replace(/\D/g, "");
}

function serializeCustomer(customer) {
  return {
    id: customer._id,
    name: customer.name,
    phone: customer.phone,
    address: customer.address || "",
    avatarUrl: customer.avatarUrl || ""
  };
}

function serializeRecentShop(entry) {
  const shop = entry.shopId;

  return {
    slug: shop.slug,
    basePath: `/shop/${shop.slug}`,
    name: shop.name,
    address: shop.address || "",
    description: shop.description || "",
    logoUrl: shop.logoUrl || "",
    savedAt: entry.lastOpenedAt || entry.updatedAt || entry.createdAt
  };
}

function signCustomerToken(customer) {
  return jwt.sign(
    {
      customerId: String(customer._id)
    },
    env.jwtSecret,
    { expiresIn: "30d" }
  );
}

async function getCustomerSession(req) {
  const header = req.header("authorization") || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";

  if (!token) {
    return null;
  }

  try {
    const payload = jwt.verify(token, env.jwtSecret);
    const customer = await Customer.findById(payload.customerId).select("name phone address avatarUrl");

    if (!customer) {
      return null;
    }

    return serializeCustomer(customer);
  } catch (_error) {
    return null;
  }
}

async function getShop(req, res) {
  const shop = await Shop.findOne({
    slug: req.params.slug,
    isActive: true
  }).select("name slug address phone whatsappNumber logoUrl description settings payment");

  if (!shop) {
    throw new ApiError(404, "Shop not found");
  }

  const products = await Product.find({
    shopId: shop._id,
    isAvailable: true
  })
    .sort({ sortOrder: 1, name: 1 })
    .select("name description price codPrice onlinePrice imageUrl category isAvailable sortOrder");

  res.json({
    success: true,
    data: {
      shop: {
        id: shop._id,
        name: shop.name,
        slug: shop.slug,
        address: shop.address,
        logoUrl: shop.logoUrl,
        description: shop.description,
        settings: shop.settings,
        payment: shop.payment
      },
      products
    }
  });
}

async function createOrder(req, res) {
  const customerSession = await getCustomerSession(req);
  const order = await createOrderForShop(req.params.slug, req.body, customerSession);

  res.status(201).json({
    success: true,
    data: {
      orderId: order._id,
      orderNumber: order.orderNumber,
      status: order.status,
      totalAmount: order.totalAmount,
      pricing: order.pricing,
      payment: order.payment,
      fcmStatus: order.notification.fcmStatus,
      whatsappFallbackUrl: order.notification.whatsappFallbackUrl
    }
  });
}

async function verifyCustomerOtp(req, res) {
  const cleanPhone = normalizePhone(req.body.phone);
  const cleanName = String(req.body.name || "").trim();
  const otp = String(req.body.otp || "").trim();

  if (!cleanPhone) {
    throw new ApiError(400, "Phone number is required");
  }

  if (cleanPhone.length < 10) {
    throw new ApiError(400, "Enter a valid phone number");
  }

  if (otp !== STATIC_CUSTOMER_OTP) {
    throw new ApiError(401, "Invalid OTP");
  }

  const customer = await Customer.findOneAndUpdate(
    { phone: cleanPhone },
    {
      $set: {
        phone: cleanPhone,
        lastLoginAt: new Date(),
        ...(cleanName ? { name: cleanName } : {})
      },
      $setOnInsert: {
        name: cleanName
      }
    },
    {
      upsert: true,
      new: true,
      setDefaultsOnInsert: true
    }
  );

  res.json({
    success: true,
    data: {
      token: signCustomerToken(customer),
      customer: serializeCustomer(customer)
    }
  });
}

async function saveCustomerFcmToken(req, res) {
  const { fcmToken } = req.body;

  if (!fcmToken || typeof fcmToken !== "string") {
    throw new ApiError(400, "fcmToken is required");
  }

  const order = await Order.findById(req.params.orderId);

  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  order.customer.fcmToken = fcmToken;
  await order.save();

  res.json({
    success: true,
    message: "Customer notifications enabled for this order"
  });
}

async function requireCustomer(req) {
  const header = req.header("authorization") || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";

  if (!token) {
    throw new ApiError(401, "Please login with your phone number");
  }

  try {
    const payload = jwt.verify(token, env.jwtSecret);
    const customer = await Customer.findById(payload.customerId);

    if (!customer) {
      throw new ApiError(401, "Customer session expired");
    }

    return customer;
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }

    throw new ApiError(401, "Customer session expired");
  }
}

async function updateCustomerProfile(req, res) {
  const customer = await requireCustomer(req);
  const cleanName = String(req.body.name || "").trim();
  const cleanAddress = String(req.body.address || "").trim();

  if (!cleanName) {
    throw new ApiError(400, "Name is required");
  }

  customer.name = cleanName;
  customer.address = cleanAddress;
  await customer.save();

  res.json({
    success: true,
    data: {
      customer: serializeCustomer(customer)
    }
  });
}

async function uploadCustomerAvatar(req, res) {
  const customer = await requireCustomer(req);

  if (!req.file) {
    throw new ApiError(400, "Please upload a profile image");
  }

  customer.avatarUrl = await uploadImage(req.file, {
    folder: "qrmart/customer-avatars"
  });
  await customer.save();

  res.json({
    success: true,
    data: {
      customer: serializeCustomer(customer)
    }
  });
}

async function listRecentShops(req, res) {
  const customer = await requireCustomer(req);
  const recentShops = await CustomerRecentShop.find({ customerId: customer._id })
    .sort({ lastOpenedAt: -1 })
    .limit(12)
    .populate({
      path: "shopId",
      match: { isActive: true },
      select: "name slug address logoUrl description"
    });

  res.json({
    success: true,
    data: recentShops.filter((entry) => entry.shopId).map(serializeRecentShop)
  });
}

async function recordRecentShop(req, res) {
  const customer = await requireCustomer(req);
  const shop = await Shop.findOne({
    slug: req.params.slug,
    isActive: true
  }).select("name slug address logoUrl description");

  if (!shop) {
    throw new ApiError(404, "Shop not found");
  }

  const recentShop = await CustomerRecentShop.findOneAndUpdate(
    {
      customerId: customer._id,
      shopId: shop._id
    },
    {
      $set: {
        lastOpenedAt: new Date()
      },
      $inc: {
        openCount: 1
      }
    },
    {
      upsert: true,
      new: true,
      setDefaultsOnInsert: true
    }
  ).populate({
    path: "shopId",
    select: "name slug address logoUrl description"
  });

  res.status(201).json({
    success: true,
    data: serializeRecentShop(recentShop)
  });
}

async function getOrderStatus(req, res) {
  const order = await Order.findById(req.params.orderId).select(
    "orderNumber customer items pricing payment totalAmount status rejectionReason timeline createdAt updatedAt"
  );

  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  const orderWithImages = await attachOrderItemImages(order);

  res.json({
    success: true,
    data: {
      orderId: orderWithImages._id,
      orderNumber: orderWithImages.orderNumber,
      status: orderWithImages.status,
      rejectionReason: orderWithImages.rejectionReason || "",
      items: orderWithImages.items,
      totalAmount: orderWithImages.totalAmount,
      pricing: orderWithImages.pricing,
      payment: orderWithImages.payment,
      customerSnapshot: {
        address: orderWithImages.customer?.address || "",
        note: orderWithImages.customer?.note || ""
      },
      timeline: orderWithImages.timeline,
      createdAt: orderWithImages.createdAt,
      updatedAt: orderWithImages.updatedAt
    }
  });
}

async function attachOrderItemImages(order) {
  const plainOrder = typeof order.toObject === "function" ? order.toObject() : order;
  const missingImageProductIds = (plainOrder.items || [])
    .filter((item) => !item.imageUrl && item.productId)
    .map((item) => String(item.productId));

  if (!missingImageProductIds.length) {
    return plainOrder;
  }

  const products = await Product.find({ _id: { $in: missingImageProductIds } }).select("imageUrl");
  const imageByProductId = new Map(
    products.map((product) => [String(product._id), product.imageUrl || ""])
  );

  return {
    ...plainOrder,
    items: (plainOrder.items || []).map((item) => ({
      ...item,
      imageUrl: item.imageUrl || imageByProductId.get(String(item.productId)) || ""
    }))
  };
}

module.exports = {
  getShop,
  createOrder,
  saveCustomerFcmToken,
  verifyCustomerOtp,
  updateCustomerProfile,
  uploadCustomerAvatar,
  listRecentShops,
  recordRecentShop,
  getOrderStatus
};
