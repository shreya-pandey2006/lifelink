
const express = require("express");
const router = express.Router();

const { getMyDonorProfile } = require("../controllers/donorController");
const { auth, requireRole } = require("../middleware/authMiddleware");

router.get("/me", auth, requireRole("donor"), getMyDonorProfile);

module.exports = router;
