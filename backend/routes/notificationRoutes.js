const express = require("express");
const router = express.Router();

const {
    getNotifications,
    getUnreadCount,
    markAsRead,
    markAllAsRead,
    deleteNotification
} = require("../controllers/notificationController");

const { auth } = require("../middleware/authMiddleware");

// Get all notifications
router.get("/", auth, getNotifications);

// Get unread notification count
router.get("/unread-count", auth, getUnreadCount);

// Mark all notifications as read
router.patch("/read-all", auth, markAllAsRead);

// Mark one notification as read
router.patch("/:id/read", auth, markAsRead);

// Delete one notification
router.delete("/:id", auth, deleteNotification);

module.exports = router;