
const User = require("../models/User");
const bcrypt = require("bcrypt");
const Donor = require("../models/Donor");

exports.register = async (req, res) => {
    try {
        const { name, email, password, role, phone, city } = req.body;

        if (!name || !email || !password || !role || !city) {
            return res.status(400).json({
                success: false,
                message: "Please fill all required fields"
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                message: "Password must be at least 6 characters"
            });
        }

        if (!["requester", "donor", "admin"].includes(role)) {
            return res.status(400).json({
                success: false,
                message: "Invalid user role"
            });
        }

        const existingUser = await User.findOne({
            email: email.toLowerCase().trim()
        });

        if (existingUser) {
            return res.status(409).json({
                success: false,
                message: "Email already exists"
            });
        }

        const passwordHash = await bcrypt.hash(password, 10);

        const user = await User.create({
            name,
            email: email.toLowerCase().trim(),
            passwordHash,
            role,
            phone,
            city
        });
        if (role === "donor") {
            await Donor.create({
            user: user._id,
            bloodGroup: req.body.bloodGroup,
            city
          });
        }  

        
       const allowedBloodGroups = [
            "A+", "A-", "B+", "B-",
            "AB+", "AB-", "O+", "O-"];

        if (role === "donor" && !allowedBloodGroups.includes(req.body.bloodGroup)
        ) {
         return res.status(400).json({
            success: false,
            message: "A valid blood group is required for donors"
          });
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

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: "Email and password are required"
            });
        }

        const user = await User.findOne({
            email: email.toLowerCase().trim()
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
