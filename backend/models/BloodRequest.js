const mongoose = require("mongoose");

const bloodRequestSchema = new mongoose.Schema(
  {
    requester: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true
    },

    bloodGroup: {
      type: String,
      enum: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],
      required: true
    },

    city: {
      type: String,
      required: true,
      trim: true,
      index: true
    },

    units: {
      type: Number,
      required: true,
      min: 1
    },

    urgency: {
      type: String,
      enum: ["normal", "urgent", "emergency"],
      default: "normal"
    },

    status: {
      type: String,
      enum: ["open", "matched", "fulfilled", "cancelled"],
      default: "open",
      index: true
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model(
  "BloodRequest",
  bloodRequestSchema
);
