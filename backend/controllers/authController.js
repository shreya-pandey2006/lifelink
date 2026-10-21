const User = require("../models/User");
const bcrypt = require("bcrypt");
const Donor = require("../models/Donor");
const validator = require("validator");
const jwt = require("jsonwebtoken");
const { createAndSendOtp } = require("../utils/emailOtp");

exports.register = async (req, res) => {
    try {
        const { name, email, password, role, phone, city } = req.body;

        // Check required fields and their types
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

        if (cleanName.length < 2 || cleanName.length > 50) {
           return res.status(400).json({
               success: false,
               message: "Name must be between 2 and 50 characters"
            });
        }

        if (!/^[A-Za-z]+(?:[ '-][A-Za-z]+)*$/.test(cleanName)) {
            return res.status(400).json({
                success: false,
                message: "Name can contain only English letters, spaces, hyphens, and apostrophes"
            });
        }

       const cleanCity = city.trim().replace(/\s+/g, " ");
        if ( cleanCity.length > 100 ||
            !/^[A-Za-z]+(?:[ '-][A-Za-z]+)*$/.test(cleanCity)
        ) {
            return res.status(400).json({
                success: false,
                message: "Enter a valid city using letters, spaces, hyphens, or apostrophes"
            });
        }
        
        let cleanPhone;
        if (phone !== undefined && phone !== null && phone !== "") {
            if ( typeof phone !== "string" ||
                !/^\+?[0-9]{10,15}$/.test(phone.trim())
            ) {
            return res.status(400).json({
                  success: false,
                  message: "Phone number must contain 10–15 digits, optionally starting with +"
            });
        }
            cleanPhone = phone.trim();
        }

       const normalizedEmail = email.trim().toLowerCase();

        if (!validator.isEmail(normalizedEmail)) {
            return res.status(400).json({
                success: false,
                message: "Please enter a valid email address"
            });
        }

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

        const domain = normalizedEmail.split("@")[1];
         if (commonDomainTypos[domain]) {
            return res.status(400).json({
                success: false,
                message: `Did you mean ${normalizedEmail.split("@")[0]}@${commonDomainTypos[domain]}?`
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
            name: cleanName,
            email: normalizedEmail,
            passwordHash,
            role,
            phone: cleanPhone,
            city: cleanCity,
            isEmailVerified: false
        });
        try {
            if (role === "donor") {
                await Donor.create({
                    user: user._id,
                    bloodGroup: req.body.bloodGroup,
                    city: city.trim()
                });
            }
            // Generate and send the email verification OTP
            await createAndSendOtp(user);

        } catch (error) {
            // Clean up if donor creation or OTP delivery fails
            if (role === "donor") {
                await Donor.deleteOne({ user: user._id });
            }
            await User.findByIdAndDelete(user._id);
            throw error;
        }

        return res.status(201).json({
            success: true,
            message: "Registration successful. Please verify your email using the OTP sent to your inbox.",
            requiresEmailVerification: true,
            email: user.email
        });
        } catch (error) {
            console.error("Registration error:", error.message);

            return res.status(500).json({
                success: false,
                message: "Registration failed"
            });
        }
        };        


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
        if (!user.isEmailVerified) {
            return res.status(403).json({
                success: false,
                message: "Please verify your email before logging in",
                requiresEmailVerification: true,
                email: user.email
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
