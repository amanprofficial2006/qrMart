const mongoose = require("mongoose");

const ownerSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Shop",
      required: true,
      index: true
    },
    name: {
      type: String,
      required: true,
      trim: true
    },
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true
    },
    email: {
      type: String,
      lowercase: true,
      trim: true,
      default: ""
    },
    passwordHash: {
      type: String,
      default: ""
    },
    authProvider: {
      type: String,
      enum: ["password", "google"],
      default: "password"
    },
    googleSub: {
      type: String,
      trim: true,
      default: ""
    },
    isActive: {
      type: Boolean,
      default: true
    },
    lastLoginAt: Date
  },
  {
    timestamps: true
  }
);

ownerSchema.index(
  { googleSub: 1 },
  {
    unique: true,
    sparse: true,
    partialFilterExpression: { googleSub: { $type: "string", $gt: "" } }
  }
);

ownerSchema.index(
  { email: 1 },
  {
    unique: true,
    sparse: true,
    partialFilterExpression: { email: { $type: "string", $gt: "" } }
  }
);

module.exports = mongoose.model("Owner", ownerSchema);
