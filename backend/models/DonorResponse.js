const mongoose = require("mongoose");

const donorResponseSchema = new mongoose.Schema(
  {
    bloodRequest: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "BloodRequest",
      required: true,
      index: true
    },

    donor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true
    },

    status: {
      type: String,
      enum: ["accepted", "declined"],
      required: true
    },

    message: {
      type: String,
      trim: true,
      maxlength: 300,
      default: ""
    },

    donated: {
      type: Boolean,
      default: false
    },

    donatedAt: {
      type: Date,
      default: null
    }
  },
  { timestamps: true }
);

// A donor can respond only once to the same request.
donorResponseSchema.index(
  { bloodRequest: 1, donor: 1 },
  { unique: true }
);

module.exports = mongoose.model(
  "DonorResponse",
  donorResponseSchema
);
