const fs = require("fs");
const path = require("path");
const multer = require("multer");
const ApiError = require("../utils/ApiError");

const uploadRoot = path.join(process.cwd(), "uploads");
const shopLogoDir = path.join(uploadRoot, "shops");
const productImageDir = path.join(uploadRoot, "products");
const paymentQrDir = path.join(uploadRoot, "payments");

for (const dir of [uploadRoot, shopLogoDir, productImageDir, paymentQrDir]) {
  fs.mkdirSync(dir, { recursive: true });
}

function imageFilter(_req, file, cb) {
  if (!["image/jpeg", "image/png", "image/webp"].includes(file.mimetype)) {
    return cb(new ApiError(400, "Only JPG, PNG, or WebP images are allowed"));
  }

  return cb(null, true);
}

function createStorage(folder) {
  return multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, folder),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase();
      const safeName = `${Date.now()}-${Math.random().toString(36).slice(2, 9)}${ext}`;
      cb(null, safeName);
    }
  });
}

const limits = {
  fileSize: 2 * 1024 * 1024
};

const uploadShopLogo = multer({
  storage: createStorage(shopLogoDir),
  fileFilter: imageFilter,
  limits
});

const uploadProductImage = multer({
  storage: createStorage(productImageDir),
  fileFilter: imageFilter,
  limits
});

const uploadPaymentQr = multer({
  storage: createStorage(paymentQrDir),
  fileFilter: imageFilter,
  limits
});

module.exports = {
  uploadShopLogo,
  uploadProductImage,
  uploadPaymentQr
};
