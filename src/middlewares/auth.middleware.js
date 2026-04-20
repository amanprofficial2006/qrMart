const ApiError = require("../utils/ApiError");
const env = require("../config/env");
const jwt = require("jsonwebtoken");
const Owner = require("../models/Owner");

function requireApiKey(kind) {
  return (req, _res, next) => {
    const apiKey = req.header("x-api-key");
    const expected = kind === "admin" ? env.adminApiKey : env.ownerApiKey;

    if (!expected || expected.startsWith("change-this")) {
      return next(new ApiError(500, `${kind} API key is not configured safely`));
    }

    if (!apiKey || apiKey !== expected) {
      return next(new ApiError(401, "Invalid or missing API key"));
    }

    next();
  };
}

module.exports = {
  requireApiKey,
  requireOwnerAuth
};

async function requireOwnerAuth(req, _res, next) {
  try {
    const header = req.header("authorization") || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : "";

    if (!token) {
      throw new ApiError(401, "Missing authentication token");
    }

    const payload = jwt.verify(token, env.jwtSecret);
    const owner = await Owner.findById(payload.ownerId).select("-passwordHash");

    if (!owner || !owner.isActive) {
      throw new ApiError(401, "Owner account is inactive or unavailable");
    }

    req.owner = owner;
    req.shopId = owner.shopId;
    next();
  } catch (error) {
    if (error instanceof ApiError) {
      return next(error);
    }

    return next(new ApiError(401, "Invalid or expired authentication token"));
  }
}
