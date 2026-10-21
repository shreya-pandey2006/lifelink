const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: true,
            trim: true,
            minlength: 2,
            maxlength: 20,
            match: /^[A-Za-z]+(?:[ '-][A-Za-z]+)*$/
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
            trim: true,
            validate: {
                validator: function (value) {
                    return !value || /^(?:\+91[\s-]?)?[0-9]{10}$/.test(value);
                },
                message: "Phone number must contain exactly 10 digits"
            }
        },
        city: {
            type: String,
            required: true,
            trim: true,
            maxlength: 100,
            match: /^[A-Za-z]+(?:[ '-][A-Za-z]+)*$/
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("User", userSchema);
