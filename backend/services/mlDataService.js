function prepareDonorForML(donor) {
  const requiredFields = [
    donor.age,
    donor.weightKg,
    donor.hemoglobinGDl,
    donor.totalDonations
  ];

  if ( requiredFields.some(
      value => typeof value !== "number" || !Number.isFinite(value)
    )
  ) {
    return null;
  }
  let daysSinceLastDonation = null;

  if (donor.lastDonationDate) {
    const lastDonation = new Date(donor.lastDonationDate);

    if (Number.isNaN(lastDonation.getTime())) {
      return null;
    }

    daysSinceLastDonation = Math.floor(
      (Date.now() - lastDonation.getTime()) / (1000 * 60 * 60 * 24)
    );

    if (daysSinceLastDonation < 0) {
      return null;
    }
  } else if (donor.totalDonations > 0) {
    return null;
  } else {
    // Confirm with the ML developer how never-donated donors
    // should be represented before sending them to the model.
    return null;
  }

  return {
    donorId: donor._id.toString(),
    age: donor.age,
    weight_kg: donor.weightKg,
    hemoglobin_g_dl: donor.hemoglobinGDl,
    total_donations: donor.totalDonations,
    days_since_last_donation: daysSinceLastDonation
  };
}
module.exports = { prepareDonorForML };
