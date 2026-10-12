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

module.exports = {
  getCompatibleBloodGroups
};
