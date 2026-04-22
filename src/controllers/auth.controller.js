const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const env = require("../config/env");
const ApiError = require("../utils/ApiError");
const slugify = require("../utils/slugify");
const buildShopUrl = require("../utils/shopUrl");
const { googleClientId } = require("../config/google");
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

async function verifyGoogleCredential(credential) {
  if (!googleClientId) {
    throw new ApiError(500, "Google sign-in is not configured");
  }

  if (!credential) {
    throw new ApiError(400, "Google credential is required");
  }

  if (typeof fetch !== "function") {
    throw new ApiError(500, "Google sign-in requires Node.js 18 or newer");
  }

  const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(credential)}`);
  const profile = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new ApiError(401, profile.error_description || "Invalid Google credential");
  }

  if (profile.aud !== googleClientId) {
    throw new ApiError(401, "Google credential was issued for another app");
  }

  if (profile.email_verified !== "true" && profile.email_verified !== true) {
    throw new ApiError(401, "Google email is not verified");
  }

  return {
    googleSub: profile.sub,
    email: String(profile.email || "").toLowerCase().trim(),
    name: String(profile.name || profile.email || "Shop owner").trim()
  };
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
    passwordHash,
    authProvider: "password"
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

async function google(req, res) {
  const { credential, name = "", phone = "", shopName = "", password = "" } = req.body;
  const profile = await verifyGoogleCredential(credential);

  if (!profile.email || !profile.googleSub) {
    throw new ApiError(401, "Google account did not return a valid profile");
  }

  let owner = await Owner.findOne({
    $or: [{ googleSub: profile.googleSub }, { email: profile.email }],
    isActive: true
  });

  if (owner) {
    if (!owner.googleSub) {
      owner.googleSub = profile.googleSub;
    }

    if (!owner.email) {
      owner.email = profile.email;
    }

    owner.authProvider = owner.authProvider || "google";
    owner.lastLoginAt = new Date();
    await owner.save();

    const shop = await Shop.findById(owner.shopId);

    return res.json({
      success: true,
      data: {
        token: signOwnerToken(owner),
        owner: serializeOwner(owner),
        shop
      }
    });
  }

  const cleanPhone = normalizePhone(phone);

  if (!shopName || !cleanPhone || !password) {
    return res.json({
      success: true,
      data: {
        needsProfile: true,
        profile: {
          name: profile.name,
          email: profile.email
        }
      }
    });
  }

  if (password.length < 6) {
    throw new ApiError(400, "Password must be at least 6 characters");
  }

  if (await Owner.exists({ phone: cleanPhone })) {
    throw new ApiError(409, "An owner account with this phone already exists");
  }

  const slug = await createUniqueSlug(shopName);
  const qrUrl = buildShopUrl(slug);

  const shop = await Shop.create({
    name: shopName,
    slug,
    ownerName: name || profile.name,
    phone: cleanPhone,
    whatsappNumber: cleanPhone,
    qrUrl,
    isActive: true
  });

  owner = await Owner.create({
    shopId: shop._id,
    name: name || profile.name,
    phone: cleanPhone,
    email: profile.email,
    passwordHash: await bcrypt.hash(password, 12),
    authProvider: "google",
    googleSub: profile.googleSub
  });

  return res.status(201).json({
    success: true,
    data: {
      token: signOwnerToken(owner),
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

  if (!owner || !owner.passwordHash || !(await bcrypt.compare(password, owner.passwordHash))) {
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
  google,
  login,
  me
};
