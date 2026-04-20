const mongoose = require("mongoose");

const ownerDeviceSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Shop",
      required: true,
      index: true
    },
    ownerId: {
      type: String,
      trim: true,
      default: ""
    },
    platform: {
      type: String,
      enum: ["android", "ios", "web"],
      default: "android"
    },
    fcmToken: {
      type: String,
      required: true,
      unique: true
    },
    isActive: {
      type: Boolean,
      default: true
    },
    lastSeenAt: {
      type: Date,
      default: Date.now
    }
  },
  {
    timestamps: true
  }
);

ownerDeviceSchema.index({ shopId: 1, isActive: 1 });

module.exports = mongoose.model("OwnerDevice", ownerDeviceSchema);
