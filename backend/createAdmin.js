require("dotenv").config({ path: require("path").resolve(__dirname, ".env") });
console.log("MONGO_URI loaded:", Boolean(process.env.MONGO_URI));

const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
const User = require("./models/User");

async function createAdmin() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);

    const email = "admin@lifelink.com";
    const password = "Admin@12345";

    const existingAdmin = await User.findOne({ email });

    if (existingAdmin) {
      console.log("An account with this email already exists.");
      return;
    }

    const passwordHash = await bcrypt.hash(password, 10);

    await User.create({
      name: "LifeLink Admin",
      email,
      passwordHash,
      role: "admin",
      phone: "9999999999",
      city: "Ghaziabad"
    });

    console.log("Admin account created successfully.");
    console.log("Email:", email);
    console.log("Password:", password);
  } catch (error) {
    console.error("Error creating admin:", error.message);
  } finally {
    await mongoose.disconnect();
  }
}

createAdmin();
