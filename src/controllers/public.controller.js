const jwt = require("jsonwebtoken");
const env = require("../config/env");
const Shop = require("../models/Shop");
const Product = require("../models/Product");
const Order = require("../models/Order");
const Customer = require("../models/Customer");
const { createOrderForShop } = require("../services/order.service");
const ApiError = require("../utils/ApiError");

const STATIC_CUSTOMER_OTP = "142006";

function normalizePhone(phone) {
  return String(phone || "").replace(/\D/g, "");
}

function serializeCustomer(customer) {
  return {
    id: customer._id,
    name: customer.name,
    phone: customer.phone
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
    const customer = await Customer.findById(payload.customerId).select("name phone");

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
    .select("name description price imageUrl category isAvailable sortOrder");

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

async function getOrderStatus(req, res) {
  const order = await Order.findById(req.params.orderId).select(
    "orderNumber customer pricing payment totalAmount status timeline createdAt updatedAt"
  );

  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  res.json({
    success: true,
    data: {
      orderId: order._id,
      orderNumber: order.orderNumber,
      status: order.status,
      totalAmount: order.totalAmount,
      pricing: order.pricing,
      payment: order.payment,
      customerSnapshot: {
        address: order.customer?.address || "",
        note: order.customer?.note || ""
      },
      timeline: order.timeline,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt
    }
  });
}

module.exports = {
  getShop,
  createOrder,
  saveCustomerFcmToken,
  verifyCustomerOtp,
  getOrderStatus
};
