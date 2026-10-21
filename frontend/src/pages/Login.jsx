import { useState } from "react";
import "./Login.css";
import { validateEmail, validatePassword } from "../utils/validators";

function Login({ onLogin, loading, error, onGoRegister }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [fieldErrors, setFieldErrors] = useState({});
  const [touched, setTouched] = useState({});

  function validate(fields = { email, password }) {
    const errors = {};
    const emailErr = validateEmail(fields.email);
    if (emailErr) errors.email = emailErr;

    const passErr = validatePassword(fields.password, { minLength: 6, requireMixed: false });
    if (passErr) errors.password = passErr;

    return errors;
  }

  function handleBlur(field) {
    setTouched((prev) => ({ ...prev, [field]: true }));
    setFieldErrors(validate());
  }

  function handleSubmit(event) {
    event.preventDefault();
    setTouched({ email: true, password: true });

    const errors = validate();
    setFieldErrors(errors);

    if (Object.keys(errors).length > 0) {
      return;
    }

    onLogin(email.trim().toLowerCase(), password);
  }

  return (
    <div className="auth-page">
      <header className="auth-topbar">
        <div className="auth-brand">
          
<div className="lifelink-logo">
  <div className="logo-icon">
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
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

  <div>
    <h2 className="logo-name">LifeLink <span>DISPATCH</span></h2>
    <p className="logo-subtitle">Regional Blood Network</p>
  </div>
</div>
        </div>

        <div className="security-badges">
          <span>♢ Secure Access</span>
          <span>• Encrypted Connection</span>
        </div>

        <div className="emergency-line">
          <span className="emergency-dot">●</span>
          <div>
            <small>Emergency Line</small>
            <strong>1800-180-260</strong>
          </div>
        </div>
      </header>

      <main className="auth-card">
        <section className="auth-visual">
          <div className="network-status">
            <span>● NETWORK ACCESS</span>
            <span>Blood Support Network</span>
          </div>

          <div className="visual-brand">
            <div className="visual-logo">⌁</div>
            <div>
              <h2>LifeLink</h2>
              <p>CLINICAL DISPATCH</p>
            </div>
          </div>

          <h1>Connecting Donors.<br />Saving Lives.</h1>

          <p className="visual-description">
            A connected blood support network helping coordinate
            requests, donors and emergency response.
          </p>

          <div className="visual-info">
            <span className="info-label">OUR MISSION</span>
            <h3>Every Drop Matters</h3>
            <p>
              Bringing people and blood support services together
              when every moment counts.
            </p>
          </div>

          <div className="visual-image">
            <img
              src="https://images.unsplash.com/photo-1615461066841-6116e61058f4?auto=format&fit=crop&w=1000&q=80"
              alt="Blood donation equipment in a clinical setting"
            />
            <div className="image-caption">
              <span>OUR NETWORK</span>
              <h3>Support When It Matters</h3>
            </div>
          </div>

          <div className="visual-disclaimer">
            <span>ⓘ</span>
            <p>
              Authorized access only. Please use your registered
              account to continue.
            </p>
          </div>

          <div className="visual-footer">
            <span>LifeLink Blood Network</span>
            <span>Secure Portal</span>
          </div>
        </section>

        <section className="auth-form-panel">
          <div className="form-heading">
            <span className="section-eyebrow">SECURE ACCESS POINT</span>
            <h1>Welcome Back</h1>
            <p>Sign in to access your LifeLink account.</p>
          </div>

          <div className="auth-tabs">
            <button className="auth-tab selected" type="button">
              Sign In
            </button>
            <button
              className="auth-tab"
              type="button"
              onClick={onGoRegister}
            >
              Create Account →
            </button>
          </div>

          <div className="protocol-banner">
            <span>◷</span>
            <p>
              <strong>Secure Session:</strong> Sign in using your
              registered email and password.
            </p>
          </div>

          <form className="auth-form" onSubmit={handleSubmit} noValidate>
            <label htmlFor="login-email">Email Address</label>
            <input
              id="login-email"
              type="email"
              className={touched.email && fieldErrors.email ? "input-invalid" : ""}
              placeholder="Enter your registered email"
              value={email}
              onChange={(event) => {
                setEmail(event.target.value);
                if (touched.email) setFieldErrors(validate({ email: event.target.value, password }));
              }}
              onBlur={() => handleBlur("email")}
              autoComplete="email"
              required
            />
            {touched.email && fieldErrors.email && (
              <span className="field-error-msg">{fieldErrors.email}</span>
            )}

            <div className="password-label">
              <label htmlFor="login-password">Password</label>
            </div>

            <div className="password-input">
              <input
                id="login-password"
                type={showPassword ? "text" : "password"}
                className={touched.password && fieldErrors.password ? "input-invalid" : ""}
                placeholder="Enter your password"
                value={password}
                onChange={(event) => {
                  setPassword(event.target.value);
                  if (touched.password) setFieldErrors(validate({ email, password: event.target.value }));
                }}
                onBlur={() => handleBlur("password")}
                autoComplete="current-password"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? "Hide password" : "Show password"}
              >
                {showPassword ? "Hide" : "Show"}
              </button>
            </div>
            {touched.password && fieldErrors.password && (
              <span className="field-error-msg">{fieldErrors.password}</span>
            )}

            {error && <p className="auth-error">{error}</p>}

            <button className="auth-submit" type="submit" disabled={loading}>
              {loading ? "Signing In..." : "Sign In to LifeLink"}
            </button>
          </form>

          <p className="register-prompt">
            New to LifeLink?{" "}
            <button type="button" onClick={onGoRegister}>
              Create your account
            </button>
          </p>

          <div className="form-bottom">
            <span>● Secure Access</span>
            <span>• Privacy Protected</span>
            <span>♧ Blood Support Network</span>
          </div>
        </section>
      </main>

      <footer className="auth-page-footer">
        <span>© LifeLink · Emergency Blood Network</span>
        <div>
          <span>♧</span>
          <strong>24/7 Dispatch Hotline: 1800-180-260</strong>
        </div>
      </footer>
    </div>
  );
}

export default Login;
