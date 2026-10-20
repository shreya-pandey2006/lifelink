# LifeLink App: Demo Script (about 3 minutes)

## Before you start (5 minutes earlier)
- [ ] Phone charged, screen timeout set to long, USB or Wi-Fi ready.
- [ ] Open `https://lifelink-backend-8onj.onrender.com/api/health` in a browser so the free-tier Render server is awake.
- [ ] Ensure `lib/core/config.dart` is set to your desired mode (`kUseMockApi = false` for live backend, `true` for offline mock).
- [ ] App installed and logged out. Location services turned on in phone settings.
- [ ] Mobile hotspot ready as an alternative connection.
- [ ] A backup screen recording of the full flow saved on the phone in case of venue network outages.

## Test accounts

### Mock mode (`kUseMockApi = true`)
Password for all mock accounts: `123456`

| Role | Email | Details |
|---|---|---|
| Requester | `requester@lifelink.test` | City: Ghaziabad |
| Donor | `donor@lifelink.test` | Blood group: O-, City: Ghaziabad |

### Live server mode (`kUseMockApi = false`)
You can use pre-registered accounts or register live during the demo:

| Role | Suggested Email | Password | Details |
|---|---|---|---|
| Requester | `requester@lifelink.test` (or register new) | `123456` | City: Ghaziabad |
| Donor | `donor@lifelink.test` (or register new) | `123456` | Blood group: O-, City: Ghaziabad |

*(Tip: Registering a new account live takes only 15 seconds and proves the live database integration).*

## The flow

| Time | Action | Voice Track |
|---|---|---|
| **0:00** | Open the app. Splash screen renders, then redirects to Login. | "LifeLink connects patients in critical need of blood with eligible nearby donors in seconds. This mobile app is built with Flutter, using Provider for state management and GoRouter for declarative navigation." |
| **0:20** | Log in as the **requester**. Present Home dashboard. | "The requester dashboard displays live emergency indicators, active blood requests, fulfilled requests, and the total count of ready donors available in the network." |
| **0:35** | Tap **Create Urgent Request**. Select O-, 2 units, Critical severity, enter hospital name and city (e.g. Ghaziabad). Tap **Use my GPS** or **Pick on map** and place the pin. Tap Submit. | "The hospital location is selected using our Google Maps location picker and GPS integration with Geolocator. Patient vitals are submitted to the backend, which triggers an automated ML urgency evaluation." |
| **1:10** | Open the **Requests** tab. Select the newly created request. | "The live tracking screen monitors dispatch progress in real time, showing the target hospital pin and donor responses as they arrive. The screen auto-refreshes using lifecycle-managed polling." |
| **1:30** | Log out. Log in as the **donor**. View the **Requests** tab (alert feed) and **Alerts** tab (notifications with unread badge). | "Donors receive prioritized alerts filtered by their blood compatibility and city. Notifications display unread counts and emergency sound indicators without requiring external push services." |
| **1:55** | Open **Profile**. Tap **Update Live Location**, then **Donor Health Details**. | "Donors record their age, weight, hemoglobin, and previous donation history. These metrics are stored on the backend and supplied to the ML ranking service to score donor response probability." |
| **2:15** | Return to the alert feed. Open **Alert Detail** (shows hospital distance and map). Tap **Accept**. | "Accepting signals the medical center that a donor is dispatched. The request state updates atomically, and the server guards against duplicate or over-fulfilled responses with HTTP 409." |
| **2:35** | Log back in as the requester. Show the live notification badge and updated dispatch tracking screen. | "The requester instantly sees the donor's dispatch confirmation, name, and emergency contact details for direct coordination." |
| **2:50** | Summary & wrap-up. | "LifeLink's architecture decouples screens from networking through dedicated providers, a resilient API client, and a full mock API layer that ensures reliable offline testing and demonstrations." |

## Troubleshooting during demo

| Problem | Remedy |
|---|---|
| Server responds slowly or spins | State "The free-tier cloud instance is warming up", wait 15–20 seconds, and retry. |
| Map tiles do not render | Google Maps displays the pinned hospital marker and coordinates cleanly with automatic fallback to city center coordinates if GPS is unavailable. |
| GPS location permission denied | Enable Location in phone Settings > Apps > LifeLink, or use manual city selection. |
| Venue Wi-Fi drops | Switch to mobile hotspot. If network remains unavailable, toggle `kUseMockApi = true`, hot restart (`R`), and use the mock accounts. |
| Complete device failure | Switch to the pre-recorded video walk-through. |

## What to say about live backend versus mock API
> "LifeLink communicates end-to-end with the deployed backend on Render. User authentication, request creation, request tracking, donor responses, and the full notification lifecycle all interact with live MongoDB and Node.js microservices. The app also features an integrated MockApi engine that mirrors the backend contract, guaranteeing zero-downtime offline demonstrations when network connectivity is unpredictable."