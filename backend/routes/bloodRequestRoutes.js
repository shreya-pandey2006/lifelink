const express = require("express");
const router = express.Router();

const {
  createBloodRequest,
  getBloodRequests
} = require("../controllers/bloodRequestController");

const {
  auth,
  requireRole
} = require("../middleware/authMiddleware");

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

module.exports = router;
