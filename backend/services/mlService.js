const DONOR_RANKING_URL = "https://model1-1-l5kq.onrender.com/rank-donors";

const URGENCY_ML_BASE_URL = process.env.URGENCY_ML_BASE_URL;

async function callML(url, payload) {
  let response;

  try {
    response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(100000),
    });
  } catch (error) {
    throw new Error(
      error.name === "TimeoutError"
        ? "ML service timed out"
        : "Unable to connect to ML service"
    );
  }

  const data = await response.json().catch(() => null);

  if (!response.ok) {
    throw new Error(`ML service returned status ${response.status}`);
  }

  if (data === null) {
    throw new Error("ML service returned an invalid JSON response");
  }

  return data;
}

// API 1: Rank shortlisted donors
async function rankDonors(donors) {
  if (!Array.isArray(donors) || donors.length === 0) {
    throw new Error("A non-empty donors array is required");
  }

  if (donors.length > 500) {
    throw new Error("Maximum 500 donors can be ranked at once");
  }

  return callML(DONOR_RANKING_URL, { donors });
}

// API 2: Predict blood request urgency
async function predictUrgency(requestData) {
  if (!URGENCY_ML_BASE_URL) {
    throw new Error("URGENCY_ML_BASE_URL is not configured");
  }

  const baseUrl = URGENCY_ML_BASE_URL.replace(/\/+$/, "");

  let parsedUrl;

  try {
    parsedUrl = new URL(baseUrl);
  } catch {
    throw new Error("Invalid urgency ML service URL");
  }

  if (!["http:", "https:"].includes(parsedUrl.protocol)) {
    throw new Error("Urgency ML URL must use HTTP or HTTPS");
  }

  return callML(`${baseUrl}/predict`, requestData);
}

module.exports = {
  rankDonors,
  predictUrgency,
};
