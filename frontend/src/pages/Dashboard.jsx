import { useEffect, useState } from "react";
import "./Dashboard.css";
import BloodRequests from "./BloodRequests";
import Donors from "./Donors";
import Analytics from "./Analytics";
import Notifications from "./Notifications";
import Settings from "./Settings";

const API_URL = "https://lifelink-backend-8onj.onrender.com";

function Dashboard({ onLogout }) {
  const [activePage, setActivePage] = useState("dashboard");
  const [requests, setRequests] = useState([]);
  const [donorCount, setDonorCount] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [unreadNotificationCount, setUnreadNotificationCount] = useState(0);
  const [navbarSearch, setNavbarSearch] = useState("");

  const [user] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem("user")) || {};
    } catch {
      return {};
    }
  });

  async function fetchDashboardData() {
    setLoading(true);
    setError("");

    const token = localStorage.getItem("token");

    if (!token) {
      setError("Please log in again to view dashboard data.");
      setLoading(false);
      return;
    }

    const headers = {
      Authorization: `Bearer ${token}`,
    };

    try {
      const [requestResult, donorResult] = await Promise.allSettled([
        fetch(`${API_URL}/api/requests`, { headers }),
        fetch(`${API_URL}/api/donors/available/count`, { headers }),
      ]);

      if (requestResult.status === "fulfilled") {
        const response = requestResult.value;

        if (response.ok) {
          const data = await response.json();

          const list = Array.isArray(data.bloodRequests)
            ? data.bloodRequests
            : Array.isArray(data.requests)
            ? data.requests
            : Array.isArray(data.data)
            ? data.data
            : Array.isArray(data)
            ? data
            : [];

          setRequests(list);
        } else {
          setError(`Requests API returned ${response.status}`);
        }
      } else {
        setError("Could not connect to the requests API.");
      }

      if (donorResult.status === "fulfilled" && donorResult.value.ok) {
        const data = await donorResult.value.json();

        const count =
          data.availableDonorCount ??
          data.count ??
          data.availableDonors ??
          data.total ??
          data.data?.count;

        setDonorCount(typeof count === "number" ? count : null);
      } else {
        setDonorCount(null);
      }
    } catch (err) {
      setError(err.message || "Unable to load dashboard data.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchDashboardData();

    const intervalId = setInterval(fetchDashboardData, 15000);

    return () => clearInterval(intervalId);
  }, []);

  useEffect(() => {
    let isMounted = true;

    async function fetchUnreadNotificationCount() {
      const token = localStorage.getItem("token");

      if (!token) return;

      try {
        const response = await fetch(
          `${API_URL}/api/notifications/unread-count`,
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );

        if (!response.ok) return;

        const data = await response.json();

        if (isMounted) {
          setUnreadNotificationCount(Number(data.unreadCount || 0));
        }
      } catch (err) {
        console.error("Unable to fetch notifications:", err);
      }
    }

    fetchUnreadNotificationCount();

    const intervalId = setInterval(fetchUnreadNotificationCount, 30000);

    return () => {
      isMounted = false;
      clearInterval(intervalId);
    };
  }, []);

  function getStatus(request) {
    return String(request.status || "unknown")
      .trim()
      .toLowerCase()
      .replace(/[\s-]+/g, "_");
  }

  const openRequests = requests.filter((request) =>
    ["open", "pending"].includes(getStatus(request))
  );

  const matchedRequests = requests.filter((request) =>
    ["matched", "in_transit"].includes(getStatus(request))
  );

  const fulfilledRequests = requests.filter((request) =>
    ["fulfilled", "completed"].includes(getStatus(request))
  );

  const recentRequests = [...requests]
    .sort(
      (a, b) =>
        new Date(b.createdAt || 0) - new Date(a.createdAt || 0)
    )
    .slice(0, 5);

  const userName =
    user.name ||
    user.fullName ||
    user.username ||
    user.email ||
    "User";

  const userRole = user.role || "LifeLink User";
  const avatarLetter = String(userName).charAt(0).toUpperCase();

  const searchQuery = navbarSearch.trim().toLowerCase();

  const filteredRequests = requests.filter((request) => {
    if (!searchQuery) return true;

    const values = [
      request._id,
      request.id,
      request.requestId,
      request.patientName,
      request.hospitalName,
      request.hospital,
      request.city,
      request.bloodGroup,
      request.bloodType,
      request.status,
      request.urgency,
      request.priority,
      request.units,
      request.unitsNeeded,
    ];

    return values.some((value) =>
      String(value ?? "").toLowerCase().includes(searchQuery)
    );
  });

  function formatRequestTime(value) {
    if (!value) return "Time unavailable";

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
      return "Time unavailable";
    }

    return date.toLocaleString("en-IN", {
      day: "2-digit",
      month: "short",
      hour: "2-digit",
      minute: "2-digit",
    });
  }

  function display(value) {
    return loading ? "..." : value;
  }

  function handleLogout() {
    if (onLogout) {
      onLogout();
    }
  }

  return (
    <div className="dashboard">
      <aside className="sidebar">
        <div className="dashboard-brand">
          <div className="dashboard-brand-icon">
            <svg
              viewBox="0 0 24 24"
              fill="currentColor"
              role="img"
              aria-label="LifeLink blood drop logo"
            >
              <path d="M12 2.5C10.2 5.7 5.5 10.1 5.5 14.5a6.5 6.5 0 0 0 13 0C18.5 10.1 13.8 5.7 12 2.5Z" />
              <path
                d="M8.5 14.5a3.5 3.5 0 0 0 3.5 3.5"
                fill="none"
                stroke="#FFFFFF"
                strokeWidth="1.5"
                strokeLinecap="round"
              />
            </svg>
          </div>

          <div className="dashboard-brand-text">
            <h2>LifeLink</h2>
            <p>CLINICAL DISPATCH</p>
          </div>
        </div>

        <p className="sidebar-label">COMMAND CENTER</p>

        <div
          className={`nav-item ${activePage === "dashboard" ? "active" : ""}`}
          onClick={() => setActivePage("dashboard")}
        >
          ▦ Overview
        </div>

        <div
          className={`nav-item ${activePage === "requests" ? "active" : ""}`}
          onClick={() => setActivePage("requests")}
        >
          ♡ Blood Requests
        </div>

        <div
          className={`nav-item ${activePage === "donors" ? "active" : ""}`}
          onClick={() => setActivePage("donors")}
        >
          ♧ Donors
        </div>

        <div
          className={`nav-item ${activePage === "analytics" ? "active" : ""}`}
          onClick={() => setActivePage("analytics")}
        >
          ▥ Analytics
        </div>

        <div
          className={`nav-item ${
            activePage === "notifications" ? "active" : ""
          }`}
          onClick={() => setActivePage("notifications")}
        >
          🔔 Notifications
          {unreadNotificationCount > 0 && (
            <span className="notification-badge">
              {unreadNotificationCount > 99
                ? "99+"
                : unreadNotificationCount}
            </span>
          )}
        </div>

        <div
          className={`nav-item ${activePage === "settings" ? "active" : ""}`}
          onClick={() => setActivePage("settings")}
        >
          ⚙ Settings
        </div>

        <div className="sidebar-bottom">
          <strong>CODE RED PROTOCOL</strong>
          <p>Emergency blood network</p>
        </div>
      </aside>

      <main className="main-content">
        <header className="topbar">
          <div className="navbar-search">
            <span>⌕</span>
            <input
              type="search"
              placeholder="Search requests, hospitals, blood groups..."
              aria-label="Search requests"
              value={navbarSearch}
              onChange={(event) => setNavbarSearch(event.target.value)}
            />

            {navbarSearch && (
              <button
                type="button"
                onClick={() => setNavbarSearch("")}
                aria-label="Clear search"
              >
                ×
              </button>
            )}
          </div>

          <div className="navbar-actions">
            <div className="notification-wrapper">
              <button
                className="notification-button"
                onClick={() => setActivePage("notifications")}
                aria-label="Open notifications"
                title="Notifications"
              >
                🔔
                {unreadNotificationCount > 0 && (
                  <span className="notification-badge">
                    {unreadNotificationCount > 99
                      ? "99+"
                      : unreadNotificationCount}
                  </span>
                )}
              </button>
            </div>

            <div className="profile-info">
              <div className="profile-avatar">{avatarLetter}</div>
              <div className="profile-text">
                <strong>{userName}</strong>
                <span>{userRole}</span>
              </div>
            </div>

            <button className="logout-button" onClick={handleLogout}>
              Logout
            </button>
          </div>
        </header>

        {activePage === "settings" ? (
          <Settings />
        ) : activePage === "notifications" ? (
          <Notifications
            onUnreadCountChange={setUnreadNotificationCount}
          />
        ) : activePage === "requests" ? (
          <BloodRequests />
        ) : activePage === "donors" ? (
          <Donors />
        ) : activePage === "analytics" ? (
          <Analytics />
        ) : (
          <section className="dashboard-page">
            <div className="welcome-section">
              <div>
                <p className="eyebrow">LIFELINK COMMAND CENTER</p>
                <h1>Dashboard Overview</h1>
                <p className="welcome-description">
                  Monitor blood requests and availability across the network.
                </p>
              </div>

              <button
                className="refresh-button"
                onClick={fetchDashboardData}
                disabled={loading}
              >
                {loading ? "Refreshing..." : "↻ Refresh Data"}
              </button>
            </div>

            {error && (
              <div className="error-message">
                <strong>Unable to load all dashboard data</strong>
                <p>{error}</p>
                <button onClick={fetchDashboardData}>Try Again</button>
              </div>
            )}

            <div className="stats-grid">
              <div className="stat-card">
                <div className="stat-heading">
                  <span>Open Requests</span>
                  <span className="stat-icon red">♡</span>
                </div>
                <h2>{display(openRequests.length)}</h2>
                <p>Requests awaiting fulfillment</p>
              </div>

              <div className="stat-card">
                <div className="stat-heading">
                  <span>Matched / In Transit</span>
                  <span className="stat-icon blue">⇄</span>
                </div>
                <h2>{display(matchedRequests.length)}</h2>
                <p>Requests with a match or in transit</p>
              </div>

              <div className="stat-card">
                <div className="stat-heading">
                  <span>Fulfilled Requests</span>
                  <span className="stat-icon green">✓</span>
                </div>
                <h2>{display(fulfilledRequests.length)}</h2>
                <p>Completed requests</p>
              </div>

              <div className="stat-card">
                <div className="stat-heading">
                  <span>Available Donors</span>
                  <span className="stat-icon purple">♧</span>
                </div>
                <h2>
                  {loading
                    ? "..."
                    : donorCount === null
                    ? "N/A"
                    : donorCount}
                </h2>
                <p>
                  {donorCount === null
                    ? "Donor count unavailable"
                    : "Available donor count from API"}
                </p>
              </div>
            </div>

            <div className="request-section">
              <div className="section-heading">
                <div>
                  <h2>Blood Request Queue</h2>
                  <p>
                    {searchQuery
                      ? `Showing ${filteredRequests.length} matching requests`
                      : "Latest requests received from the API"}
                  </p>
                </div>

                <button
                  className="view-all-button"
                  onClick={() => setActivePage("requests")}
                >
                  View All Requests →
                </button>
              </div>

              {loading ? (
                <div className="empty-state">
                  Loading requests from server...
                </div>
              ) : error ? (
                <div className="empty-state">
                  Requests could not be loaded. Check the error above.
                </div>
              ) : filteredRequests.length === 0 ? (
                <div className="empty-state">
                  <span className="empty-icon">♡</span>
                  <h3>No blood requests found</h3>
                  <p>
                    {searchQuery
                      ? "Try another search term or clear the search."
                      : "The API returned no requests to display."}
                  </p>
                </div>
              ) : (
                <div className="table-wrapper">
                  <table className="requests-table">
                    <thead>
                      <tr>
                        <th>Request / Hospital</th>
                        <th>Blood Group</th>
                        <th>Units</th>
                        <th>Urgency</th>
                        <th>Status</th>
                      </tr>
                    </thead>

                    <tbody>
                      {filteredRequests.slice(0, 8).map((request, index) => (
                        <tr key={request._id || request.id || index}>
                          <td>
                            <strong>
                              {request.hospitalName ||
                                request.hospital ||
                                request.patientName ||
                                request._id ||
                                request.id ||
                                "Request"}
                            </strong>
                            <span className="table-subtitle">
                              {request.requestId ||
                                request._id ||
                                request.id ||
                                "—"}
                            </span>
                          </td>

                          <td>
                            {request.bloodGroup || request.bloodType || "—"}
                          </td>

                          <td>
                            {request.units ?? request.unitsNeeded ?? "—"}
                          </td>

                          <td>
                            {request.urgency || request.priority || "—"}
                          </td>

                          <td>
                            <span
                              className={`status-pill ${getStatus(request)}`}
                            >
                              {request.status || "Unknown"}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            <div className="dispatch-feed-section">
              <div className="section-heading">
                <div>
                  <h2>Live Dispatch Feed</h2>
                  <p>Latest blood request activity from the backend</p>
                </div>

                <span className="live-indicator">
                  <span className="live-dot"></span>
                  API Updates
                </span>
              </div>

              {loading ? (
                <div className="empty-state">
                  Loading recent activity...
                </div>
              ) : recentRequests.length === 0 ? (
                <div className="empty-state">
                  <h3>No recent activity</h3>
                  <p>
                    New blood requests will appear here when returned by the API.
                  </p>
                </div>
              ) : (
                <div className="dispatch-feed-list">
                  {recentRequests.map((request, index) => {
                    const urgency = String(
                      request.urgency || request.priority || "normal"
                    ).toLowerCase();

                    const status = getStatus(request);

                    return (
                      <div
                        className={`dispatch-feed-item ${urgency}`}
                        key={request._id || request.id || index}
                      >
                        <div className={`dispatch-feed-icon ${urgency}`}>
                          {urgency === "emergency"
                            ? "!"
                            : urgency === "urgent"
                            ? "↑"
                            : "•"}
                        </div>

                        <div className="dispatch-feed-details">
                          <strong>
                            {urgency === "emergency"
                              ? "Emergency blood request"
                              : urgency === "urgent"
                              ? "Urgent blood request"
                              : "Blood request received"}
                          </strong>

                          <p>
                            {request.bloodGroup ||
                              request.bloodType ||
                              "Blood group unavailable"}
                            {" · "}
                            {request.city || "City unavailable"}
                            {" · "}
                            {request.units ?? request.unitsNeeded ?? "—"} units
                          </p>

                          <div className="dispatch-feed-meta">
                            <span className={`status-pill ${status}`}>
                              {request.status || status}
                            </span>
                            <span>
                              {formatRequestTime(request.createdAt)}
                            </span>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            <p className="dashboard-footer">
              LifeLink Emergency Blood Network · Data loaded from backend API
            </p>
          </section>
        )}
      </main>
    </div>
  );
}

export default Dashboard;
