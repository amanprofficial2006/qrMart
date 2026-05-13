const express = require("express");
const asyncHandler = require("../utils/asyncHandler");
const publicController = require("../controllers/public.controller");
const { publicOrderLimiter } = require("../middlewares/rateLimit.middleware");
const { uploadCustomerAvatar } = require("../middlewares/upload.middleware");

const router = express.Router();

router.get("/shops/:slug", asyncHandler(publicController.getShop));
router.post("/customers/verify-otp", publicOrderLimiter, asyncHandler(publicController.verifyCustomerOtp));
router.patch("/customers/profile", asyncHandler(publicController.updateCustomerProfile));
router.post("/customers/profile/avatar", uploadCustomerAvatar.single("avatar"), asyncHandler(publicController.uploadCustomerAvatar));
router.get("/customers/recent-shops", asyncHandler(publicController.listRecentShops));
router.post("/customers/recent-shops/:slug", asyncHandler(publicController.recordRecentShop));
router.post("/shops/:slug/orders", publicOrderLimiter, asyncHandler(publicController.createOrder));
router.get("/orders/:orderId/status", asyncHandler(publicController.getOrderStatus));
router.post("/orders/:orderId/customer-token", asyncHandler(publicController.saveCustomerFcmToken));

module.exports = router;
