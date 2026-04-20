const mongoose = require("mongoose");

const shopSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true
    },
    slug: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true
    },
    ownerName: {
      type: String,
      trim: true
    },
    logoUrl: {
      type: String,
      trim: true,
      default: ""
    },
    phone: {
      type: String,
      trim: true
    },
    whatsappNumber: {
      type: String,
      required: true,
      trim: true
    },
    address: {
      type: String,
      trim: true
    },
    description: {
      type: String,
      trim: true,
      default: ""
    },
    payment: {
      upiId: {
        type: String,
        trim: true,
        default: ""
      },
      qrCodeUrl: {
        type: String,
        trim: true,
        default: ""
      }
    },
    isActive: {
      type: Boolean,
      default: true
    },
    qrUrl: {
      type: String,
      trim: true
    },
    settings: {
      allowPickup: {
        type: Boolean,
        default: true
      },
      allowTableNumber: {
        type: Boolean,
        default: false
      },
      autoWhatsAppFallback: {
        type: Boolean,
        default: true
      },
      deliveryCharge: {
        type: Number,
        min: 0,
        default: 0
      }
    }
  },
  {
    timestamps: true
  }
);

shopSchema.index({ isActive: 1 });

module.exports = mongoose.model("Shop", shopSchema);
