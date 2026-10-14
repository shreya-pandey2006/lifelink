const {
  rankDonors,
  predictUrgency,
} = require("../services/mlService");

// POST /api/ml/rank-donors
exports.rankDonorsController = async (req, res) => {
  try {
    const result = await rankDonors(req.body.donors);
    return res.status(200).json(result);
  } catch (error) {
    console.error("Donor ranking error:", error.message);

    return res.status(502).json({
      success: false,
      message: "Donor ranking service failed",
    });
  }
};

// POST /api/ml/predict-urgency
exports.predictUrgencyController = async (req, res) => {
  try {
    const result = await predictUrgency(req.body);
    return res.status(200).json(result);
  } catch (error) {
    console.error("Urgency prediction error:", error.message);

    return res.status(502).json({
      success: false,
      message: "Urgency prediction service failed",
    });
  }
};