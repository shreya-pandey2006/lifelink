const express = require("express");
const router = express.Router();
const {
    register,
    login,
    getMe
} = require("../controllers/authController");
const {
    verifyEmail,
    resendOtp
} = require("../controllers/emailVerificationController");
const { auth } = require("../middleware/authMiddleware");

router.post("/register", register);
router.post("/login", login);
router.post("/verify-email", verifyEmail);
router.post("/resend-otp", resendOtp);
router.get("/me", auth, getMe);

module.exports = router;