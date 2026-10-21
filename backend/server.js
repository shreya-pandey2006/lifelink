const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const mongoose = require("mongoose");
require("dotenv").config();

// Import routes
const healthRoutes = require("./routes/healthRoutes");
const authRoutes = require("./routes/authRoutes");
const donorRoutes = require("./routes/donorRoutes");
const bloodRequestRoutes = require("./routes/bloodRequestRoutes");
const donorResponseRoutes = require("./routes/donorResponseRoutes");
const mlRoutes = require("./routes/mlRoutes");
const adminRoutes = require("./routes/adminRoutes");
const notificationRoutes = require("./routes/notificationRoutes");

const app = express();

// Security
app.disable("x-powered-by");
app.use(helmet());

// Allowed frontend URLs
const allowedOrigins = (process.env.ALLOWED_ORIGINS || "")
    .split(",")
    .map(origin => origin.trim())
    .filter(Boolean);

// CORS configuration
app.use(cors({
    origin: (origin, callback) => {
        if (!origin || allowedOrigins.includes(origin)) {
            return callback(null, true);
        }

        return callback(new Error("Origin not allowed by CORS"));
    }
}));

// Read JSON data sent by the frontend or Postman
app.use(express.json({ limit: "100kb" }));

// API routes
app.use("/api/health", healthRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/donors", donorRoutes);
app.use("/api/requests", bloodRequestRoutes);
app.use("/api/responses", donorResponseRoutes);
app.use("/api/ml", mlRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/notifications", notificationRoutes);

// Home route
app.get("/", (req, res) => {
    res.status(200).json({
        success: true,
        message: "LifeLink backend is running!"
    });
});

// Handle routes that do not exist
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: "Route not found"
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error("API Error:", err.message);

    if (res.headersSent) {
        return next(err);
    }

    if (err.message === "Origin not allowed by CORS") {
        return res.status(403).json({
            success: false,
            message: "Origin not allowed"
        });
    }

    if (err instanceof SyntaxError && err.status === 400 && "body" in err) {
        return res.status(400).json({
            success: false,
            message: "Invalid JSON"
        });
    }

    if (err.status === 413) {
        return res.status(413).json({
            success: false,
            message: "Request body is too large"
        });
    }

    return res.status(500).json({
        success: false,
        message: "Internal server error"
    });
});

// Connect to MongoDB and start the server
const PORT = process.env.PORT || 5000;

async function startServer() {
    try {
        if (!process.env.MONGODB_URI) {
            throw new Error("MONGODB_URI is missing");
        }

        if (allowedOrigins.length === 0) {
            throw new Error("ALLOWED_ORIGINS is missing");
        }

        await mongoose.connect(process.env.MONGODB_URI);
        console.log("MongoDB connected successfully!");

        app.listen(PORT, () => {
            console.log(`LifeLink server running on port ${PORT}`);
        });
    } catch (error) {
        console.error("Server startup failed:", error.message);
        process.exit(1);
    }
}

startServer();