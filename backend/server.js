const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
require("dotenv").config();
const healthRoutes = require("./routes/healthRoutes");
const authRoutes = require("./routes/authRoutes");
const donorRoutes = require("./routes/donorRoutes");
const bloodRequestRoutes = require("./routes/bloodRequestRoutes");
const donorResponseRoutes = require("./routes/donorResponseRoutes");

const app = express();

app.use(cors());
app.use(express.json());
app.use("/api/health", healthRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/donors", donorRoutes);
app.use("/api/requests", bloodRequestRoutes);
app.use("/api/responses", donorResponseRoutes);

app.get("/", (req, res) => {
    res.json({
        message: "LifeLink backend is running!"
    });
});

const PORT = process.env.PORT || 5000;
async function startServer() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log("MongoDB connected successfully!");

        app.listen(PORT, () => {
            console.log(`LifeLink server running on port ${PORT}`);
        });
    } catch (error) {
        console.error("MongoDB connection failed:", error.message);
        process.exit(1);
    }
}
startServer();
