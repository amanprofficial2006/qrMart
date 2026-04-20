const mongoose = require("mongoose");

const orderItemSchema = new mongoose.Schema(
  {
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      required: true
    },
    name: {
      type: String,
      required: true
    },
    price: {
      type: Number,
      required: true,
      min: 0
    },
    quantity: {
      type: Number,
      required: true,
      min: 1
    },
    subtotal: {
      type: Number,
      required: true,
      min: 0
    }
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Shop",
      required: true,
      index: true
    },
    orderNumber: {
      type: String,
      required: true,
      unique: true,
      index: true
    },
    customer: {
      name: {
        type: String,
        trim: true,
        default: ""
      },
      phone: {
        type: String,
        trim: true,
        default: ""
      },
      address: {
        type: String,
        trim: true,
        default: ""
      },
      note: {
        type: String,
        trim: true,
        default: ""
      },
      location: {
        latitude: Number,
        longitude: Number,
        mapsUrl: {
          type: String,
          trim: true,
          default: ""
        }
      },
      fcmToken: {
        type: String,
        trim: true,
        default: ""
      }
    },
    items: {
      type: [orderItemSchema],
      required: true,
      validate: {
        validator(items) {
          return Array.isArray(items) && items.length > 0;
        },
        message: "Order must contain at least one item"
      }
    },
    totalAmount: {
      type: Number,
      required: true,
      min: 0
    },
    pricing: {
      itemTotal: {
        type: Number,
        min: 0,
        default: 0
      },
      deliveryCharge: {
        type: Number,
        required: true,
        min: 0,
        default: 0
      },
      finalTotal: {
        type: Number,
        min: 0,
        default: 0
      }
    },
    payment: {
      method: {
        type: String,
        enum: ["upi", "cash", "unknown"],
        default: "unknown"
      },
      declaredPaid: {
        type: Boolean,
        default: false
      },
      upiId: {
        type: String,
        trim: true,
        default: ""
      }
    },
    status: {
      type: String,
      enum: ["placed", "seen", "accepted", "rejected", "preparing", "ready", "completed", "cancelled"],
      default: "placed",
      index: true
    },
    source: {
      type: String,
      enum: ["qr", "manual"],
      default: "qr"
    },
    notification: {
      fcmStatus: {
        type: String,
        enum: ["pending", "sent", "partial", "failed", "skipped"],
        default: "pending"
      },
      fcmMessageId: {
        type: String,
        default: ""
      },
      whatsappFallbackUrl: {
        type: String,
        default: ""
      },
      lastTriedAt: Date
    },
    timeline: [
      {
        status: String,
        at: {
          type: Date,
          default: Date.now
        },
        by: {
          type: String,
          default: "system"
        }
      }
    ]
  },
  {
    timestamps: true
  }
);

orderSchema.index({ shopId: 1, status: 1, createdAt: -1 });

module.exports = mongoose.model("Order", orderSchema);
