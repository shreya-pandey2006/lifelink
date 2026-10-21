import { useEffect, useMemo, useState } from "react";
import "./Donors.css";

const API_URL = "https://lifelink-backend-8onj.onrender.com";

const BLOOD_GROUPS = ["O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+"];

const demoDonors = [
  { id: "DEMO-9041", bloodGroup: "O-", area: "Downtown Central", distance: "2.1 km", status: "Available on-call" },
  { id: "DEMO-7814", bloodGroup: "AB-", area: "Medical District", distance: "0.8 km", status: "Available on-call" },
  { id: "DEMO-6320", bloodGroup: "B-", area: "North Metro", distance: "8.4 km", status: "Available on-call" },
  { id: "DEMO-4899", bloodGroup: "O-", area: "East Suburbs", distance: "11.2 km", status: "In Cooldown" },
  { id: "DEMO-5103", bloodGroup: "O+", area: "Downtown Medical District", distance: "1.4 km", status: "Available on-call" },
  { id: "DEMO-3390", bloodGroup: "A-", area: "South County Hub", distance: "5.9 km", status: "Available on-call" },
  { id: "DEMO-1092", bloodGroup: "A+", area: "Downtown Core", distance: "3.0 km", status: "Available on-call" },
  { id: "DEMO-2201", bloodGroup: "B+", area: "East Suburbs", distance: "Outside zone", status: "Snoozed" },
];

function Donors() {
  const [availableCount, setAvailableCount] = useState(null);
  const [countLoading, setCountLoading] = useState(true);
  const [apiError, setApiError] = useState("");

  const [rareBloodData, setRareBloodData] = useState(null);
  const [reliabilityData, setReliabilityData] = useState(null);
  const [analyticsLoading, setAnalyticsLoading] = useState(true);
  const [rareBloodError, setRareBloodError] = useState("");
  const [reliabilityError, setReliabilityError] = useState("");

  const [search, setSearch] = useState("");
  const [selectedBlood, setSelectedBlood] = useState([]);
  const [availability, setAvailability] = useState("all");
  const [area, setArea] = useState("all");

  async function fetchDonorCount() {
    setCountLoading(true);
    setApiError("");

    const token = localStorage.getItem("token");

    if (!token) {
      setApiError("Please log in again to load donor data.");
      setAvailableCount(null);
      setCountLoading(false);
      return;
    }

    try {
      const response = await fetch(
        `${API_URL}/api/donors/available/count`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        throw new Error(data.message || `API returned ${response.status}`);
      }

      const count =
        data.availableDonorCount ??
        data.count ??
        data.availableDonors ??
        data.total;

      setAvailableCount(
        typeof count === "number" ? count : null
      );

      if (typeof count !== "number") {
        setApiError("The API response did not include a donor count.");
      }
    } catch (error) {
      setAvailableCount(null);
      setApiError(error.message || "Unable to load donor count.");
    } finally {
      setCountLoading(false);
    }
  }

  async function fetchDonorAnalytics() {
    setAnalyticsLoading(true);
    setRareBloodError("");
    setReliabilityError("");

    const token = localStorage.getItem("token");

    if (!token) {
      setRareBloodData(null);
      setReliabilityData(null);
      setRareBloodError("Please log in again to load analytics.");
      setReliabilityError("Please log in again to load analytics.");
      setAnalyticsLoading(false);
      return;
    }

    const headers = {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    };

    const endpoints = [
      {
        type: "rare",
        url: `${API_URL}/api/admin/analytics/rare-blood-groups`,
      },
      {
        type: "reliability",
        url: `${API_URL}/api/admin/analytics/response-reliability`,
      },
    ];

    const results = await Promise.allSettled(
      endpoints.map(async (endpoint) => {
        const response = await fetch(endpoint.url, { headers });
        const data = await response.json().catch(() => ({}));

        if (!response.ok) {
          throw new Error(
            data.message || `HTTP ${response.status}`
          );
        }

        if (data.success === false) {
          throw new Error(data.message || "API request failed");
        }

        return {
          type: endpoint.type,
          data: data.data ?? data,
        };
      })
    );

    results.forEach((result, index) => {
      const type = endpoints[index].type;

      if (result.status === "rejected") {
        const message =
          result.reason?.message || "Unable to load data.";

        if (type === "rare") {
          setRareBloodData(null);
          setRareBloodError(message);
        } else {
          setReliabilityData(null);
          setReliabilityError(message);
        }

        return;
      }

      if (type === "rare") {
        setRareBloodData(result.value.data);
        setRareBloodError("");
      } else {
        setReliabilityData(result.value.data);
        setReliabilityError("");
      }
    });

    setAnalyticsLoading(false);
  }

  async function refreshAllData() {
    await Promise.all([
      fetchDonorCount(),
      fetchDonorAnalytics(),
    ]);
  }

  useEffect(() => {
    refreshAllData();
  }, []);

  const filteredDonors = useMemo(() => {
    return demoDonors.filter((donor) => {
      const matchesSearch = [
        donor.id,
        donor.bloodGroup,
        donor.area,
        donor.status,
      ].some((value) =>
        value.toLowerCase().includes(search.trim().toLowerCase())
      );

      const matchesBlood =
        selectedBlood.length === 0 ||
        selectedBlood.includes(donor.bloodGroup);

      const matchesAvailability =
        availability === "all" ||
        (availability === "available" &&
          donor.status === "Available on-call") ||
        (availability === "cooldown" &&
          donor.status === "In Cooldown") ||
        (availability === "snoozed" &&
          donor.status === "Snoozed");

      const matchesArea = area === "all" || donor.area === area;

      return (
        matchesSearch &&
        matchesBlood &&
        matchesAvailability &&
        matchesArea
      );
    });
  }, [search, selectedBlood, availability, area]);

  function toggleBlood(group) {
    setSelectedBlood((current) =>
      current.includes(group)
        ? current.filter((item) => item !== group)
        : [...current, group]
    );
  }

  function clearFilters() {
    setSearch("");
    setSelectedBlood([]);
    setAvailability("all");
    setArea("all");
  }

  const activeDemoCount = demoDonors.filter(
    (donor) => donor.status === "Available on-call"
  ).length;

  const rareGroups = Array.isArray(rareBloodData?.rareGroups)
    ? rareBloodData.rareGroups
    : [];

  const rareGroupCount =
    rareBloodData?.rareGroupCount ?? rareGroups.length;

  const acceptanceRate = reliabilityData?.acceptanceRatePercentage;

  function getRareGroupName(group) {
    if (typeof group === "string") return group;

    return (
      group?.bloodGroup ??
      group?.group ??
      group?.name ??
      "Unknown"
    );
  }

  return (
    <section className="donor-directory">
      <div className="donor-registry-line">
        <span className="registry-dot" />
        REGIONAL REGISTRY NODE: DEMO
        <span className="registry-separator">•</span>
        DIRECTORY PREVIEW
      </div>

      <div className="donor-page-heading">
        <div>
          <h1>Donor Network Directory</h1>
          <p>
            Donor registry overview, blood group filters and availability
            monitoring.
          </p>
        </div>

        <button
          className="donor-outline-button"
          onClick={refreshAllData}
          disabled={countLoading || analyticsLoading}
        >
          {countLoading || analyticsLoading
            ? "Refreshing..."
            : "↻ Refresh Data"}
        </button>
      </div>

      {apiError && (
        <div className="donor-api-error">
          <strong>Donor API information</strong>
          <span>{apiError}</span>
        </div>
      )}

      <div className="donor-stats-grid">
        <article className="donor-stat-card">
          <span className="donor-stat-label">AVAILABLE DONORS</span>
          <h2>{countLoading ? "..." : availableCount ?? "N/A"}</h2>
          <p>Live count from backend API</p>
          <span className="donor-stat-icon red-icon">♥</span>
        </article>

        <article className="donor-stat-card green-accent">
          <span className="donor-stat-label">DEMO AVAILABLE RECORDS</span>
          <h2>{activeDemoCount}</h2>
          <p>Sample rows, not live donor records</p>
          <span className="donor-stat-icon green-icon">●</span>
        </article>

        <article className="donor-stat-card amber-accent">
          <span className="donor-stat-label">RARE BLOOD GROUPS</span>

          <h2>
            {analyticsLoading
              ? "..."
              : rareBloodData
              ? rareGroupCount
              : "N/A"}
          </h2>

          <p>
            {analyticsLoading
              ? "Loading from backend..."
              : rareBloodData
              ? rareGroups.length > 0
                ? rareGroups.map(getRareGroupName).join(", ")
                : "Rare group details unavailable"
              : "Data unavailable"}
          </p>

          {rareBloodError && (
            <small className="donor-analytics-error">
              {rareBloodError}
            </small>
          )}

          <span className="donor-stat-icon amber-icon">✚</span>
        </article>

        <article className="donor-stat-card blue-accent">
          <span className="donor-stat-label">RESPONSE RELIABILITY</span>

          <h2>
            {analyticsLoading
              ? "..."
              : acceptanceRate != null
              ? `${acceptanceRate}%`
              : "N/A"}
          </h2>

          <p>
            {analyticsLoading
              ? "Loading from backend..."
              : reliabilityData
              ? `Accepted: ${
                  reliabilityData.acceptedResponses ?? 0
                } · Declined: ${
                  reliabilityData.declinedResponses ?? 0
                } · Total: ${
                  reliabilityData.totalResponses ?? 0
                }`
              : "Data unavailable"}
          </p>

          {reliabilityError && (
            <small className="donor-analytics-error">
              {reliabilityError}
            </small>
          )}

          <span className="donor-stat-icon blue-icon">◉</span>
        </article>
      </div>

      <div className="donor-filters-card">
        <div className="donor-filter-row">
          <label className="donor-search">
            <span>⌕</span>
            <input
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search donor ID, area or blood group..."
            />
          </label>

          <select
            value={area}
            onChange={(event) => setArea(event.target.value)}
          >
            <option value="all">All demo areas</option>
            {[...new Set(demoDonors.map((donor) => donor.area))].map(
              (item) => (
                <option key={item} value={item}>
                  {item}
                </option>
              )
            )}
          </select>

          <select
            value={availability}
            onChange={(event) => setAvailability(event.target.value)}
          >
            <option value="all">All availability</option>
            <option value="available">Available on-call</option>
            <option value="cooldown">In cooldown</option>
            <option value="snoozed">Snoozed</option>
          </select>

          <button className="donor-clear-button" onClick={clearFilters}>
            ↻ Clear Filters
          </button>
        </div>

        <div className="donor-blood-filters">
          <strong>BLOOD TYPE:</strong>
          {BLOOD_GROUPS.map((group) => (
            <button
              key={group}
              className={`blood-filter ${
                selectedBlood.includes(group) ? "selected" : ""
              }`}
              onClick={() => toggleBlood(group)}
              aria-pressed={selectedBlood.includes(group)}
            >
              {group}
            </button>
          ))}
        </div>

        <div className="donor-legend">
          <span className="legend-available">
            <i /> Available sample
          </span>
          <span className="legend-cooldown">
            <i /> Cooldown sample
          </span>
          <span className="legend-snoozed">
            <i /> Snoozed sample
          </span>
        </div>
      </div>

      <div className="donor-middle-grid">
        <article className="donor-map-card">
          <div className="donor-panel-heading">
            <h3>◎ Regional Standby Geo-Distribution</h3>
            <span className="demo-label">DEMO MAP</span>
          </div>

          <div className="donor-map-visual">
            <div className="map-road road-one" />
            <div className="map-road road-two" />
            <div className="map-road road-three" />
            <div className="map-water" />

            <span className="map-area area-one">NORTH ZONE</span>
            <span className="map-area area-two">CENTRAL ZONE</span>
            <span className="map-area area-three">EAST ZONE</span>
            <span className="map-area area-four">SOUTH ZONE</span>

            <span className="map-marker marker-one">●</span>
            <span className="map-marker marker-two">●</span>
            <span className="map-marker marker-three">●</span>
            <span className="map-marker marker-four">●</span>
            <span className="map-marker marker-five">●</span>

            <div className="map-bottom-note">
              <span>●</span> Illustrative locations only — no live coordinates
            </div>
          </div>
        </article>

        <article className="donor-dispatch-card">
          <div className="donor-panel-heading">
            <h3>TRIAGE READINESS</h3>
            <span className="readiness-pill">Preview</span>
          </div>

          <h2>Emergency Dispatch</h2>
          <p>
            Live donor matching and dispatch actions require connected
            backend endpoints.
          </p>

          <div className="dispatch-info-row">
            <span>Available donor count</span>
            <strong>
              {countLoading ? "..." : availableCount ?? "Unavailable"}
            </strong>
          </div>

          <div className="dispatch-progress">
            <span />
          </div>

          <p className="dispatch-note">
            No live acceptance latency or SLA data is available.
          </p>

          <button
            className="dispatch-refresh-button"
            onClick={fetchDonorCount}
            disabled={countLoading}
          >
            ↻ Refresh Donor Availability
          </button>
        </article>
      </div>

      <article className="donor-table-card">
        <div className="donor-table-heading">
          <div>
            <h3>
              Active Matching Pool <span>{filteredDonors.length} demo rows</span>
            </h3>
            <p>Illustrative records only — not retrieved from the donor API.</p>
          </div>
          <span className="privacy-label">♙ No real donor PII displayed</span>
        </div>

        <div className="donor-table-scroll">
          <table className="donor-table">
            <thead>
              <tr>
                <th>DONOR ID</th>
                <th>BLOOD GROUP</th>
                <th>PRIMARY AREA / LOCATION</th>
                <th>AVAILABILITY STATUS</th>
                <th>RECORD TYPE</th>
              </tr>
            </thead>

            <tbody>
              {filteredDonors.map((donor) => (
                <tr key={donor.id}>
                  <td>
                    <strong>#{donor.id}</strong>
                    <span className="demo-shield">DEMO</span>
                  </td>
                  <td>
                    <span
                      className={`donor-blood-badge ${
                        donor.bloodGroup
                          .replace("+", "plus")
                          .replace("-", "minus")
                      }`}
                    >
                      {donor.bloodGroup}
                    </span>
                  </td>
                  <td>
                    <strong>{donor.area}</strong>
                    <small>{donor.distance} · Illustrative location</small>
                  </td>
                  <td>
                    <span
                      className={`donor-availability ${
                        donor.status === "Available on-call"
                          ? "is-available"
                          : donor.status === "In Cooldown"
                          ? "is-cooldown"
                          : "is-snoozed"
                      }`}
                    >
                      <i />
                      {donor.status}
                    </span>
                  </td>
                  <td>
                    <span className="demo-record-tag">Sample data</span>
                  </td>
                </tr>
              ))}

              {filteredDonors.length === 0 && (
                <tr>
                  <td colSpan="5" className="donor-empty">
                    No demo records match your filters.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="donor-table-footer">
          <span>Showing {filteredDonors.length} illustrative records</span>
          <span>Live directory listing API not currently connected</span>
        </div>
      </article>

      <div className="donor-compliance-footer">
        <div className="compliance-shield">✚</div>
        <div>
          <strong>Privacy & Clinical Data Safeguard</strong>
          <p>
            This screen uses a live availability count and clearly labelled
            demo directory rows. Real donor identities and locations are not
            displayed.
          </p>
        </div>
      </div>
    </section>
  );
}

export default Donors;
