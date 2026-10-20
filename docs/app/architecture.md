# LifeLink App: Architecture

The LifeLink mobile app is built with Flutter. It lets requesters post urgent blood requests and lets donors respond to them. This document explains how the app is organized and why.

## 1. Layers

```
+-----------+     +-----------+     +-----------+     +-------------+     +---------+
|  Screens  | --> | Providers | --> | ApiClient | --> | Express API | --> | MongoDB |
|  (widgets)|     | (state +  |     | (HTTP +   |     | (Node.js,   |     |         |
|           |     |  logic)   |     |  JWT)     |     |  on Render) |     |         |
+-----------+     +-----------+     +-----+-----+     +------+------+     +---------+
      ^                 |                 |                  |
      |  watch / read   |                 |                  +--> ML services (FastAPI/Render)
      +-----------------+                 +--> MockApi (when kUseMockApi = true)

   Flutter app                                   Backend and ML services
```

- **Screens** only display UI and capture user interactions. They never call the network directly.
- **Providers** hold state (current user, requests, alerts, notifications, tracking) and contain business logic. They invoke `ApiClient`, then call `notifyListeners()` to rebuild dependent UI widgets.
- **ApiClient** is the unified HTTP client for the app. It manages base URL prefixing, attaches the JWT bearer token, enforces network timeouts with retry logic, and maps HTTP error status codes into human-readable messages.
- **MockApi** is a self-contained offline mock backend that simulates the backend API contract. A single flag (`kUseMockApi` in `lib/core/config.dart`) toggles between the mock layer and the deployed backend.
- **ML services**: The mobile client communicates with ML indirectly through the backend. The app collects donor health metrics for donor ranking (Model 1) and patient clinical vitals for emergency urgency classification (Model 2).

## 2. Folder structure

```
lib/
  main.dart            App entry point, provider tree initialization & theme config
  core/                Design tokens, theme, constants, formatting helpers, and network config
  models/              AppUser, BloodRequest, AlertItem, Responder, PotentialDonor, AppNotification, Donation
  services/            api_client, mock_api, token_storage, location_service
  providers/           auth, request, alert, donor, tracking, notification, history
  router/              App navigation routes (go_router) and authentication guards
  screens/             auth, home, requests, alerts, notifications, profile, map
  widgets/             Reusable UI (HospitalMap with Google Maps, location cards, status chips)
```

## 3. State management: Provider

Each provider extends `ChangeNotifier` and is registered at the app root in `main.dart` using `MultiProvider`.

- `context.watch<T>()` is used inside `build()` methods to re-render widgets on state changes.
- `context.read<T>()` is used in event handlers (e.g. `onPressed`) to trigger actions without binding to rebuilds.
- On user logout, every provider's `clear()` method runs to eliminate cross-session data leaks.

| Provider | Responsibility |
|---|---|
| `AuthProvider` | Logged-in user, login, register, session persistence, and logout |
| `RequestProvider` | Requester's blood requests, creating requests, and potential donor matching |
| `AlertProvider` | Compatible open blood requests and alerts matching donor blood group/city |
| `DonorProvider` | Availability toggle, GPS location, and health details used by ML ranking |
| `TrackingProvider` | Live request dispatch timeline, hospital coordinates, and responding donors |
| `NotificationProvider` | In-app notification feed, unread counter, read/delete mutations |
| `HistoryProvider` | Donor's past responses and donation record history |

## 4. Navigation: go_router

All application screens are defined as declarative routes in `lib/router/app_router.dart`.

- **Login Guard**: A centralized `redirect` callback evaluates session state prior to navigating. Unauthenticated users are redirected to `/login`, and authenticated users are barred from auth pages.
- **`refreshListenable: auth`**: The router observes `AuthProvider`. When auth state changes, the redirect logic re-evaluates automatically.
- **Splash**: While stored credentials are validated on boot (`initializing == true`), users remain on `/splash`.
- **Bottom Navigation Shell**: `StatefulShellRoute.indexedStack` maintains state across four persistent tabs (Home, Requests/Alerts, Notifications, Profile).
- **Role-Aware Tabs**: The `/requests` route automatically switches between the Donor Alert Feed for donors and "My Requests" for requesters.
- **Modal & Detail Routes**: Full-screen routes outside the tab bar include `/request/new`, `/request/:id`, `/pick-location`, `/alert/:requestId`, `/donor-details`, and `/history`. `/request/new` is registered before `/request/:id` to prevent route parameter collision.

## 5. Authentication flow

1. The user registers or signs in. The server returns a JWT and user profile object.
2. `AuthProvider` stores the JWT in `SharedPreferences` and configures `ApiClient.instance.token`.
3. Every subsequent API request carries `Authorization: Bearer <token>`.
4. On cold start, `AuthProvider.init()` retrieves the saved token and verifies it with `GET /api/auth/me`. If valid, the session is restored instantly.
5. If the backend responds with HTTP `401`, `ApiClient` triggers `onUnauthorized`, clearing providers and sending the user to login.
6. Admin accounts are restricted to the web management console.

## 6. Live updates: Polling

To maintain low latency without third-party push notification dependencies, screens use lifecycle-managed `Timer.periodic` polling that automatically disposes when screens unmount:

| Screen / Component | Interval | Target Endpoint |
|---|---|---|
| Request Tracking Screen | 8 seconds | `GET /api/requests/:requestId` |
| My Requests Screen | 10 seconds | `GET /api/requests` |
| Donor Alert Feed | 15 seconds | `GET /api/requests` & `GET /api/notifications` |
| Main Navigation Shell (Notification Badge) | 20 seconds | `GET /api/notifications/unread-count` |

## 7. Location and maps

- **Geolocator**: Retrieves high-accuracy device GPS coordinates with permission handling via `LocationService`.
- **Google Maps Integration (`google_maps_flutter`)**: Native Google Maps displays hospital locations, donor GPS coordinates, and pin-drop hospital placement across mobile with satellite and street mapping.
- **Pin Placement**: Requesters can drop hospital coordinates interactively on `LocationPickerScreen`, sending precise latitude and longitude with the blood request.
- **Distance Calculation**: Donor alert cards display straight-line distance to the target hospital using Haversine calculation against the donor's saved coordinates.

## 8. Error handling

- `ApiClient` catches timeouts, socket errors, and HTTP status codes, converting them into structured `ApiException` instances with clear error messages.
- Screens implement three core states: Loading (spinner), Error (alert banner with retry button), and Loaded Data (with tailored empty states).
- Models parse JSON defensively (supporting both `id` and `_id`, fallback values, and safe type casting) to prevent parsing crashes.
- Client forms execute field-level validation before network dispatch.

## 9. Mock API

To facilitate offline development and uninterrupted demonstrations, the app includes an embedded `MockApi` engine (`lib/services/mock_api.dart`). It persists mock records in `SharedPreferences`, models blood compatibility matrices, and enforces realistic dispatch states. When `kUseMockApi = true`, no network access is needed.

## 10. Limitations and future work

- Polling introduces small intervals between updates; migrating to WebSocket (Socket.IO) or FCM push notifications would provide instantaneous events with lower battery consumption.
- JWT is stored in standard `SharedPreferences`; production hardening should adopt `flutter_secure_storage` with Android Keystore / iOS Keychain.
- Matching currently filters by city and blood group compatibility with backend ML ranking; distance-based geospatial radius queries (`$nearSphere`) can be introduced in future iterations.
- This application is an educational prototype and demonstration system, not a certified clinical dispatch device.