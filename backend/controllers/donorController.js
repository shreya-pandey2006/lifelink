const Donor = require("../models/Donor");

const getMyDonorProfile = async (req, res) => {
  try {
    const donor = await Donor.findOne({
      user: req.user.id
    });

    if (!donor) {
      return res.status(404).json({
        success: false,
        message: "Donor profile not found"
      });
    }

    return res.status(200).json({
      success: true,
      donor
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch donor profile"
    });
  }
};

const updateAvailability = async (req, res) => {
  try {
    const { available } = req.body;

    if (typeof available !== "boolean") {
      return res.status(400).json({
        success: false,
        message: "Available must be true or false"
      });
    }

    const donor = await Donor.findOneAndUpdate(
      { user: req.user.id },
      { available },
      { new: true, runValidators: true }
    );

    if (!donor) {
      return res.status(404).json({
        success: false,
        message: "Donor profile not found"
      });
    }

    return res.status(200).json({
      success: true,
      message: "Availability updated successfully",
      available: donor.available
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update availability"
    });
  }
};

const updateMLDetails = async (req, res) => {
  try {
    const { age, weightKg, hemoglobinGDl } = req.body;

    if (
      !Number.isFinite(age) ||
      !Number.isFinite(weightKg) ||
      !Number.isFinite(hemoglobinGDl)
    ) {
      return res.status(400).json({
        success: false,
        message: "Age, weightKg and hemoglobinGDl must be numbers"
      });
    };

    if (
      age < 18 ||
      age > 100 ||
      weightKg <= 0 ||
      hemoglobinGDl <= 0
    ) {
      return res.status(400).json({
        success: false,
        message: "Please provide valid donor details"
      });
    }

    const donor = await Donor.findOneAndUpdate(
      { user: req.user.id },
      { age, weightKg, hemoglobinGDl },
      { new: true, runValidators: true }
    );

    if (!donor) {
      return res.status(404).json({
        success: false,
        message: "Donor profile not found"
      });
    }

    return res.status(200).json({
      success: true,
      message: "ML details updated successfully",
      donor: {
        age: donor.age,
        weightKg: donor.weightKg,
        hemoglobinGDl: donor.hemoglobinGDl
      }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update ML details"
    });
  }
}

const getAvailableDonorCount = async (req, res) => {
  try {
    const count = await Donor.countDocuments({
      available: true
    });

    return res.status(200).json({
      success: true,
      availableDonorCount: count
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to count available donors"
    });
  }
};

module.exports = {
  getMyDonorProfile,
  updateAvailability,
  updateMLDetails,
  getAvailableDonorCount
};
