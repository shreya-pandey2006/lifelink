const crypto = require("crypto");
const EmailVerification = require("../models/EmailVerification");
const sendEmail = require("./sendEmail");

function hashOtp(userId, otp) {
    return crypto
        .createHmac("sha256", process.env.OTP_SECRET)
        .update(`${userId}:${otp}`)
        .digest("hex");
}

async function createAndSendOtp(user) {
    const otp = crypto.randomInt(100000, 1000000).toString();

    // Remove any previous OTP for this user.
    await EmailVerification.deleteOne({ user: user._id });

    await EmailVerification.create({
        user: user._id,
        otpHash: hashOtp(user._id.toString(), otp),
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
        attempts: 0
    });

    try {
        await sendEmail({
            to: user.email,
            subject: "Verify your LifeLink email",
            text: `Your LifeLink verification code is ${otp}. It expires in 10 minutes. Do not share this code.`,
            html: `<p>Your LifeLink verification code is:</p>
                   <h2>${otp}</h2>
                   <p>This code expires in 10 minutes. Do not share it.</p>`
        });
    } catch (error) {
        await EmailVerification.deleteOne({ user: user._id });
        throw error;
    }
}

module.exports = { createAndSendOtp, hashOtp };
