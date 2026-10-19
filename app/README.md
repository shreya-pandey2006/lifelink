# LifeLink App 🩸

> Cross-platform Flutter mobile & web client for the LifeLink emergency blood dispatch network.

---

## Features

- **Role-Based Experience**:
  - **Requesters**: Create emergency blood requests, track real-time dispatch progress, view matched donors, and manage active requests.
  - **Donors**: Receive nearby SOS emergency blood alerts, view interactive dispatch maps, accept or decline alerts, and track donation history.
- **Tactical Medical Radar (`LifeLinkMapView`)**: Interactive street map and radar sweep visualizer using OpenStreetMap with ESRI fallback (no watermarks or API lockouts).
- **AI Urgency Triage**: Evaluates patient indicators to classify requests into Normal, Urgent, or Critical severity.
- **Live Notifications & Hotlines**: SOS notifications with sound/siren alerts, unread counts, and speed dials for emergency services (108 Ambulance, 104 Blood Helpline).

---

## Project Structure

```
lib/
├── core/         # Design tokens, theme, constants, and network config
├── models/       # Data models (requests, notifications, users, donors)
├── providers/    # State management with Provider (auth, alerts, tracking, etc.)
├── router/       # App navigation with GoRouter & auth redirect guards
├── screens/      # Feature screens (alerts, auth, home, profile, requests)
├── services/     # API client, device location, ML scoring, and local storage
└── widgets/      # Reusable UI components (LifeLinkMapView, cards, chips)
```

---

## Configuration

Settings are located in `lib/core/`:

- **API Base URL** (`lib/core/config.dart`):
  ```dart
  const kBaseUrl = 'https://lifelink-backend-8onj.onrender.com/api';
  const bool kUseMockApi = false; // set true for offline development
  ```
- **Google Maps API Key** (`lib/core/constants.dart`):
  ```dart
  const kGoogleMapsApiKey = 'AIzaSyBxpvUpDr9k-t-5QVT_XN1BfC4EL3hEce0';
  ```

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.13.2` or later
- Dart SDK `^3.1.0` or later

### Setup & Run
```bash
# Install dependencies
flutter pub get

# Run on Web (Chrome)
flutter run -d chrome

# Run on Mobile
flutter run -d android # or ios
```

### Testing & Linting
```bash
flutter analyze
flutter test
```
