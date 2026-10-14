
const express = require("express");
const router = express.Router();

const {
  rankDonorsController,
  predictUrgencyController,
} = require("../controllers/mlController");

const { auth } = require("../middleware/authMiddleware");

// Donor ranking API
router.post(
  "/rank-donors",
  auth,
  rankDonorsController
);

// Blood request urgency prediction API
router.post(
  "/predict-urgency",
  auth,
  predictUrgencyController
);

module.exports = router;
