import { useEffect, useState } from "react";
import "./Dashboard.css";
import BloodRequests from "./BloodRequests";

const API_URL = "https://lifelink-backend-8onj.onrender.com";

function Dashboard({ onLogout }) {
  const [activePage, setActivePage] = useState("dashboard");
  const [requests, setRequests] = useState([]);
  const [donorCount, setDonorCount] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [theme, setTheme] = useState(
    localStorage.getItem("lifelink-theme") || "light"
  );

  const [showNotifications, setShowNotifications] = useState(false);
  const [navbarSearch, setNavbarSearch] = useState("");

  const [user] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem("user")) || {};
    } catch {
      return {};
    }
  });

  function toggleTheme() {
    const newTheme = theme === "light" ? "dark" : "light";
    setTheme(newTheme);
    localStorage.setItem("lifelink-theme", newTheme);
  }

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

      let requestError = "";

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
          requestError = `Requests API returned ${response.status}`;
        }
      } else {
        requestError = "Could not connect to the requests API.";
      }

      if (donorResult.status === "fulfilled") {
        const response = donorResult.value;

        if (response.ok) {
          const data = await response.json();

          const count =
            data.availableDonorCount ??
            data.count ??
            data.availableDonors ??
            data.total ??
            data.data?.count;

          setDonorCount(
            typeof count === "number" ? count : null
          );
        } else {
          setDonorCount(null);
        }
      } else {
        setDonorCount(null);
      }

      if (requestError) {
        setError(requestError);
      }
    } catch (err) {
      setError(err.message || "Unable to load dashboard data.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchDashboardData();

    const intervalId = setInterval(() => {
      fetchDashboardData();
    }, 15000);

    return () => clearInterval(intervalId);
  }, []);

  function getStatus(request) {
    return String(request.status || "unknown").toLowerCase();
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
        new Date(b.createdAt || 0) -
        new Date(a.createdAt || 0)
    )
    .slice(0, 5);

  function formatRequestTime(dateValue) {
    if (!dateValue) return "Time unavailable";

    const date = new Date(dateValue);

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

  const userName =
    user.name ||
    user.fullName ||
    user.username ||
    user.email ||
    "User";

  const userRole = user.role || "LifeLink User";

  const avatarLetter = String(userName).charAt(0).toUpperCase();

  const filteredRequests = requests.filter((request) => {
    const search = navbarSearch.toLowerCase().trim();

    if (!search) return true;

    return [
      request._id,
      request.id,
      request.patientName,
      request.hospitalName,
      request.hospital,
      request.bloodGroup,
      request.bloodType,
      request.status,
    ].some((value) =>
      String(value || "").toLowerCase().includes(search)
    );
  });

  function display(value) {
    return loading ? "..." : value;
  }

  return (
    <div
      className={`dashboard ${
        theme === "dark" ? "dark-theme" : ""
      }`}
    >
      <aside className="sidebar">
        <h2 className="brand">♥ LifeLink</h2>
        <p className="brand-subtitle">CLINICAL DISPATCH</p>

        <p className="sidebar-label">COMMAND CENTER</p>

        <div
          className={`nav-item ${
            activePage === "dashboard" ? "active" : ""
          }`}
          onClick={() => setActivePage("dashboard")}
        >
          ▦ Overview
        </div>

        <div
          className={`nav-item ${
            activePage === "requests" ? "active" : ""
          }`}
          onClick={() => setActivePage("requests")}
        >
          ♡ Blood Requests
        </div>

        <div className="nav-item" title="Donor page not connected yet">
          ♧ Donors
        </div>

        <div className="nav-item" title="Analytics page not connected yet">
          ▥ Analytics
        </div>

        <div className="nav-item" title="Settings page not connected yet">
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
              type="text"
              placeholder="Search requests, hospitals, blood groups..."
              value={navbarSearch}
              onChange={(event) =>
                setNavbarSearch(event.target.value)
              }
            />
          </div>

          <div className="navbar-actions">
            <button
              className="theme-button"
              onClick={toggleTheme}
              title="Toggle dark mode"
            >
              {theme === "light" ? "🌙" : "☀️"}
            </button>

            <div className="notification-wrapper">
              <button
                className="notification-button"
                onClick={() =>
                  setShowNotifications(!showNotifications)
                }
                aria-label="Toggle notifications"
              >
                ♧
              </button>

              {showNotifications && (
                <div className="notification-dropdown">
                  <h3>Notifications</h3>
                  <p>
                    {loading
                      ? "Loading request information..."
                      : error
                      ? "Dashboard data could not be loaded."
                      : `${openRequests.length} open or pending requests currently found.`}
                  </p>
                  <button
                    onClick={() => {
                      setActivePage("requests");
                      setShowNotifications(false);
                    }}
                  >
                    View Blood Requests
                  </button>
                </div>
              )}
            </div>

            <div className="profile-info">
              <div className="profile-avatar">{avatarLetter}</div>
              <div className="profile-text">
                <strong>{userName}</strong>
                <span>{userRole}</span>
              </div>
            </div>

            <button className="logout-button" onClick={onLogout}>
              Logout
            </button>
          </div>
        </header>

        {activePage === "requests" ? (
          <BloodRequests />
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
                <button onClick={fetchDashboardData}>
                  Try Again
                </button>
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
                    ? "Donor count unavailable for this account"
                    : "Available donor count from API"}
                </p>
              </div>
            </div>

            <div className="request-section">
              <div className="section-heading">
                <div>
                  <h2>Blood Request Queue</h2>
                  <p>
                    {navbarSearch.trim()
                      ? `Search results for "${navbarSearch}"`
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
                    {navbarSearch.trim()
                      ? "Try another search term."
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
                              {request._id || request.id || "—"}
                            </span>
                          </td>

                          <td>
                            {request.bloodGroup ||
                              request.bloodType ||
                              "—"}
                          </td>

                          <td>
                            {request.units ??
                              request.unitsNeeded ??
                              "—"}
                          </td>

                          <td>
                            {request.urgency || request.priority || "—"}
                          </td>

                          <td>
                            <span className={`status-pill ${getStatus(request).replace(/\s+/g, "-")}`}>
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
                      request.urgency || "normal"
                    ).toLowerCase();

                    const status = getStatus(request);

                    return (
                      <div
                        className="dispatch-feed-item"
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
                            {request.bloodGroup || "Blood group unavailable"}
                            {" · "}
                            {request.city || "City unavailable"}
                            {" · "}
                            {request.units ?? "—"} units
                          </p>

                          <div className="dispatch-feed-meta">
                            <span className={`status-pill ${status}`}>
                              {status}
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
