import { useState } from "react";
import Login from "./pages/Login";
import Register from "./pages/Register";
import Dashboard from "./pages/Dashboard";
import Settings from "./pages/Settings";

const API_URL = "https://lifelink-backend-8onj.onrender.com";

function App() {
  const [page, setPage] = useState(
    localStorage.getItem("token") ? "dashboard" : "login"
  );

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleLogin(email, password) {
    setLoading(true);
    setError("");

    try {
      const response = await fetch(`${API_URL}/api/auth/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      });

      const data = await response.json();

      if (!response.ok || !data.success || !data.token) {
        throw new Error(data.message || "Login failed");
      }

      localStorage.setItem("token", data.token);
      localStorage.setItem("user", JSON.stringify(data.user));

      setPage("dashboard");
    } catch (err) {
      setError(err.message || "Unable to connect to the server.");
    } finally {
      setLoading(false);
    }
  }

  async function handleRegister(formData) {
    setLoading(true);
    setError("");

    try {
      const response = await fetch(`${API_URL}/api/auth/register`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(formData),
      });

      const data = await response.json();

      if (!response.ok || !data.success) {
        throw new Error(data.message || "Registration failed");
      }

      setError("");
      setPage("login");
    } catch (err) {
      setError(err.message || "Registration failed.");
    } finally {
      setLoading(false);
    }
  }

  function handleLogout() {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    setError("");
    setPage("login");
  }

  if (page === "settings") {
    return (
      <Settings
        onBack={() => setPage("dashboard")}
        onLogout={handleLogout}
      />
    );
  }

  if (page === "dashboard") {
    return (
      <Dashboard
        onLogout={handleLogout}
        onOpenSettings={() => setPage("settings")}
      />
    );
  }

  if (page === "register") {
    return (
      <Register
        onRegister={handleRegister}
        loading={loading}
        error={error}
        onGoLogin={() => {
          setError("");
          setPage("login");
        }}
      />
    );
  }

  return (
    <Login
      onLogin={handleLogin}
      loading={loading}
      error={error}
      onGoRegister={() => {
        setError("");
        setPage("register");
      }}
    />
  );
}

export default App;
