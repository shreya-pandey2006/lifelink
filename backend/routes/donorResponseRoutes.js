
const express = require("express");
const router = express.Router();

const {
  respondToBloodRequest,
  getMyResponses,
  updateDonationStatus
} = require("../controllers/donorResponseController");

const {
  auth,
  requireRole
} = require("../middleware/authMiddleware");

// Donor accepts or declines a blood request
router.post(
  "/:requestId",
  auth,
  requireRole("donor"),
  respondToBloodRequest
);

// Donor updates their donation status (donated: true/false)
router.patch(
  "/:requestId/donation-status",
  auth,
  requireRole("donor"),
  updateDonationStatus
);

// Donor views their own responses
router.get(
  "/my",
  auth,
  requireRole("donor"),
  getMyResponses
);

module.exports = router;
