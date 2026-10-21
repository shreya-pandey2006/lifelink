import { useEffect, useState } from "react";
import "./Notifications.css";

const API_URL = "https://lifelink-backend-8onj.onrender.com";

function Notifications({ onUnreadCountChange }) {
  const [notifications, setNotifications] = useState([]);
  const [filter, setFilter] = useState("all");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [workingId, setWorkingId] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);

  const getToken = () => localStorage.getItem("token");

  async function apiRequest(path, options = {}) {
    const token = getToken();

    if (!token) {
      throw new Error("Please login first to view notifications.");
    }

    const response = await fetch(`${API_URL}${path}`, {
      ...options,
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        ...options.headers,
      },
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      throw new Error(
        data.message || `Request failed (${response.status})`
      );
    }

    return data;
  }

  async function loadNotifications() {
    setLoading(true);
    setError("");

    try {
      const [listResult, countResult] = await Promise.all([
        apiRequest("/api/notifications?page=1&limit=100"),
        apiRequest("/api/notifications/unread-count"),
      ]);

      const list = Array.isArray(listResult.notifications)
        ? listResult.notifications
        : [];

      setNotifications(list);

      const unread = Number(countResult.unreadCount || 0);
      onUnreadCountChange?.(unread);
    } catch (err) {
      setError(err.message || "Could not load notifications.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadNotifications();
  }, []);

  const updateUnreadCount = (list) => {
    onUnreadCountChange?.(
      list.filter((item) => !item.isRead).length
    );
  };

  async function markAsRead(notification) {
    if (notification.isRead) return;

    setWorkingId(notification._id);

    try {
      await apiRequest(
        `/api/notifications/${notification._id}/read`,
        { method: "PATCH" }
      );

      const updated = notifications.map((item) =>
        item._id === notification._id
          ? { ...item, isRead: true }
          : item
      );

      setNotifications(updated);
      updateUnreadCount(updated);
    } catch (err) {
      setError(err.message);
    } finally {
      setWorkingId(null);
    }
  }

  async function markAllAsRead() {
    setActionLoading(true);
    setError("");

    try {
      await apiRequest("/api/notifications/read-all", {
        method: "PATCH",
      });

      const updated = notifications.map((item) => ({
        ...item,
        isRead: true,
      }));

      setNotifications(updated);
      onUnreadCountChange?.(0);
    } catch (err) {
      setError(err.message);
    } finally {
      setActionLoading(false);
    }
  }

  async function deleteNotification(id) {
    setWorkingId(id);

    try {
      await apiRequest(`/api/notifications/${id}`, {
        method: "DELETE",
      });

      const updated = notifications.filter(
        (item) => item._id !== id
      );

      setNotifications(updated);
      updateUnreadCount(updated);
    } catch (err) {
      setError(err.message);
    } finally {
      setWorkingId(null);
    }
  }

  const unreadCount = notifications.filter(
    (item) => !item.isRead
  ).length;

  const filteredNotifications = notifications.filter((item) => {
    if (filter === "unread") return !item.isRead;
    if (filter === "read") return item.isRead;
    return true;
  });

  function getTypeLabel(type) {
    const labels = {
      emergency: "Emergency",
      blood_request: "Blood Request",
      request_update: "Request Update",
      general: "General",
    };

    return labels[type] || "Notification";
  }

  function getTypeIcon(type) {
    const icons = {
      emergency: "⚠",
      blood_request: "🩸",
      request_update: "↻",
      general: "●",
    };

    return icons[type] || "●";
  }

  function formatDate(dateValue) {
    if (!dateValue) return "Date unavailable";

    const date = new Date(dateValue);

    if (Number.isNaN(date.getTime())) {
      return "Date unavailable";
    }

    return date.toLocaleString("en-IN", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  }

  return (
    <section className="notifications-page">
      <div className="notifications-heading">
        <div>
          <p className="notifications-eyebrow">
            LIFELINK COMMAND CENTER
          </p>

          <h1>Notifications</h1>

          <p className="notifications-subtitle">
            Stay updated on blood requests and emergency activity.
          </p>
        </div>

        <button
          className="notification-refresh-btn"
          onClick={loadNotifications}
          disabled={loading}
        >
          ↻ {loading ? "Refreshing..." : "Refresh"}
        </button>
      </div>

      <div className="notification-summary">
        <div className="notification-summary-icon">♧</div>

        <div className="notification-summary-text">
          <span>Unread notifications</span>
          <strong>{unreadCount}</strong>
        </div>

        <button
          className="mark-all-btn"
          onClick={markAllAsRead}
          disabled={actionLoading || unreadCount === 0}
        >
          {actionLoading ? "Updating..." : "Mark all as read"}
        </button>
      </div>

      <div className="notifications-toolbar">
        <div>
          <h2>Recent Activity</h2>
          <p>Updates from your LifeLink network</p>
        </div>

        <div className="notification-filters">
          {[
            { value: "all", label: "All" },
            { value: "unread", label: "Unread" },
            { value: "read", label: "Read" },
          ].map((item) => (
            <button
              key={item.value}
              className={
                filter === item.value
                  ? "notification-filter active"
                  : "notification-filter"
              }
              onClick={() => setFilter(item.value)}
            >
              {item.label}
              {item.value === "unread" && unreadCount > 0 && (
                <span className="filter-count">{unreadCount}</span>
              )}
            </button>
          ))}
        </div>
      </div>

      {error && (
        <div className="notification-error">
          <strong>Unable to load notifications</strong>
          <p>{error}</p>
          <button onClick={loadNotifications}>Try again</button>
        </div>
      )}

      {loading ? (
        <div className="notification-state">
          <div className="notification-spinner" />
          <p>Loading notifications from LifeLink server...</p>
        </div>
      ) : filteredNotifications.length === 0 ? (
        <div className="notification-empty">
          <div className="notification-empty-icon">♧</div>
          <h3>
            {filter === "unread"
              ? "You're all caught up!"
              : filter === "read"
              ? "No read notifications"
              : "No notifications yet"}
          </h3>
          <p>
            {filter === "unread"
              ? "There are no unread notifications right now."
              : "New updates from your LifeLink network will appear here."}
          </p>
          <button
            className="notification-refresh-btn"
            onClick={loadNotifications}
          >
            Refresh notifications
          </button>
        </div>
      ) : (
        <div className="notification-list">
          {filteredNotifications.map((notification) => (
            <article
              className={`notification-card ${
                notification.isRead ? "is-read" : "is-unread"
              }`}
              key={notification._id}
            >
              <div
                className={`notification-type-icon type-${notification.type || "general"}`}
              >
                {getTypeIcon(notification.type)}
              </div>

              <div className="notification-content">
                <div className="notification-card-top">
                  <span
                    className={`notification-type-label type-label-${notification.type || "general"}`}
                  >
                    {getTypeLabel(notification.type)}
                  </span>

                  {!notification.isRead && (
                    <span className="unread-indicator">
                      <span />
                      Unread
                    </span>
                  )}
                </div>

                <h3>{notification.title || "LifeLink Update"}</h3>

                <p className="notification-message">
                  {notification.message || "You have a new update."}
                </p>

                <p className="notification-date">
                  <span>◷</span> {formatDate(notification.createdAt)}
                </p>

                <div className="notification-actions">
                  {!notification.isRead && (
                    <button
                      className="notification-read-btn"
                      disabled={workingId === notification._id}
                      onClick={() => markAsRead(notification)}
                    >
                      Mark as read
                    </button>
                  )}

                  <button
                    className="notification-delete-btn"
                    disabled={workingId === notification._id}
                    onClick={() =>
                      deleteNotification(notification._id)
                    }
                  >
                    Delete
                  </button>
                </div>
              </div>
            </article>
          ))}
        </div>
      )}
    </section>
  );
}

export default Notifications;
