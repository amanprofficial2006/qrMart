const multer = require("multer");
const ApiError = require("../utils/ApiError");

function imageFilter(_req, file, cb) {
  if (!String(file.mimetype || "").toLowerCase().startsWith("image/")) {
    return cb(new ApiError(400, "Only image files are allowed"));
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

const uploadShopVerificationPhotos = multer({
  storage: multer.memoryStorage(),
  fileFilter: imageFilter,
  limits
});

module.exports = {
  uploadShopLogo,
  uploadProductImage,
  uploadPaymentQr,
  uploadShopVerificationPhotos
};
