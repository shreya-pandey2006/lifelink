const mongoose = require("mongoose");
const BloodRequest = require("../models/BloodRequest");
const Donor = require("../models/Donor");
const Notification = require("../models/Notification");

const {
  getCompatibleBloodGroups
} = require("../services/donorMatchingService");

const {
  predictUrgency,
  rankDonors
} = require("../services/mlService");

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

// Escape special characters before using a city name in a regex.
const escapeRegex = (value) =>
  value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); 

// Calculate days since the last donation.
const daysSince = (date) => {
  if (!date) return 365;

  const time = new Date(date).getTime();

  if (Number.isNaN(time)) return 365;

  return Math.max(
    0,
    Math.floor((Date.now() - time) / DAY_MS)
  );
};

// Check whether a value is a plain object.
const isPlainObject = (value) =>
  value !== null &&
  typeof value === "object" &&
  !Array.isArray(value) &&
  (
    Object.getPrototypeOf(value) === Object.prototype ||
    Object.getPrototypeOf(value) === null
  );

// Validate pagination.
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
      error:
        "Page must be a positive integer and limit must be between 1 and 100"
    };
  }

  const skip = (page - 1) * limit;

  if (!Number.isSafeInteger(skip)) {
    return {
      error: "Page is too large"
    };
  }

  return { page, limit, skip };
};

// CREATE BLOOD REQUEST
const createBloodRequest = async (req, res) => {
  try {
    if (!isPlainObject(req.body)) {
      return res.status(400).json({
        success: false,
        message: "Request body must be a valid JSON object"
      });
    }

    const {
      bloodGroup,
      city,
      units,
      urgency,
      patient
    } = req.body;

    // Required fields.
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

    // Validate field types.
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

    // Validate blood group.
    if (!VALID_BLOOD_GROUPS.includes(normalizedBloodGroup)) {
      return res.status(400).json({
        success: false,
        message: "Invalid blood group"
      });
    }

    // Validate city.
    if (
      !normalizedCity ||
      normalizedCity.length > 100
    ) {
      return res.status(400).json({
        success: false,
        message: "City must contain 1 to 100 characters"
      });
    }

    // Units must be a positive integer.
    if (!Number.isSafeInteger(units) || units < 1) {
      return res.status(400).json({
        success: false,
        message: "Units must be a positive integer"
      });
    }

    // Normalize and validate urgency.
    const normalizedUrgency =
      typeof urgency === "string"
        ? urgency.trim().toLowerCase()
        : urgency;

    if (
      normalizedUrgency !== undefined &&
      !VALID_URGENCY_LEVELS.includes(normalizedUrgency)
    ) {
      return res.status(400).json({
        success: false,
        message: "Urgency must be normal, urgent or emergency"
      });
    }

    // Patient must be an object when provided.
    if (
      patient !== undefined &&
      patient !== null &&
      !isPlainObject(patient)
    ) {
      return res.status(400).json({
        success: false,
        message: "Patient must be an object"
      });
    }

    // Validate patient details.
    if (patient && Object.keys(patient).length > 0) {
      if (
        patient.age !== undefined &&
        (
          typeof patient.age !== "number" ||
          !Number.isFinite(patient.age) ||
          patient.age < 0 ||
          patient.age > 120
        )
      ) {
        return res.status(400).json({
          success: false,
          message: "Patient age must be between 0 and 120"
        });
      }

      if ( patient.weightKg !== undefined &&
        (
          typeof patient.weightKg !== "number" ||
          !Number.isFinite(patient.weightKg) ||
          patient.weightKg <= 0
        )
      ) {
        return res.status(400).json({
          success: false,
          message: "Patient weight must be a positive number"
        });
      }

      if (
        patient.gender !== undefined &&
        (
          typeof patient.gender !== "string" ||
          !patient.gender.trim()
        )
      ) {
        return res.status(400).json({
          success: false,
          message: "Patient gender must be a non-empty string"
        });
      }

      // Validate numeric patient measurements.
      const patientNumberRanges = {
        hemoglobinGDl: [0, 30],
        plateletCount: [0, 2000000],
        systolicBp: [0, 400],
        heartRate: [0, 350],
        spo2Percent: [0, 100],
        requiredWithinHours: [0, 8760]
      };

      for (
        const [field, [min, max]]
        of Object.entries(patientNumberRanges)
      ) {
        if (
          patient[field] !== undefined &&
          (
            typeof patient[field] !== "number" ||
            !Number.isFinite(patient[field]) ||
            patient[field] < min ||
            patient[field] > max
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              `Patient ${field} must be between ${min} and ${max}`
          });
        }
      }

      // Validate boolean patient fields.
      for (const field of [
        "activeBleeding",
        "previousTransfusions"
      ]) {
        if (
          patient[field] !== undefined &&
          typeof patient[field] !== "boolean"
        ) {
          return res.status(400).json({
            success: false,
            message: `Patient ${field} must be true or false`
          });
        }
      }

      // Validate string patient fields.
      for (const field of [
        "healthIssue",
        "bloodComponentNeeded"
      ]) {
        if (
          patient[field] !== undefined &&
          typeof patient[field] !== "string"
        ) {
          return res.status(400).json({
            success: false,
            message: `Patient ${field} must be a string`
          });
        }
      }
    }

    let predictedUrgency = null;

    // Predict urgency only when patient data is supplied.
    if (patient && Object.keys(patient).length > 0) {
      try {
        const mlResult = await predictUrgency({
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

        if (
          mlResult?.status === "success" &&
          typeof mlResult.predicted_urgency_level === "string"
        ) {
          predictedUrgency =
            mlResult.predicted_urgency_level;
        }
      } catch (mlError) {
        // Request creation continues if ML is unavailable.
        console.error(
          "Urgency ML error:",
          mlError.message
        );
      }
    }

    // Create the blood request.
    const bloodRequest = await BloodRequest.create({
      requester: req.user.id,
      bloodGroup: normalizedBloodGroup,
      city: normalizedCity,
      units,
      urgency: normalizedUrgency || "normal",
      patient:
        patient && Object.keys(patient).length > 0
          ? patient
          : null,
      predictedUrgency
    });

    // Create notifications for matching donors.
    try {
      const compatibleGroups =
        getCompatibleBloodGroups(normalizedBloodGroup);

      const safeCityRegex = new RegExp(
        `^${escapeRegex(normalizedCity)}$`,
        "i"
      );

      const matchingDonors = await Donor.find({
        bloodGroup: { $in: compatibleGroups },
        city: { $regex: safeCityRegex },
        available: true,
        user: { $ne: req.user.id }
      }).select("_id user lastDonationDate totalDonations");

      // Exclude donors who donated within the previous 90 days.
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 90);

      const eligibleDonors = matchingDonors.filter((donor) => {
        const totalDonations = donor.totalDonations ?? 0;

        if (totalDonations === 0) {
          return !donor.lastDonationDate;
        }

        if (!donor.lastDonationDate) {
          return false;
        }

        const lastDonation = new Date(donor.lastDonationDate);

        return (
          !Number.isNaN(lastDonation.getTime()) &&
          lastDonation <= cutoffDate
        );
      });

      const notificationDocuments = eligibleDonors
        .filter((donor) => donor.user)
        .map((donor) => ({
          userId: donor.user,
          title:
            (normalizedUrgency || "normal") === "emergency"
              ? "Emergency Blood Request"
              : "New Blood Request",
          message:
            `${normalizedBloodGroup} blood required in ${normalizedCity}. ` +
            `Units required: ${units}. ` +
            `Urgency: ${normalizedUrgency || "normal"}.`,
          type:
            (normalizedUrgency || "normal") === "emergency"
              ? "emergency"
              : "blood_request",
          relatedRequest: bloodRequest._id
        }));

      if (notificationDocuments.length > 0) {
        await Notification.insertMany(notificationDocuments);
      }

      console.log(
        `Created ${notificationDocuments.length} donor notifications`
      );
    } catch (notificationError) {
      console.error(
        "Create donor notifications error:",
        notificationError.message
      );
    }

    return res.status(201).json({
      success: true,
      message: "Blood request created successfully",
      bloodRequest
    });
  } catch (error) {
    console.error(
      "Create blood request error:",
      error.message
    );

    if (
      error.name === "ValidationError" ||
      error.name === "CastError"
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid blood request data"
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to create blood request"
    });
  }
};

// GET BLOOD REQUESTS WITH PAGINATION
const getBloodRequests = async (req, res) => {
  try {
    const pagination = validatePagination(req.query);

    if (pagination.error) {
      return res.status(400).json({
        success: false,
        message: pagination.error
      });
    }

    const { page, limit, skip } = pagination;

    // Admins can see all requests; other users see their own.
    const filter =
      req.user.role === "admin"
        ? {}
        : { requester: req.user.id };

    const [requests, totalRequests] = await Promise.all([
      BloodRequest.find(filter)
        .sort({ createdAt: -1, _id: -1 })
        .skip(skip)
        .limit(limit),

      BloodRequest.countDocuments(filter)
    ]);

    const totalPages = Math.ceil(totalRequests / limit);

    return res.status(200).json({
      success: true,
      totalRequests,
      bloodRequests: requests,
      pagination: {
        currentPage: page,
        limit,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1
      }
    });
  } catch (error) {
    console.error(
      "Get blood requests error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message: "Failed to fetch blood requests"
    });
  }
};

/* GET A SINGLE BLOOD REQUEST BY ID */
const getBloodRequestById = async (req, res) => {
  try {
    const { requestId } = req.params;

    // Validate MongoDB ObjectId
    if (!mongoose.isValidObjectId(requestId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid blood request ID"
      });
    }

    // Find the blood request
    const bloodRequest = await BloodRequest.findById(requestId);

    if (!bloodRequest) {
      return res.status(404).json({
        success: false,
        message: "Blood request not found"
      });
    }

    // Requesters can access only their own requests.
    // Admins can access all requests.
    if (
      req.user.role !== "admin" &&
      bloodRequest.requester.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to access this blood request"
      });
    }

    return res.status(200).json({
      success: true,
      bloodRequest
    });
  } catch (error) {
    console.error("Get blood request by ID error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch blood request"
    });
  }
};

// FIND POTENTIAL DONORS WITH PAGINATION
const getPotentialDonors = async (req, res) => {
  try {
    const { requestId } = req.params;

    // Validate MongoDB ObjectId.
    if (!mongoose.isValidObjectId(requestId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid blood request ID"
      });
    }

    const pagination = validatePagination(req.query);

    if (pagination.error) {
      return res.status(400).json({
        success: false,
        message: pagination.error
      });
    }

    const { page, limit, skip } = pagination;

    const bloodRequest =
      await BloodRequest.findById(requestId);

    if (!bloodRequest) {
      return res.status(404).json({
        success: false,
        message: "Blood request not found"
      });
    }

    // Requesters can only view donors for their own requests.
    if (
      req.user.role !== "admin" &&
      bloodRequest.requester.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        message: "You cannot view donors for this request"
      });
    }

    const compatibleGroups =
      getCompatibleBloodGroups(bloodRequest.bloodGroup);

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

    // Exclude donors who donated within the previous 90 days.
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 90);

    const eligibleDonors = donors.filter((donor) => {
      const totalDonations = donor.totalDonations ?? 0;

      if (totalDonations === 0) {
        return !donor.lastDonationDate;
      }

      if (!donor.lastDonationDate) {
        return false;
      }

      const lastDonation =
        new Date(donor.lastDonationDate);

      if (Number.isNaN(lastDonation.getTime())) {
        return false;
      }

      return lastDonation <= cutoffDate;
    });

    const hasMlData = (donor) =>
      donor.age != null &&
      donor.weightKg != null &&
      donor.hemoglobinGDl != null;

    const mlReady = eligibleDonors.filter(hasMlData);

    const mlSkipped =
      eligibleDonors.filter((donor) => !hasMlData(donor));

    let rankedList = mlReady.map((donor) => donor.toObject());
    let rankingApplied = false;

    if (mlReady.length > 0) {
      try {
        const result = await rankDonors(
          mlReady.map((donor) => ({
            donorId: donor._id.toString(),
            age: donor.age,
            weight_kg: donor.weightKg,
            hemoglobin_g_dL: donor.hemoglobinGDl,
            total_donations: donor.totalDonations ?? 0,
            days_since_last_donation:
              daysSince(donor.lastDonationDate)
          }))
        );

        // Validate the ranking service response.
        if (
          !Array.isArray(result) ||
          result.some(
            (item) =>
              !item ||
              typeof item.donor_id !== "string" ||
              typeof item.response_probability !== "number" ||
              !Number.isFinite(item.response_probability) ||
              item.response_probability < 0 ||
              item.response_probability > 1
          )
        ) {
          throw new Error(
            "ML ranking service returned invalid data"
          );
        }

        const scoreMap = new Map(
          result.map((item) => [
            item.donor_id,
            item.response_probability
          ])
        );

        rankedList = mlReady
          .map((donor) => ({
            ...donor.toObject(),
            responseProbability:
              scoreMap.get(donor._id.toString()) ?? null
          }))
          .sort(
            (a, b) =>
              (b.responseProbability ?? -1) -
              (a.responseProbability ?? -1)
          );

        rankingApplied = true;
      } catch (mlError) {
        // Fall back to the original donor list if ML fails.
        console.error(
          "Rank donors ML error:",
          mlError.message
        );
      }
    }

    // Donors without ML data remain at the end.
    const potentialDonors = [
      ...rankedList,
      ...mlSkipped.map((donor) => donor.toObject())
    ];

    // Paginate after ranking.
    const totalPotentialDonors = potentialDonors.length;

    const totalPages =
      Math.ceil(totalPotentialDonors / limit);

    const paginatedDonors =
      potentialDonors.slice(skip, skip + limit);

    return res.status(200).json({
      success: true,
      requestId: bloodRequest._id,
      predictedUrgency: bloodRequest.predictedUrgency,
      rankingApplied,
      totalPotentialDonors,
      potentialDonors: paginatedDonors,
      pagination: {
        currentPage: page,
        limit,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1
      }
    });
  } catch (error) {
    console.error(
      "Find potential donors error:",
      error.message
    );

    return res.status(500).json({
      success: false,
      message: "Failed to find potential donors"
    });
  }
};

module.exports = {
  createBloodRequest,
  getBloodRequests,
  getBloodRequestById,
  getPotentialDonors
};