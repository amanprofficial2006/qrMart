const express = require("express");
const asyncHandler = require("../utils/asyncHandler");
const authController = require("../controllers/auth.controller");
const { requireOwnerAuth } = require("../middlewares/auth.middleware");

const router = express.Router();

router.post("/register", asyncHandler(authController.register));
router.post("/login", asyncHandler(authController.login));
router.get("/me", requireOwnerAuth, asyncHandler(authController.me));

module.exports = router;

