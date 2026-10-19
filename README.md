# LifeLink 🩸

> **Intelligent Emergency Blood Dispatch & Donor Matching Network**  
> An AI-powered, real-time healthcare ecosystem connecting critical patients and emergency rooms with eligible nearby blood donors within seconds.

---

## 📌 Table of Contents
1. [Overview](#-overview)
2. [Ecosystem Architecture](#-ecosystem-architecture)
3. [Domain Subsystems](#-domain-subsystems)
   - [Mobile Client (`/app`)](#1-mobile-client-app)
   - [Backend Microservice (`/backend`)](#2-backend-microservice-backend)
   - [Admin Web Console (`/frontend`)](#3-admin-web-console-frontend)
   - [Machine Learning Engine (`/ml`)](#4-machine-learning-engine-ml)
4. [Documentation Hub (`/docs`)](#-documentation-hub-docs)
5. [Core Features](#-core-features)
6. [Repository Structure](#-repository-structure)
7. [Getting Started & Local Setup](#-getting-started--local-setup)
   - [Prerequisites](#prerequisites)
   - [1. Backend Setup](#1-backend-setup)
   - [2. Mobile App Setup](#2-mobile-app-setup)
   - [3. Frontend Web Setup](#3-frontend-web-setup)
   - [4. ML Service Setup](#4-ml-service-setup)
8. [Deployed Endpoints & Cloud Infrastructure](#-deployed-endpoints--cloud-infrastructure)
9. [Tech Stack](#-tech-stack)
10. [Development Team & Contributors](#-development-team--contributors)
11. [License](#-license)

---

## 📖 Overview

In critical medical emergencies, traumas, and scheduled surgeries, locating compatible blood units and willing donors is time-sensitive. Conventional blood banks often suffer from communication delays, unverified donor lists, and fragmented geographic coordination.

**LifeLink** solves this with a unified, cross-platform emergency dispatch network:
- **Instant SOS Dispatch**: Requesters create urgent requests with clinical patient vitals and hospital GPS coordinates.
- **Biomedical Compatibility Matrix**: System filters candidate donors based on antigen compatibility (ABO & Rh factor) and geographic proximity.
- **AI-Driven Triage & Prioritization**: Dual machine learning models evaluate clinical urgency (Model 2) and score donor response probability (Model 1) to ensure the fastest possible response.
- **Lifecycle Coordination**: Live in-app notifications, dispatch tracking, tactical radar sweep visualization, and automated status synchronization.

---

## 🏗️ Ecosystem Architecture

```
                                  +---------------------------------------+
                                  |         LifeLink Ecosystem            |
                                  +---------------------------------------+
                                                      |
           +--------------------------+---------------+--------------------------+
           |                          |                                          |
           v                          v                                          v
+---------------------+    +---------------------+                    +---------------------+
|   Mobile Client     |    |  Admin Web Console  |                    |  ML Microservices   |
|     (Flutter)       |    |   (React 19/Vite)   |                    |  (FastAPI / Render) |
| - Requesters        |    | - Real-time metrics |                    | - Donor Ranking     |
| - Donors            |    | - Request audits    |                    | - Urgency Triage    |
| - Tactical Radar    |    | - User management   |                    +----------+----------+
+----------+----------+    +----------+----------+                               ^
           |                          |                                          |
           +--------------------------+                                          |
                                      | HTTP / REST (JWT)                        |
                                      v                                          |
                         +--------------------------+                            |
                         |   Backend REST Service   |----------------------------+
                         |     (Node.js/Express)    |
                         | - Auth & Role Middleware |
                         | - Blood Dispatch Engine  |
                         | - Notification Broker    |
                         +------------+-------------+
                                      |
                                      v
                         +--------------------------+
                         |      Database Layer      |
                         |     (MongoDB Atlas)      |
                         +--------------------------+
```

---

## 🧩 Domain Subsystems

LifeLink is structured into dedicated, decoupled domain folders:

### 1. Mobile Client (`/app`)
* **Technology**: Flutter 3.13+ / Dart 3.1+ (Android, iOS, Web).
* **State Management**: Reactive state management built on `ChangeNotifier` and `Provider` (`AuthProvider`, `RequestProvider`, `AlertProvider`, `DonorProvider`, `TrackingProvider`, `NotificationProvider`, `HistoryProvider`).
* **Navigation**: Declarative routing via `GoRouter` with auth guards, dynamic redirect on state changes (`refreshListenable`), and a persistent bottom navigation shell.
* **Tactical Medical Radar & Street Map (`LifeLinkMapView`)**: Cross-platform tactical medical radar and street map component with OSM & ESRI tile providers. Visualizes live dispatch radiuses (10 km concentric ranges, pulse sweep animations, and tactical blueprint grid toggle) with zero watermarks or paid API billing constraints on Android, iOS, and Web.
* **Dual Operation Mode**: Powered by a central `ApiClient` that connects to the live deployed cloud backend, with an embedded local `MockApi` for zero-downtime offline demonstrations.

### 2. Backend Microservice (`/backend`)
* **Technology**: Node.js, Express 5, Mongoose, JWT, Bcrypt.
* **Role-Based Access Control (RBAC)**: Secure access gating for `requester`, `donor`, and `admin` roles.
* **Core Modules**:
  * `auth`: User registration, password hashing, and token issuance.
  * `requests`: Request lifecycle (creation, pagination, single-request inspection, cancellation).
  * `donors`: Profile management, availability switches, and ML demographic collection.
  * `responses`: Donor response handling (`accepted`/`declined`) with conflict detection (HTTP 409).
  * `notifications`: Read/unread counters, batch status updates, and deletion.
  * `ml`: Gateway proxy invoking upstream FastAPI microservices.

### 3. Admin Web Console (`/frontend`)
* **Technology**: React 19, Vite, Oxlint, Modern Vanilla CSS.
* **Features**:
  * Centralized dashboard with real-time analytics on total requests, fulfilled cases, and active donors.
  * Blood request monitoring grid with filterable urgency and fulfillment statuses.
  * Donor registry inspection and operational oversight.

### 4. Machine Learning Engine (`/ml`)
* **Technology**: Python 3.10+, FastAPI, Scikit-learn, Pandas, NumPy, Joblib.
* **Microservices**:
  1. **Donor Ranking Service (Model 1)**: Evaluates shortlisted compatible donors on age, weight, hemoglobin level, total previous donations, and days since last donation to rank them by likelihood of responding (`POST /rank-donors`).
  2. **Urgency Prediction Service (Model 2)**: Analyzes patient clinical vitals (systolic BP, heart rate, SpO2, active bleeding, hemoglobin, required timeframe) to categorize severity into `Low`, `Medium`, `High`, or `Critical` (`POST /predict`).

---

## 📚 Documentation Hub (`/docs`)

All architectural guides, API specifications, and demonstration scripts are located in the [`docs/`](docs) folder:

| Document | Path | Description |
|---|---|---|
| **Architecture Specification** | [`docs/app/architecture.md`](docs/app/architecture.md) | In-depth breakdown of application layers, Provider state architecture, GoRouter navigation guards, polling intervals, and error handling. |
| **API Integration Guide** | [`docs/app/api-integration.md`](docs/app/api-integration.md) | Comprehensive endpoint status matrix, request/response JSON schemas, JWT authentication, and ML service contracts. |
| **Demo Script** | [`docs/app/demo-script.md`](docs/app/demo-script.md) | Structured 3-minute project demonstration narrative, pre-configured test credentials, flow timetable, and emergency troubleshooting. |
| **Viva Notes** | [`docs/app/viva-notes.md`](docs/app/viva-notes.md) | Rapid-fire technical Q&A reference covering state management, network security, polling tradeoffs, tactical radar mapping, and future scope. |
| **UI Screenshots** | [`docs/app/screenshots/`](docs/app/screenshots) | Visual gallery of 18 captured mobile screens (Authentication, Emergency Creation, Tactical Radar Map, Alerts, Tracking, Health Profile). |

---

## ✨ Core Features

* **⚡ Role-Specific Experience**:
  * *Requesters*: Intuitive request builder with hospital pin drop, urgency triage, live timeline tracking, and contact reveal upon donor acceptance.
  * *Donors*: Tailored emergency alert feed filtered by antigen compatibility and city, hospital distance calculation, and health metric tracking.
  * *Admins*: Consolidated metrics and fleet-wide request moderation.
* **🎯 Dual AI Integration**: Automatic urgency classification on request creation and response probability scoring for donor selection.
* **🗺️ Tactical Medical Radar**: Real-time rotating radar sweep, concentric dispatch range rings (25%, 50%, 100%), tactical blueprint grid mode, and interactive hospital pin dropping.
* **🔔 Live Notification Feed**: Lifecycle-aware periodic polling (8s–20s) with unread indicators and emergency sound alert styling without third-party push dependencies.
* **🛡️ Defensive Offline Fallback**: One-click switch (`kUseMockApi`) enabling a complete in-memory mock backend for offline testing.

---

## 📁 Repository Structure

```
LifeLink/
├── app/                        # Flutter mobile & web application
│   ├── lib/
│   │   ├── core/               # Theme tokens, constants, network config
│   │   ├── models/             # Data models (BloodRequest, AppNotification, etc.)
│   │   ├── providers/          # ChangeNotifier state providers
│   │   ├── router/             # GoRouter navigation & auth guards
│   │   ├── screens/            # UI feature screens (auth, requests, alerts, etc.)
│   │   ├── services/           # ApiClient, MockApi, location services
│   │   └── widgets/            # LifeLinkMapView, hospital cards, status chips
│   └── pubspec.yaml            # Flutter dependencies & assets
│
├── backend/                    # Express.js REST API
│   ├── controllers/            # Route controllers (auth, bloodRequest, donor, etc.)
│   ├── middleware/             # JWT auth & requireRole authorization
│   ├── models/                 # Mongoose schemas (User, Donor, BloodRequest, etc.)
│   ├── routes/                 # Express route definitions
│   ├── services/               # Donor matching logic & ML proxy callers
│   └── server.js               # Server entry point & DB connection
│
├── frontend/                   # React 19 + Vite admin web dashboard
│   ├── src/
│   │   ├── pages/              # Dashboard, BloodRequests, Login, Register
│   │   └── App.jsx             # Main routing component
│   └── package.json            # Frontend dependencies
│
├── ml/                         # Machine learning models & microservices
│   ├── main.py                 # FastAPI urgency prediction service
│   ├── requirements.txt        # Python ML dependencies
│   └── *.ipynb                 # Exploratory data analysis & model training notebooks
│
└── docs/                       # Project documentation & assets
    └── app/
        ├── api-integration.md  # Live endpoint statuses & schemas
        ├── architecture.md     # System architecture & component design
        ├── demo-script.md      # Timed walkthrough & test credentials
        ├── viva-notes.md       # Technical defense & evaluation Q&A
        └── screenshots/        # Application interface screenshots
```

---

## 🚀 Getting Started & Local Setup

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (`^3.13.2`)
* [Node.js](https://nodejs.org/) (`^18.x` or `^20.x`) and `npm`
* [Python](https://www.python.org/) (`^3.10.x`) and `pip`
* [MongoDB](https://www.mongodb.com/) (Local instance or MongoDB Atlas URI)

---

### 1. Backend Setup
```bash
cd backend

# Install dependencies
npm install

# Configure environment variables (.env)
# MONGODB_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net/lifelink
# JWT_SECRET=your_jwt_secret_key
# PORT=5000
# URGENCY_ML_BASE_URL=https://model-2-lbjw.onrender.com

# Start backend server
npm start
```
The backend API will run on `http://localhost:5000`.

---

### 2. Mobile App Setup
```bash
cd app

# Fetch packages
flutter pub get

# Run on Chrome (Web)
flutter run -d chrome

# Run on Android / iOS
flutter run -d android

# Build optimized Release APKs (split per CPU architecture)
flutter build apk --split-per-abi
```

> **Build Artifacts**:
> Building with `--split-per-abi` generates targeted, size-optimized binaries in `app/build/app/outputs/flutter-apk/`:
> - `app-arm64-v8a-release.apk` (~18.5 MB) — Optimized for modern 64-bit ARM devices (most Android phones).
> - `app-armeabi-v7a-release.apk` (~16.2 MB) — Optimized for older 32-bit ARM devices.
> - `app-x86_64-release.apk` (~19.9 MB) — Optimized for x86 64-bit Android emulators and Intel chipsets.

> **Configuration Tip**: Toggle `kUseMockApi = true` in `lib/core/config.dart` to test the app offline without running the backend server.

---

### 3. Frontend Web Setup
```bash
cd frontend

# Install dependencies
npm install

# Start Vite development server
npm run dev
```
The admin console will be accessible at `http://localhost:5173`.

---

### 4. ML Service Setup
```bash
cd ml

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Start FastAPI server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
The urgency prediction API docs will be accessible at `http://localhost:8000/docs`.

---

## 🌐 Deployed Endpoints & Cloud Infrastructure

| Service | Environment | Provider | URL |
|---|---|---|---|
| **Backend REST API** | Production | Render | `https://lifelink-backend-8onj.onrender.com` |
| **API Health Check** | Production | Render | `https://lifelink-backend-8onj.onrender.com/api/health` |
| **Model 1: Donor Ranking** | Production | Render | `https://model1-1-l5kq.onrender.com/rank-donors` |
| **Model 2: Urgency Triage** | Production | Render | `https://model-2-lbjw.onrender.com/predict` |

*(Note: Free-tier Render instances spin down after inactivity. Ping `/api/health` prior to testing to wake the container).*

---

## 💻 Tech Stack

* **Client**: Flutter, Dart, GoRouter, Provider, OpenStreetMap, ESRI Tiles, Geolocator
* **Web Dashboard**: React 19, Vite, Oxlint, Vanilla CSS
* **Backend**: Node.js, Express 5, MongoDB, Mongoose, JWT, Bcrypt, Axios
* **Machine Learning**: Python, FastAPI, Scikit-learn, Pandas, NumPy, Joblib, Uvicorn
* **Hosting**: Render Cloud Services, MongoDB Atlas

## 👥 Development Team & Contributors

* **[Shreya Pandey](https://github.com/shreya-pandey2006)** ([@shreya-pandey2006](https://github.com/shreya-pandey2006)) — *Project Lead & Mobile Application (Flutter), Architecture & Documentation*
* **Parv Agarwal** — *Backend Engineering, RESTful APIs & MongoDB Architecture*
* **Rashi Chaurasia** — *Frontend Web Console (React 19 / Vite)*
* **Shaurya Singh** — *Machine Learning Microservices & Model Training (FastAPI)*

---

## 📄 License
This project is developed for educational and demonstration purposes.