import { useEffect, useState } from "react";
import "./BloodRequests.css";

const API_URL = "https://lifelink-backend-8onj.onrender.com";

function BloodRequests() {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [urgencyFilter, setUrgencyFilter] = useState("all");
  const [bloodFilter, setBloodFilter] = useState("all");

  async function fetchRequests() {
    setLoading(true);
    setError("");

    const token = localStorage.getItem("token");

    if (!token) {
      setError("Please log in first.");
      setLoading(false);
      return;
    }

    try {
      const response = await fetch(`${API_URL}/api/requests`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }

      const data = await response.json();

      const requestList = Array.isArray(data.bloodRequests)
        ? data.bloodRequests
        : Array.isArray(data.requests)
        ? data.requests
        : Array.isArray(data.data)
        ? data.data
        : Array.isArray(data)
        ? data
        : [];

      setRequests(requestList);
    } catch (err) {
      setError(err.message || "Unable to load blood requests.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchRequests();
  }, []);

  function normalize(value) {
    return String(value ?? "").trim().toLowerCase().replace(/[\s-]+/g, "_");
  }

  function getStatus(request) {
    return normalize(request.status || "unknown");
  }

  function getUrgency(request) {
    return normalize(request.urgency || request.priority || "unknown");
  }

  function getBloodGroup(request) {
    return String(request.bloodGroup || request.bloodType || "").trim();
  }

  const openCount = requests.filter((request) =>
    ["open", "pending"].includes(getStatus(request))
  ).length;

  const urgentCount = requests.filter((request) =>
    ["urgent", "emergency", "critical"].includes(getUrgency(request))
  ).length;

  const fulfilledCount = requests.filter((request) =>
    ["fulfilled", "completed"].includes(getStatus(request))
  ).length;

  const bloodGroups = [
    ...new Set(
      requests.map(getBloodGroup).filter(Boolean)
    ),
  ].sort((a, b) => a.localeCompare(b));

  const filteredRequests = requests.filter((request) => {
    const query = search.trim().toLowerCase();

    const searchableValues = [
      request.requestId,
      request._id,
      request.id,
      request.city,
      request.bloodGroup,
      request.bloodType,
      request.hospitalName,
      request.hospital,
      request.patientName,
      request.status,
      request.urgency,
      request.priority,
    ];

    const matchesSearch =
      !query ||
      searchableValues.some((value) =>
        String(value ?? "").toLowerCase().includes(query)
      );

    const status = getStatus(request);
    const urgency = getUrgency(request);
    const bloodGroup = normalize(getBloodGroup(request));

    const matchesStatus =
      statusFilter === "all" ||
      (statusFilter === "fulfilled"
        ? ["fulfilled", "completed"].includes(status)
        : status === statusFilter);

    const matchesUrgency =
      urgencyFilter === "all" ||
      (urgencyFilter === "urgent"
        ? ["urgent", "emergency", "critical"].includes(urgency)
        : urgency === urgencyFilter);

    const matchesBlood =
      bloodFilter === "all" ||
      bloodGroup === normalize(bloodFilter);

    return (
      matchesSearch &&
      matchesStatus &&
      matchesUrgency &&
      matchesBlood
    );
  });

  function resetFilters() {
    setSearch("");
    setStatusFilter("all");
    setUrgencyFilter("all");
    setBloodFilter("all");
  }

  return (
    <div className="blood-requests-page">
      <div className="blood-requests-heading">
        <div>
          <p className="blood-requests-label">LIFELINK MONITORING</p>
          <h1>Blood Requirement Requests</h1>
          <p>Monitor blood requests received from the backend.</p>
        </div>

        <button
          className="blood-refresh-button"
          onClick={fetchRequests}
          disabled={loading}
        >
          {loading ? "Loading..." : "Refresh"}
        </button>
      </div>

      <div className="blood-summary-grid">
        <div className="blood-summary-card">
          <p>Total Requests</p>
          <h2>{loading ? "..." : requests.length}</h2>
        </div>

        <div className="blood-summary-card">
          <p>Open Requests</p>
          <h2>{loading ? "..." : openCount}</h2>
        </div>

        <div className="blood-summary-card">
          <p>Urgent Requests</p>
          <h2>{loading ? "..." : urgentCount}</h2>
        </div>

        <div className="blood-summary-card">
          <p>Fulfilled Requests</p>
          <h2>{loading ? "..." : fulfilledCount}</h2>
        </div>
      </div>

      <div className="blood-filters">
        <input
          type="search"
          aria-label="Search blood requests"
          placeholder="Search request ID, city or blood group..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />

        <select
          aria-label="Filter by status"
          value={statusFilter}
          onChange={(event) => setStatusFilter(event.target.value)}
        >
          <option value="all">All Statuses</option>
          <option value="open">Open</option>
          <option value="pending">Pending</option>
          <option value="matched">Matched</option>
          <option value="in_transit">In Transit</option>
          <option value="fulfilled">Fulfilled</option>
          <option value="cancelled">Cancelled</option>
        </select>

        <select
          aria-label="Filter by urgency"
          value={urgencyFilter}
          onChange={(event) => setUrgencyFilter(event.target.value)}
        >
          <option value="all">All Urgencies</option>
          <option value="emergency">Emergency</option>
          <option value="critical">Critical</option>
          <option value="urgent">Urgent</option>
          <option value="high">High</option>
          <option value="normal">Normal</option>
          <option value="low">Low</option>
        </select>

        <select
          aria-label="Filter by blood group"
          value={bloodFilter}
          onChange={(event) => setBloodFilter(event.target.value)}
        >
          <option value="all">All Blood Groups</option>
          {bloodGroups.map((group) => (
            <option key={group} value={group}>
              {group}
            </option>
          ))}
        </select>
      </div>

      <div className="blood-table-card">
        {loading ? (
          <p className="blood-message">Loading requests from API...</p>
        ) : error ? (
          <div className="blood-message">
            <p className="blood-error">{error}</p>
            <button
              className="blood-refresh-button"
              onClick={fetchRequests}
            >
              Try Again
            </button>
          </div>
        ) : filteredRequests.length === 0 ? (
          <div className="blood-message">
            <p>No requests match your search or filters.</p>
            <button
              className="blood-refresh-button"
              onClick={resetFilters}
            >
              Clear Filters
            </button>
          </div>
        ) : (
          <>
            <p className="blood-results-count">
              Showing {filteredRequests.length} of {requests.length} requests
            </p>

            <div className="blood-table-wrapper">
              <table className="blood-requests-table">
                <thead>
                  <tr>
                    <th>Request ID</th>
                    <th>Blood Group</th>
                    <th>Units</th>
                    <th>City</th>
                    <th>Urgency</th>
                    <th>Status</th>
                  </tr>
                </thead>

                <tbody>
                  {filteredRequests.map((request, index) => (
                    <tr key={request._id || request.id || index}>
                      <td>
                        {request.requestId ||
                          request._id ||
                          request.id ||
                          "—"}
                      </td>

                      <td>{getBloodGroup(request) || "—"}</td>

                      <td>
                        {request.units ??
                          request.unitsNeeded ??
                          "—"}
                      </td>

                      <td>{request.city || "—"}</td>

                      <td>
                        <span className="blood-urgency">
                          {request.urgency ||
                            request.priority ||
                            "Unknown"}
                        </span>
                      </td>

                      <td>
                        <span className="blood-status">
                          {request.status || "Unknown"}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default BloodRequests;
