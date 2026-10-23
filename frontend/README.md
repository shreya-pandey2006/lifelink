# LifeLink Admin Web Console 💻

> **Real-Time Operational Oversight, Fleet Analytics & Blood Dispatch Management Dashboard**  
> Built with React 19, Vite, React Router, Lucide Icons, and Modern Vanilla CSS.

---

## 📌 Overview

The **LifeLink Admin Web Console** (`/frontend`) is the central desktop management interface for healthcare administrators, emergency coordinators, and dispatch operators. It delivers system-wide visibility into blood bank inventories, active emergency SOS requests, donor registries, and triage statistics.

---

## ✨ Features

- **📊 Central Executive Dashboard (`/dashboard`)**:
  - Real-time operational metric counters: Total Requests, Units Needed, Fulfilled Emergencies, Active Donor Fleet.
  - Urgency breakdown charts (Critical, Urgent, Normal) with color-coded severity badges.
  - Recent emergency activity stream with live status indicators.
- **🩸 Blood Requests Grid (`/requests`)**:
  - Filterable by urgency (`Critical`, `Urgent`, `Normal`) and status (`open`, `matched`, `cancelled`).
  - Search by city, patient name, hospital, and blood group.
  - Inspect unit counts, patient vitals, and matched donor dispatches.
- **👥 Donor Registry Oversight (`/donors`)**:
  - Comprehensive listing of registered donors across cities.
  - View blood groups, availability toggles, total lifetime donations, and last donation timestamps.
  - Inspect ML demographic readiness (age, weight, hemoglobin levels).
- **📈 Real-Time Analytics (`/analytics`)**:
  - Deep-dive metrics into fulfillment rates, dispatch response times, and city-level demand distributions.
  - Historical trend monitoring for regional blood bank planning.
- **🔔 Notifications Center (`/notifications`)**:
  - System-wide alert logs, dispatch notifications, and administrative audit trails.
- **⚙️ Settings & Configuration (`/settings`)**:
  - Manage administrator preferences, operational thresholds, and system endpoints.

---

## 🏗️ Tech Stack

- **Framework**: [React 19](https://react.dev/)
- **Build Tool**: [Vite](https://vitejs.dev/) with Fast Refresh (HMR)
- **Routing**: [React Router](https://reactrouter.com/) (Declarative client-side routing)
- **Styling**: Modern Vanilla CSS with scoped component stylesheets and custom CSS variables
- **Icons**: [Lucide React](https://lucide.dev/)
- **Linting & Quality**: [Oxlint](https://oxc.rs/)

---

## 📁 Project Structure

```
frontend/
├── src/
│   ├── assets/         # Static media, SVGs, and branding logos
│   ├── pages/          # Administrative feature views
│   │   ├── Analytics.jsx     # Deep-dive charts & historical analytics
│   │   ├── BloodRequests.jsx # Emergency requests moderation grid
│   │   ├── Dashboard.jsx     # Executive dashboard overview
│   │   ├── Donors.jsx        # Registered donor directory
│   │   ├── Login.jsx         # Admin authentication portal
│   │   ├── Notifications.jsx # System broadcast & alert logs
│   │   ├── Register.jsx      # Staff onboarding & registration
│   │   └── Settings.jsx      # Preferences & system configuration
│   ├── utils/          # API helpers, auth token managers, formatting utilities
│   ├── App.jsx         # App router and persistent sidebar navigation frame
│   ├── main.jsx        # React root DOM initialization
│   └── index.css       # Global CSS design tokens and theme variables
├── package.json        # Dependencies and scripts
└── vite.config.js      # Vite compilation configuration
```

---

## 🚀 Getting Started

### Prerequisites
- [Node.js](https://nodejs.org/) (`^18.x` or `^20.x`)
- `npm` (`^9.x` or later)

### Installation & Run

```bash
# 1. Navigate to the frontend directory
cd frontend

# 2. Install dependencies
npm install

# 3. Start the development server
npm run dev
```

The admin web console will be accessible at:
```text
http://localhost:5173
```

### Production Build

```bash
# Build the optimized production bundle
npm run build

# Preview the production build locally
npm run preview
```

---

## 🌐 API & Backend Integration

The console connects to the deployed LifeLink REST API on Render:
- Base API URL: `https://lifelink-backend-8onj.onrender.com/api`
- Authentication: Communicates with `/api/auth/login` and sends `Authorization: Bearer <JWT>` for all protected management endpoints.
- Role Requirement: Administrative accounts with `role: "admin"` have elevated access to audit fleet-wide requests, all registered donors, and aggregate system metrics.

---

## 📄 License
This project is developed for educational and demonstration purposes.
