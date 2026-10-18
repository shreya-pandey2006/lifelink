# LifeLink Mobile & Web App 🩸

> **Real-Time Emergency Blood Dispatch & Donor Network**  
> Built with Flutter, Material 3, and AI-Driven Triage.

---

## 📌 Overview

**LifeLink App** is a cross-platform mobile and web application designed to eliminate critical response delays during blood emergencies. The application connects patients, hospitals, and emergency responders directly with compatible, verified blood donors within a tactical geographic radius.

Powered by a responsive Material 3 design system, real-time dispatch radar, declarative navigation, and integrated AI urgency scoring, LifeLink delivers a mission-critical experience for both blood requesters and voluntary donors.

---

## 🌟 Key Features

### 👤 Role-Based Experience

LifeLink adapts dynamically based on user identity:

| Feature Area | Blood Requester View | Blood Donor View |
| :--- | :--- | :--- |
| **Primary Dashboard** | **Emergency Request Hub** with active, fulfilled, and total statistics | **Tactical Dispatch Radar** with live availability status |
| **Actions** | Create SOS blood requests, monitor donor responses, mark requests fulfilled | Browse nearby emergency alerts, view route to hospital, accept/decline calls |
| **Tracking** | Step-by-step dispatch timeline, matched unit progress bar, responder contacts | View logged donation history, track lives impacted |
| **Screening & Health** | Hospital directory & blood bank contacts | Medical eligibility screening (age, weight, hemoglobin, donation cooldown) |

---

### 🚨 Emergency Blood Requests & AI Triage
- **Fast-Track Request Creation**: Create emergency requests specifying blood group, units required, hospital location, and contact information.
- **AI Urgency Assessment**: Integrates machine learning services to evaluate patient age, clinical indicators, and required timeframes to triage requests into **Normal**, **Urgent**, or **Critical**.
- **Real-Time Request Tracking**:
  - Live timeline tracking: `Broadcast Sent` ➔ `Donors Accepted` ➔ `Units Matched` ➔ `Blood Transfusion Fulfilled`.
  - Linear unit progress bar displaying matched versus requested units.
  - Responder roster with direct phone dialer and copy-to-clipboard utilities.
  - One-tap cancellation or fulfillment workflows.

---

### 📡 Tactical Medical Radar & Interactive Maps (`LifeLinkMapView`)
- **Dual-Mode Visualizer**: Switch seamlessly between interactive street mapping and an animated military/medical radar sweep.
- **Zero-Dependency Architecture**: Built on Web Mercator projection using **OpenStreetMap (OSM)** with **ESRI World Street Map** fallback.
- **Concentric Range Rings**: Visualizes donor dispatch radius at 2.5 km, 5.0 km, 7.5 km, and 10.0 km intervals.
- **Interactive Controls**: Touch/click zoom controls (`+` / `−`), view toggling, and instant pin recentering across Mobile and Web.

---

### 🔔 Live Emergency Notifications Hub
- **SOS Alert System**: Broadcast notifications for incoming blood requirements with optional audio siren triggers.
- **Smart Filtering**: Categorize alerts by `All`, `Emergency`, and `General`.
- **Triage Actions**: Optimistic "Mark all read", swipe-to-delete dismissals, and direct navigation to request details.
- **Emergency Speed Dial**: Immediate modal access to national emergency hotlines (108 Ambulance, 104 Blood Helpline).

---

## 🏗️ Architecture & Project Structure

The application follows the **Provider State Management** pattern combined with clean layered separation:

```
app/
├── android/                   # Native Android host configuration
├── ios/                       # Native iOS host configuration
├── web/                       # Web runner, PWA manifest, and index.html
├── test/                      # Unit and widget test suite
│   ├── notification_provider_test.dart
│   └── notifications_screen_test.dart
└── lib/
    ├── core/                  # Design tokens, theme, and global constants
    │   ├── config.dart        # Backend API URLs and offline mock toggle
    │   ├── constants.dart     # Blood compatibility rules, city coordinates, map keys
    │   ├── format.dart        # Relative timeAgo and date utilities
    │   └── theme.dart         # Material 3 theme palette, custom cards, and styling
    ├── models/                # Strongly-typed data models
    │   ├── alert_item.dart          # Emergency alert item representation
    │   ├── app_notification.dart    # System and emergency notifications
    │   ├── app_user.dart            # Authenticated user profile entity
    │   ├── blood_request.dart       # Blood request details and AI triage metadata
    │   ├── donation.dart            # Completed donation history record
    │   ├── donor_response_item.dart # Donor dispatch response entity
    │   ├── potential_donor.dart     # AI-matched candidate model
    │   └── responder.dart           # Responder identity and contact details
    ├── providers/             # ChangeNotifier business logic and state stores
    │   ├── alert_provider.dart        # Real-time donor alerts and dispatch actions
    │   ├── auth_provider.dart         # JWT authentication, session, and role state
    │   ├── donor_provider.dart        # Donor status, health indicators, and GPS
    │   ├── history_provider.dart      # Donation history and impact metrics
    │   ├── notification_provider.dart # Emergency notification feed and unread badge
    │   ├── request_provider.dart      # Requester blood requests and management
    │   └── tracking_provider.dart     # Polling and live dispatch tracking
    ├── router/                # Declarative routing
    │   └── app_router.dart    # GoRouter with authentication redirect guards
    ├── screens/               # User interface views
    │   ├── alerts/            # BloodAlertsScreen & AlertDetailScreen
    │   ├── auth/              # LoginScreen, RegisterScreen, SplashScreen
    │   ├── home/              # HomeScreen & MainShell navigation bar
    │   ├── map/               # LocationPickerScreen
    │   ├── notifications/     # NotificationsScreen
    │   ├── profile/           # ProfileScreen, DonorDetailsScreen, HistoryScreen
    │   └── requests/          # CreateRequestScreen, MyRequestsScreen, RequestTrackingScreen
    ├── services/              # External interfaces and hardware access
    │   ├── api_client.dart       # HTTP client with JWT interceptor and error handling
    │   ├── location_service.dart # Geolocator GPS queries and Haversine distance math
    │   ├── ml_service.dart       # AI urgency prediction and donor scoring API
    │   ├── mock_api.dart         # Offline development fallback provider
    │   └── token_storage.dart    # SharedPreferences secure credential persistence
    ├── widgets/               # Reusable atomic UI components
    │   ├── alert_card.dart          # Dispatch alert card with map preview
    │   ├── city_search_field.dart   # City autocomplete search input
    │   ├── hospital_map.dart        # Hospital location radar container
    │   ├── lifelink_map_view.dart   # Canvas radar and OSM/ESRI map visualizer
    │   ├── location_card.dart       # Map pin selector card
    │   ├── request_card.dart        # Blood request card with action buttons
    │   ├── status_chip.dart         # Live pulsing status indicators
    │   ├── ui.dart                  # PrimaryButton, AppCard, FieldLabel, Pill
    │   └── urgency_pill.dart        # Urgency level badges
    └── main.dart              # MultiProvider bootstrap and MaterialApp entry point
```

---

## 🎨 Design System

LifeLink utilizes a custom Material 3 palette tuned for medical urgency and clear visibility:

- **Primary Crimson**: `#D42A40` (Hero buttons, SOS accents)
- **Primary Dark**: `#A50F2D` (Header bars, critical badges)
- **Primary Soft**: `#FDE7EA` (Pill backgrounds, active tabs)
- **Background**: `#FBF8FD` (Clean high-contrast background)
- **Ink / Typography**: `#1B1B1F` (Dark high-readability text)
- **Muted**: `#6E6E78` (Secondary metadata and subheadings)
- **Amber Warning**: `#B7791F` / `#FFE6C2` (Urgent triage indicators)

---

## ⚙️ Configuration & Environment

Configuration parameters are organized in `lib/core/`:

### 1. Backend API Endpoint
Edit `lib/core/config.dart`:
```dart
// Points to the live LifeLink backend on Render or local Node.js server
const kBaseUrl = 'https://lifelink-backend-8onj.onrender.com/api';

// Set to true to run fully offline with simulated in-memory responses
const bool kUseMockApi = false;
```

### 2. Google Maps API Key
Located in `lib/core/constants.dart`:
```dart
const kGoogleMapsApiKey = 'AIzaSyBxpvUpDr9k-t-5QVT_XN1BfC4EL3hEce0';
```
*(Also synchronized in `web/index.html` and `android/app/src/main/AndroidManifest.xml`)*.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.2` or later)
- [Dart SDK](https://dart.dev/get-dart) (`^3.1.0` or later)
- Android Studio / Xcode (for mobile emulation) or Google Chrome (for Web)

### 1. Clone & Navigate
```bash
cd app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Verify Code Quality
Run static analysis and test suite:
```bash
# Analyze static typing and lints
flutter analyze

# Run unit and widget test suite
flutter test
```

### 4. Run the Application

#### Web (Chrome)
```bash
flutter run -d chrome
```

#### Android
```bash
flutter run -d android
```

#### iOS
```bash
flutter run -d ios
```

---

## 🧪 Testing

The app includes automated test coverage for core business logic, asynchronous providers, and interactive widgets:

- **`test/notification_provider_test.dart`**: Tests unread counter synchronization, optimistic updates, pagination, and deletion APIs with mock HTTP backends.
- **`test/notifications_screen_test.dart`**: Validates widget rendering, filter tabs, "Mark all read" state changes, and swipe-to-delete gestures.

Run all tests with:
```bash
flutter test
```

---

## 📄 License

This project is part of the **LifeLink** emergency response network. All rights reserved.
