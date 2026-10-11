
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
        lastDonationDate: {
            type: Date,
            default: null
        },
        totalAlerts: {
            type: Number,
            default: 0
        },
        totalAccepts: {
            type: Number,
            default: 0
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Donor", donorSchema);
