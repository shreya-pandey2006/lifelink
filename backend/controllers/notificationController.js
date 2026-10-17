const Notification = require("../models/Notification");

// GET /api/notifications
// Fetch notifications for the logged-in user
exports.getNotifications = async (req, res) => {
    try {
        const userId = req.user.id || req.user._id;

        const page = Math.max(1, parseInt(req.query.page, 10) || 1);
        const limit = Math.min(
            100,
            Math.max(1, parseInt(req.query.limit, 10) || 20)
        );

        const notifications = await Notification.find({ userId })
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(limit)
            .lean();

        const total = await Notification.countDocuments({ userId });

        res.status(200).json({
            success: true,
            message: "Notifications fetched successfully",
            total,
            page,
            limit,
            notifications
        });
    } catch (error) {
        console.error("Get notifications error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to fetch notifications"
        });
    }
};

// GET /api/notifications/unread-count
exports.getUnreadCount = async (req, res) => {
    try {
        const userId = req.user.id || req.user._id;

        const unreadCount = await Notification.countDocuments({
            userId,
            isRead: false
        });

        res.status(200).json({
            success: true,
            unreadCount
        });
    } catch (error) {
        console.error("Unread notification count error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to fetch unread notification count"
        });
    }
};

// PATCH /api/notifications/:id/read
exports.markAsRead = async (req, res) => {
    try {
        const userId = req.user.id || req.user._id;
        const { id } = req.params;

        if (!/^[0-9a-fA-F]{24}$/.test(id)) {
            return res.status(400).json({
                success: false,
                message: "Invalid notification ID"
            });
        }

        const notification = await Notification.findOneAndUpdate(
            { _id: id, userId },
            { $set: { isRead: true } },
            { new: true, runValidators: true }
        );

        if (!notification) {
            return res.status(404).json({
                success: false,
                message: "Notification not found"
            });
        }

        res.status(200).json({
            success: true,
            message: "Notification marked as read",
            notification
        });
    } catch (error) {
        console.error("Mark notification as read error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to mark notification as read"
        });
    }
};

// PATCH /api/notifications/read-all
exports.markAllAsRead = async (req, res) => {
    try {
        const userId = req.user.id || req.user._id;

        const result = await Notification.updateMany(
            { userId, isRead: false },
            { $set: { isRead: true } }
        );

        res.status(200).json({
            success: true,
            message: "All notifications marked as read",
            modifiedCount: result.modifiedCount
        });
    } catch (error) {
        console.error("Mark all notifications as read error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to mark all notifications as read"
        });
    }
};

// DELETE /api/notifications/:id
exports.deleteNotification = async (req, res) => {
    try {
        const userId = req.user.id || req.user._id;
        const { id } = req.params;

        if (!/^[0-9a-fA-F]{24}$/.test(id)) {
            return res.status(400).json({
                success: false,
                message: "Invalid notification ID"
            });
        }

        const notification = await Notification.findOneAndDelete({
            _id: id,
            userId
        });

        if (!notification) {
            return res.status(404).json({
                success: false,
                message: "Notification not found"
            });
        }

        res.status(200).json({
            success: true,
            message: "Notification deleted successfully"
        });
    } catch (error) {
        console.error("Delete notification error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to delete notification"
        });
    }
};