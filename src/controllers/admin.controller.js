const ApiError = require("../utils/ApiError");
const slugify = require("../utils/slugify");
const buildShopUrl = require("../utils/shopUrl");
const Shop = require("../models/Shop");
const Product = require("../models/Product");
const { toDataUrl } = require("../services/qr.service");

async function createShop(req, res) {
  const { name, ownerName, phone, whatsappNumber, address, settings } = req.body;

  if (!name || !whatsappNumber) {
    throw new ApiError(400, "Shop name and WhatsApp number are required");
  }

  const baseSlug = slugify(req.body.slug || name);

  if (!baseSlug) {
    throw new ApiError(400, "Invalid shop slug");
  }

  let slug = baseSlug;
  let counter = 1;

  while (await Shop.exists({ slug })) {
    counter += 1;
    slug = `${baseSlug}-${counter}`;
  }

  const qrUrl = buildShopUrl(slug);

  const shop = await Shop.create({
    name,
    slug,
    ownerName,
    phone,
    whatsappNumber,
    address,
    qrUrl,
    settings
  });

  res.status(201).json({
    success: true,
    data: shop
  });
}

async function listShops(_req, res) {
  const shops = await Shop.find().sort({ createdAt: -1 });

  res.json({
    success: true,
    data: shops
  });
}

async function createProduct(req, res) {
  const { shopId } = req.params;
  const { name, description, price, imageUrl, category, isAvailable, sortOrder } = req.body;

  if (!name || price === undefined) {
    throw new ApiError(400, "Product name and price are required");
  }

  const shop = await Shop.findById(shopId);

  if (!shop) {
    throw new ApiError(404, "Shop not found");
  }

  const product = await Product.create({
    shopId,
    name,
    description,
    price,
    imageUrl,
    category,
    isAvailable,
    sortOrder
  });

  res.status(201).json({
    success: true,
    data: product
  });
}

async function updateProduct(req, res) {
  const product = await Product.findByIdAndUpdate(req.params.productId, req.body, {
    new: true,
    runValidators: true
  });

  if (!product) {
    throw new ApiError(404, "Product not found");
  }

  res.json({
    success: true,
    data: product
  });
}

async function getShopQr(req, res) {
  const shop = await Shop.findById(req.params.shopId);

  if (!shop) {
    throw new ApiError(404, "Shop not found");
  }

  const qrUrl = buildShopUrl(shop.slug);
  const qrDataUrl = await toDataUrl(qrUrl);

  res.json({
    success: true,
    data: {
      qrUrl,
      qrDataUrl
    }
  });
}

module.exports = {
  createShop,
  listShops,
  createProduct,
  updateProduct,
  getShopQr
};
