const express = require("express");
const asyncHandler = require("../utils/asyncHandler");
const publicController = require("../controllers/public.controller");
const { publicOrderLimiter } = require("../middlewares/rateLimit.middleware");

const router = express.Router();

router.get("/shops/:slug", asyncHandler(publicController.getShop));
router.post("/shops/:slug/orders", publicOrderLimiter, asyncHandler(publicController.createOrder));
router.post("/orders/:orderId/customer-token", asyncHandler(publicController.saveCustomerFcmToken));

module.exports = router;
