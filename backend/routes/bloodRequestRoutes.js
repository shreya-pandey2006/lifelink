const express = require("express");
const router = express.Router();

const {
  createBloodRequest,
  getBloodRequests,
  getPotentialDonors
} = require("../controllers/bloodRequestController");

const { auth, requireRole } = require("../middleware/authMiddleware");

// Create a blood request
router.post(
  "/",
  auth,
  requireRole("requester"),
  createBloodRequest
);

// View blood requests
router.get(
  "/",
  auth,
  requireRole("requester", "admin"),
  getBloodRequests
);

// Find eligible potential donors for a blood request
router.get(
  "/:requestId/potential-donors",
  auth,
  requireRole("requester", "admin"),
  getPotentialDonors
);

module.exports = router;