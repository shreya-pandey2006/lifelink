const { prepareDonorForML } = require("./services/mlDataService");

const testDonor = {
  _id: "donor123",
  age: 28,
  weightKg: 70.5,
  hemoglobinGDl: 14.2,
  totalDonations: 2,
  lastDonationDate: new Date("2026-09-01")
};

const result = prepareDonorForML(testDonor);

console.log("ML input data:");
console.log(result);
