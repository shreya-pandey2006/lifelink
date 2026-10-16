
const User = require("../models/User");
const Donor = require("../models/Donor");
const BloodRequest = require("../models/BloodRequest");
const DonorResponse = require("../models/DonorResponse");

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
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(
      100,
      Math.max(1, parseInt(req.query.limit, 10) || 10)
    );

    const skip = (page - 1) * limit;

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
    const page = Math.max(
      1,
      parseInt(req.query.page, 10) || 1
    );

    const limit = Math.min(
      100,
      Math.max(1, parseInt(req.query.limit, 10) || 10)
    );

    const skip = (page - 1) * limit;

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
    const page = Math.max(
      1,
      parseInt(req.query.page, 10) || 1
    );

    const limit = Math.min(
      100,
      Math.max(1, parseInt(req.query.limit, 10) || 10)
    );

    const skip = (page - 1) * limit;

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
    const page = Math.max(
      1,
      parseInt(req.query.page, 10) || 1
    );

    const limit = Math.min(
      100,
      Math.max(1, parseInt(req.query.limit, 10) || 10)
    );

    const skip = (page - 1) * limit;

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
