const path = require("path");
const multer = require("multer");
const ApiError = require("../utils/ApiError");

const imageExtensions = new Set([
  ".avif",
  ".bmp",
  ".gif",
  ".heic",
  ".heif",
  ".jpeg",
  ".jpg",
  ".png",
  ".svg",
  ".tif",
  ".tiff",
  ".webp"
]);

function hasImageExtension(filename) {
  const extension = path.extname(String(filename || "")).toLowerCase();
  return imageExtensions.has(extension);
}

function imageFilter(_req, file, cb) {
  const mimeType = String(file.mimetype || "").toLowerCase();
  const originalName = String(file.originalname || file.filename || "");

  if (!mimeType.startsWith("image/") && !hasImageExtension(originalName)) {
    return cb(new ApiError(400, "Only image files are allowed"));
  }

  return cb(null, true);
}

const defaultLimits = {
  fileSize: 2 * 1024 * 1024
};

const verificationPhotoLimits = {
  fileSize: 8 * 1024 * 1024
};

const uploadShopLogo = multer({
  storage: multer.memoryStorage(),
  fileFilter: imageFilter,
  limits: defaultLimits
});

const uploadProductImage = multer({
  storage: multer.memoryStorage(),
  fileFilter: imageFilter,
  limits: defaultLimits
});

const uploadPaymentQr = multer({
  storage: multer.memoryStorage(),
  fileFilter: imageFilter,
  limits: defaultLimits
});

const uploadCustomerAvatar = multer({
  storage: multer.memoryStorage(),
  fileFilter: imageFilter,
  limits: defaultLimits
});

const uploadShopVerificationPhotos = multer({
  storage: multer.memoryStorage(),
  fileFilter: imageFilter,
  limits: verificationPhotoLimits
});

module.exports = {
  uploadShopLogo,
  uploadProductImage,
  uploadPaymentQr,
  uploadCustomerAvatar,
  uploadShopVerificationPhotos
};
