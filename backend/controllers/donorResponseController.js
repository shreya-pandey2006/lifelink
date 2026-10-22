const mongoose = require("mongoose");
const DonorResponse = require("../models/DonorResponse");
const BloodRequest = require("../models/BloodRequest");
const Donor = require("../models/Donor");
const Notification = require("../models/Notification");
const User = require("../models/User");

// Donor accepts or declines a blood request
const respondToBloodRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const { status, message = "" } = req.body;

    if (!mongoose.isValidObjectId(requestId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid blood request ID"
      });
    }

    if (
      typeof message !== "string" ||
      message.length > 300
    ) {
      return res.status(400).json({
        success: false,
        message: "Message must be a string with at most 300 characters"
      });
    }

    if (
      typeof status !== "string" ||
      !["accepted", "declined"].includes(status)
    ) {
      return res.status(400).json({
        success: false,
        message: "Status must be accepted or declined"
      });
    }

    // Populate requester details
    const bloodRequest = await BloodRequest.findById(requestId).populate(
      "requester",
      "name phone email city"
    );

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
      city: {
        $regex: `^${bloodRequest.city.trim()}$`,
        $options: "i"
      }
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

    // Synchronize unitsAccepted and status on the blood request
    const acceptedCount = await DonorResponse.countDocuments({
      bloodRequest: bloodRequest._id,
      status: "accepted"
    });

    bloodRequest.unitsAccepted = acceptedCount;

    if (
      acceptedCount >= bloodRequest.units &&
      bloodRequest.status === "open"
    ) {
      bloodRequest.status = "matched";
    }

    await bloodRequest.save();

    // Create notification for requester
    try {
      const donorUser = await User.findById(req.user.id).select(
        "name phone"
      );

      const donorName = donorUser?.name || "A donor";

      await Notification.create({
        userId: bloodRequest.requester?._id || bloodRequest.requester,
        title:
          status === "accepted"
            ? "Donor Accepted Your Request"
            : "Donor Response Update",
        message:
          status === "accepted"
            ? `${donorName} has accepted your blood request for ${bloodRequest.bloodGroup} in ${bloodRequest.city}.`
            : `A donor has declined your blood request for ${bloodRequest.bloodGroup}.`,
        type: "request_update",
        relatedRequest: bloodRequest._id
      });
    } catch (notifErr) {
      console.error(
        "Failed to notify requester:",
        notifErr.message
      );
    }

    // Return requester contact details to the donor
    const requesterUser = bloodRequest.requester || {};

    return res.status(201).json({
      success: true,
      message: "Your response has been saved",
      response,
      unitsAccepted: acceptedCount,
      requestStatus: bloodRequest.status,
      requesterPhone: requesterUser.phone || null,
      requesterName: requesterUser.name || null
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
    const page = Number(req.query.page ?? 1);
    const limit = Number(req.query.limit ?? 10);

    if (
      !Number.isSafeInteger(page) ||
      page < 1 ||
      !Number.isSafeInteger(limit) ||
      limit < 1 ||
      limit > 100
    ) {
      return res.status(400).json({
        success: false,
        message: "Page must be >= 1 and limit must be between 1 and 100"
      });
    }

    const skip = (page - 1) * limit;

    if (!Number.isSafeInteger(skip)) {
      return res.status(400).json({
        success: false,
        message: "Invalid pagination values"
      });
    }

    const filter = { donor: req.user.id };

    const [responses, total] = await Promise.all([
      DonorResponse.find(filter)
        .populate({
          path: "bloodRequest",
          select:
            "bloodGroup city units urgency status createdAt hospital hospitalName patient requester",
          populate: {
            path: "requester",
            select: "name phone email city"
          }
        })
        .sort({ createdAt: -1, _id: -1 })
        .skip(skip)
        .limit(limit),

      DonorResponse.countDocuments(filter)
    ]);

    return res.status(200).json({
      success: true,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
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

// Donor updates their donation status (donated: true/false)
const updateDonationStatus = async (req, res) => {
  try {
    const { requestId } = req.params;
    const { donated } = req.body;

    if (!mongoose.isValidObjectId(requestId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid blood request ID"
      });
    }

    if (typeof donated !== "boolean") {
      return res.status(400).json({
        success: false,
        message: "Donated field must be a boolean"
      });
    }

    const response = await DonorResponse.findOne({
      bloodRequest: requestId,
      donor: req.user.id
    });

    if (!response) {
      return res.status(404).json({
        success: false,
        message: "You have not responded to this blood request"
      });
    }

    response.donated = donated;
    response.donatedAt = donated ? new Date() : null;
    await response.save();

    // If marked as donated, update donor profile metrics and notify requester
    if (donated) {
      try {
        await Donor.findOneAndUpdate(
          { user: req.user.id },
          {
            $set: { lastDonationDate: new Date() },
            $inc: { totalDonations: 1 }
          }
        );
      } catch (err) {
        console.error("Failed to update donor profile metrics:", err.message);
      }

      try {
        const bloodRequest = await BloodRequest.findById(requestId);
        if (bloodRequest) {
          const donorUser = await User.findById(req.user.id).select("name");
          const donorName = donorUser?.name || "An accepted donor";
          await Notification.create({
            userId: bloodRequest.requester,
            title: "Donation Completed",
            message: `${donorName} has confirmed completing their blood donation for your request.`,
            type: "donation_update",
            relatedRequest: bloodRequest._id
          });
        }
      } catch (notifErr) {
        console.error("Failed to notify requester of donation:", notifErr.message);
      }
    }

    return res.status(200).json({
      success: true,
      message: donated
        ? "Donation status marked as completed. Thank you for saving a life!"
        : "Donation status updated",
      donated: response.donated,
      donatedAt: response.donatedAt,
      response
    });
  } catch (error) {
    console.error("Update donation status error:", error.message);
    return res.status(500).json({
      success: false,
      message: "Failed to update donation status"
    });
  }
};

module.exports = {
  respondToBloodRequest,
  getMyResponses,
  updateDonationStatus
};