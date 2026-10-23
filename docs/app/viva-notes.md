# LifeLink App: Viva Notes

Concise, accurate answers to the technical and architectural questions most likely to be asked about the Flutter mobile application during viva or project evaluation.

---

## 1. Project and Architecture
**What does the app do?**  
LifeLink is an emergency blood dispatch application. Requesters post urgent blood requests with hospital coordinates, severity levels, and clinical vitals. Donors receive alerts matching their blood group and dynamic geographic radius, view hospital route/distance details, accept or decline in real time, coordinate directly with requesters, and mark donation completion. Both roles receive status updates through a live in-app notification center.

**What did you build yourself?**  
The entire Flutter mobile client: responsive UI in dark-mode medical aesthetics, Provider-based state management, declarative GoRouter navigation with auth guards, the resilient HTTP `ApiClient`, device GPS integration, native Google Maps integration, dynamic urgency radius filtering, privacy masking boundaries, and a full-featured offline `MockApi` engine. I integrated the app with the deployed Node.js/Express backend and FastAPI ML microservices built by the team.

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

**How does post-acceptance navigation work for donors?**  
When a donor accepts an alert on `AlertDetailScreen`, GoRouter immediately navigates the donor to `/requests/track/:id`. This transitions the donor directly into dispatch mode, showing the hospital map, requester phone dialer, and donation completion checkbox.

**Why is `/request/new` declared before `/request/:id` in route definitions?**  
GoRouter evaluates routes in the order they are defined. If `/request/:id` was listed first, the string `"new"` would be captured as a path parameter `:id` instead of matching the creation screen.

---

## 4. Networking, Security, and Privacy
**How does login session persistence work?**  
Upon login, the returned JWT is saved in `SharedPreferences`. When the app starts up, `AuthProvider.init()` reads the saved token and verifies it via `GET /api/auth/me`. If the token is valid, the session is restored without prompting for credentials.

**How is the access token transmitted?**  
`ApiClient` intercepts every outgoing HTTP request and appends the header:  
`Authorization: Bearer <token>`.

**How does LifeLink protect user privacy?**  
Through mutual privacy boundaries:
1. **Donor Privacy**: In candidate donor listings (`potential-donors`), donor phone numbers and emails are masked (`null`) to protect volunteers from unsolicited calls. Requesters only receive a donor's contact after that donor has voluntarily accepted the alert.
2. **Requester Privacy**: The requester's contact phone number is exposed to a donor only after the donor accepts the request.
3. **Scoped Visibility**: When a donor views the tracking screen, the backend scopes the response array to show only that donor's response, preventing visibility of other donors' identities.

**What happens when a token expires?**  
The backend responds with HTTP `401 Unauthorized`. `ApiClient` triggers its `onUnauthorized` callback, which clears local credentials, resets providers, and redirects the user to the login screen.

**Where is role-based authorization enforced?**  
The Flutter client uses role checks (e.g. `isDonor`) purely for UI convenience and navigation routing. True role security is strictly enforced on the server by backend JWT authentication middleware (`requireRole('requester')`, `requireRole('donor')`).

---

## 5. Live Updates, Maps, and Dynamic Radius
**How do live updates work without push notifications?**  
Using lifecycle-aware periodic polling (`Timer.periodic`). The polling frequency is tailored per screen:
- **Request Tracking**: Every 8 seconds (syncs units accepted and donation status)
- **My Requests**: Every 10 seconds
- **Donor Alert Feed**: Every 15 seconds
- **Shell Notification Badge**: Every 20 seconds  
All timers are safely cancelled in `dispose()`.

**How does dynamic radius matching work?**  
Matching dynamically adjusts search radius based on patient clinical urgency:
- **Critical / Emergency**: 5 km radius (prioritizes immediate response time)
- **Urgent**: 10 km radius
- **Normal**: 20 km radius  
The Haversine formula calculates real-time distance between hospital GPS coordinates and donor coordinates. Donors outside the respective boundary are filtered out.

**How does map rendering and location picking work?**  
The app integrates `google_maps_flutter` for native, hardware-accelerated mapping across the emergency dispatch flow. It renders destination hospital markers, donor GPS locations, and provides an interactive map picker for dropping precise destination coordinates. Pin placement is synchronized with Geolocator GPS coordinates and city center fallbacks.

---

## 6. Donation Lifecycle and Completion
**How is the donation lifecycle verified and closed?**  
1. When the donor arrives at the hospital and completes donation, they check the **"Mark as Donated"** toggle on the Tracking Screen.
2. The app invokes `PATCH /api/responses/:requestId/donation-status` with `{ "donated": true }`.
3. The backend logs the timestamp `donatedAt`, updates the donor's profile (`lastDonationDate`, increments `totalDonations`), and automatically sends an in-app notification to the requester.
4. When all required units are matched, the request status updates to `matched`.

---

## 7. Machine Learning and Backend Integration
**Where is ML used in LifeLink?**  
LifeLink utilizes two ML microservices hosted on Render:
1. **Donor Ranking Model (Model 1)**: Ranks candidate donors based on `age`, `weight_kg`, `hemoglobin_g_dL`, `total_donations`, and `days_since_last_donation`. The app collects `age`, `weightKg`, and `hemoglobinGDl` on the Donor Health Details screen and posts them via `PATCH /api/donors/ml-details`.
2. **Urgency Prediction Model (Model 2)**: Predicts emergency severity (Low, Medium, High, Critical) from patient clinical vitals submitted during blood request creation.  
*The mobile client never calls the ML services directly; the backend orchestrates ML calls and data enrichment.*

**What is the Mock API and why did you build it?**  
Because the frontend and backend were developed concurrently, `MockApi` was created to simulate the agreed API contract using local device storage. It enforces the same business logic (e.g., blood compatibility matrices, unit limits, 409 conflict checks) and serves as an offline test harness and demo safety net.

**How do you toggle between the live server and mock mode?**  
In `lib/core/config.dart`, change `const bool kUseMockApi = false;` to `true`.

---

## 8. Limitations and Future Improvements
**What would you improve with more time?**  
1. Replace polling with real-time WebSockets (Socket.IO) or Firebase Cloud Messaging (FCM) push notifications.
2. Upgrade credential storage to `flutter_secure_storage`.
3. Add turn-by-turn routing with Google Directions API displaying live polyline routes for dispatched donors.
4. Integrate biometric authentication (fingerprint/Face ID) for rapid emergency login.

**Is LifeLink intended for clinical deployment?**  
No, this is an academic prototype and engineering proof of concept. A production medical dispatch network requires certified hospital integrations, regulatory compliance (HIPAA/GDPR), donor medical screening, and verified emergency dispatch protocols.