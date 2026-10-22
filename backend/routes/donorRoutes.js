const express = require("express");
const router = express.Router();

const {
  getMyDonorProfile,
  updateAvailability,
  updateMLDetails,
  getAvailableDonorCount,
  updateDonorProfile
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

router.put(
  "/me",
  auth,
  requireRole("donor"),
  updateDonorProfile
);

router.patch(
  "/me",
  auth,
  requireRole("donor"),
  updateDonorProfile
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