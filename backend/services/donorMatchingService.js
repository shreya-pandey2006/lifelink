// services/donorMatchingService.js
// Blood-group compatibility, city coordinates, distance, and urgency helpers.

const BLOOD_GROUP_COMPATIBILITY = Object.freeze({
  "A+": ["A+", "A-", "O+", "O-"],
  "A-": ["A-", "O-"],
  "B+": ["B+", "B-", "O+", "O-"],
  "B-": ["B-", "O-"],
  "AB+": ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],
  "AB-": ["A-", "B-", "AB-", "O-"],
  "O+": ["O+", "O-"],
  "O-": ["O-"]
});

const VALID_BLOOD_GROUPS = Object.freeze(
  Object.keys(BLOOD_GROUP_COMPATIBILITY)
);

// Normalize and validate a blood group.
const normalizeBloodGroup = (bloodGroup) => {
  if (typeof bloodGroup !== "string") return null;

  const normalized = bloodGroup.trim().toUpperCase().replace(/\s+/g, "");
  return VALID_BLOOD_GROUPS.includes(normalized) ? normalized : null;
};

// Returns blood groups that can donate red blood cells to the requested group.
const getCompatibleBloodGroups = (requestedBloodGroup) => {
  const normalized = normalizeBloodGroup(requestedBloodGroup);

  if (!normalized) return [];

  return [...BLOOD_GROUP_COMPATIBILITY[normalized]];
};

// Check whether a donor's blood group is compatible with the requested group.
const isBloodGroupCompatible = (donorBloodGroup, requestedBloodGroup) => {
  const donorGroup = normalizeBloodGroup(donorBloodGroup);
  const requestedGroup = normalizeBloodGroup(requestedBloodGroup);

  if (!donorGroup || !requestedGroup) return false;

  return BLOOD_GROUP_COMPATIBILITY[requestedGroup].includes(donorGroup);
};

// Approximate city-center coordinates.
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
  srinagar: { lat: 34.0837, lng: 74.7978 },
  goa: { lat: 15.2993, lng: 74.1240 },
  panaji: { lat: 15.4909, lng: 73.8278 }
};

// Get coordinates for a known city.
const getCoordinatesForCity = (city) => {
  if (typeof city !== "string" || !city.trim()) return null;

  const key = city.trim().toLowerCase().replace(/\s+/g, " ");
  const coordinates = CITY_COORDINATES[key];

  return coordinates
    ? { lat: coordinates.lat, lng: coordinates.lng }
    : null;
};

// Validate a latitude/longitude pair.
const isValidCoordinatePair = (lat, lng) => {
  if (
    lat === undefined ||
    lat === null ||
    lng === undefined ||
    lng === null
  ) {
    return false;
  }

  if (
    (typeof lat === "string" && !lat.trim()) ||
    (typeof lng === "string" && !lng.trim())
  ) {
    return false;
  }

  const latitude = Number(lat);
  const longitude = Number(lng);

  return (
    Number.isFinite(latitude) &&
    Number.isFinite(longitude) &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180
  );
};

// Calculate the great-circle distance between two points in kilometers.
const calculateDistanceKm = (lat1, lng1, lat2, lng2) => {
  if (
    !isValidCoordinatePair(lat1, lng1) ||
    !isValidCoordinatePair(lat2, lng2)
  ) {
    return null;
  }

  const latitude1 = Number(lat1);
  const longitude1 = Number(lng1);
  const latitude2 = Number(lat2);
  const longitude2 = Number(lng2);

  const toRadians = (degrees) => (degrees * Math.PI) / 180;

  const dLat = toRadians(latitude2 - latitude1);
  const dLng = toRadians(longitude2 - longitude1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(latitude1)) *
      Math.cos(toRadians(latitude2)) *
      Math.sin(dLng / 2) ** 2;

  // Protect against floating-point rounding errors.
  const safeA = Math.min(1, Math.max(0, a));

  const centralAngle =
    2 * Math.atan2(Math.sqrt(safeA), Math.sqrt(1 - safeA));

  return 6371 * centralAngle;
};

// Radius rules:
// Normal = 20 km, urgent = 10 km, critical = 5 km.
const getMaxRadiusKm = (urgency) => {
  const normalized = String(urgency ?? "").trim().toLowerCase();

  if (["critical", "emergency", "3"].includes(normalized)) return 5;

  if (["urgent", "high", "medium", "2"].includes(normalized)) return 10;

  if (["normal", "low", "1", ""].includes(normalized)) return 20;

  return 20;
};

// Resolve coordinates from direct fields, nested user fields, or city.
const getEffectiveCoordinates = (item) => {
  if (!item || typeof item !== "object") return null;

  const candidates = [
    { lat: item.lat, lng: item.lng },
    { lat: item.latitude, lng: item.longitude },
    { lat: item.user?.lat, lng: item.user?.lng },
    { lat: item.user?.latitude, lng: item.user?.longitude }
  ];

  for (const candidate of candidates) {
    if (isValidCoordinatePair(candidate.lat, candidate.lng)) {
      return {
        lat: Number(candidate.lat),
        lng: Number(candidate.lng)
      };
    }
  }

  const city = item.city ?? item.user?.city;

  return getCoordinatesForCity(city);
};

// Calculate distance between a donor and a blood request.
const getDistanceBetweenItemsKm = (firstItem, secondItem) => {
  const first = getEffectiveCoordinates(firstItem);
  const second = getEffectiveCoordinates(secondItem);

  if (!first || !second) return null;

  return calculateDistanceKm(
    first.lat,
    first.lng,
    second.lat,
    second.lng
  );
};

module.exports = {
  BLOOD_GROUP_COMPATIBILITY,
  VALID_BLOOD_GROUPS,
  CITY_COORDINATES,
  normalizeBloodGroup,
  getCompatibleBloodGroups,
  isBloodGroupCompatible,
  getCoordinatesForCity,
  isValidCoordinatePair,
  calculateDistanceKm,
  getMaxRadiusKm,
  getEffectiveCoordinates,
  getDistanceBetweenItemsKm
};
