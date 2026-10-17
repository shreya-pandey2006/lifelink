const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true
        },

        title: {
            type: String,
            required: true,
            trim: true
        },

        message: {
            type: String,
            required: true,
            trim: true
        },

        type: {
            type: String,
            enum: [
                "emergency",
                "blood_request",
                "request_update",
                "general"
            ],
            default: "general"
        },

        isRead: {
            type: Boolean,
            default: false
        },

        relatedRequest: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Request",
            default: null
        }
    },
    {
        timestamps: true
    }
);

notificationSchema.index({ userId: 1, isRead: 1, createdAt: -1 });

module.exports = mongoose.model("Notification", notificationSchema);