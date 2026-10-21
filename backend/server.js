const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const mongoose = require("mongoose");
require("dotenv").config();

const healthRoutes = require("./routes/healthRoutes");
const authRoutes = require("./routes/authRoutes");
const donorRoutes = require("./routes/donorRoutes");
const bloodRequestRoutes = require("./routes/bloodRequestRoutes");
const donorResponseRoutes = require("./routes/donorResponseRoutes");
const mlRoutes = require("./routes/mlRoutes");
const adminRoutes = require("./routes/adminRoutes");
const notificationRoutes = require("./routes/notificationRoutes");

const app = express();

// Basic security
app.disable("x-powered-by");
app.use(helmet());

// Allowed frontend origins from .env
const allowedOrigins = (process.env.ALLOWED_ORIGINS || "")
    .split(",")
    .map(origin => origin.trim())
    .filter(Boolean);

app.use(cors({
    origin: (origin, callback) => {
        // Allow requests without an Origin header, such as
        // server-to-server requests and some API clients.
        if (!origin || allowedOrigins.includes(origin)) {
            return callback(null, true);
        }

        return callback(new Error("Origin not allowed by CORS"));
    },
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"]
}));

// Parse JSON with a size limit
app.use(express.json({ limit: "100kb" }));

// Handle malformed JSON and oversized request bodies
app.use((err, req, res, next) => {
    if (err instanceof SyntaxError && err.status === 400 && "body" in err) {
        return res.status(400).json({
            success: false,
            message: "Invalid JSON in request body"
        });
    }

    if (err.status === 413) {
        return res.status(413).json({
            success: false,
            message: "Request body is too large"
        });
    }

    next(err);
});

// API routes
app.use("/api/health", healthRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/donors", donorRoutes);
app.use("/api/requests", bloodRequestRoutes);
app.use("/api/responses", donorResponseRoutes);
app.use("/api/ml", mlRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/notifications", notificationRoutes);

// Root route
app.get("/", (req, res) => {
    res.status(200).json({
        success: true,
        message: "LifeLink backend is running!"
    });
});

// Handle unknown routes
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: `Route not found: ${req.method} ${req.originalUrl}`
    });
});

// Global error handler (must remain last)
app.use((err, req, res, next) => {
    if (res.headersSent) {
        return next(err);
    }

    // Log details on the server, not in the client response
    console.error("API Error:", err.message);

    if (err.message === "Origin not allowed by CORS") {
        return res.status(403).json({
            success: false,
            message: "Origin not allowed"
        });
    }

    const status = Number.isInteger(err.status) &&
        err.status >= 400 &&
        err.status < 500
        ? err.status
        : 500;

    res.status(status).json({
        success: false,
        message: status < 500
            ? err.message
            : "Internal server error"
    });
});

// Start server only after MongoDB connects
const PORT = process.env.PORT || 5000;

async function startServer() {
    if (!process.env.MONGODB_URI) {
        console.error("MONGODB_URI is missing from environment variables");
        process.exit(1);
    }

    if (allowedOrigins.length === 0) {
        console.error("ALLOWED_ORIGINS must contain at least one frontend origin");
        process.exit(1);
    }

    try {
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
