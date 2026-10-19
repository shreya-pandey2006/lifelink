# LifeLink App: Demo Script (about 3 minutes)

## Before you start (5 minutes earlier)
- [ ] Phone charged, screen timeout set to long, USB or Wi-Fi ready.
- [ ] Open `https://lifelink-backend-8onj.onrender.com/api/health` in a browser so the server is awake.
- [ ] `lib/core/config.dart` is set the way you want to demo (`kUseMockApi`).
- [ ] App installed and logged out. Location is turned on in the phone settings.
- [ ] Phone hotspot ready as a backup for the network.
- [ ] A screen recording of this full flow is saved on the phone, in case the network fails.

## Test accounts
**Mock mode** (password `123456`):

| Role | Email |
|---|---|
| Requester | `requester@lifelink.test` |
| Donor | `donor@lifelink.test` (blood group O-, city Ghaziabad) |

**Live server:** TODO: write the requester and donor emails and passwords you created on the real server.

## The flow

| Time | Do this | Say this |
|---|---|---|
| 0:00 | Open the app. Splash, then Login. | "LifeLink connects people who urgently need blood with donors nearby. This is the Flutter app. State is managed with Provider and navigation with go_router." |
| 0:20 | Log in as the **requester**. Show Home. | "The dashboard shows my active requests, fulfilled requests and how many donors are available." |
| 0:35 | Tap **Create Urgent Request**. Choose O-, 2 units, Critical, hospital name, city. Tap **Use my GPS** or **Edit pin** and drop the pin. Submit. | "The hospital location is picked with the Google Maps SDK, and Geolocator reads the phone's GPS after asking permission. The request goes to the backend with a JWT." |
| 1:10 | Open the **Requests** tab. Tap the new request. | "The tracking screen shows progress, the hospital on the map, and the donors who responded. It refreshes automatically every few seconds." |
| 1:30 | Log out. Log in as the **donor**. Show the **Requests** tab (alert feed) and the **Alerts** tab (notifications with a badge). | "Donors see only requests that match their blood group and city. Notifications are shown in an in-app screen with an unread badge, using polling instead of push." |
| 1:55 | Open **Profile**. Tap **Update Live Location**, then **Donor Health Details**. | "Age, weight, hemoglobin and days since the last donation are sent to the backend, where the ML service uses them to rank donors by how likely they are to respond." |
| 2:15 | Back to the alert. Open **Alert Detail** (distance and map). Tap **Accept**. | "Accepting tells the requester a donor is on the way. If the request is already covered, the server answers 409 and the app shows a friendly message." |
| 2:35 | Log in as the requester again. Show the new notification and the updated tracking screen. | "The requester sees the donor and their phone number only after the donor accepts." |
| 2:50 | Close. | "The app is built in layers: screens, providers, one API client, and a built-in mock API that lets us develop without the server." |

## If something fails
| Problem | What to do |
|---|---|
| The server is slow or asleep | Say "the free server is waking up", wait about 30 seconds and try again. |
| The map is grey | The Maps key or network is the problem. Continue the demo; coordinates still work. |
| Location fails | Turn on GPS and allow the permission under Settings > Apps > LifeLink. |
| The network is down | Switch to the hotspot. If that fails, set `kUseMockApi = true`, hot restart with **R**, and use the mock accounts. |
| Everything fails | Play the screen recording. |

## What to say about live versus mock
> "Registration, login and requests use the deployed backend. The alert feed, notifications and request tracking need endpoints that are not in the backend yet, so the app uses its built-in mock API for them. The mock returns the same JSON as the agreed contract, so switching to the real server is one setting."

**TODO: change this paragraph to match what really worked in your live test.**