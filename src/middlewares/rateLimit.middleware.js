const { rateLimit } = require("express-rate-limit");

const publicOrderLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: "Too many requests. Please try again in a minute."
  }
});

module.exports = {
  publicOrderLimiter
};
