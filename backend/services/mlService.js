const DONOR_RANKING_URL = "https://model1-1-l5kq.onrender.com/rank-donors";

const URGENCY_ML_BASE_URL = process.env.URGENCY_ML_BASE_URL;

async function callML(url, payload) {
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
    signal: AbortSignal.timeout(30000),
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(
      `ML service returned ${response.status}: ` +
      JSON.stringify(data)
    );
  }
  return data;
}

// API 1: Rank shortlisted donors
async function rankDonors(donors) {
  if (!Array.isArray(donors) || donors.length === 0) {
    throw new Error("A non-empty donors array is required");
  }

  return callML(DONOR_RANKING_URL, { donors });
}

// API 2: Predict blood request urgency
async function predictUrgency(requestData) {
  if (!URGENCY_ML_BASE_URL) {
    throw new Error("URGENCY_ML_BASE_URL is not configured");
  }

  const baseUrl = URGENCY_ML_BASE_URL.replace(/\/+$/, "");
  return callML(`${baseUrl}/predict`, requestData);
}

module.exports = {
  rankDonors,
  predictUrgency,
};