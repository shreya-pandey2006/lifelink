require("dotenv").config();

const sendEmail = require("./utils/sendEmail");

async function testEmail() {
    try {
        await sendEmail({
            to: process.env.SMTP_USER,
            subject: "LifeLink Email Test",
            text: "Your LifeLink email service is working!"
        });

        console.log("Test email sent successfully");
    } catch (error) {
        console.error("Email sending failed:", error.message);
    }
}

testEmail();
