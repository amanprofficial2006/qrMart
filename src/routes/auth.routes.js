const express = require("express");
const asyncHandler = require("../utils/asyncHandler");
const authController = require("../controllers/auth.controller");
const { requireOwnerAuth } = require("../middlewares/auth.middleware");
const { uploadShopVerificationPhotos } = require("../middlewares/upload.middleware");

const router = express.Router();

router.post(
  "/register",
  uploadShopVerificationPhotos.array("shopPhotos", 6),
  asyncHandler(authController.register)
);
router.post("/google", asyncHandler(authController.google));
router.post("/login", asyncHandler(authController.login));
router.get("/me", requireOwnerAuth, asyncHandler(authController.me));

module.exports = router;
