const express = require("express");
const router = express.Router();

const {
  getMyDonorProfile,
  updateAvailability,
  updateMLDetails,
  getAvailableDonorCount
} = require("../controllers/donorController");

const {
  auth,
  requireRole
} = require("../middleware/authMiddleware");

router.get(
  "/me",
  auth,
  requireRole("donor"),
  getMyDonorProfile
);

router.patch(
  "/availability",
  auth,
  requireRole("donor"),
  updateAvailability
);

router.patch(
  "/ml-details",
  auth,
  requireRole("donor"),
  updateMLDetails
);

router.get(
  "/available/count",
  auth,
  requireRole("requester", "admin"),
  getAvailableDonorCount
);

module.exports = router;
