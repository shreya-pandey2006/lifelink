const {
  rankDonors,
  predictUrgency,
} = require("../services/mlService");

// POST /api/ml/rank-donors
exports.rankDonorsController = async (req, res) => {
  try {
    const { donors } = req.body || {};

    if (!Array.isArray(donors) || donors.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Donors must be a non-empty array"
      });
    }

    if (donors.length > 500) {
      return res.status(400).json({
        success: false,
        message: "Maximum 500 donors can be ranked at once"
      });
    }

    if (
      donors.some(
        donor =>
          !donor ||
          typeof donor !== "object" ||
          Array.isArray(donor)
      )
    ) {
      return res.status(400).json({
        success: false,
        message: "Each donor must be an object"
      });
    }

    const result = await rankDonors(donors);

    return res.status(200).json(result);
  } catch (error) {
    console.error("Donor ranking error:", error.message);

    return res.status(502).json({
      success: false,
      message: "Donor ranking service failed"
    });
  }
};

// POST /api/ml/predict-urgency
exports.predictUrgencyController = async (req, res) => {
  try {
    const input = req.body;

    if (
      !input ||
      typeof input !== "object" ||
      Array.isArray(input)
    ) {
      return res.status(400).json({
        success: false,
        message: "Request body must be an object"
      });
    }

    if (Object.keys(input).length === 0) {
      return res.status(400).json({
        success: false,
        message: "Prediction input cannot be empty"
      });
    }

    const result = await predictUrgency(input);

    return res.status(200).json(result);
  } catch (error) {
    console.error("Urgency prediction error:", error.message);

    return res.status(502).json({
      success: false,
      message: "Urgency prediction service failed"
    });
  }
};