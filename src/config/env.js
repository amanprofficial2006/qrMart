const path = require("path");
const dotenv = require("dotenv");

dotenv.config();

const required = ["MONGODB_URI", "JWT_SECRET"];

for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}

module.exports = {
  nodeEnv: process.env.NODE_ENV || "development",
  port: Number(process.env.PORT || 5000),
  appBaseUrl: process.env.APP_BASE_URL || "http://localhost:5000",
  corsOrigin: process.env.CORS_ORIGIN || "*",
  mongodbUri: process.env.MONGODB_URI,
  firebaseServiceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH
    ? path.resolve(process.cwd(), process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
    : "",
  firebaseServiceAccountBase64: process.env.FIREBASE_SERVICE_ACCOUNT_BASE64 || "",
  adminApiKey: process.env.ADMIN_API_KEY || "",
  ownerApiKey: process.env.OWNER_API_KEY || "",
  jwtSecret: process.env.JWT_SECRET || ""
};
