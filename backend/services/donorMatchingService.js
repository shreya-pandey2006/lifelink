const BLOOD_GROUP_COMPATIBILITY = {
  "A+": ["A+", "A-", "O+", "O-"],
  "A-": ["A-", "O-"],
  "B+": ["B+", "B-", "O+", "O-"],
  "B-": ["B-", "O-"],
  "AB+": ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],
  "AB-": ["A-", "B-", "AB-", "O-"],
  "O+": ["O+", "O-"],
  "O-": ["O-"]
};

const getCompatibleBloodGroups = (requestedBloodGroup) => {
  return BLOOD_GROUP_COMPATIBILITY[requestedBloodGroup] || [];
};

const CITY_COORDINATES = {
  ghaziabad: { lat: 28.6692, lng: 77.4538 },
  noida: { lat: 28.5355, lng: 77.3910 },
  "greater noida": { lat: 28.4744, lng: 77.5040 },
  delhi: { lat: 28.6139, lng: 77.2090 },
  "new delhi": { lat: 28.6139, lng: 77.2090 },
  gurugram: { lat: 28.4595, lng: 77.0266 },
  faridabad: { lat: 28.4089, lng: 77.3178 },
  meerut: { lat: 28.9845, lng: 77.7064 },
  mumbai: { lat: 19.0760, lng: 72.8777 },
  "navi mumbai": { lat: 19.0330, lng: 73.0297 },
  thane: { lat: 19.2183, lng: 72.9781 },
  pune: { lat: 18.5204, lng: 73.8567 },
  nagpur: { lat: 21.1458, lng: 79.0882 },
  nashik: { lat: 19.9975, lng: 73.7898 },
  bengaluru: { lat: 12.9716, lng: 77.5946 },
  mysuru: { lat: 12.2958, lng: 76.6394 },
  hyderabad: { lat: 17.3850, lng: 78.4867 },
  secunderabad: { lat: 17.4399, lng: 78.4983 },
  chennai: { lat: 13.0827, lng: 80.2707 },
  coimbatore: { lat: 11.0168, lng: 76.9558 },
  madurai: { lat: 9.9252, lng: 78.1198 },
  kolkata: { lat: 22.5726, lng: 88.3639 },
  howrah: { lat: 22.5958, lng: 88.2636 },
  lucknow: { lat: 26.8467, lng: 80.9462 },
  kanpur: { lat: 26.4499, lng: 80.3319 },
  varanasi: { lat: 25.3176, lng: 82.9739 },
  prayagraj: { lat: 25.4358, lng: 81.8463 },
  agra: { lat: 27.1767, lng: 78.0081 },
  patna: { lat: 25.5941, lng: 85.1376 },
  gaya: { lat: 24.7955, lng: 85.0002 },
  ranchi: { lat: 23.3441, lng: 85.3096 },
  jamshedpur: { lat: 22.8046, lng: 86.2029 },
  ahmedabad: { lat: 23.0225, lng: 72.5714 },
  surat: { lat: 21.1702, lng: 72.8311 },
  vadodara: { lat: 22.3072, lng: 73.1812 },
  jaipur: { lat: 26.9124, lng: 75.7873 },
  jodhpur: { lat: 26.2389, lng: 73.0243 },
  udaipur: { lat: 24.5854, lng: 73.7125 },
  bhopal: { lat: 23.2599, lng: 77.4126 },
  indore: { lat: 22.7196, lng: 75.8577 },
  gwalior: { lat: 26.2183, lng: 78.1828 },
  jabalpur: { lat: 23.1815, lng: 79.9864 },
  chandigarh: { lat: 30.7333, lng: 76.7794 },
  ludhiana: { lat: 30.9010, lng: 75.8573 },
  amritsar: { lat: 31.6340, lng: 74.8723 },
  dehradun: { lat: 30.3165, lng: 78.0322 },
  haridwar: { lat: 29.9457, lng: 78.1642 },
  bhubaneswar: { lat: 20.2961, lng: 85.8245 },
  cuttack: { lat: 20.4625, lng: 85.8828 },
  kochi: { lat: 9.9312, lng: 76.2673 },
  thiruvananthapuram: { lat: 8.5241, lng: 76.9366 },
  kozhikode: { lat: 11.2588, lng: 75.7804 },
  guwahati: { lat: 26.1445, lng: 91.7362 },
  raipur: { lat: 21.2514, lng: 81.6296 },
  shillong: { lat: 25.5788, lng: 91.8933 },
  shimla: { lat: 31.1048, lng: 77.1734 },
  jammu: { lat: 32.7266, lng: 74.8570 },
  srinagar: { lat: 34.0837, lng: 74.7973 },
  goa: { lat: 15.2993, lng: 74.1240 },
  panaji: { lat: 15.4909, lng: 73.8278 }
};

const getCoordinatesForCity = (city) => {
  if (!city || typeof city !== "string") return null;
  const key = city.trim().toLowerCase();
  return CITY_COORDINATES[key] || null;
};

// Calculate Haversine distance in kilometers
const calculateDistanceKm = (lat1, lng1, lat2, lng2) => {
  if (
    lat1 === undefined || lat1 === null ||
    lng1 === undefined || lng1 === null ||
    lat2 === undefined || lat2 === null ||
    lng2 === undefined || lng2 === null
  ) {
    return null;
  }
  const nLat1 = Number(lat1);
  const nLng1 = Number(lng1);
  const nLat2 = Number(lat2);
  const nLng2 = Number(lng2);

  if (
    !Number.isFinite(nLat1) ||
    !Number.isFinite(nLng1) ||
    !Number.isFinite(nLat2) ||
    !Number.isFinite(nLng2)
  ) {
    return null;
  }

  const R = 6371.0; // Earth radius in km
  const toRad = (deg) => (deg * Math.PI) / 180.0;
  const dLat = toRad(nLat2 - nLat1);
  const dLng = toRad(nLng2 - nLng1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(nLat1)) *
      Math.cos(toRad(nLat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

// Urgency rules:
// Normal: donors within 20 km radius
// Urgent: donors within 10 km radius
// Critical: donors within 5 km radius
const getMaxRadiusKm = (urgency) => {
  const norm = String(urgency || "").trim().toLowerCase();
  if (norm === "critical" || norm === "emergency" || norm === "3") {
    return 5.0;
  }
  if (norm === "urgent" || norm === "high" || norm === "medium" || norm === "2") {
    return 10.0;
  }
  return 20.0; // normal / low / default
};

const getEffectiveCoordinates = (item) => {
  if (!item) return null;
  let lat = item.lat ?? item.latitude;
  let lng = item.lng ?? item.longitude;

  if (lat !== undefined && lat !== null && lng !== undefined && lng !== null) {
    const nLat = Number(lat);
    const nLng = Number(lng);
    if (Number.isFinite(nLat) && Number.isFinite(nLng)) {
      return { lat: nLat, lng: nLng };
    }
  }

  const city = item.city || item.user?.city;
  return getCoordinatesForCity(city);
};

module.exports = {
  getCompatibleBloodGroups,
  CITY_COORDINATES,
  getCoordinatesForCity,
  calculateDistanceKm,
  getMaxRadiusKm,
  getEffectiveCoordinates
};