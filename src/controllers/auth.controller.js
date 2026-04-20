const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const env = require("../config/env");
const ApiError = require("../utils/ApiError");
const slugify = require("../utils/slugify");
const buildShopUrl = require("../utils/shopUrl");
const Owner = require("../models/Owner");
const Shop = require("../models/Shop");

function normalizePhone(phone) {
  return String(phone || "").replace(/\D/g, "");
}

function signOwnerToken(owner) {
  return jwt.sign(
    {
      ownerId: String(owner._id),
      shopId: String(owner.shopId)
    },
    env.jwtSecret,
    { expiresIn: "30d" }
  );
}

function serializeOwner(owner) {
  return {
    id: owner._id,
    name: owner.name,
    phone: owner.phone,
    email: owner.email,
    shopId: owner.shopId
  };
}

async function createUniqueSlug(name) {
  const baseSlug = slugify(name);

  if (!baseSlug) {
    throw new ApiError(400, "Please enter a valid shop name");
  }

  let slug = baseSlug;
  let counter = 1;

  while (await Shop.exists({ slug })) {
    counter += 1;
    slug = `${baseSlug}-${counter}`;
  }

  return slug;
}

async function register(req, res) {
  const { name, phone, email = "", password, shopName } = req.body;
  const cleanPhone = normalizePhone(phone);

  if (!name || !cleanPhone || !password || !shopName) {
    throw new ApiError(400, "Name, phone, password, and shop name are required");
  }

  if (password.length < 6) {
    throw new ApiError(400, "Password must be at least 6 characters");
  }

  if (await Owner.exists({ phone: cleanPhone })) {
    throw new ApiError(409, "An owner account with this phone already exists");
  }

  if (email && (await Owner.exists({ email: email.toLowerCase().trim() }))) {
    throw new ApiError(409, "An owner account with this email already exists");
  }

  const slug = await createUniqueSlug(shopName);
  const qrUrl = buildShopUrl(slug);

  const shop = await Shop.create({
    name: shopName,
    slug,
    ownerName: name,
    phone: cleanPhone,
    whatsappNumber: cleanPhone,
    qrUrl,
    isActive: true
  });

  const passwordHash = await bcrypt.hash(password, 12);
  const owner = await Owner.create({
    shopId: shop._id,
    name,
    phone: cleanPhone,
    email: email.toLowerCase().trim(),
    passwordHash
  });

  const token = signOwnerToken(owner);

  res.status(201).json({
    success: true,
    data: {
      token,
      owner: serializeOwner(owner),
      shop
    }
  });
}

async function login(req, res) {
  const { identifier, phone, email, password } = req.body;
  const loginId = identifier || phone || email;

  if (!loginId || !password) {
    throw new ApiError(400, "Phone/email and password are required");
  }

  const cleanPhone = normalizePhone(loginId);
  const owner = await Owner.findOne({
    $or: [
      { phone: cleanPhone },
      { email: String(loginId).toLowerCase().trim() }
    ],
    isActive: true
  });

  if (!owner || !(await bcrypt.compare(password, owner.passwordHash))) {
    throw new ApiError(401, "Invalid login details");
  }

  owner.lastLoginAt = new Date();
  await owner.save();

  const shop = await Shop.findById(owner.shopId);

  res.json({
    success: true,
    data: {
      token: signOwnerToken(owner),
      owner: serializeOwner(owner),
      shop
    }
  });
}

async function me(req, res) {
  const shop = await Shop.findById(req.owner.shopId);

  res.json({
    success: true,
    data: {
      owner: serializeOwner(req.owner),
      shop
    }
  });
}

module.exports = {
  register,
  login,
  me
};
