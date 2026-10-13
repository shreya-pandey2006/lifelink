
import { useMemo, useState } from "react";
import "./Dashboard.css";

const initialRequests = [
  {
    id: "REQ-8902",
    patient: "Elena Rostova",
    ward: "Trauma Bay 2",
    group: "O-",
    hospital: "St. Jude Trauma Hub",
    city: "Chicago",
    units: 4,
    urgency: "Critical",
    status: "Open",
  },
  {
    id: "REQ-8898",
    patient: "Marcus Vance",
    ward: "Surgical Wing C",
    group: "A+",
    hospital: "Memorial Health Center",
    city: "Evanston",
    units: 2,
    urgency: "Urgent",
    status: "Matched",
  },
  {
    id: "REQ-8895",
    patient: "Amara Chen",
    ward: "Oncology Ward",
    group: "B+",
    hospital: "City General Hospital",
    city: "Naperville",
    units: 3,
    urgency: "Normal",
    status: "Fulfilled",
  },
  {
    id: "REQ-8891",
    patient: "Dominic Reed",
    ward: "Pediatric ICU",
    group: "AB-",
    hospital: "Metro Children's Hospital",
    city: "Oak Park",
    units: 2,
    urgency: "Critical",
    status: "Open",
  },
  {
    id: "REQ-8884",
    patient: "Kareem Al-Sayed",
    ward: "Cardio Thoracic",
    group: "O+",
    hospital: "Northwestern Memorial",
    city: "Chicago",
    units: 5,
    urgency: "Urgent",
    status: "Matched",
  },
];

const inventory = [
  { group: "O+", percentage: 78, label: "Stable", color: "green" },
  { group: "A+", percentage: 62, label: "Optimal", color: "blue" },
  { group: "B+", percentage: 45, label: "Moderate", color: "purple" },
  { group: "O-", percentage: 18, label: "Low Stock", color: "red" },
  { group: "AB+", percentage: 34, label: "Attention", color: "gray" },
];

const activities = [
  {
    icon: "person_check",
    type: "blue",
    title: <>Donor <strong>David K.</strong> matched with <b>#REQ-8902 (O-)</b></>,
    detail: "3 mins ago · Rapid Triage Match",
  },
  {
    icon: "done_all",
    type: "green",
    title: <><b>#REQ-8891</b> marked Fulfilled at Metro General</>,
    detail: "14 mins ago · Blood Units Delivered",
  },
  {
    icon: "cell_tower",
    type: "red",
    title: <>Critical Request <b>#REQ-8905</b> broadcast to 45 donors</>,
    detail: "28 mins ago · SMS & Mobile Push (demo)",
  },
  {
    icon: "assignment_turned_in",
    type: "gray",
    title: <>Donor check-in verified at St. Jude Trauma Wing</>,
    detail: "42 mins ago · Demo activity",
  },
];

const hotspots = [
  { name: "St. Jude Trauma", level: "Critical", distance: "3.2 km", color: "red" },
  { name: "Memorial Health", level: "Urgent", distance: "7.8 km", color: "orange" },
  { name: "Metro Children's", level: "Critical", distance: "12.4 km", color: "red" },
  { name: "City General", level: "Normal", distance: "18.1 km", color: "blue" },
];

const navigation = [
  { label: "Dashboard", icon: "grid_view", page: "dashboard" },
  { label: "Blood Requests", icon: "bloodtype", page: "blood-requests" },
  { label: "Request Details", icon: "clinical_notes", page: "request-details" },
  { label: "Donors & Notifications", icon: "group", page: "donors-notifications" },
  { label: "Analytics & Profile", icon: "monitoring", page: "analytics-profile" },
];

function Icon({ children, className = "" }) {
  return (
    <span className={`material-symbols-outlined ${className}`}>
      {children}
    </span>
  );
}

function StatCard({ icon, label, value, badge, note, color }) {
  return (
    <section className="dash-stat-card">
      <div className="dash-stat-top">
        <div className="dash-stat-label">
          <span className={`dash-stat-icon ${color}`}>
            <Icon>{icon}</Icon>
          </span>
          <span>{label}</span>
        </div>
        <span className={`dash-stat-badge ${color}`}>{badge}</span>
      </div>
      <div className="dash-stat-bottom">
        <strong className="dash-stat-value">{value}</strong>
        <span className={`dash-stat-note ${color}`}>{note}</span>
      </div>
    </section>
  );
}

function StatusBadge({ children }) {
  return (
    <span className={`dash-status ${String(children).toLowerCase()}`}>
      {children}
    </span>
  );
}

function CreateRequestModal({ onClose, onCreate }) {
  const [patient, setPatient] = useState("");
  const [group, setGroup] = useState("O-");
  const [hospital, setHospital] = useState("");
  const [city, setCity] = useState("");
  const [units, setUnits] = useState("1");
  const [urgency, setUrgency] = useState("Urgent");

  function handleSubmit(event) {
    event.preventDefault();

    onCreate({
      id: `REQ-${Math.floor(9000 + Math.random() * 999)}`,
      patient: patient.trim(),
      ward: "New request",
      group,
      hospital: hospital.trim(),
      city: city.trim(),
      units: Number(units),
      urgency,
      status: "Open",
    });

    onClose();
  }

  return (
    <div className="dash-modal-backdrop" onMouseDown={(event) => {
      if (event.target === event.currentTarget) onClose();
    }}>
      <section className="dash-modal" role="dialog" aria-modal="true" aria-labelledby="create-request-title">
        <div className="dash-modal-heading">
          <div>
            <span className="dash-eyebrow">LIFELINK · DEMO</span>
            <h2 id="create-request-title">Create Blood Request</h2>
          </div>
          <button className="dash-icon-button" type="button" onClick={onClose} aria-label="Close form">
            <Icon>close</Icon>
          </button>
        </div>

        <form className="dash-request-form" onSubmit={handleSubmit}>
          <label>
            Patient name
            <input value={patient} onChange={(e) => setPatient(e.target.value)} required placeholder="Enter patient name" />
          </label>

          <div className="dash-form-row">
            <label>
              Blood group
              <select value={group} onChange={(e) => setGroup(e.target.value)}>
                {["O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+"].map((item) => (
                  <option key={item}>{item}</option>
                ))}
              </select>
            </label>
            <label>
              Units needed
              <input type="number" min="1" max="20" value={units} onChange={(e) => setUnits(e.target.value)} required />
            </label>
          </div>

          <label>
            Hospital
            <input value={hospital} onChange={(e) => setHospital(e.target.value)} required placeholder="Enter hospital name" />
          </label>

          <label>
            City
            <input value={city} onChange={(e) => setCity(e.target.value)} required placeholder="Enter city" />
          </label>

          <label>
            Urgency
            <select value={urgency} onChange={(e) => setUrgency(e.target.value)}>
              <option>Critical</option>
              <option>Urgent</option>
              <option>Normal</option>
            </select>
          </label>

          <p className="dash-demo-note">
            This creates a temporary sample request in this browser session. It does not contact donors or a hospital.
          </p>

          <div className="dash-modal-actions">
            <button type="button" className="dash-button secondary" onClick={onClose}>Cancel</button>
            <button type="submit" className="dash-button primary">
              <Icon>add</Icon> Add Request
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}

export default function Dashboard({ onNavigate, onSignOut }) {
  const [requests, setRequests] = useState(initialRequests);
  const [search, setSearch] = useState("");
  const [urgencyFilter, setUrgencyFilter] = useState("All");
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [notice, setNotice] = useState("");
  const [page, setPage] = useState(1);

  const filteredRequests = useMemo(() => {
    const query = search.trim().toLowerCase();

    return requests.filter((request) => {
      const matchesSearch = [
        request.id,
        request.patient,
        request.group,
        request.hospital,
        request.city,
        request.status,
      ].some((value) => value.toLowerCase().includes(query));

      const matchesUrgency =
        urgencyFilter === "All" || request.urgency === urgencyFilter;

      return matchesSearch && matchesUrgency;
    });
  }, [requests, search, urgencyFilter]);

  function createRequest(request) {
    setRequests((current) => [request, ...current]);
    setPage(1);
    setNotice("Sample request added to the dashboard.");
  }

  function exportRequests() {
    const header = ["Request ID", "Patient", "Blood Group", "Hospital", "City", "Units", "Urgency", "Status"];
    const rows = filteredRequests.map((r) => [
      r.id, r.patient, r.group, r.hospital, r.city, r.units, r.urgency, r.status,
    ]);

    const csv = [header, ...rows]
      .map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(","))
      .join("\n");

    const url = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8;" }));
    const link = document.createElement("a");
    link.href = url;
    link.download = "lifelink-demo-requests.csv";
    link.click();
    URL.revokeObjectURL(url);
    setNotice("Demo requests exported.");
  }

  function navigateTo(pageName) {
    if (pageName === "dashboard") return;
    if (onNavigate) {
      onNavigate(pageName);
    } else {
      setNotice(`${pageName.replaceAll("-", " ")} screen is not connected yet.`);
    }
  }

  return (
    <div className="lifelink-dashboard">
      <aside className="dash-sidebar">
        <div>
          <div className="dash-brand">
            <div className="dash-brand-mark"><Icon>water_drop</Icon></div>
            <div>
              <strong>LifeLink</strong>
              <span>EMERGENCY BLOOD NETWORK</span>
            </div>
          </div>

          <nav className="dash-navigation" aria-label="Main navigation">
            {navigation.map((item) => (
              <button
                key={item.page}
                type="button"
                className={`dash-nav-item ${item.page === "dashboard" ? "active" : ""}`}
                onClick={() => navigateTo(item.page)}
              >
                <Icon>{item.icon}</Icon>
                <span>{item.label}</span>
              </button>
            ))}
          </nav>
        </div>

        <div className="dash-sidebar-bottom">
          <div className="dash-online">
            <span className="dash-online-dot" />
            <span>System Online <b>·</b> 24/7 Dispatch</span>
          </div>
          <button
            className="dash-nav-item dash-signout"
            type="button"
            onClick={() => {
              if (onSignOut) onSignOut();
              else if (onNavigate) onNavigate("login");
              else setNotice("Connect this button to your existing sign-out flow.");
            }}
          >
            <Icon>logout</Icon><span>Sign Out</span>
          </button>
        </div>
      </aside>

      <div className="dash-main">
        <header className="dash-topbar">
          <div className="dash-breadcrumb">
            <span className="dash-top-logo"><Icon>water_drop</Icon></span>
            <strong>LifeLink Command</strong>
            <span className="dash-breadcrumb-divider">/</span>
            <span>Triage Network</span>
          </div>

          <label className="dash-search">
            <Icon>search</Icon>
            <input
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              placeholder="Search requests, donor IDs, hospitals..."
              aria-label="Search requests"
            />
            {search && (
              <button type="button" onClick={() => setSearch("")} aria-label="Clear search">
                <Icon>close</Icon>
              </button>
            )}
          </label>

          <div className="dash-top-actions">
            <button className="dash-notification-button" type="button" onClick={() => setNotice("You have 3 demo notifications.")} aria-label="Notifications">
              <Icon>notifications</Icon><span>3</span>
            </button>
            <button className="dash-button primary create-top-button" type="button" onClick={() => setShowCreateForm(true)}>
              <Icon>add</Icon><span>Create Request</span>
            </button>
            <div className="dash-profile">
              <div className="dash-avatar"><Icon>person</Icon></div>
              <div><strong>Dr. Sarah Jenkins</strong><span>Head Administrator</span></div>
            </div>
          </div>
        </header>

        <main className="dash-content">
          <section className="dash-page-heading">
            <div>
              <div className="dash-eyebrow"><span className="dash-live-dot" /> Emergency Incident Operations Center</div>
              <h1>Dashboard Overview</h1>
              <p>Live Emergency Dispatch &amp; Blood Availability Overview Across Regional Trauma Hubs</p>
            </div>
            <div className="dash-heading-actions">
              <span className="dash-updated"><Icon>sync</Icon> Sample data · demo mode</span>
              <button className="dash-button primary" type="button" onClick={() => setNotice("Fast triage is a visual demo; no real dispatch was sent.")}>
                <Icon>e911_emergency</Icon> Fast Triage Dispatch
              </button>
            </div>
          </section>

          {notice && (
            <div className="dash-notice" role="status">
              <Icon>info</Icon><span>{notice}</span>
              <button type="button" onClick={() => setNotice("")} aria-label="Dismiss message"><Icon>close</Icon></button>
            </div>
          )}

          <section className="dash-stats-grid">
            <StatCard icon="emergency" label="Open Requests" value="28" badge="+4 today" note="High Urgency Load" color="red" />
            <StatCard icon="handshake" label="Matched Requests" value="64" badge="85% match rate" note="18 In Transit" color="blue" />
            <StatCard icon="task_alt" label="Fulfilled Requests" value="142" badge="This month" note="+18.4% vs last mo" color="green" />
            <StatCard icon="groups" label="Registered Donors" value="1,840" badge="+32 verified" note="412 On Standby" color="gray" />
          </section>

          <div className="dash-content-grid">
            <div className="dash-left-column">
              <section className="dash-emergency-banner">
                <div className="dash-emergency-icon"><Icon>notification_important</Icon></div>
                <div className="dash-emergency-copy">
                  <h2>Severe O-Negative Deficit in Sector 4</h2>
                  <p>Demo alert: immediate attention required for the sample regional network.</p>
                </div>
                <button type="button" onClick={() => navigateTo("donors-notifications")}>Dispatch Alerts</button>
              </section>

              <section className="dash-panel dash-requests-panel">
                <div className="dash-panel-heading">
                  <div>
                    <h2>Recent Blood Requests</h2>
                    <p>Sample trauma admissions and donor requisition records</p>
                  </div>
                  <div className="dash-table-controls">
                    <label className="dash-filter">
                      <Icon>filter_list</Icon>
                      <select value={urgencyFilter} onChange={(e) => { setUrgencyFilter(e.target.value); setPage(1); }} aria-label="Filter by urgency">
                        <option value="All">All Triage Levels</option>
                        <option value="Critical">Critical Only</option>
                        <option value="Urgent">Urgent Only</option>
                        <option value="Normal">Normal Only</option>
                      </select>
                    </label>
                    <button type="button" className="dash-button secondary export-button" onClick={exportRequests}>
                      <Icon>file_download</Icon> Export
                    </button>
                  </div>
                </div>

                <div className="dash-table-wrap">
                  <table className="dash-requests-table">
                    <thead>
                      <tr>
                        <th>Request ID</th><th>Patient Name</th><th>Group</th><th>Hospital</th>
                        <th>City</th><th>Units</th><th>Urgency</th><th>Status</th><th>Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredRequests.length > 0 ? filteredRequests.map((request) => (
                        <tr key={request.id}>
                          <td className="dash-request-id">#{request.id}</td>
                          <td><div className="dash-patient-name">{request.patient}</div><span className="dash-table-subtitle">{request.ward}</span></td>
                          <td><span className={`dash-blood-group ${request.group === "O-" || request.group === "AB-" ? "negative" : ""}`}>{request.group}</span></td>
                          <td className="dash-hospital-cell">{request.hospital}</td>
                          <td>{request.city}</td>
                          <td className="dash-units">{request.units}</td>
                          <td><StatusBadge>{request.urgency}</StatusBadge></td>
                          <td><StatusBadge>{request.status}</StatusBadge></td>
                          <td><button className="dash-view-link" type="button" onClick={() => {
                            if (onNavigate) onNavigate("request-details", request);
                            else setNotice(`Selected sample request #${request.id}. Connect Request Details to view more.`);
                          }}>View <Icon>arrow_forward</Icon></button></td>
                        </tr>
                      )) : (
                        <tr><td colSpan="9" className="dash-empty">No requests match your search or filter.</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>

                <div className="dash-table-footer">
                  <span>Showing {filteredRequests.length} sample request{filteredRequests.length === 1 ? "" : "s"} of {requests.length}</span>
                  <div className="dash-pagination">
                    <button type="button" disabled={page === 1} onClick={() => setPage(1)}>Previous</button>
                    <button type="button" className="selected" onClick={() => setPage(1)}>{page}</button>
                    <button type="button" onClick={() => setNotice("Only the first sample page is available in this prototype.")}>Next</button>
                  </div>
                </div>
              </section>

              <section className="dash-quick-actions">
                <button type="button" onClick={() => navigateTo("donors-notifications")}>
                  <span className="dash-quick-icon red"><Icon>campaign</Icon></span>
                  <span><strong>Regional Broadcast</strong><small>Alert nearby donors (demo)</small></span>
                </button>
                <button type="button" onClick={() => setNotice("Courier availability shown here is sample data.")}>
                  <span className="dash-quick-icon blue"><Icon>local_shipping</Icon></span>
                  <span><strong>Drone Dispatch</strong><small>3 couriers available (demo)</small></span>
                </button>
                <button type="button" onClick={() => setNotice("Compatibility testing must be performed by qualified medical services.")}>
                  <span className="dash-quick-icon green"><Icon>biotech</Icon></span>
                  <span><strong>Lab Crossmatch</strong><small>Compatibility workflow</small></span>
                </button>
              </section>
            </div>

            <div className="dash-right-column">
              <section className="dash-panel dash-inventory-panel">
                <div className="dash-panel-title">
                  <div><h2>Blood Inventory Health</h2><p>Sample regional bank reserve levels</p></div>
                  <Icon>water_drop</Icon>
                </div>
                <div className="dash-inventory-list">
                  {inventory.map((item) => (
                    <div className={`dash-inventory-item ${item.color === "red" ? "critical" : ""}`} key={item.group}>
                      <div className="dash-inventory-labels">
                        <strong><span className={`dash-legend-dot ${item.color}`} />Group {item.group}{item.color === "red" ? " (Critical)" : ""}</strong>
                        <span><b>{item.percentage}%</b> <small>{item.label}</small></span>
                      </div>
                      <div className="dash-progress-track">
                        <div className={`dash-progress-fill ${item.color}`} style={{ width: `${item.percentage}%` }} />
                      </div>
                    </div>
                  ))}
                </div>
              </section>

              <section className="dash-panel">
                <div className="dash-panel-title">
                  <div><h2>Request Status Breakdown</h2><p>Illustrative distribution</p></div>
                  <span className="dash-total-tag">234 Total</span>
                </div>
                <div className="dash-stacked-bar" aria-label="Open 12%, Matched 28%, Fulfilled 55%, Cancelled 5%">
                  <span className="open-bar" /><span className="matched-bar" /><span className="fulfilled-bar" /><span className="cancelled-bar" />
                </div>
                <div className="dash-status-legend">
                  <span><i className="open-bar" />Open (12%)</span>
                  <span><i className="matched-bar" />Matched (28%)</span>
                  <span><i className="fulfilled-bar" />Fulfilled (55%)</span>
                  <span><i className="cancelled-bar" />Cancelled (5%)</span>
                </div>
              </section>

              <section className="dash-panel">
                <div className="dash-panel-title">
                  <div><h2>Dispatch Hotspots</h2><p>Illustrative 35 km trauma network</p></div>
                  <Icon>radar</Icon>
                </div>
                <div className="dash-radar">
                  <div className="dash-radar-ring ring-large" />
                  <div className="dash-radar-ring ring-medium" />
                  <div className="dash-radar-ring ring-small" />
                  <div className="dash-radar-cross horizontal" />
                  <div className="dash-radar-cross vertical" />
                  <span className="dash-radar-point point-one" title="St. Jude Trauma" />
                  <span className="dash-radar-point point-two" title="Memorial Health" />
                  <span className="dash-radar-point point-three" title="City General" />
                  <span className="dash-radar-point point-four" title="Metro Children's" />
                  <span className="dash-radar-center"><Icon>local_hospital</Icon></span>
                </div>
                <div className="dash-hotspot-list">
                  {hotspots.map((spot) => (
                    <div className="dash-hotspot-row" key={spot.name}>
                      <div><span className={`dash-legend-dot ${spot.color}`} /><strong>{spot.name}</strong><StatusBadge>{spot.level}</StatusBadge></div>
                      <span>{spot.distance}</span>
                    </div>
                  ))}
                </div>
                <p className="dash-demo-note">This is a decorative panel, not a real map or verified distance calculation.</p>
              </section>

              <section className="dash-panel dash-activity-panel">
                <div className="dash-panel-title">
                  <div><h2>Live Network Activity</h2><p>Sample dispatch activity feed</p></div>
                  <span className="dash-live-label">DEMO</span>
                </div>
                <div className="dash-activity-list">
                  {activities.map((activity, index) => (
                    <div className="dash-activity-item" key={index}>
                      <span className={`dash-activity-icon ${activity.type}`}><Icon>{activity.icon}</Icon></span>
                      <div><p>{activity.title}</p><small>{activity.detail}</small></div>
                    </div>
                  ))}
                </div>
              </section>
            </div>
          </div>

          <footer className="dash-footer">
            <span>LifeLink · Admin Dashboard Prototype</span>
            <span>Sample data only · Not connected to live emergency services</span>
          </footer>
        </main>
      </div>

      {showCreateForm && (
        <CreateRequestModal
          onClose={() => setShowCreateForm(false)}
          onCreate={createRequest}
        />
      )}
    </div>
  );
}
