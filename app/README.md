# LifeLink App 🩸

> **Cross-Platform Emergency Blood Dispatch & Donor Response Mobile Client**  
> Built with Flutter 3.13+, Dart 3.1+, Provider, GoRouter, and native Google Maps integration.

---

## 📌 Overview

The **LifeLink App** is the mobile and web client for the LifeLink emergency blood dispatch network. Designed for high-stress medical emergencies, it connects hospitals, trauma centers, and families with compatible, willing blood donors within a dynamic geographic radius in minutes.

The app provides two tailored, role-based workflows:
1. **Requesters**: Create urgent blood requests with clinical patient vitals and hospital GPS coordinates, inspect ML-ranked candidate donors, and monitor live dispatch progress.
2. **Donors**: Receive nearby SOS emergency blood alerts matching their ABO/Rh blood compatibility and location, view hospital directions on interactive Google Maps, accept or decline dispatch requests, coordinate with requesters, and track their life-saving donation history.

---

## ✨ Key Features

### 1. ⚡ Role-Based Workflows
- **Emergency Requesters**:
  - Multi-step request creation with blood group, units required, and patient vitals.
  - Interactive hospital pin-drop location picker (`LocationPickerScreen`) with automatic GPS detection.
  - Live dispatch tracking (`/requests/track/:id`) displaying accepted donors, matched units, and hospital destinations.
  - Direct telephone calling to accepted donors once dispatched.
  - Safe cancellation of open or matched requests.
- **Volunteer Donors**:
  - Filtered emergency alert feed matching blood group compatibility and city.
  - Real-time notification center with SOS sound/siren alerts and unread counters.
  - One-tap alert acceptance that immediately navigates the donor to the live **Tracking Screen**.
  - **Requester Contact Reveal**: Direct phone dialer and coordinator name displayed upon alert acceptance.
  - **Donation Completion Checkbox**: In-app "Mark as Donated" toggle (`PATCH /api/responses/:requestId/donation-status`) that logs donation timestamp, increments total donations on the donor profile, updates last donation date, and automatically notifies the requester.
  - Profile management with donor availability toggle and ML health metric entry.

### 2. 🗺️ Interactive Medical Dispatch Maps (`Google Maps`)
- Powered by `google_maps_flutter` for native, hardware-accelerated mapping across Android, iOS, and Web.
- Hospital destination markers, patient trauma coordinates, and donor GPS location visualization.
- Interactive pin placement with automatic reverse-geocoding fallback to city center coordinates.
- Straight-line distance calculation using the Haversine formula to show donors proximity to the medical facility.

### 3. 🛡️ Dynamic Clinical Radius Matching & Donor Privacy
- **Clinical Urgency Radius Tiers**:
  - **Critical / Emergency**: Shortlists donors within a strict **5 km** radius for fastest arrival.
  - **Urgent**: Shortlists donors within a **10 km** radius.
  - **Normal**: Shortlists donors within a **20 km** radius.
- **Strict Privacy Safeguards**:
  - Potential donor phone numbers and emails are shielded (`null`) from requesters until the donor explicitly accepts the alert.
  - Donors querying request details only see their own response record to prevent exposing other volunteers' identities.
  - Requester contact details (phone and name) are strictly revealed only to donors who have accepted the request.

### 4. 🧠 Dual Machine Learning Integration
- **Model 1: Donor Response Probability Ranking**:
  - The app captures donor demographics (`age`, `weightKg`, `hemoglobinGDl`) in the Profile section.
  - Backend invokes FastAPI ML microservices (`POST /rank-donors`) to score candidate donors by response likelihood.
- **Model 2: Emergency Urgency Triage**:
  - Requesters input clinical vitals (systolic BP, heart rate, SpO2, active bleeding, hemoglobin level, required timeframe).
  - Automated ML evaluation classifies urgency into `Normal`, `Urgent`, or `Critical`.

### 5. 🚨 Emergency Hotlines & Sound Alerts
- Built-in speed dials for public emergency services:
  - **108**: Emergency Ambulance Service
  - **104**: Blood Helpline / Medical Consultation
- Audible SOS siren and sound indicators for high-urgency notifications.

### 6. 🔄 Dual Mode Operation: Live Cloud & Offline Mock
- Connects to the live deployed REST API on Render (`https://lifelink-backend-8onj.onrender.com/api`).
- Embedded **`MockApi`** engine (`kUseMockApi = true` in `lib/core/config.dart`) simulating all database models, authentication, blood compatibility rules, and responses in local device storage for offline demos and testing.

---

## 🏗️ Architecture & Project Structure

The mobile application follows a strict layered architecture:

```
lib/
├── core/                   # Design tokens, theme, constants, network config, formatters
│   ├── config.dart         # API Base URL and kUseMockApi toggle
│   ├── constants.dart      # Colors, typography, Google Maps API key, blood groups
│   ├── format.dart         # Date, distance, and string formatting helpers
│   └── theme.dart          # Medical dark-mode theme configuration
├── models/                 # Strongly-typed data models with defensive JSON parsing
│   ├── alert_item.dart     # Donor emergency alert feed item
│   ├── app_notification.dart # In-app notification model with unread state
│   ├── app_user.dart       # User authentication & role entity
│   ├── blood_request.dart  # Request entity with patient vitals & hospital coordinates
│   ├── donation.dart       # Donor past donation history record
│   ├── potential_donor.dart# Candidate donor record with ML response probability
│   └── responder.dart      # Dispatched donor response & completion status
├── providers/              # Reactive state management extending ChangeNotifier
│   ├── alert_provider.dart # Donor alert feed & compatibility filtering
│   ├── auth_provider.dart  # User authentication, JWT storage & session restore
│   ├── donor_provider.dart # Donor profile, availability toggle & ML health metrics
│   ├── history_provider.dart# Donor past donation history
│   ├── notification_provider.dart # Notification feed, unread counter & polling
│   ├── request_provider.dart# Blood request creation & requester listing
│   └── tracking_provider.dart # Live dispatch tracking, donation completion & radius logic
├── router/                 # Declarative navigation with GoRouter
│   └── app_router.dart     # Routes, auth redirect guards & StatefulShellRoute bottom nav
├── screens/                # User interface screens organized by feature domain
│   ├── alerts/             # AlertDetailScreen (hospital map, distance, accept/decline)
│   ├── auth/               # LoginScreen, RegisterScreen, SplashScreen
│   ├── home/               # HomeScreen (role-based dashboard & emergency stats)
│   ├── map/                # LocationPickerScreen (interactive Google Maps pin drop)
│   ├── notifications/      # NotificationsScreen (live notifications & unread badges)
│   ├── profile/            # ProfileScreen, DonorHealthDetailsScreen, HistoryScreen
│   └── requests/           # CreateRequestScreen, MyRequestsScreen, RequestTrackingScreen
├── services/               # Infrastructure & external integration services
│   ├── api_client.dart     # Unified HTTP client with JWT interceptor & retry logic
│   ├── location_service.dart# Geolocator GPS coordinator & permission handler
│   ├── mock_api.dart       # Complete in-memory offline mock backend engine
│   └── token_storage.dart  # SharedPreferences JWT persistence
└── widgets/                # Reusable UI components
    ├── city_search_field.dart # Searchable Indian cities autocomplete dropdown
    ├── hospital_map.dart   # Embedded Google Maps widget with destination marker
    ├── potential_donors_sheet.dart # Bottom sheet displaying ML-ranked candidate donors
    ├── request_card.dart   # Request preview card with urgency badges
    └── status_chip.dart    # Color-coded urgency and status indicators
```

---

## ⚙️ Configuration & Environment

Settings are maintained in `lib/core/`:

### 1. API & Backend Toggle (`lib/core/config.dart`)
```dart
// Set to false for live Render cloud backend; set to true for offline mock
const bool kUseMockApi = false;

// Production REST API Base URL
const kBaseUrl = 'https://lifelink-backend-8onj.onrender.com/api';
```

### 2. Google Maps API Key (`lib/core/constants.dart`)
```dart
const kGoogleMapsApiKey = 'AIzaSyBxpvUpDr9k-t-5QVT_XN1BfC4EL3hEce0';
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.13.2` or later
- **Dart SDK**: `^3.1.0` or later
- Android Studio / Xcode / Google Chrome (for Web)
- A connected physical device or emulator with Location Services enabled

### Installation & Execution

```bash
# 1. Clone repository and navigate to app folder
cd app

# 2. Fetch Flutter packages
flutter pub get

# 3. Run on Chrome (Web)
flutter run -d chrome

# 4. Run on Android Device / Emulator
flutter run -d android

# 5. Run on iOS Simulator
flutter run -d ios
```

### Building Production Release Binaries

To produce size-optimized Android release APKs targeted by CPU architecture:

```bash
flutter build apk --split-per-abi
```

Target binaries will be output to `app/build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (~18.5 MB) — Modern 64-bit ARM devices (most Android phones).
- `app-armeabi-v7a-release.apk` (~16.2 MB) — Older 32-bit ARM devices.
- `app-x86_64-release.apk` (~19.9 MB) — Android emulators and Intel chipsets.

---

## 🧪 Testing & Verification

The application includes unit tests, widget tests, and code analysis suites:

```bash
# Run static analysis and linting
flutter analyze

# Run all test suites
flutter test

# Run location radius filtering unit tests
flutter test test/radius_filter_test.dart

# Run notification provider unit tests
flutter test test/notification_provider_test.dart
```

### Verified Test Suites
- `test/radius_filter_test.dart`: Validates dynamic radius boundary calculations for Critical (5 km), Urgent (10 km), and Normal (20 km) urgency tiers.
- `test/notification_provider_test.dart`: Validates in-app notification parsing, unread badge calculation, and read state synchronization.
- `test/widget_test.dart`: Tests widget hierarchy and initial screen rendering.

---

## 🛡️ Security & Privacy Architecture

- **Token Interception**: `ApiClient` automatically injects `Authorization: Bearer <JWT>` on all authenticated endpoints.
- **Automated Session Invalidation**: HTTP `401 Unauthorized` responses immediately clear all providers and route users back to `/login`.
- **Contact Masking**: Candidate donor phone numbers are strictly protected until the donor accepts the request.
- **Requester Protection**: Requesters' contact numbers and precise trauma center coordinates are disclosed only to confirmed, accepted donors.
- **Provider Isolation**: Provider states are cleared on logout to prevent cross-account data leaks.

---

## 📄 License
This project is developed for educational and demonstration purposes.
