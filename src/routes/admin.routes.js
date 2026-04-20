const express = require("express");
const asyncHandler = require("../utils/asyncHandler");
const adminController = require("../controllers/admin.controller");

const router = express.Router();

router.post("/shops", asyncHandler(adminController.createShop));
router.get("/shops", asyncHandler(adminController.listShops));
router.get("/shops/:shopId/qr", asyncHandler(adminController.getShopQr));
router.post("/shops/:shopId/products", asyncHandler(adminController.createProduct));
router.patch("/products/:productId", asyncHandler(adminController.updateProduct));

module.exports = router;

