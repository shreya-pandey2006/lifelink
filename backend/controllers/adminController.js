
const User = require("../models/User");
const Donor = require("../models/Donor");
const BloodRequest = require("../models/BloodRequest");
const DonorResponse = require("../models/DonorResponse");

const validatePagination = (query) => {
  const page = Number(query.page ?? 1);
  const limit = Number(query.limit ?? 10);

  if (
    !Number.isSafeInteger(page) ||
    page < 1 ||
    !Number.isSafeInteger(limit) ||
    limit < 1 ||
    limit > 100
  ) {
    return {
      error: "Page must be >= 1 and limit must be between 1 and 100"
    };
  }

  const skip = (page - 1) * limit;

  if (!Number.isSafeInteger(skip)) {
    return { error: "Invalid pagination values" };
  }

  return { page, limit, skip };
};

// GET /api/admin/dashboard-stats
exports.getDashboardStats = async (req, res) => {
  try {
    const [
      totalUsers,
      totalDonors,
      availableDonors,
      totalBloodRequests
    ] = await Promise.all([
      User.countDocuments(),
      Donor.countDocuments(),
      Donor.countDocuments({ available: true }),
      BloodRequest.countDocuments()
    ]);

    return res.status(200).json({
      success: true,
      stats: {
        totalUsers,
        totalDonors,
        availableDonors,
        totalBloodRequests
      }
    });
  } catch (error) {
    console.error("Admin dashboard stats error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch dashboard statistics"
    });
  }
};

// GET /api/admin/users?page=1&limit=10
exports.getAllUsers = async (req, res) => {
  try {
    const pagination = validatePagination(req.query);

    if (pagination.error) {
      return res.status(400).json({
        success: false,
        message: pagination.error
      });
    }

const { page, limit, skip } = pagination;

    const [users, totalUsers] = await Promise.all([
      User.find()
        .select("-passwordHash")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      User.countDocuments()
    ]);

    return res.status(200).json({
      success: true,
      users,
      pagination: {
        totalUsers,
        currentPage: page,
        totalPages: Math.ceil(totalUsers / limit),
        limit
      }
    });
  } catch (error) {
    console.error("Admin get all users error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch users"
    });
  }
};

// GET /api/admin/requests?page=1&limit=10
exports.getAllBloodRequests = async (req, res) => {
  try {
    const pagination = validatePagination(req.query);

    if (pagination.error) {
      return res.status(400).json({
        success: false,
        message: pagination.error
      });
    }
    const { page, limit, skip } = pagination;

    const [requests, totalRequests] = await Promise.all([
      BloodRequest.find()
        .populate("requester", "name email phone city")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),

      BloodRequest.countDocuments()
    ]);

    return res.status(200).json({
      success: true,
      requests,
      pagination: {
        totalRequests,
        currentPage: page,
        totalPages: Math.ceil(totalRequests / limit),
        limit
      }
    });
  } catch (error) {
    console.error("Admin get all blood requests error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch blood requests"
    });
  }
};

// GET /api/admin/donors?page=1&limit=10
exports.getAllDonors = async (req, res) => {
  try {
    const pagination = validatePagination(req.query);

    if (pagination.error) {
      return res.status(400).json({
        success: false,
        message: pagination.error
      });
    }
    const { page, limit, skip } = pagination;

    const [donors, totalDonors] = await Promise.all([
      Donor.find()
        .populate("user", "name email phone role")
        .sort({ _id: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),

      Donor.countDocuments()
    ]);

    return res.status(200).json({
      success: true,
      donors,
      pagination: {
        totalDonors,
        currentPage: page,
        totalPages: Math.ceil(totalDonors / limit),
        limit
      }
    });
  } catch (error) {
    console.error("Admin get all donors error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch donors"
    });
  }
};

// GET /api/admin/responses?page=1&limit=10
exports.getAllDonorResponses = async (req, res) => {
  try {
    const pagination = validatePagination(req.query);

    if (pagination.error) {
      return res.status(400).json({
        success: false,
        message: pagination.error
      });
    }
    const { page, limit, skip } = pagination;

    const [responses, totalResponses] = await Promise.all([
      DonorResponse.find()
        .populate("donor", "name email phone")
        .populate("bloodRequest")
        .sort({ _id: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),

      DonorResponse.countDocuments()
    ]);

    return res.status(200).json({
      success: true,
      responses,
      pagination: {
        totalResponses,
        currentPage: page,
        totalPages: Math.ceil(totalResponses / limit),
        limit
      }
    });
  } catch (error) {
    console.error("Admin get all donor responses error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch donor responses"
    });
  }
};


 // PATCH /api/admin/requests/:requestId/status
exports.updateBloodRequestStatus = async (req, res) => {
  try {
    const mongoose = require("mongoose");
    const { requestId } = req.params;
    const { status } = req.body;

    // Validate request ID
    if (!mongoose.Types.ObjectId.isValid(requestId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid blood request ID"
      });
    }

    // Validate status
    const allowedStatuses = [
      "open",
      "matched",
      "fulfilled",
      "cancelled"
    ];

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Status must be open, matched, fulfilled, or cancelled"
      });
    }

    // Find and update blood request
    const updatedRequest = await BloodRequest.findByIdAndUpdate(
      requestId,
      { status },
      { new: true, runValidators: true }
    ).populate("requester", "name email phone city");

    if (!updatedRequest) {
      return res.status(404).json({
        success: false,
        message: "Blood request not found"
      });
    }

    return res.status(200).json({
      success: true,
      message: "Blood request status updated successfully",
      request: updatedRequest
    });
  } catch (error) {
    console.error("Update blood request status error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to update blood request status"
    });
  }
};

const BLOOD_GROUPS = ["O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+"];

// GET /api/admin/analytics/rare-blood-groups
exports.getRareBloodGroups = async (req, res) => {
  try {
    const rawThreshold = req.query.threshold ?? "3";
    const threshold = Number(rawThreshold);

    if (
      !Number.isSafeInteger(threshold) ||
      threshold < 0 ||
      threshold > 1000000
    ) {
      return res.status(400).json({
        success: false,
        message: "Threshold must be an integer between 0 and 1000000"
      });
    }

    const counts = await Donor.aggregate([
      { $match: { available: true } },
      {
        $group: {
          _id: "$bloodGroup",
          availableDonors: { $sum: 1 }
        }
      }
    ]);

    const countMap = new Map(
      counts.map(item => [item._id, item.availableDonors])
    );

    const bloodGroups = BLOOD_GROUPS.map(bloodGroup => ({
      bloodGroup,
      availableDonors: countMap.get(bloodGroup) || 0
    }));

    const rareGroups = bloodGroups.filter(
      group => group.availableDonors <= threshold
    );

    return res.status(200).json({
      success: true,
      data: {
        threshold,
        bloodGroups,
        rareGroups,
        rareGroupCount: rareGroups.length
      }
    });
  } catch (error) {
    console.error("Rare blood groups error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch rare blood group statistics"
    });
  }
};

// GET /api/admin/analytics/response-reliability
exports.getResponseReliability = async (req, res) => {
  try {
    const [totalResponses, acceptedResponses, declinedResponses] =
      await Promise.all([
        DonorResponse.countDocuments(),
        DonorResponse.countDocuments({ status: "accepted" }),
        DonorResponse.countDocuments({ status: "declined" })
      ]);

    const acceptanceRatePercentage =
      totalResponses === 0
        ? null
        : Number(
            ((acceptedResponses / totalResponses) * 100).toFixed(2)
          );

    return res.status(200).json({
      success: true,
      data: {
        totalResponses,
        acceptedResponses,
        declinedResponses,
        acceptanceRatePercentage,
        metric: "donor_response_acceptance_rate"
      }
    });
  } catch (error) {
    console.error("Response reliability error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch response reliability"
    });
  }
};
