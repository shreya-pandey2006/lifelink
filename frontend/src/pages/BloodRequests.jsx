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

  function getStatus(request) {
    return String(request.status || "unknown").toLowerCase();
  }

  const openCount = requests.filter((request) =>
    ["open", "pending"].includes(getStatus(request))
  ).length;

  const urgentCount = requests.filter(
    (request) =>
      String(request.urgency || "").toLowerCase() === "urgent"
  ).length;

  const fulfilledCount = requests.filter((request) =>
    ["fulfilled", "completed"].includes(getStatus(request))
  ).length;

  const filteredRequests = requests.filter((request) => {
    const bloodGroup = String(
      request.bloodGroup || request.bloodType || ""
    ).toLowerCase();

    const status = getStatus(request);

    const urgency = String(
      request.urgency || "unknown"
    ).toLowerCase();

    const requestId = String(
      request.requestId || request._id || request.id || ""
    ).toLowerCase();

    const city = String(request.city || "").toLowerCase();

    const searchText = search.toLowerCase();

    const matchesSearch =
      requestId.includes(searchText) ||
      city.includes(searchText) ||
      bloodGroup.includes(searchText);

    const matchesStatus =
      statusFilter === "all" || status === statusFilter;

    const matchesUrgency =
      urgencyFilter === "all" || urgency === urgencyFilter;

    const matchesBlood =
      bloodFilter === "all" || bloodGroup === bloodFilter;

    return (
      matchesSearch &&
      matchesStatus &&
      matchesUrgency &&
      matchesBlood
    );
  });

  const bloodGroups = [
    ...new Set(
      requests
        .map((request) =>
          String(request.bloodGroup || request.bloodType || "")
        )
        .filter(Boolean)
    ),
  ];

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
          type="text"
          placeholder="Search request ID, city or blood group..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />

        <select
          value={statusFilter}
          onChange={(event) => setStatusFilter(event.target.value)}
        >
          <option value="all">All Statuses</option>
          <option value="open">Open</option>
          <option value="pending">Pending</option>
          <option value="matched">Matched</option>
          <option value="in_transit">In Transit</option>
          <option value="fulfilled">Fulfilled</option>
          <option value="completed">Completed</option>
          <option value="cancelled">Cancelled</option>
        </select>

        <select
          value={urgencyFilter}
          onChange={(event) => setUrgencyFilter(event.target.value)}
        >
          <option value="all">All Urgencies</option>
          <option value="urgent">Urgent</option>
          <option value="high">High</option>
          <option value="normal">Normal</option>
          <option value="low">Low</option>
        </select>

        <select
          value={bloodFilter}
          onChange={(event) => setBloodFilter(event.target.value)}
        >
          <option value="all">All Blood Groups</option>

          {bloodGroups.map((group) => (
            <option key={group} value={group.toLowerCase()}>
              {group}
            </option>
          ))}
        </select>
      </div>

      <div className="blood-table-card">
        {loading ? (
          <p className="blood-message">Loading requests from API...</p>
        ) : error ? (
          <p className="blood-error">{error}</p>
        ) : filteredRequests.length === 0 ? (
          <p className="blood-message">
            No requests match your search or filters.
          </p>
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

                      <td>{request.city || "—"}</td>

                      <td>
                        <span className="blood-urgency">
                          {request.urgency || "Unknown"}
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

