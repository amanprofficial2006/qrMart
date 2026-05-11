const crypto = require("crypto");
const env = require("../config/env");
const ApiError = require("../utils/ApiError");

function parseCloudinaryUrl(value) {
  if (!value) {
    return null;
  }

  let parsed;

  try {
    parsed = new URL(value);
  } catch (_error) {
    throw new Error("Invalid CLOUDINARY_URL format");
  }

  if (parsed.protocol !== "cloudinary:") {
    throw new Error("CLOUDINARY_URL must start with cloudinary://");
  }

  const cloudName = decodeURIComponent(parsed.hostname || "").trim();
  const apiKey = decodeURIComponent(parsed.username || "").trim();
  const apiSecret = decodeURIComponent(parsed.password || "").trim();

  if (!cloudName || !apiKey || !apiSecret) {
    throw new Error("CLOUDINARY_URL must include cloud name, api key, and api secret");
  }

  return {
    cloudName,
    apiKey,
    apiSecret
  };
}

const cloudinaryConfig = parseCloudinaryUrl(env.cloudinaryUrl);

function isCloudinaryConfigured() {
  return Boolean(cloudinaryConfig);
}

function buildSignature(params, apiSecret) {
  const payload = Object.entries(params)
    .filter(([, value]) => value !== undefined && value !== null && value !== "")
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([key, value]) => `${key}=${value}`)
    .join("&");

  return crypto.createHash("sha1").update(`${payload}${apiSecret}`).digest("hex");
}

function normalizeFolder(folder) {
  return String(folder || "")
    .trim()
    .replace(/^\/+|\/+$/g, "");
}

async function uploadImage(file, options = {}) {
  if (!file?.buffer?.length) {
    return "";
  }

  if (!cloudinaryConfig) {
    return `data:${file.mimetype};base64,${file.buffer.toString("base64")}`;
  }

  const folder = normalizeFolder(options.folder || "qrmart");
  const timestamp = Math.floor(Date.now() / 1000);
  const paramsToSign = {
    folder,
    timestamp
  };
  const formData = new FormData();
  const blob = new Blob([file.buffer], {
    type: file.mimetype || "application/octet-stream"
  });

  formData.append("file", blob, file.originalname || file.filename || "upload");
  formData.append("api_key", cloudinaryConfig.apiKey);
  formData.append("timestamp", String(timestamp));
  formData.append("folder", folder);
  formData.append("signature", buildSignature(paramsToSign, cloudinaryConfig.apiSecret));

  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${cloudinaryConfig.cloudName}/image/upload`,
    {
      method: "POST",
      body: formData
    }
  );

  const payload = await response.json().catch(() => ({}));

  if (!response.ok) {
    const message = payload?.error?.message || "Cloudinary upload failed";
    throw new ApiError(502, message);
  }

  return String(payload.secure_url || payload.url || "").trim();
}

module.exports = {
  isCloudinaryConfigured,
  uploadImage
};
