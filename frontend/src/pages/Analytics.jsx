import { useEffect, useMemo, useState } from "react";
import "./Analytics.css";

const API_URL = "https://lifelink-backend-8onj.onrender.com";

function Analytics() {
  const [requests, setRequests] = useState([]);
  const [donorCount, setDonorCount] = useState(null);
  const [rareBloodData, setRareBloodData] = useState(null);
  const [reliabilityData, setReliabilityData] = useState(null);

  const [loading, setLoading] = useState(true);
  const [extraLoading, setExtraLoading] = useState(true);
  const [error, setError] = useState("");
  const [extraApiError, setExtraApiError] = useState("");
  const [lastUpdated, setLastUpdated] = useState(null);
  const [range, setRange] = useState("7");

  async function loadAnalytics() {
    const token = localStorage.getItem("token");

    if (!token) {
      setError("Login session nahi mila. Please log in again.");
      setLoading(false);
      setExtraLoading(false);
      return;
    }

    const headers = {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
    };

    setLoading(true);
    setError("");
    setExtraApiError("");
    setExtraLoading(true);

    const mainPromise = (async () => {
      try {
        const [requestsResponse, donorsResponse] = await Promise.all([
          fetch(`${API_URL}/api/requests`, { headers }),
          fetch(`${API_URL}/api/donors/available/count`, { headers }),
        ]);

        if (!requestsResponse.ok) {
          throw new Error(`Requests API error: ${requestsResponse.status}`);
        }

        const responseData = await requestsResponse.json();

        const list = Array.isArray(responseData)
          ? responseData
          : Array.isArray(responseData.bloodRequests)
          ? responseData.bloodRequests
          : Array.isArray(responseData.requests)
          ? responseData.requests
          : Array.isArray(responseData.data)
          ? responseData.data
          : null;

        if (!list) {
          throw new Error("Requests API response format sahi nahi hai.");
        }

        setRequests(list);

        if (donorsResponse.ok) {
          const donorData = await donorsResponse.json();

          const count =
            donorData.availableDonorCount ??
            donorData.count ??
            donorData.availableDonors ??
            donorData.total ??
            donorData.data?.count;

          setDonorCount(
            count !== null &&
              count !== undefined &&
              Number.isFinite(Number(count))
              ? Number(count)
              : null
          );
        } else {
          setDonorCount(null);
        }

        setLastUpdated(new Date());
      } catch (err) {
        setError(err.message || "Analytics data load nahi ho paaya.");
      } finally {
        setLoading(false);
      }
    })();

    const rarePromise = (async () => {
      try {
        const response = await fetch(
          `${API_URL}/api/admin/analytics/rare-blood-groups`,
          { headers }
        );

        if (!response.ok) {
          throw new Error(`Rare Blood Groups API: ${response.status}`);
        }

        const result = await response.json();

        if (result.success === false || !result.data) {
          throw new Error("Rare blood groups ka data nahi mila.");
        }

        setRareBloodData(result.data);
      } catch (err) {
        setRareBloodData(null);
        setExtraApiError((previous) =>
          `${previous}${previous ? " | " : ""}${err.message}`
        );
      }
    })();

    const reliabilityPromise = (async () => {
      try {
        const response = await fetch(
          `${API_URL}/api/admin/analytics/response-reliability`,
          { headers }
        );

        if (!response.ok) {
          throw new Error(`Response Reliability API: ${response.status}`);
        }

        const result = await response.json();

        if (result.success === false || !result.data) {
          throw new Error("Response reliability ka data nahi mila.");
        }

        setReliabilityData(result.data);
      } catch (err) {
        setReliabilityData(null);
        setExtraApiError((previous) =>
          `${previous}${previous ? " | " : ""}${err.message}`
        );
      }
    })();

    await mainPromise;
    await Promise.all([rarePromise, reliabilityPromise]);
    setExtraLoading(false);
  }

  useEffect(() => {
    loadAnalytics();

    const interval = setInterval(loadAnalytics, 30000);

    return () => clearInterval(interval);
  }, []);

  const analytics = useMemo(() => {
    const normalise = (value) =>
      String(value || "").toLowerCase().replace(/[\s-]+/g, "_");

    const isFulfilled = (request) =>
      ["fulfilled", "completed"].includes(normalise(request.status));

    const isPending = (request) =>
      ["open", "pending"].includes(normalise(request.status));

    const fulfilled = requests.filter(isFulfilled);
    const pending = requests.filter(isPending);

    const matched = requests.filter((request) =>
      ["matched", "in_transit"].includes(normalise(request.status))
    );

    const groupCounts = {};

    requests.forEach((request) => {
      const group = String(
        request.bloodGroup || request.bloodType || ""
      ).toUpperCase();

      if (group) {
        groupCounts[group] = (groupCounts[group] || 0) + 1;
      }
    });

    const groups = ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"]
      .map((group) => ({
        group,
        count: groupCounts[group] || 0,
      }))
      .sort((a, b) => b.count - a.count);

    const now = new Date();
    const days = Number(range);

    const daily = Array.from({ length: days }, (_, index) => {
      const date = new Date(now);
      date.setHours(0, 0, 0, 0);
      date.setDate(date.getDate() - (days - 1 - index));

      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);

      const count = requests.filter((request) => {
        const created = new Date(request.createdAt);

        return (
          !Number.isNaN(created.getTime()) &&
          created >= date &&
          created < nextDate
        );
      }).length;

      return {
        label: date.toLocaleDateString("en-IN", {
          day: "2-digit",
          month: "short",
        }),
        count,
      };
    });

    const maxDaily = Math.max(1, ...daily.map((item) => item.count));
    const maxGroup = Math.max(1, ...groups.map((item) => item.count));

    const districtsMap = {};

    requests.forEach((request) => {
      const city = request.city || request.hospitalCity || "Unspecified";

      if (!districtsMap[city]) {
        districtsMap[city] = {
          city,
          total: 0,
          pending: 0,
          fulfilled: 0,
        };
      }

      districtsMap[city].total += 1;

      if (isPending(request)) districtsMap[city].pending += 1;
      if (isFulfilled(request)) districtsMap[city].fulfilled += 1;
    });

    const districts = Object.values(districtsMap)
      .sort((a, b) => b.total - a.total)
      .slice(0, 6);

    return {
      total: requests.length,
      pending: pending.length,
      fulfilled: fulfilled.length,
      matched: matched.length,
      groups,
      daily,
      maxDaily,
      maxGroup,
      districts,
    };
  }, [requests, range]);

  const urgentCount = requests.filter((request) =>
    ["urgent", "emergency", "critical"].includes(
      String(request.urgency || request.priority || "").toLowerCase()
    )
  ).length;

  return (
    <section className="analytics-page">
      <div className="analytics-heading">
        <div>
          <p className="analytics-eyebrow">
            LIFELINK / COMMAND INTELLIGENCE
          </p>
          <h1>Operations &amp; Demand Analytics</h1>
          <p className="analytics-subtitle">
            Network demand, request status and operational overview
          </p>
        </div>

        <button
          className="analytics-refresh"
          onClick={loadAnalytics}
          disabled={loading || extraLoading}
        >
          {loading || extraLoading ? "Loading..." : "↻ Refresh"}
        </button>
      </div>

      <div className="analytics-toolbar">
        <div className="analytics-live">
          <span className="analytics-live-dot" />
          Backend data
        </div>

        <label>
          Period
          <select
            value={range}
            onChange={(event) => setRange(event.target.value)}
          >
            <option value="7">Last 7 days</option>
            <option value="14">Last 14 days</option>
            <option value="30">Last 30 days</option>
          </select>
        </label>

        <span className="analytics-updated">
          {lastUpdated
            ? `Updated ${lastUpdated.toLocaleTimeString("en-IN")}`
            : "Not yet updated"}
        </span>
      </div>

      {error && (
        <div className="analytics-error">
          <strong>Analytics data load nahi ho paaya</strong>
          <p>{error}</p>
          <button onClick={loadAnalytics}>Try again</button>
        </div>
      )}

      {extraApiError && (
        <div className="analytics-error">
          <strong>Additional analytics APIs load nahi hui</strong>
          <p>{extraApiError}</p>
          <small>
            Admin token, permissions aur deployed backend endpoints check karein.
          </small>
        </div>
      )}

      <div className="analytics-kpi-grid">
        <article className="analytics-kpi">
          <span className="kpi-icon red">↗</span>
          <p>Total Blood Requests</p>
          <h2>{loading ? "…" : analytics.total}</h2>
          <small>Requests returned by the API</small>
        </article>

        <article className="analytics-kpi">
          <span className="kpi-icon amber">◷</span>
          <p>Open / Pending</p>
          <h2>{loading ? "…" : analytics.pending}</h2>
          <small>Awaiting fulfillment</small>
        </article>

        <article className="analytics-kpi">
          <span className="kpi-icon green">✓</span>
          <p>Fulfilled Requests</p>
          <h2>{loading ? "…" : analytics.fulfilled}</h2>
          <small>Marked fulfilled or completed</small>
        </article>

        <article className="analytics-kpi">
          <span className="kpi-icon blue">♧</span>
          <p>Available Donors</p>
          <h2>
            {loading ? "…" : donorCount === null ? "N/A" : donorCount}
          </h2>
          <small>
            {donorCount === null
              ? "Count unavailable from API"
              : "Available donor count from API"}
          </small>
        </article>
      </div>

      <div className="analytics-alert">
        <div className="analytics-alert-icon">!</div>
        <div>
          <h3>Urgent demand overview</h3>
          <p>
            {loading
              ? "Checking request urgency..."
              : `${urgentCount} request(s) are marked urgent, emergency or critical in the returned records.`}
          </p>
        </div>
        <span className="analytics-alert-count">
          {loading ? "…" : urgentCount}
        </span>
      </div>

      <div className="analytics-panels">
        <article className="analytics-panel analytics-demand-panel">
          <div className="analytics-panel-heading">
            <div>
              <h2>Request Volume Trend</h2>
              <p>Requests grouped by creation date</p>
            </div>
            <span className="analytics-panel-tag">API DATA</span>
          </div>

          {loading ? (
            <div className="analytics-state">Loading request history…</div>
          ) : analytics.total === 0 ? (
            <div className="analytics-state">
              No requests returned by the API.
            </div>
          ) : (
            <div className="analytics-bar-chart">
              {analytics.daily.map((day) => (
                <div className="analytics-bar-column" key={day.label}>
                  <strong>{day.count}</strong>
                  <div className="analytics-bar-track">
                    <div
                      className="analytics-bar"
                      style={{
                        height: `${
                          day.count > 0
                            ? Math.max(
                                5,
                                (day.count / analytics.maxDaily) * 100
                              )
                            : 0
                        }%`,
                      }}
                    />
                  </div>
                  <span>{day.label}</span>
                </div>
              ))}
            </div>
          )}
        </article>

        <article className="analytics-panel">
          <div className="analytics-panel-heading">
            <div>
              <h2>Demand by Blood Group</h2>
              <p>Count of returned requests</p>
            </div>
          </div>

          {loading ? (
            <div className="analytics-state">Loading blood groups…</div>
          ) : analytics.groups.every((item) => item.count === 0) ? (
            <div className="analytics-state">
              No blood-group data is available in the returned requests.
            </div>
          ) : (
            <div className="analytics-group-list">
              {analytics.groups
                .filter((item) => item.count > 0)
                .map((item) => (
                  <div className="analytics-group-row" key={item.group}>
                    <strong>{item.group}</strong>
                    <div className="analytics-group-track">
                      <div
                        className="analytics-group-fill"
                        style={{
                          width: `${
                            (item.count / analytics.maxGroup) * 100
                          }%`,
                        }}
                      />
                    </div>
                    <span>{item.count}</span>
                  </div>
                ))}
            </div>
          )}
        </article>
      </div>

      <div className="analytics-panels">
        <article className="analytics-panel">
          <div className="analytics-panel-heading">
            <div>
              <h2>Rare Blood Groups</h2>
              <p>Groups with low available donor counts</p>
            </div>
            <span className="analytics-panel-tag">API DATA</span>
          </div>

          {extraLoading ? (
            <div className="analytics-state">Loading rare blood groups…</div>
          ) : !rareBloodData ? (
            <div className="analytics-state">
              Rare blood group data unavailable.
            </div>
          ) : (
            <>
              <h3>
                {rareBloodData.rareGroupCount ?? 0} groups need attention
              </h3>

              {(rareBloodData.rareGroups || []).length === 0 ? (
                <div className="analytics-state">
                  No rare blood groups found for this threshold.
                </div>
              ) : (
                <div className="analytics-group-list">
                  {rareBloodData.rareGroups.map((item) => (
                    <div
                      className="analytics-group-row"
                      key={item.bloodGroup}
                    >
                      <strong>{item.bloodGroup}</strong>
                      <div className="analytics-group-track">
                        <div
                          className="analytics-group-fill"
                          style={{
                            width: `${
                              item.availableDonors === 0
                                ? 0
                                : Math.min(
                                    100,
                                    item.availableDonors * 10
                                  )
                            }%`,
                          }}
                        />
                      </div>
                      <span>
                        {item.availableDonors} donor(s)
                      </span>
                    </div>
                  ))}
                </div>
              )}

              <div className="analytics-panel-heading">
                <div>
                  <h3>All Blood Groups</h3>
                  <p>Available donors by blood group</p>
                </div>
              </div>

              <div className="analytics-status-list">
                {(rareBloodData.bloodGroups || []).map((item) => (
                  <div key={item.bloodGroup}>
                    <span>{item.bloodGroup}</span>
                    <strong>{item.availableDonors}</strong>
                  </div>
                ))}
              </div>
            </>
          )}
        </article>
        <article className="analytics-panel">
          <div className="analytics-panel-heading">
            <div>
              <h2>Donor Response Reliability</h2>
              <p>Donor response acceptance rate</p>
            </div>
            <span className="analytics-panel-tag">API DATA</span>
          </div>

          {extraLoading ? (
            <div className="analytics-state">
              Loading response reliability…
            </div>
          ) : !reliabilityData ? (
            <div className="analytics-state">
              Response reliability data unavailable.
            </div>
          ) : (
            <>
              <p>Acceptance rate</p>
              <h2>
                {reliabilityData.acceptanceRatePercentage == null
                  ? "—"
                  : `${reliabilityData.acceptanceRatePercentage}%`}
              </h2>

              {reliabilityData.totalResponses === 0 && (
                <p>No donor responses yet.</p>
              )}

              <div className="analytics-status-list">
                <div>
                  <span>Accepted responses</span>
                  <strong>{reliabilityData.acceptedResponses ?? 0}</strong>
                </div>
                <div>
                  <span>Declined responses</span>
                  <strong>{reliabilityData.declinedResponses ?? 0}</strong>
                </div>
                <div>
                  <span>Total responses</span>
                  <strong>{reliabilityData.totalResponses ?? 0}</strong>
                </div>
              </div>
            </>
          )}
        </article>
      </div>

      <div className="analytics-panels analytics-bottom-panels">
        <article className="analytics-panel">
          <div className="analytics-panel-heading">
            <div>
              <h2>Request Status Summary</h2>
              <p>Calculated from API status fields</p>
            </div>
          </div>

          {loading ? (
            <div className="analytics-state">Loading statuses…</div>
          ) : (
            <div className="analytics-status-list">
              <div>
                <span className="status-dot pending-dot" />
                <span>Open / Pending</span>
                <strong>{analytics.pending}</strong>
              </div>
              <div>
                <span className="status-dot matched-dot" />
                <span>Matched / In transit</span>
                <strong>{analytics.matched}</strong>
              </div>
              <div>
                <span className="status-dot fulfilled-dot" />
                <span>Fulfilled / Completed</span>
                <strong>{analytics.fulfilled}</strong>
              </div>
            </div>
          )}
        </article>

        <article className="analytics-panel">
          <div className="analytics-panel-heading">
            <div>
              <h2>District Demand</h2>
              <p>Grouped by city field returned by the API</p>
            </div>
          </div>

          {loading ? (
            <div className="analytics-state">Loading locations…</div>
          ) : analytics.districts.length === 0 ? (
            <div className="analytics-state">
              No location records available.
            </div>
          ) : (
            <div className="analytics-table-wrap">
              <table className="analytics-table">
                <thead>
                  <tr>
                    <th>City / Area</th>
                    <th>Total</th>
                    <th>Pending</th>
                    <th>Fulfilled</th>
                  </tr>
                </thead>
                <tbody>
                  {analytics.districts.map((district) => (
                    <tr key={district.city}>
                      <td>{district.city}</td>
                      <td>{district.total}</td>
                      <td>{district.pending}</td>
                      <td>{district.fulfilled}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </article>
      </div>

      <p className="analytics-footnote">
        Source: authenticated LifeLink backend APIs. Response acceptance rate
        represents accepted donor responses divided by total donor responses.
        It does not represent completed donations or delivery speed.
      </p>
    </section>
  );
}

export default Analytics;
