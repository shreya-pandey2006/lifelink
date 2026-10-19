# LifeLink App: Viva Notes

Concise, accurate answers to the technical and architectural questions most likely to be asked about the Flutter mobile application during viva or project evaluation.

---

## 1. Project and Architecture
**What does the app do?**  
LifeLink is an emergency blood dispatch application. Requesters can post urgent blood requests complete with hospital coordinates, severity levels, and clinical vitals. Donors receive alerts matching their blood group and city, view hospital route/distance details, and accept or decline in real time. Both roles receive status updates through a live in-app notification center.

**What did you build yourself?**  
The entire Flutter mobile client: responsive UI in dark-mode medical aesthetics, Provider-based state management, declarative GoRouter navigation with auth guards, the resilient HTTP `ApiClient`, device GPS integration, custom `LifeLinkMapView` tactical radar visualizer, and a full-featured offline `MockApi` engine. I integrated the app with the deployed Node.js/Express backend and FastAPI ML microservices built by the team.

**How is the app structured?**  
In clean layers:
- **Screens**: Presentation only; react to state changes and dispatch user intents.
- **Providers**: Encapsulate state, business logic, and API calls; call `notifyListeners()` on mutations.
- **ApiClient**: Central HTTP transport; handles base URLs, JWT injection, retries, and errors.
- **Backend & ML**: Express.js REST API with MongoDB, communicating with external FastAPI ML services.

---

## 2. State Management
**Why use Provider over Bloc or Riverpod?**  
`Provider` (built on `ChangeNotifier`) is official, lightweight, and offers low cognitive overhead for this scale. It cleanly separates state from UI without requiring boilerplate code generation, while providing granular rebuild control via `context.watch()` and `context.select()`.

**What is the difference between `context.watch<T>()` and `context.read<T>()`?**  
- `context.watch<T>()` subscribes the widget to provider updates, triggering `build()` whenever `notifyListeners()` is called. It must be called inside `build()`.
- `context.read<T>()` retrieves the provider instance once without creating a reactive binding. It is used inside event handlers (e.g., `onPressed`) to trigger methods.

**Why clear providers on logout?**  
To prevent data contamination between sessions. Clearing ensures that when a new user logs in, they never see cached requests, alerts, coordinates, or notifications belonging to the previous account.

---

## 3. Navigation and Routing
**How does `go_router` protect private routes?**  
A top-level `redirect` function checks the user's authentication state before every navigation event. Unauthenticated users trying to access private routes are redirected to `/login`, while authenticated users are prevented from revisiting auth pages.

**What is `refreshListenable` in GoRouter?**  
It links a `Listenable` (here, `AuthProvider`) directly to the router. Whenever `AuthProvider` calls `notifyListeners()` (e.g. on login or token expiration), GoRouter re-runs the redirect logic immediately without manual navigation calls.

**What is a `StatefulShellRoute`?**  
`StatefulShellRoute.indexedStack` maintains a persistent navigation frame (the bottom navigation bar) across multiple tabs, preserving each tab's scroll position and widget state when switching back and forth.

**What is the difference between `context.go()` and `context.push()`?**  
- `context.go()` replaces the current navigation stack with the target route.
- `context.push()` pushes a new screen onto the top of the stack, enabling standard back-button pop behavior.

**Why is `/request/new` declared before `/request/:id` in route definitions?**  
GoRouter evaluates routes in the order they are defined. If `/request/:id` was listed first, the string `"new"` would be captured as a path parameter `:id` instead of matching the creation screen.

---

## 4. Networking and Security
**How does login session persistence work?**  
Upon login, the returned JWT is saved in `SharedPreferences`. When the app starts up, `AuthProvider.init()` reads the saved token and verifies it via `GET /api/auth/me`. If the token is valid, the session is restored without prompting for credentials.

**How is the access token transmitted?**  
`ApiClient` intercepts every outgoing HTTP request and appends the header:  
`Authorization: Bearer <token>`.

**What happens when a token expires?**  
The backend responds with HTTP `401 Unauthorized`. `ApiClient` triggers its `onUnauthorized` callback, which clears local credentials, resets providers, and redirects the user to the login screen.

**Is `SharedPreferences` secure for production storage?**  
No, `SharedPreferences` stores unencrypted XML/plist data. In a production release, `flutter_secure_storage` would be used, leveraging Android Keystore and iOS Keychain for hardware-backed encryption.

**Where is role-based authorization enforced?**  
The Flutter client uses role checks (e.g. `isDonor`) purely for UI convenience and navigation routing. True role security is strictly enforced on the server by backend JWT authentication middleware (`requireRole('requester')`, `requireRole('donor')`).

**How are network errors and cold starts handled?**  
`ApiClient` handles timeouts (up to 45s) and retries on transient 502/503/504 errors (useful when waking Render free-tier instances). It converts low-level socket and HTTP exceptions into user-friendly `ApiException` messages with retry options.

---

## 5. Live Updates and Location
**How do live updates work without push notifications?**  
Using lifecycle-aware periodic polling (`Timer.periodic`). The polling frequency is tailored per screen:
- **Request Tracking**: Every 8 seconds
- **My Requests**: Every 10 seconds
- **Donor Alert Feed**: Every 15 seconds
- **Shell Notification Badge**: Every 20 seconds  
All timers are safely cancelled in `dispose()`.

**What are the tradeoffs of polling vs. WebSockets/Push?**  
Polling introduces a slight latency (up to the interval duration) and consumes more battery/network requests. The production upgrade would be WebSocket (Socket.IO) or Firebase Cloud Messaging (FCM).

**How does map rendering and location picking work?**  
The app uses `LifeLinkMapView`, a high-performance cross-platform tactical medical radar and street map component with OSM & ESRI tile providers. It avoids the paid billing accounts, restricted API keys, and grey watermark lockouts of Google Maps, while working natively across Android, iOS, and Flutter Web. It renders live rotating radar sweeps, concentric distance rings (25%, 50%, 100%), and a tactical blueprint grid toggle. It converts GPS coordinates (latitude/longitude) to screen pixels to place hospital/donor pins and draw the 10 km dispatch radius. Requesters can drop hospital pins interactively, and donors view straight-line hospital distances computed via the Haversine formula.

---

## 6. Machine Learning and Backend Integration
**Where is ML used in LifeLink?**  
LifeLink utilizes two ML microservices hosted on Render:
1. **Donor Ranking Model (Model 1)**: Ranks candidate donors based on `age`, `weight_kg`, `hemoglobin_g_dL`, `total_donations`, and `days_since_last_donation`. The app collects `age`, `weightKg`, and `hemoglobinGDl` on the Donor Health Details screen and posts them via `PATCH /api/donors/ml-details`.
2. **Urgency Prediction Model (Model 2)**: Predicts emergency severity (Low, Medium, High, Critical) from patient clinical vitals submitted during blood request creation.  
*The mobile client never calls the ML services directly; the backend orchestrates ML calls and data enrichment.*

**What is the Mock API and why did you build it?**  
Because the frontend and backend were developed concurrently, `MockApi` was created to simulate the agreed API contract using local device storage. It enforces the same business logic (e.g., blood compatibility matrices, unit limits, 409 conflict checks) and serves as an offline test harness and demo safety net.

**How do you toggle between the live server and mock mode?**  
In `lib/core/config.dart`, change `const bool kUseMockApi = false;` to `true`.

**Which parts use the live backend?**  
User authentication (registration, login, session check), blood requests (creating, listing, single request detail, cancellation), potential donor queries, donor responses (accept/decline), donor profile & availability, ML details, and the full notification lifecycle (list, unread count, mark read, delete) all communicate directly with the live deployed backend. The alert feed aggregates live open requests and notifications.

---

## 7. Limitations and Future Improvements
**What would you improve with more time?**  
1. Replace polling with real-time WebSockets or FCM push notifications.
2. Upgrade credential storage to `flutter_secure_storage`.
3. Add live GPS tracking of dispatched donors on route to the hospital.
4. Implement geospatial query indexing (`$nearSphere`) directly in MongoDB.

**Is LifeLink intended for clinical deployment?**  
No, this is an academic prototype and engineering proof of concept. A production medical dispatch network requires certified hospital integrations, regulatory compliance (HIPAA/GDPR), donor medical screening, and verified emergency dispatch protocols.