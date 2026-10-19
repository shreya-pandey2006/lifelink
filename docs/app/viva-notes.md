# LifeLink App: Viva Notes

Short answers to the questions most likely to be asked about the app.

## Project and design
**What does the app do?**
Requesters post urgent blood requests with a hospital location. Donors see requests that match their blood group and city, and accept or decline. Everyone gets updates through a notifications screen.

**What did you build yourself?**
The whole Flutter app: screens in the Stitch design, state management, navigation, the API client, location and maps, notifications, and a mock API. I integrated it with the backend my teammate built.

**How is the app structured?**
In layers: screens, providers, one API client, then the server. Screens never call the network. Providers hold state and logic. The API client handles the server address, JWT, timeouts and errors.

## State management
**Why Provider?**
A `ChangeNotifier` holds the data and calls `notifyListeners()` when it changes, so the widgets that watch it rebuild. It is simple, official, and enough for this app.

**What is the difference between `watch` and `read`?**
`watch` is used in `build` and rebuilds the widget when the value changes. `read` is used in callbacks and only gets the provider to call a method.

**Why clear the providers on logout?**
So the next user never sees the previous user's requests, alerts or notifications.

## Navigation
**How does go_router protect screens?**
The `redirect` function runs before every navigation. If the user is logged out, it sends them to `/login`, and if they are logged in, it keeps them away from the login page.

**What is `refreshListenable`?**
It tells the router to run `redirect` again when something changes. I gave it `AuthProvider`, so when the user logs in or out the screen changes by itself.

**What is a shell route?**
It keeps a common frame, here the bottom navigation bar, around several tabs. Each tab keeps its own state.

**What is the difference between `go` and `push`?**
`go` replaces the navigation stack with a new location. `push` opens a screen on top, so back returns to the previous one.

**Why is `/request/new` declared before `/request/:id`?**
Routes are matched in order, and otherwise `:id` would match the word "new".

## Networking and security
**How does login persist?**
After login the JWT is saved with `shared_preferences`. At startup `AuthProvider.init()` reads it and calls `GET /auth/me`. If the server accepts it, the user goes straight to Home.

**How is the token sent?**
In the `Authorization: Bearer <token>` header on every request, added in `ApiClient`.

**What happens when the token expires?**
The server answers 401, `ApiClient` triggers a logout, and the router sends the user to Login.

**Is `shared_preferences` secure?**
No, it is not encrypted. In production I would use `flutter_secure_storage`, which uses Android's Keystore.

**Where is role-based access enforced?**
The app hides screens by role for a clean interface, but the backend middleware is what really enforces permissions.

**How are errors handled?**
`ApiClient` turns timeouts, connection problems and server errors into readable messages. Each screen shows loading, error with a retry button, or the data and an empty state.

## Live updates
**How do updates arrive without push notifications?**
By polling. A `Timer.periodic` asks the server again every 8 to 15 seconds, and is cancelled when the screen closes.

**What are the limits of polling, and what is the alternative?**
There is a small delay, extra battery use, and nothing arrives when the app is closed. The upgrade is Socket.IO or Firebase Cloud Messaging.

## Location and maps
**How does the app get the location?**
Geolocator checks that location services are on, asks for permission, then reads the position. I wrapped this in `LocationService` so the screens only handle a clear error message.

**How does the map picker work?**
`GoogleMap` reports the tapped point as a latitude and longitude. I show it as a marker and send both numbers with the request.

**Why restrict the Maps API key?**
So nobody can reuse a leaked key. It works only for my app's package name and signing certificate.

## ML and backend
**Where is ML used?**
In the backend. The ML service ranks donors by age, weight, hemoglobin and days since the last donation, and returns a probability that each donor will respond. My app collects those four values on the Donor Health Details screen and sends them to the backend. The app does not call the ML service.

**What is the mock API and why did you build it?**
The backend was built in parallel, so I needed something to develop against. The mock returns the same JSON as the agreed contract, enforces the same rules, and is controlled by one setting, `kUseMockApi`. It is also the demo fallback.

**How do you switch to the real backend?**
Set `kUseMockApi = false`. `ApiClient` then sends requests to the deployed server with the `/api` prefix and the JWT.

**Which parts use the real backend and which use the mock?**
**TODO: write this from your own live test.** For example: "Register, login and requests use the deployed server. The alert feed, notifications and tracking use the mock, because the backend has no route for them yet."

## Honest limits and future work
**What would you improve?**
Real-time updates with Socket.IO or push notifications, secure token storage, distance-based matching on the server, request tracking with live donor locations, and automated tests.

**Is this safe to use for real blood requests?**
No. It is a college demo. A real system needs verified hospitals, donor screening, consent and legal review.