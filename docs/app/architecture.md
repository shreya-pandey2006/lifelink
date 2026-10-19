# LifeLink App: Architecture

The LifeLink mobile app is built with Flutter. It lets requesters post urgent blood requests and lets donors respond to them. This document explains how the app is organised and why.

## 1. Layers

```
+-----------+     +-----------+     +-----------+     +-------------+     +---------+
|  Screens  | --> | Providers | --> | ApiClient | --> | Express API | --> | MongoDB |
|  (widgets)|     | (state +  |     | (HTTP +   |     | (Node.js,   |     |         |
|           |     |  logic)   |     |  JWT)     |     |  on Render) |     |         |
+-----------+     +-----------+     +-----+-----+     +------+------+     +---------+
      ^                 |                 |                  |
      |  watch / read   |                 |                  +--> ML service (FastAPI)
      +-----------------+                 +--> MockApi (when kUseMockApi = true)

   Flutter app (my domain)                       Backend and ML (teammates)
```

- **Screens** only show data and react to taps. They never call the network directly.
- **Providers** hold the state (current user, requests, alerts, notifications) and contain the logic. They call `ApiClient`, then call `notifyListeners()` so the screens rebuild.
- **ApiClient** is the only file that knows the server address. It adds the JWT to every request, applies a timeout, and turns network and server errors into readable messages.
- **MockApi** is a built-in fake backend that returns the same JSON as the agreed API contract. A single switch (`kUseMockApi` in `lib/core/config.dart`) chooses between the mock and the real server.
- The app **never calls the ML service**. The backend calls it to rank donors. The app only collects the donor details the model needs (age, weight, hemoglobin, days since last donation).

## 2. Folder structure

```
lib/
  main.dart            starts the app and registers the providers
  core/                config, constants, theme, formatting helpers
  models/              AppUser, BloodRequest, AlertItem, Responder, AppNotification, Donation
  services/            api_client, mock_api, token_storage, location_service
  providers/           auth, request, alert, donor, tracking, notification, history
  router/              all go_router routes and the login guard
  screens/             auth, home, requests, alerts, notifications, profile, map
  widgets/             shared UI pieces (cards, chips, maps)
```

## 3. State management: Provider

Each provider is a `ChangeNotifier` class registered once in `main.dart` with `MultiProvider`.

- `context.watch<T>()` is used inside `build`. The widget rebuilds when the provider changes.
- `context.read<T>()` is used in callbacks such as `onPressed`. It calls a method without rebuilding.
- On logout, every provider's `clear()` runs, so the next user never sees someone else's data.

| Provider | Responsibility |
|---|---|
| AuthProvider | Logged-in user, login, register, logout, saved-token check at start |
| RequestProvider | A requester's own requests, creating requests, donor responses |
| AlertProvider | Open requests that match a donor, accept and decline |
| DonorProvider | Availability, location, health details used by the ML ranking |
| TrackingProvider | One request with its timeline and responded donors |
| NotificationProvider | Notification list and unread count |
| HistoryProvider | A donor's donation history |

## 4. Navigation: go_router

All screens are routes with paths, defined in `lib/router/app_router.dart`.

- **Login guard:** the `redirect` function runs before every navigation. Logged-out users are always sent to `/login`, and logged-in users never see `/login`.
- **`refreshListenable: auth`:** the router re-runs the redirect whenever `AuthProvider` calls `notifyListeners()`. Logging in or out therefore changes the screen automatically.
- **Splash:** while the saved token is being checked (`initializing = true`), the router keeps the user on `/splash`.
- **Bottom tabs:** `StatefulShellRoute.indexedStack` builds the four tabs (Home, Requests, Alerts, Profile). Each tab keeps its own state.
- **Role-aware tab:** `/requests` shows the donor alert feed to donors and "My Requests" to requesters.
- **Full-screen routes** sit outside the tabs: `/request/new`, `/request/:id`, `/pick-location`, `/alert/:requestId`, `/donor-details`, `/history`. `/request/new` is declared before `/request/:id` so `:id` does not capture the word "new".

## 5. Authentication flow

1. The user registers or logs in. The server returns a JWT and the user.
2. `AuthProvider` saves the token with `shared_preferences` and gives it to `ApiClient`.
3. Every later request sends `Authorization: Bearer <token>`.
4. When the app starts, `AuthProvider.init()` reads the saved token and calls `GET /auth/me`. If the server accepts it, the user goes straight to Home.
5. If the server answers `401`, `ApiClient` calls `onUnauthorized` and the user is logged out.
6. Admin accounts are refused in the app, because admins use the web dashboard.

## 6. Live updates: polling

The app does not use push notifications. A `Timer.periodic` asks the server again at a fixed interval, and is cancelled in `dispose()`.

| Screen | Interval |
|---|---|
| My Requests | 10 seconds |
| Donor alert feed | 8 seconds |
| Request tracking | 8 seconds |
| Notifications (unread badge) | 15 seconds |

## 7. Location and maps

- **Geolocator** reads the phone's GPS. `LocationService` checks that location is on, asks for permission, and turns failures into messages that are safe to show.
- **Google Maps SDK** (`google_maps_flutter`) shows the map. The requester taps the map or uses GPS to place the hospital pin, and the latitude and longitude are sent with the request.
- Donors save their location from the Profile tab. Alert cards then show the straight-line distance to the hospital.
- The Maps API key is stored in `AndroidManifest.xml` and restricted to the app's package name and signing certificate.

## 8. Error handling

- `ApiClient` converts timeouts, connection failures and bad responses into an `ApiException` with a readable message.
- Every screen that loads data has three states: loading (spinner), error (message and "Try again"), and data (or an empty state).
- Models read JSON defensively (`id` or `_id`, default values), so a missing field does not crash a screen.
- Forms validate input before anything is sent.

## 9. Mock API

The backend was built in parallel with the app, so the app includes `MockApi`. It stores users, requests, responses and notifications with `shared_preferences`, enforces the same rules as the real contract (matching blood group and city, units, 409 when a request is already covered), and creates notifications. This let every screen be built and tested before the real server was ready, and it is the fallback for the demo if the network fails.

## 10. Limitations and future work

- Polling has a small delay and uses extra battery. Socket.IO or Firebase Cloud Messaging would give instant updates.
- The JWT is stored in `shared_preferences`, which is not encrypted. `flutter_secure_storage` would be used in production.
- Matching is by city and blood group, with ML ranking done by the backend. Distance-based matching with geo queries is a possible upgrade.
- Some features depend on backend routes that are not available yet (see `api-integration.md`).
- This is a college demo. It is not a medical screening tool.