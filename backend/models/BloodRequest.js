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
      minlength: 1,
      maxlength: 100,
      index: true
    },

    units: {
      type: Number,
      required: true,
      min: 1,
      validate: {
        validator: Number.isSafeInteger,
        message: "Units must be a positive integer"
      }
    },

    unitsAccepted: {
      type: Number,
      default: 0,
      min: 0,
      validate: {
        validator: Number.isSafeInteger,
        message: "Units accepted must be an integer"
      }
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
    },

    patient: {
      type: mongoose.Schema.Types.Mixed,
      default: null
    },

    predictedUrgency: {
      type: mongoose.Schema.Types.Mixed,
      default: null
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model(
  "BloodRequest",
  bloodRequestSchema
);