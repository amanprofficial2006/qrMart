const mongoose = require("mongoose");

const customerSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      trim: true,
      default: ""
    },
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true
    },
    address: {
      type: String,
      trim: true,
      default: ""
    },
    avatarUrl: {
      type: String,
      trim: true,
      default: ""
    },
    lastLoginAt: Date
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model("Customer", customerSchema);
