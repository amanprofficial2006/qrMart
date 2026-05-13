const mongoose = require("mongoose");

const customerRecentShopSchema = new mongoose.Schema(
  {
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Customer",
      required: true
    },
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Shop",
      required: true
    },
    lastOpenedAt: {
      type: Date,
      default: Date.now
    },
    openCount: {
      type: Number,
      min: 1,
      default: 1
    }
  },
  {
    timestamps: true
  }
);

customerRecentShopSchema.index({ customerId: 1, shopId: 1 }, { unique: true });
customerRecentShopSchema.index({ customerId: 1, lastOpenedAt: -1 });

module.exports = mongoose.model("CustomerRecentShop", customerRecentShopSchema);
