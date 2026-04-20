const multer = require("multer");
const ApiError = require("../utils/ApiError");

function imageFilter(_req, file, cb) {
  if (!["image/jpeg", "image/png", "image/webp"].includes(file.mimetype)) {
    return cb(new ApiError(400, "Only JPG, PNG, or WebP images are allowed"));
  }

  return cb(null, true);
}

const limits = {
  fileSize: 2 * 1024 * 1024
};

const uploadShopLogo = multer({
  storage: multer.memoryStorage(),
  fileFilter: imageFilter,
  limits
});

const uploadProductImage = multer({
  storage: multer.memoryStorage(),
  fileFilter: imageFilter,
  limits
});

const uploadPaymentQr = multer({
  storage: multer.memoryStorage(),
  fileFilter: imageFilter,
  limits
});

module.exports = {
  uploadShopLogo,
  uploadProductImage,
  uploadPaymentQr
};
