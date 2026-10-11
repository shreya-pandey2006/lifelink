
const mongoose = require("mongoose");
const userSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: true,
            trim: true
        },
        email: {
            type: String,
            required: true,
            unique: true,
            lowercase: true,
            trim: true
        },
        passwordHash: {
            type: String,
            required: true
        },
        role: {
            type: String,
            enum: ["requester", "donor", "admin"],
            required: true
        },
        phone: {
            type: String,
            trim: true
        },
        city: {
            type: String,
            required: true,
            trim: true
        }
    },
    {
        timestamps: true
    }
);
module.exports = mongoose.model("User", userSchema);
