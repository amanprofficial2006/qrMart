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
    lastLoginAt: Date
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model("Customer", customerSchema);
