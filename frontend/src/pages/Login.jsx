
import { useState } from "react";
import "./Login.css";

function Login({ onRegisterPage, onLogin, initialMessage }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [message, setMessage] = useState(initialMessage || "");

  function handleSubmit(event) {
    event.preventDefault();

    setMessage("");

    if (!email.trim() || !password) {
      setMessage("Please enter your email and password.");
      return;
    }

    onLogin(email, password);
    }

  return (
    <main className="login-page">
      <section className="login-card">
        <div className="login-logo">🩸LifeLink</div>

        <p className="login-badge">
          Emergency Blood Network
        </p>

        <h1>Welcome Back</h1>

        <p className="login-description">
          Sign in to the LifeLink Administrator Portal.
        </p>

        {message && (
          <p className="login-message" role="status">
            {message}
          </p>
        )}

        <form onSubmit={handleSubmit}>
          <label htmlFor="email">
            Institutional Email
          </label>

          <input
            id="email"
            type="email"
            placeholder="admin@lifelink.org"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
          />

          <label htmlFor="password">
            Password
          </label>

          <div className="password-wrapper">
            <input
              id="password"
              type={showPassword ? "text" : "password"}
              placeholder="Enter your password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />

            <button
              type="button"
              className="show-password"
              onClick={() => setShowPassword(!showPassword)}
            >
              {showPassword ? "Hide" : "Show"}
            </button>
          </div>

          <div className="login-options">
            <label className="remember-label">
              <input type="checkbox" />
              Remember me
            </label>

            <button
              type="button"
              className="forgot-button"
              onClick={() =>
                setMessage("Password recovery is not connected yet.")
              }
            >
              Forgot password?
            </button>
          </div>

          <button type="submit" className="login-button">
            Sign In to Dashboard
          </button>
        </form>

            <p className="signup-text">
              New to LifeLink?{" "}
              <button
                type="button"
                className="signup-link"
                onClick={onRegisterPage}
              >
                Create an account
              </button>
            </p>


        <p className="login-footer">
          LifeLink · Emergency Response Network
        </p>
      </section>
    </main>
  );
}

export default Login;
