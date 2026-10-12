const BloodRequest = require("../models/BloodRequest");

const createBloodRequest = async (req, res) => {
  try {
    const { bloodGroup, city, units, urgency } = req.body;

    if (!bloodGroup || !city || units === undefined) {
      return res.status(400).json({
        success: false,
        message: "Blood group, city and units are required"
      });
    }

    if (
      !["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
        .includes(bloodGroup)
    ) {
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
    return res.status(500).json({
      success: false,
      message: "Failed to create blood request"
    });
  }
};

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
    return res.status(500).json({
      success: false,
      message: "Failed to fetch blood requests"
    });
  }
};

module.exports = { createBloodRequest, getBloodRequests };
