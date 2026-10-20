import { useEffect, useState } from "react";
import "./Settings.css";

function Settings() {
  const [user, setUser] = useState({});

  const [preferences, setPreferences] = useState(() => {
    try {
      const saved = localStorage.getItem("lifelink-notification-preferences");
      return saved
        ? JSON.parse(saved)
        : {
            email: true,
            inApp: true,
            emergency: true,
          };
    } catch {
      return {
        email: true,
        inApp: true,
        emergency: true,
      };
    }
  });

  const [message, setMessage] = useState("");

  useEffect(() => {
    try {
      const savedUser = JSON.parse(localStorage.getItem("user")) || {};
      setUser(savedUser);
    } catch {
      setUser({});
    }
  }, []);

  const name =
    user.name ||
    user.fullName ||
    user.username ||
    user.email ||
    "Logged-in User";

  const email = user.email || "Email not available";

  const role = user.role || "LifeLink User";

  const initials = String(name)
    .trim()
    .split(/\s+/)
    .map((part) => part[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  function handleToggle(key) {
    const updated = {
      ...preferences,
      [key]: !preferences[key],
    };

    setPreferences(updated);

    try {
      localStorage.setItem(
        "lifelink-notification-preferences",
        JSON.stringify(updated)
      );
      setMessage("Notification preferences saved on this device.");
    } catch {
      setMessage("Unable to save preferences on this device.");
    }
  }

  function resetPreferences() {
    const defaults = {
      email: true,
      inApp: true,
      emergency: true,
    };

    setPreferences(defaults);

    try {
      localStorage.setItem(
        "lifelink-notification-preferences",
        JSON.stringify(defaults)
      );
      setMessage("Notification preferences have been reset.");
    } catch {
      setMessage("Unable to reset preferences.");
    }
  }

  return (
    <section className="settings-page">
      <div className="settings-heading">
        <div>
          <p className="settings-eyebrow">ACCOUNT CONFIGURATION</p>
          <h1>Settings</h1>
          <p>Manage your profile and notification preferences.</p>
        </div>

        <button
          type="button"
          className="settings-reset-button"
          onClick={resetPreferences}
        >
          Reset Preferences
        </button>
      </div>

      <div className="settings-layout">
        <div className="settings-main-column">
  
          <section className="settings-card">
            <div className="settings-card-heading">
              <div className="settings-card-icon profile-icon">
                ♙
              </div>
              <div>
                <h2>Profile Information</h2>
                <p>Your currently logged-in account details.</p>
              </div>
            </div>

            <div className="settings-profile-preview">
              <div className="settings-avatar">
                {initials || "U"}
              </div>

              <div className="settings-profile-name">
                <h3>{name}</h3>
                <p>{email}</p>
              </div>

              <span className="settings-role-badge">
                {role}
              </span>
            </div>

            <div className="settings-form-grid">
              <div className="settings-field">
                <label htmlFor="settings-name">Full Name</label>
                <input
                  id="settings-name"
                  type="text"
                  value={name}
                  readOnly
                />
              </div>

              <div className="settings-field">
                <label htmlFor="settings-email">Email Address</label>
                <input
                  id="settings-email"
                  type="email"
                  value={email}
                  readOnly
                />
              </div>
            </div>

            <div className="settings-field settings-role-field">
              <label htmlFor="settings-role">Account Role</label>
              <input
                id="settings-role"
                type="text"
                value={role}
                readOnly
              />
              <small>
                Account details are provided by your login session.
              </small>
            </div>
          </section>

          <section className="settings-card">
            <div className="settings-card-heading">
              <div className="settings-card-icon notification-icon">
                ♧
              </div>
              <div>
                <h2>Notification Preferences</h2>
                <p>Choose which alerts you prefer to receive.</p>
              </div>
            </div>

            <div className="settings-toggle-row">
              <div>
                <h3>Email Notifications</h3>
                <p>Receive general system updates by email.</p>
              </div>

              <button
                type="button"
                role="switch"
                aria-checked={preferences.email}
                aria-label="Email Notifications"
                className={`settings-switch ${
                  preferences.email ? "switch-on" : ""
                }`}
                onClick={() => handleToggle("email")}
              >
                <span />
              </button>
            </div>

            <div className="settings-toggle-row">
              <div>
                <h3>In-App Notifications</h3>
                <p>Show updates and notifications in the dashboard.</p>
              </div>

              <button
                type="button"
                role="switch"
                aria-checked={preferences.inApp}
                aria-label="In-App Notifications"
                className={`settings-switch ${
                  preferences.inApp ? "switch-on" : ""
                }`}
                onClick={() => handleToggle("inApp")}
              >
                <span />
              </button>
            </div>

            <div className="settings-toggle-row">
              <div>
                <h3>Emergency Alerts</h3>
                <p>Receive alerts about urgent blood requests.</p>
              </div>

              <button
                type="button"
                role="switch"
                aria-checked={preferences.emergency}
                aria-label="Emergency Alerts"
                className={`settings-switch ${
                  preferences.emergency ? "switch-on" : ""
                }`}
                onClick={() => handleToggle("emergency")}
              >
                <span />
              </button>
            </div>

            {message && (
              <p className="settings-message" role="status">
                {message}
              </p>
            )}

            <p className="settings-info-note">
              These preferences are saved in this browser only.
              They do not change backend notification delivery yet.
            </p>
          </section>
        </div>

        {/* Right Side Cards */}
        <div className="settings-side-column">
          <section className="settings-card settings-security-card">
            <div className="settings-card-icon security-status-icon">
              ✓
            </div>

            <h2>Security Status</h2>
            <p>Your account information at a glance.</p>

            <div className="settings-security-item">
              <span>Account Type</span>
              <strong>{role}</strong>
            </div>

            <div className="settings-security-item">
              <span>Emergency Alerts Preference</span>
              <strong>
                {preferences.emergency ? "Enabled" : "Disabled"}
              </strong>
            </div>

            <div className="settings-security-item">
              <span>Session Security</span>
              <strong>
                {localStorage.getItem("token")
                  ? "Authenticated Session"
                  : "Login Required"}
              </strong>
            </div>
          </section>

          <section className="settings-card settings-help-card">
            <div className="settings-card-icon help-icon">
              i
            </div>

            <h2>Need Help?</h2>
            <p>
              For account permissions or security issues, contact
              your LifeLink system administrator.
            </p>
          </section>
        </div>
      </div>
    </section>
  );
}

export default Settings;
