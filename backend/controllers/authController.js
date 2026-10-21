const User = require("../models/User");
const bcrypt = require("bcrypt");
const Donor = require("../models/Donor");
const validator = require("validator");
const jwt = require("jsonwebtoken");

exports.register = async (req, res) => {
    let user = null;

    try {
        const { name, email, password, role, phone, city, bloodGroup } = req.body;

        // Validate required fields
        if (
            typeof name !== "string" ||
            typeof email !== "string" ||
            typeof password !== "string" ||
            typeof role !== "string" ||
            typeof city !== "string" ||
            !name.trim() ||
            !email.trim() ||
            !password ||
            !role.trim() ||
            !city.trim()
        ) {
            return res.status(400).json({
                success: false,
                message: "Please provide valid name, email, password, role, and city"
            });
        }

        // Validate name
        const cleanName = name.trim().replace(/\s+/g, " ");

        if (
            cleanName.length < 2 ||
            cleanName.length > 50 ||
            !/^[A-Za-z]+(?:[ '-][A-Za-z]+)*$/.test(cleanName)
        ) {
            return res.status(400).json({
                success: false,
                message: "Name must be 2–50 characters and contain only English letters, spaces, hyphens, or apostrophes"
            });
        }

        // Validate city
        const cleanCity = city.trim().replace(/\s+/g, " ");

        if (
            cleanCity.length > 100 ||
            !/^[A-Za-z]+(?:[ '-][A-Za-z]+)*$/.test(cleanCity)
        ) {
            return res.status(400).json({
                success: false,
                message: "Enter a valid city using letters, spaces, hyphens, or apostrophes"
            });
        }

        // Validate optional phone number
        let cleanPhone;

        if (phone !== undefined && phone !== null && phone !== "") {
            if ( typeof phone !== "string" || !/^[0-9]{10}$/.test(phone.trim())
            ) {
                return res.status(400).json({
                    success: false,
                    message: "Phone number must contain exactly 10 digits"
                });
            }
            cleanPhone = phone.trim();
        }
        // Validate email
        const normalizedEmail = email.trim().toLowerCase();

        if (!validator.isEmail(normalizedEmail)) {
            return res.status(400).json({
                success: false,
                message: "Please enter a valid email address"
            });
        }
        // Check common email domain typos
        const commonDomainTypos = {
            "gmil.com": "gmail.com",
            "gmai.com": "gmail.com",
            "gamil.com": "gmail.com",
            "yaho.com": "yahoo.com",
            "outloo.com": "outlook.com"
        };

        const [emailUsername, emailDomain] = normalizedEmail.split("@");

        if (commonDomainTypos[emailDomain]) {
            return res.status(400).json({
                success: false,
                message: `Did you mean ${emailUsername}@${commonDomainTypos[emailDomain]}?`
            });
        }

        // Validate password strength
        if (
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

        // Validate role
        if (!["requester", "donor"].includes(role)) {
            return res.status(400).json({
                success: false,
                message: "Invalid user role"
            });
        }

        // Validate donor blood group
        const allowedBloodGroups = [
            "A+", "A-", "B+", "B-",
            "AB+", "AB-", "O+", "O-"
        ];

        if (role === "donor" && !allowedBloodGroups.includes(bloodGroup)) {
            return res.status(400).json({
                success: false,
                message: "A valid blood group is required for donors"
            });
        }

        // Prevent duplicate registrations
        const existingUser = await User.findOne({
            email: normalizedEmail
        });

        if (existingUser) {
            return res.status(409).json({
                success: false,
                message: "Email already exists"
            });
        }

        // Hash password
        const passwordHash = await bcrypt.hash(password, 10);

        // Create user without OTP/email verification
        user = await User.create({
            name: cleanName,
            email: normalizedEmail,
            passwordHash,
            role,
            phone: cleanPhone,
            city: cleanCity
        });

        // Create donor profile if the role is donor
        if (role === "donor") {
            await Donor.create({
                user: user._id,
                bloodGroup,
                city: cleanCity
            });
        }

        return res.status(201).json({
            success: true,
            message: "Registration successful",
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });

    } catch (error) {
        console.error("Registration error:", error.message);

        // Roll back partially created records on failure
        if (user) {
            try {
                if (user.role === "donor") {
                    await Donor.deleteOne({ user: user._id });
                }

                await User.findByIdAndDelete(user._id);
            } catch (cleanupError) {
                console.error("Registration cleanup error:", cleanupError.message);
            }
        }

        return res.status(500).json({
            success: false,
            message: "Registration failed"
        });
    }
};


exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Validate login fields
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

        // Compare password with stored hash
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

        // Generate JWT without requiring OTP verification
        if (!process.env.JWT_SECRET) {
            throw new Error("JWT_SECRET is not configured");
        }

        const token = jwt.sign(
            {
                id: user._id,
                role: user.role
            },
            process.env.JWT_SECRET,
            { expiresIn: "1d" }
        );

        return res.status(200).json({
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

        return res.status(500).json({
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

        return res.status(200).json({
            success: true,
            user
        });

    } catch (error) {
        console.error("Get profile error:", error.message);

        return res.status(500).json({
            success: false,
            message: "Failed to fetch user"
        });
    }
};