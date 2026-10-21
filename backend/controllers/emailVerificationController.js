const User = require("../models/User");
const EmailVerification = require("../models/EmailVerification");
const { hashOtp, createAndSendOtp } = require("../utils/emailOtp");

// POST /api/auth/verify-email
exports.verifyEmail = async (req, res) => {
    try {
        const { email, otp } = req.body;

        if (
            typeof email !== "string" ||
            !email.trim() ||
            typeof otp !== "string" ||
            !/^\d{6}$/.test(otp)
        ) {
            return res.status(400).json({
                success: false,
                message: "Provide a valid email and six-digit OTP"
            });
        }

        const normalizedEmail = email.trim().toLowerCase();
        const user = await User.findOne({ email: normalizedEmail });

        if (!user) {
            return res.status(400).json({
                success: false,
                message: "Invalid email or verification code"
            });
        }

        if (user.isEmailVerified) {
            return res.status(200).json({
                success: true,
                message: "Email is already verified"
            });
        }

        const verification = await EmailVerification.findOne({
            user: user._id
        });

        if (!verification) {
            return res.status(400).json({
                success: false,
                message: "OTP not found or expired. Please request a new one."
            });
        }

        if (verification.expiresAt.getTime() <= Date.now()) {
            await EmailVerification.deleteOne({ _id: verification._id });

            return res.status(400).json({
                success: false,
                message: "OTP has expired. Please request a new one."
            });
        }

        if (verification.attempts >= 5) {
            await EmailVerification.deleteOne({ _id: verification._id });

            return res.status(429).json({
                success: false,
                message: "Too many attempts. Please request a new OTP."
            });
        }

        const submittedHash = hashOtp(user._id.toString(), otp);

        if (submittedHash !== verification.otpHash) {
            verification.attempts += 1;
            await verification.save();

            return res.status(400).json({
                success: false,
                message: "Incorrect OTP",
                attemptsRemaining: Math.max(0, 5 - verification.attempts)
            });
        }

        user.isEmailVerified = true;
        await user.save();

        await EmailVerification.deleteOne({ _id: verification._id });

        return res.status(200).json({
            success: true,
            message: "Email verified successfully. You can now log in."
        });
    } catch (error) {
        console.error("Email verification error:", error.message);

        return res.status(500).json({
            success: false,
            message: "Email verification failed"
        });
    }
};


// POST /api/auth/resend-otp
exports.resendOtp = async (req, res) => {
    try {
        const { email } = req.body;

        if (typeof email !== "string" || !email.trim()) {
            return res.status(400).json({
                success: false,
                message: "Email is required"
            });
        }

        const normalizedEmail = email.trim().toLowerCase();
        const user = await User.findOne({ email: normalizedEmail });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found"
            });
        }

        if (user.isEmailVerified) {
            return res.status(400).json({
                success: false,
                message: "Email is already verified"
            });
        }

        const existingOtp = await EmailVerification.findOne({
            user: user._id
        });

        // Allow at least 60 seconds between OTP requests.
        if (
            existingOtp &&
            Date.now() - existingOtp.createdAt.getTime() < 60 * 1000
        ) {
            return res.status(429).json({
                success: false,
                message: "Please wait 60 seconds before requesting another OTP"
            });
        }

        await createAndSendOtp(user);

        return res.status(200).json({
            success: true,
            message: "A new verification OTP has been sent"
        });
    } catch (error) {
        console.error("Resend OTP error:", error.message);

        return res.status(500).json({
            success: false,
            message: "Could not send verification OTP"
        });
    }
};