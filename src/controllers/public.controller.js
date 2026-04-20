const Shop = require("../models/Shop");
const Product = require("../models/Product");
const Order = require("../models/Order");
const { createOrderForShop } = require("../services/order.service");
const ApiError = require("../utils/ApiError");

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
  const order = await createOrderForShop(req.params.slug, req.body);

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

module.exports = {
  getShop,
  createOrder,
  saveCustomerFcmToken
};
