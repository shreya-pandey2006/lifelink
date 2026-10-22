const mongoose = require("mongoose");

const donorSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true
    },

    bloodGroup: {
      type: String,
      enum: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],
      required: true,
      index: true
    },

    city: {
      type: String,
      required: true,
      trim: true,
      index: true
    },

    available: {
      type: Boolean,
      default: true
    },

    lat: {
      type: Number,
      default: null
    },

    lng: {
      type: Number,
      default: null
    },

    lastDonationDate: {
      type: Date,
      default: null
    },

    // Features required by the ML model
    age: {
      type: Number,
      min: 18,
      max: 100
    },

    weightKg: {
      type: Number,
      min: 1
    },

    hemoglobinGDl: {
      type: Number,
      min: 1
    },

    totalDonations: {
      type: Number,
      default: 0,
      min: 0
    },

    totalAlerts: {
      type: Number,
      default: 0
    },

    totalAccepts: {
      type: Number,
      default: 0
    },
    lat: {
      type: Number,
      default: null
    },

    lng: {
      type: Number,
      default: null
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Donor", donorSchema);