const BloodRequest = require("../models/BloodRequest");
const Donor = require("../models/Donor");

const {
  getCompatibleBloodGroups
} = require("../services/donorMatchingService");

// Create a blood request
const createBloodRequest = async (req, res) => {
  try {
    const { bloodGroup, city, units, urgency } = req.body;

    if (!bloodGroup || !city || units === undefined) {
      return res.status(400).json({
        success: false,
        message: "Blood group, city and units are required"
      });
    }

    const validBloodGroups = [
      "A+", "A-", "B+", "B-",
      "AB+", "AB-", "O+", "O-"
    ];

    if (!validBloodGroups.includes(bloodGroup)) {
      return res.status(400).json({
        success: false,
        message: "Invalid blood group"
      });
    }

    if (
      typeof city !== "string" ||
      !city.trim() ||
      !Number.isInteger(units) ||
      units < 1
    ) {
      return res.status(400).json({
        success: false,
        message: "Enter a valid city and units (minimum 1)"
      });
    }

    if (
      urgency !== undefined &&
      !["normal", "urgent", "emergency"].includes(urgency)
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid urgency"
      });
    }

    const bloodRequest = await BloodRequest.create({
      requester: req.user.id,
      bloodGroup,
      city: city.trim(),
      units,
      urgency: urgency || "normal"
    });

    return res.status(201).json({
      success: true,
      message: "Blood request created successfully",
      bloodRequest
    });
  } catch (error) {
    console.error("Create blood request error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to create blood request"
    });
  }
};

// Get blood requests
const getBloodRequests = async (req, res) => {
  try {
    let requests;

    if (req.user.role === "admin") {
      requests = await BloodRequest.find()
        .sort({ createdAt: -1 });
    } else {
      requests = await BloodRequest.find({
        requester: req.user.id
      }).sort({ createdAt: -1 });
    }

    return res.status(200).json({
      success: true,
      totalRequests: requests.length,
      bloodRequests: requests
    });
  } catch (error) {
    console.error("Get blood requests error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch blood requests"
    });
  }
};

// Find potential donors for a blood request
const getPotentialDonors = async (req, res) => {
  try {
    const { requestId } = req.params;

    if (!requestId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({
        success: false,
        message: "Invalid blood request ID"
      });
    }

    const bloodRequest = await BloodRequest.findById(requestId);

    if (!bloodRequest) {
      return res.status(404).json({
        success: false,
        message: "Blood request not found"
      });
    }

    // Requesters can view matches only for their own requests.
    if (
      req.user.role !== "admin" &&
      bloodRequest.requester.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        message: "You cannot view donors for this request"
      });
    }

    const compatibleGroups = getCompatibleBloodGroups(
      bloodRequest.bloodGroup
    );

    if (!Array.isArray(compatibleGroups)) {
      return res.status(500).json({
        success: false,
        message: "Blood compatibility service returned invalid data"
      });
    }

    const donors = await Donor.find({
      bloodGroup: { $in: compatibleGroups },
      city: {
        $regex: `^${bloodRequest.city.replace(
          /[.*+?^${}()|[\]\\]/g,
          "\\$&"
        )}$`,
        $options: "i"
      },
      available: true
    }).select(
      "_id user bloodGroup city available lastDonationDate age weightKg hemoglobinGDl totalDonations"
    );

    // Exclude donors who donated within the previous 90 days.
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 90);

    const eligibleDonors = donors.filter(donor => {
      if (!donor.lastDonationDate) {
        return true;
      }

      return new Date(donor.lastDonationDate) <= cutoffDate;
    });

    return res.status(200).json({
      success: true,
      requestId: bloodRequest._id,
      totalPotentialDonors: eligibleDonors.length,
      potentialDonors: eligibleDonors
    });
  } catch (error) {
    console.error("Find potential donors error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to find potential donors"
    });
  }
};

module.exports = {
  createBloodRequest,
  getBloodRequests,
  getPotentialDonors
};