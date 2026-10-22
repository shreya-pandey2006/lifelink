const express = require("express");
const router = express.Router();

const {
  createBloodRequest,
  getBloodRequests,
  getPotentialDonors,
  getBloodRequestById,
  cancelBloodRequest
} = require("../controllers/bloodRequestController");

const { auth, requireRole } = require("../middleware/authMiddleware");

// Create a blood request
router.post(
  "/",
  auth,
  requireRole("requester"),
  createBloodRequest
);

// View all blood requests
router.get(
  "/",
  auth,
  requireRole("requester", "admin"),
  getBloodRequests
);

// Get one blood request by ID (accessible to requesters, admins, and matching donors)
router.get(
  "/:requestId",
  auth,
  requireRole("requester", "admin", "donor"),
  getBloodRequestById
);

// Find eligible potential donors
router.get(
  "/:requestId/potential-donors",
  auth,
  requireRole("requester", "admin"),
  getPotentialDonors
);

// Cancel own blood request
router.patch(
  "/:requestId/cancel",
  auth,
  requireRole("requester"),
  cancelBloodRequest
);

module.exports = router;
