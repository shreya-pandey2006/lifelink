
const Donor = require("../models/Donor");

exports.getMyDonorProfile = async (req, res) => {
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

    res.status(200).json({
      success: true,
      donor
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch donor profile"
    });
  }
};
