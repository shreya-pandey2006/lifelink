const User = require("../models/User");
const bcrypt = require("bcrypt");
const Donor = require("../models/Donor");
const validator = require("validator");

exports.register = async (req, res) => {
    try {
        const { name, email, password, role, phone, city } = req.body;

        if (!name || !email || !password || !role || !city) {
            return res.status(400).json({
                success: false,
                message: "Please fill all required fields"
            });
        }
        
        if (
            typeof name !== "string" ||
            name.trim().length < 2 ||
            name.trim().length > 100
        ) {
            return res.status(400).json({
                success: false,
                message: "Name must be between 2 and 100 characters"
            });
        }
        
        if (typeof city !== "string" || city.trim().length < 1 || city.trim().length > 100) {
            return res.status(400).json({
                success: false,
                message: "City must be between 1 and 100 characters"
            });
        }
        
        if (
            phone !== undefined &&
            phone !== null &&
            phone !== "" &&
            (
                typeof phone !== "string" ||  !/^\+?[0-9]{10,15}$/.test(phone.trim())
            )
        ) {
           return res.status(400).json({
                success: false,
                message: "Please enter a valid phone number (10–15 digits, optional + prefix)"
            });
        }

        if (typeof email !== "string") {
            return res.status(400).json({
                success: false,
                message: "Please enter a valid email address"
            });
        }
        const normalizedEmail = email.trim().toLowerCase();
        if (typeof email !== "string" || !validator.isEmail(email.trim())) {
            return res.status(400).json({
                success: false,
                message: "Please enter a valid email address"
            });
        }

        if (
            typeof password !== "string" ||
            password.length < 8 ||
            !/[A-Z]/.test(password) ||
            !/[a-z]/.test(password) ||
            !/[0-9]/.test(password) ||
            !/[^A-Za-z0-9]/.test(password)
        ) {
            return res.status(400).json({
                success: false,
                message: "Password must be at least 8 characters and contain uppercase, lowercase, number, and special character"
            });
        }

        if (!["requester", "donor"].includes(role)) {
            return res.status(400).json({
               success: false,
               message: "Invalid user role"
            });
        }

        const allowedBloodGroups = [
            "A+", "A-", "B+", "B-",
            "AB+", "AB-", "O+", "O-"
        ];   

        if (role === "donor" && !allowedBloodGroups.includes(req.body.bloodGroup)
        ) {
            return res.status(400).json({
                success: false,
                message: "A valid blood group is required for donors"
            });
        }

        const existingUser = await User.findOne({
            email: normalizedEmail
        });

        if (existingUser) {
            return res.status(409).json({
                success: false,
                message: "Email already exists"
            });
        }

        const passwordHash = await bcrypt.hash(password, 10);

        const user = await User.create({
        name: name.trim(),
        email: normalizedEmail,
        passwordHash,
        role,
        phone: phone ? phone.trim() : phone,
        city: city.trim()
    });

    try {
        if (role === "donor") {
            await Donor.create({
                user: user._id,
                bloodGroup: req.body.bloodGroup,
                city: city.trim()
            });
        }
    } catch (error) {
    // Roll back the user if donor profile creation fails.
        await User.findByIdAndDelete(user._id);
        throw error;
    }

        res.status(201).json({
            success: true,
            message: "User registered successfully",
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                city: user.city
            }
        });
    } catch (error) {
        console.error("Registration error:", error.message);
        res.status(500).json({
            success: false,
            message: "Registration failed"
        });
    }
};

const jwt = require("jsonwebtoken");

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

       if (
        typeof email !== "string" ||
        !email.trim() ||
        typeof password !== "string" ||
        !password
    ) {
        return res.status(400).json({
            success: false,
            message: "Email and password are required"
        });
    }
        const normalizedEmail = email.trim().toLowerCase();
        const user = await User.findOne({
            email: normalizedEmail
        });

        if (!user) {
            return res.status(401).json({
                success: false,
                message: "Invalid email or password"
            });
        }

        const isMatch = await bcrypt.compare(
            password,
            user.passwordHash
        );

        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: "Invalid email or password"
            });
        }

        const token = jwt.sign(
            {
                id: user._id,
                role: user.role
            },
            process.env.JWT_SECRET,
            { expiresIn: "1d" }
        );

        res.status(200).json({
            success: true,
            message: "Login successful",
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });
    } catch (error) {
        console.error("Login error:", error.message);

        res.status(500).json({
            success: false,
            message: "Login failed"
        });
    }
};


exports.getMe = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select(
            "-passwordHash"
        );

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found"
            });
        }

        res.status(200).json({
            success: true,
            user
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to fetch user"
        });
    }
};
