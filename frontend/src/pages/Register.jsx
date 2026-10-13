
import { useState } from "react";
import "./Register.css";

function Register({ onSignIn, onCreateAccount }) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState("");

  function handleSubmit(event) {
    event.preventDefault();
    setError("");

    if (!name.trim() || !email.trim() || !password || !confirmPassword) {
      setError("Please fill in all fields.");
      return;
    }

    if (password.length < 8) {
      setError("Password must be at least 8 characters.");
      return;
    }

    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    onCreateAccount({
      name: name.trim(),
      email: email.trim(),
      password,
    });
  }

  return (
    <main className="register-page">
      <section className="register-card">
        <h2 className="register-logo">♥ LifeLink</h2>
        <p className="register-badge">Emergency Blood Network</p>

        <h1>Create Account</h1>
        <p className="register-description">
          Join the LifeLink administrator demo.
        </p>

        {error && (
          <p className="register-error" role="alert">
            {error}
          </p>
        )}

        <form onSubmit={handleSubmit}>
          <label htmlFor="register-name">Full Name</label>
          <input
            id="register-name"
            type="text"
            placeholder="Enter your full name"
            value={name}
            onChange={(event) => setName(event.target.value)}
            autoComplete="name"
          />

          <label htmlFor="register-email">Email Address</label>
          <input
            id="register-email"
            type="email"
            placeholder="you@example.com"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            autoComplete="email"
          />

          <label htmlFor="register-password">Password</label>
          <input
            id="register-password"
            type="password"
            placeholder="At least 8 characters"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            autoComplete="new-password"
          />

          <label htmlFor="confirm-password">Confirm Password</label>
          <input
            id="confirm-password"
            type="password"
            placeholder="Enter your password again"
            value={confirmPassword}
            onChange={(event) => setConfirmPassword(event.target.value)}
            autoComplete="new-password"
          />

          <button className="register-button" type="submit">
            Create Account
          </button>
        </form>

        <p className="register-footer">
          Already have an account?{" "}
          <button type="button" onClick={onSignIn}>
            Sign in
          </button>
        </p>
      </section>
    </main>
  );
}

export default Register;
