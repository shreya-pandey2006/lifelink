
const express = require("express");
const router = express.Router();

const {
  respondToBloodRequest,
  getMyResponses
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

// Donor views their own responses
router.get(
  "/my",
  auth,
  requireRole("donor"),
  getMyResponses
);

module.exports = router;
