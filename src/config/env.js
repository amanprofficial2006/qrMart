const path = require("path");
const dotenv = require("dotenv");

dotenv.config();

const nodeEnv = process.env.NODE_ENV || "development";
const required = ["MONGODB_URI", "JWT_SECRET"];
const defaultCorsOrigins = [
  "http://localhost:5173",
  "http://localhost:5174",
  "https://qrmart-01.onrender.com",
  "https://qrmart.onrender.com"
];
const defaultAppBaseUrl = nodeEnv === "production" ? "https://qrmart-01.onrender.com" : "http://localhost:5173";

function parseCorsOrigins(value) {
  if (!value || value === "*") {
    return value || defaultCorsOrigins;
  }

  const origins = value
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);

  for (const origin of defaultCorsOrigins) {
    if (!origins.includes(origin)) {
      origins.push(origin);
    }
  }

  return origins.length ? origins : defaultCorsOrigins;
}

for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}

module.exports = {
  nodeEnv,
  port: Number(process.env.PORT || 5000),
  appBaseUrl: process.env.APP_BASE_URL || defaultAppBaseUrl,
  corsOrigin: parseCorsOrigins(process.env.CORS_ORIGIN),
  mongodbUri: process.env.MONGODB_URI,
  firebaseServiceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH
    ? path.resolve(process.cwd(), process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
    : "",
  firebaseServiceAccountBase64: process.env.FIREBASE_SERVICE_ACCOUNT_BASE64 || "",
  adminApiKey: process.env.ADMIN_API_KEY || "",
  ownerApiKey: process.env.OWNER_API_KEY || "",
  jwtSecret: process.env.JWT_SECRET || ""
};
