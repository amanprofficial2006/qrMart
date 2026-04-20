const mongoose = require("mongoose");

const notificationLogSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Shop",
      required: true,
      index: true
    },
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Order",
      required: true,
      index: true
    },
    channel: {
      type: String,
      enum: ["fcm", "whatsapp"],
      required: true
    },
    status: {
      type: String,
      enum: ["sent", "partial", "failed", "skipped"],
      required: true
    },
    providerMessageId: {
      type: String,
      default: ""
    },
    error: {
      type: String,
      default: ""
    }
  },
  {
    timestamps: true
  }
);

notificationLogSchema.index({ shopId: 1, createdAt: -1 });
notificationLogSchema.index({ orderId: 1, channel: 1 });

module.exports = mongoose.model("NotificationLog", notificationLogSchema);

