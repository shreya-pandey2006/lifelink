const axios = require("axios");

exports.predictUrgency = async (data) => {
  const res = await axios.post(`${process.env.ML_URGENCY_URL}/predict`, data, { timeout: 60000 });
  return res.data.predicted_urgency_level;
};

exports.rankDonors = async (donors) => {
  const res = await axios.post(`${process.env.ML_RANK_URL}/rank-donors`, { donors }, { timeout: 60000 });
  return res.data.ranked_donors;
};