const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const env = require("./config/env");
const publicRoutes = require("./routes/public.routes");
const adminRoutes = require("./routes/admin.routes");
const ownerRoutes = require("./routes/owner.routes");
const authRoutes = require("./routes/auth.routes");
const { requireApiKey, requireOwnerAuth } = require("./middlewares/auth.middleware");
const { notFound, errorHandler } = require("./middlewares/error.middleware");

const app = express();

app.set("trust proxy", 1);

app.use(
  helmet({
    crossOriginResourcePolicy: false
  })
);
app.use(
  cors({
    origin: env.corsOrigin === "*" ? true : env.corsOrigin,
    credentials: true
  })
);
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static("uploads"));

if (env.nodeEnv !== "test") {
  app.use(morgan("dev"));
}

app.get("/health", (_req, res) => {
  res.json({
    success: true,
    message: "qrMart API is healthy"
  });
});

app.use("/api/v1/public", publicRoutes);
app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/admin", requireApiKey("admin"), adminRoutes);
app.use("/api/v1/owner", requireOwnerAuth, ownerRoutes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
