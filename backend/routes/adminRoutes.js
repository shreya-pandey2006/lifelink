const express = require("express");
const router = express.Router();

const {
  getDashboardStats,
  getAllUsers,
  getAllBloodRequests,
  getAllDonors,
  getAllDonorResponses,
  updateBloodRequestStatus,
  getRareBloodGroups,
  getResponseReliability
} = require("../controllers/adminController");

const { auth, requireRole } = require("../middleware/authMiddleware");

// Admin dashboard statistics
router.get(
  "/dashboard-stats",
  auth,
  requireRole("admin"),
  getDashboardStats
);

// GET /api/admin/users?page=1&limit=10
router.get(
  "/users",
  auth,
  requireRole("admin"),
  getAllUsers
);

// GET /api/admin/requests?page=1&limit=10
router.get(
  "/requests",
  auth,
  requireRole("admin"),
  getAllBloodRequests
);

/* GET /api/admin/donors?page=1&limit=10 */
router.get(
  "/donors",
  auth,
  requireRole("admin"),
  getAllDonors
);

router.get(
  "/responses",
  auth,
  requireRole("admin"),
  getAllDonorResponses
);

// PATCH /api/admin/requests/:requestId/status
router.patch(
  "/requests/:requestId/status",
  auth,
  requireRole("admin"),
  updateBloodRequestStatus
);

router.get(
  "/analytics/rare-blood-groups",
  auth,
  requireRole("admin"),
  getRareBloodGroups
);

router.get(
  "/analytics/response-reliability",
  auth,
  requireRole("admin"),
  getResponseReliability
);

module.exports = router;
