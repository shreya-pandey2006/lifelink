
const DonorResponse = require("../models/DonorResponse");
const BloodRequest = require("../models/BloodRequest");
const Donor = require("../models/Donor");

// Donor accepts or declines a blood request
const respondToBloodRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const { status, message = "" } = req.body;

    if (!["accepted", "declined"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Status must be accepted or declined"
      });
    }

    const bloodRequest = await BloodRequest.findById(requestId);

    if (!bloodRequest) {
      return res.status(404).json({
        success: false,
        message: "Blood request not found"
      });
    }

    if (bloodRequest.status !== "open") {
      return res.status(400).json({
        success: false,
        message: "This blood request is no longer open"
      });
    }

    const donorProfile = await Donor.findOne({
      user: req.user.id,
      available: true,
      bloodGroup: {
        $in: require("../services/donorMatchingService")
          .getCompatibleBloodGroups(bloodRequest.bloodGroup)
      },
      city: { $regex: `^${bloodRequest.city.trim()}$`, $options: "i" }
    });

    if (!donorProfile) {
      return res.status(403).json({
        success: false,
        message: "You are not an available matching donor for this request"
      });
    }

    const response = await DonorResponse.create({
      bloodRequest: bloodRequest._id,
      donor: req.user.id,
      status,
      message
    });

    return res.status(201).json({
      success: true,
      message: "Your response has been saved",
      response
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "You have already responded to this request"
      });
    }

    console.error("Donor response error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to save donor response"
    });
  }
};

// Donor views their own responses
const getMyResponses = async (req, res) => {
  try {
    const responses = await DonorResponse.find({
      donor: req.user.id
    })
      .populate("bloodRequest", "bloodGroup city units urgency status createdAt")
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      total: responses.length,
      responses
    });
  } catch (error) {
    console.error("Get donor responses error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch donor responses"
    });
  }
};

module.exports = {
  respondToBloodRequest,
  getMyResponses
};
