
import { useState } from "react";
import Login from "./pages/Login";
import Register from "./pages/Register";
import Dashboard from "./pages/Dashboard";

function App() {
  const [page, setPage] = useState("login");
  const [account, setAccount] = useState(null);
  const [notice, setNotice] = useState("");

  function handleCreateAccount(newAccount) {
    if (account && account.email.toLowerCase() === newAccount.email.toLowerCase()) {
      setNotice("An account with this email already exists in this demo.");
      setPage("login");
      return;
    }

    setAccount(newAccount);
    setNotice("Account created! You can now sign in.");
    setPage("login");
  }

  
  
function handleLogin(email, password) {
  if (
    account &&
    account.email.trim().toLowerCase() === email.trim().toLowerCase() &&
    account.password === password
  ) {
    setNotice("");
    setPage("dashboard");
  } else {
    setNotice(
      "Account not found or password is incorrect. Please register first."
    );
  }
}


  if (page === "dashboard") {
  return <Dashboard onSignOut={() => setPage("login")} />;
  }

  if (page === "register") {
    return (
      <Register
        onSignIn={() => {
          setNotice("");
          setPage("login");
        }}
        onCreateAccount={handleCreateAccount}
      />
    );
  }

  return (
    <Login
      onRegisterPage={() => {
        setNotice("");
        setPage("register");
      }}
      onLogin={handleLogin}
      initialMessage={notice}
    />
  );
}

export default App;

