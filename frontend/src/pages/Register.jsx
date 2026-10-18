import { useState } from "react";
import "./Register.css";

function Register({ onRegister, loading, error, onGoLogin }) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  function handleSubmit(event) {
    event.preventDefault();

    if (password !== confirmPassword) {
      alert("Passwords do not match.");
      return;
    }

    onRegister({ name, email, password });
  }

  return (
    <div className="auth-page">
      <header className="auth-topbar">
        <div className="auth-brand">
          <div className="brand-symbol">✳</div>
          <div>
            <h2>LifeLink <span>DISPATCH</span></h2>
            <p>Regional Blood Network</p>
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
            <strong>YOUR HELPLINE</strong>
          </div>
        </div>
      </header>

      <main className="auth-card">
        <section className="auth-visual">
          <div className="network-status">
            <span>● JOIN THE NETWORK</span>
            <span>Blood Support Network</span>
          </div>

          <div className="visual-brand">
            <div className="visual-logo">⌁</div>
            <div>
              <h2>LifeLink</h2>
              <p>CLINICAL DISPATCH</p>
            </div>
          </div>

          <h1>Be Part of<br />Something Life-Saving.</h1>

          <p className="visual-description">
            Join a connected community working to coordinate
            blood requests and support people in need.
          </p>

          <div className="visual-info">
            <span className="info-label">TOGETHER WE CAN</span>
            <h3>Make Every Drop Count</h3>
            <p>
              Create your account to get started with the LifeLink
              blood support network.
            </p>
          </div>

          <div className="visual-image">
            <img
              src="https://images.unsplash.com/photo-1615461066841-6116e61058f4?auto=format&fit=crop&w=1000&q=80"
              alt="Blood donation equipment in a clinical setting"
            />
            <div className="image-caption">
              <span>JOIN OUR NETWORK</span>
              <h3>Every Contribution Matters</h3>
            </div>
          </div>

          <div className="visual-disclaimer">
            <span>ⓘ</span>
            <p>
              Provide accurate information when creating your account.
            </p>
          </div>

          <div className="visual-footer">
            <span>LifeLink Blood Network</span>
            <span>Secure Registration</span>
          </div>
        </section>

        <section className="auth-form-panel register-panel">
          <div className="form-heading">
            <span className="section-eyebrow">GET STARTED</span>
            <h1>Create Account</h1>
            <p>Register to join the LifeLink network.</p>
          </div>

          <div className="auth-tabs">
            <button
              className="auth-tab"
              type="button"
              onClick={onGoLogin}
            >
              Sign In
            </button>
            <button className="auth-tab selected" type="button">
              Register
            </button>
          </div>

          <div className="protocol-banner">
            <span>♙</span>
            <p>
              <strong>New Account:</strong> Enter your details below
              to register.
            </p>
          </div>

          <form className="auth-form" onSubmit={handleSubmit}>
            <label htmlFor="register-name">Full Name</label>
            <input
              id="register-name"
              type="text"
              placeholder="Enter your full name"
              value={name}
              onChange={(event) => setName(event.target.value)}
              autoComplete="name"
              required
            />

            <label htmlFor="register-email">Email Address</label>
            <input
              id="register-email"
              type="email"
              placeholder="Enter your email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              autoComplete="email"
              required
            />

            <label htmlFor="register-password">Password</label>
            <input
              id="register-password"
              type="password"
              placeholder="Create a password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              autoComplete="new-password"
              required
            />

            <label htmlFor="register-confirm">Confirm Password</label>
            <input
              id="register-confirm"
              type="password"
              placeholder="Enter password again"
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
              autoComplete="new-password"
              required
            />

            {error && <p className="auth-error">{error}</p>}

            <button className="auth-submit" type="submit" disabled={loading}>
              {loading ? "Creating Account..." : "Create Your Account"}
            </button>
          </form>

          <p className="register-prompt">
            Already registered?{" "}
            <button type="button" onClick={onGoLogin}>
              Sign in
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
          <strong>24/7 Dispatch Hotline: YOUR HELPLINE</strong>
        </div>
      </footer>
    </div>
  );
}

export default Register;
