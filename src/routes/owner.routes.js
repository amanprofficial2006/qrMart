const express = require("express");
const asyncHandler = require("../utils/asyncHandler");
const ownerController = require("../controllers/owner.controller");
const { uploadPaymentQr, uploadProductImage, uploadShopLogo } = require("../middlewares/upload.middleware");

const router = express.Router();

router.get("/profile", asyncHandler(ownerController.getProfile));
router.patch("/profile", asyncHandler(ownerController.updateProfile));
router.post("/profile/logo", uploadShopLogo.single("logo"), asyncHandler(ownerController.uploadLogo));
router.post("/profile/payment-qr", uploadPaymentQr.single("paymentQr"), asyncHandler(ownerController.uploadPaymentQr));

router.get("/products", asyncHandler(ownerController.listProducts));
router.post("/products", uploadProductImage.single("image"), asyncHandler(ownerController.createProduct));
router.patch("/products/:productId", uploadProductImage.single("image"), asyncHandler(ownerController.updateProduct));
router.delete("/products/:productId", asyncHandler(ownerController.deleteProduct));

router.post("/devices", asyncHandler(ownerController.registerDevice));
router.post("/send-notification", asyncHandler(ownerController.sendOrderNotification));
router.get("/orders", asyncHandler(ownerController.listOrders));
router.get("/orders/:orderId", asyncHandler(ownerController.getOrder));
router.patch("/orders/:orderId/status", asyncHandler(ownerController.updateOrderStatus));
router.get("/qr", asyncHandler(ownerController.getQr));
router.post("/qr/refresh", asyncHandler(ownerController.refreshQr));

module.exports = router;
