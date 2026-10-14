const BloodRequest = require("../models/BloodRequest");
const Donor = require("../models/Donor");

const {
  getCompatibleBloodGroups
} = require("../services/donorMatchingService");

// ML service (urgency prediction + donor ranking)
const { predictUrgency, rankDonors } = require("../services/mlService");

// Valid blood groups and urgency levels
const VALID_BLOOD_GROUPS = [
  "A+", "A-", "B+", "B-",
  "AB+", "AB-", "O+", "O-"
];

const VALID_URGENCY_LEVELS = [
  "normal",
  "urgent",
  "emergency"
];

const DAY_MS = 24 * 60 * 60 * 1000;

// Escape special characters before using city in a regex
const escapeRegex = (value) => {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
};

// Days since last donation (never donated -> 365)
const daysSince = (date) => {
  if (!date) return 365;
  const time = new Date(date).getTime();
  if (Number.isNaN(time)) return 365;
  return Math.max(0, Math.floor((Date.now() - time) / DAY_MS));
};

// Create a blood request
const createBloodRequest = async (req, res) => {
  try {
    // Validate request body
    if (
      !req.body ||
      typeof req.body !== "object" ||
      Array.isArray(req.body)
    ) {
      return res.status(400).json({
        success: false,
        message: "Request body must be a valid JSON object"
      });
    }

    const { bloodGroup, city, units, urgency, patient } = req.body;

    // Validate required fields
    if (
      bloodGroup === undefined ||
      city === undefined ||
      units === undefined
    ) {
      return res.status(400).json({
        success: false,
        message: "Blood group, city and units are required"
      });
    }

    // Validate field types
    if (
      typeof bloodGroup !== "string" ||
      typeof city !== "string"
    ) {
      return res.status(400).json({
        success: false,
        message: "Blood group and city must be strings"
      });
    }

    const normalizedBloodGroup = bloodGroup.trim().toUpperCase();
    const normalizedCity = city.trim();

    // Validate blood group
    if (!VALID_BLOOD_GROUPS.includes(normalizedBloodGroup)) {
      return res.status(400).json({
        success: false,
        message: "Invalid blood group"
      });
    }

    // Validate city and units
    if (!normalizedCity || normalizedCity.length > 100) {
      return res.status(400).json({
        success: false,
        message: "City must contain 1 to 100 characters"
      });
    }

    if (
      typeof units !== "number" ||
      !Number.isInteger(units) ||
      units < 1
    ) {
      return res.status(400).json({
        success: false,
        message: "Units must be a positive integer"
      });
    }

    // Validate optional urgency
    if (
      urgency !== undefined &&
      (
        typeof urgency !== "string" ||
        !VALID_URGENCY_LEVELS.includes(urgency)
      )
    ) {
      return res.status(400).json({
        success: false,
        message: "Urgency must be normal, urgent or emergency"
      });
    }

    // Validate optional patient details (used only by the urgency ML model)
    if (
      patient !== undefined &&
      patient !== null &&
      (typeof patient !== "object" || Array.isArray(patient))
    ) {
      return res.status(400).json({
        success: false,
        message: "Patient must be an object"
      });
    }

    // Predict urgency with ML (optional: only if patient data is sent).
    // If the ML service fails, the request is still saved.
    let predictedUrgency = null;

    if (patient) {
      try {
        predictedUrgency = await predictUrgency({
          age: patient.age,
          gender: patient.gender,
          weight_kg: patient.weightKg,
          blood_group: normalizedBloodGroup,
          city: normalizedCity,
          health_issue: patient.healthIssue,
          hemoglobin_g_dl: patient.hemoglobinGDl,
          platelet_count: patient.plateletCount,
          systolic_bp: patient.systolicBp,
          heart_rate: patient.heartRate,
          spo2_percent: patient.spo2Percent,
          active_bleeding: patient.activeBleeding,
          previous_transfusions: patient.previousTransfusions,
          blood_component_needed: patient.bloodComponentNeeded,
          units_required: units,
          required_within_hours: patient.requiredWithinHours
        });
      } catch (mlError) {
        console.error("Urgency ML error:", mlError.message);
      }
    }

    const bloodRequest = await BloodRequest.create({
      requester: req.user.id,
      bloodGroup: normalizedBloodGroup,
      city: normalizedCity,
      units,
      urgency: urgency || "normal",
      patient: patient || null,
      predictedUrgency
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

    // Validate MongoDB ObjectId
    if (!/^[0-9a-fA-F]{24}$/.test(requestId)) {
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

    // Requesters can view matches only for their own requests
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

    const safeCityRegex = new RegExp(
      `^${escapeRegex(bloodRequest.city.trim())}$`,
      "i"
    );

    const donors = await Donor.find({
      bloodGroup: { $in: compatibleGroups },
      city: { $regex: safeCityRegex },
      available: true
    }).select(
      "_id user bloodGroup city available lastDonationDate age weightKg hemoglobinGDl totalDonations"
    );

    // Exclude donors who donated within the previous 90 days
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 90);

    const eligibleDonors = donors.filter((donor) => {
      const totalDonations = donor.totalDonations ?? 0;

      // Donors with no previous donations may be eligible
      // when no previous donation date is recorded
      if (totalDonations === 0) {
        return !donor.lastDonationDate;
      }

      // Previous donations require a valid recorded date
      if (!donor.lastDonationDate) {
        return false;
      }

      const lastDonation = new Date(donor.lastDonationDate);

      if (Number.isNaN(lastDonation.getTime())) {
        return false;
      }

      return lastDonation <= cutoffDate;
    });

    // Donors with all ML features are sent to the ML ranking API.
    // Donors with missing data are added at the end, unranked.
    const hasMlData = (d) => d.age && d.weightKg && d.hemoglobinGDl;

    const mlReady = eligibleDonors.filter(hasMlData);
    const mlSkipped = eligibleDonors.filter((d) => !hasMlData(d));

    let rankedList = mlReady.map((d) => d.toObject());
    let rankingApplied = false;

    if (mlReady.length > 0) {
      try {
        const result = await rankDonors(
          mlReady.map((d) => ({
            donor_id: d._id.toString(),
            age: d.age,
            weight: d.weightKg,
            hemoglobin: d.hemoglobinGDl,
            days_since_last_donation: daysSince(d.lastDonationDate)
          }))
        );

        const scoreMap = new Map(
          result.map((r) => [r.donor_id, r.response_probability])
        );

        rankedList = mlReady
          .map((d) => ({
            ...d.toObject(),
            responseProbability: scoreMap.get(d._id.toString()) ?? null
          }))
          .sort(
            (a, b) =>
              (b.responseProbability ?? -1) - (a.responseProbability ?? -1)
          );

        rankingApplied = true;
      } catch (mlError) {
        // Fallback: keep the unranked list if ML is down
        console.error("Rank donors ML error:", mlError.message);
      }
    }

    const potentialDonors = [
      ...rankedList,
      ...mlSkipped.map((d) => d.toObject())
    ];

    return res.status(200).json({
      success: true,
      requestId: bloodRequest._id,
      predictedUrgency: bloodRequest.predictedUrgency,
      rankingApplied,
      totalPotentialDonors: potentialDonors.length,
      potentialDonors
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
