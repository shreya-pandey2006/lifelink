# LifeLink App: API Integration

## Backend
- Base URL: `https://lifelink-backend-8onj.onrender.com`
- All routes are under `/api`.
- Protected routes need `Authorization: Bearer <JWT>`.
- The service runs on Render's free tier, so the first request after a pause can take up to a minute. Open `/api/health` first to wake it.

## How the app switches between mock and real
In `lib/core/config.dart`:

```dart
const bool kUseMockApi = false; // false = real backend, true = built-in mock API
const kBaseUrl = 'https://lifelink-backend-8onj.onrender.com/api';
```

The screens and providers always call standardized internal paths (for example `/auth/login`). `ApiClient` either delegates to `MockApi` when `kUseMockApi = true` or sends the request to the live server. When connecting to the live server, `ApiClient` prepends `kBaseUrl` and normalizes paths (stripping duplicated `/api` segments if both the base URL and path contain it).

## Endpoint status
Status values: **Live** = tested and working against the deployed backend. **Aggregated** = assembled on the client using related live backend routes. **Local** = saved on device storage (SharedPreferences) with network sync fallback.

| Feature | App uses | Real endpoint | Access Roles | Status |
|---|---|---|---|---|
| Register | `POST /auth/register` | `POST /api/auth/register` | Public | Live |
| Login | `POST /auth/login` | `POST /api/auth/login` | Public | Live |
| Current user (stay logged in) | `GET /auth/me` | `GET /api/auth/me` | Authenticated | Live |
| Create blood request | `POST /requests` | `POST /api/requests` | Requester | Live |
| My requests list | `GET /requests` | `GET /api/requests` | Requester, Admin, Donor | Live |
| Single request tracking detail | `GET /requests/:id` | `GET /api/requests/:requestId` | Requester, Admin, Donor | Live |
| Cancel blood request | `PATCH /requests/:id/cancel` | `PATCH /api/requests/:requestId/cancel` | Requester (creator only) | Live |
| Matching donors for a request | `GET /requests/:id/potential-donors` | `GET /api/requests/:requestId/potential-donors` | Requester, Admin | Live |
| Donor profile | `GET /donors/me` | `GET /api/donors/me` | Donor | Live |
| Donor availability switch | `PATCH /donors/availability` | `PATCH /api/donors/availability` | Donor | Live |
| Available donor count (requester Home) | `GET /donors/available/count` | `GET /api/donors/available/count` | Requester, Admin | Live |
| Donor health details (for ML ranking) | `PATCH /donors/ml-details` | `PATCH /api/donors/ml-details` | Donor | Live |
| Donor accepts or declines | `POST /responses/:id` | `POST /api/responses/:requestId` | Donor | Live |
| Donor donation status toggle | `PATCH /responses/:id/donation-status` | `PATCH /api/responses/:requestId/donation-status` | Donor | Live |
| Donor's own responses / history | `GET /responses/my` | `GET /api/responses/my` | Donor | Live |
| Notifications list & pagination | `GET /notifications` | `GET /api/notifications` | Authenticated | Live |
| Unread notification badge count | `GET /notifications/unread-count` | `GET /api/notifications/unread-count` | Authenticated | Live |
| Mark single notification as read | `PATCH /notifications/:id/read` | `PATCH /api/notifications/:id/read` | Authenticated | Live |
| Mark all notifications as read | `PATCH /notifications/read-all` | `PATCH /api/notifications/read-all` | Authenticated | Live |
| Delete notification | `DELETE /notifications/:id` | `DELETE /api/notifications/:id` | Authenticated | Live |
| Donor alert feed | `GET /alerts` | Aggregated from `GET /api/requests` & `GET /api/notifications` | Donor | Aggregated / Live |
| Donor location update | `PUT /donors/me` | Saved in `SharedPreferences` (device GPS) with fallback | Donor | Local / Fallback |

## Request and response notes
- **Token handling**: Successful `POST /api/auth/login` returns `{ "success": true, "token": "<JWT>", "user": { "id", "name", "email", "role" } }`. The token is saved in `SharedPreferences` and attached to all subsequent requests via `Authorization: Bearer <token>`.
- **User registration**: `POST /api/auth/register` requires `{ "name", "email", "password", "role": "requester" | "donor", "city" }`. When `role == "donor"`, `bloodGroup` is also mandatory.
- **Blood requests**:
  - `POST /api/requests` sends `{ "bloodGroup", "city", "units", "urgency": "normal" | "urgent" | "emergency", "patient": { ... } }`.
  - The nested `patient` object passes clinical indicators (age, gender, weightKg, healthIssue, hemoglobinGDl, plateletCount, systolicBp, heartRate, spo2Percent, activeBleeding, previousTransfusions, bloodComponentNeeded, requiredWithinHours).
  - The server persists the request and asynchronously triggers ML urgency classification, populating `predictedUrgency`.
- **Single Request Tracking (`GET /api/requests/:requestId`)**:
  - Accessible to both requesters and donors.
  - When viewed by a donor (`role == "donor"`), `responses` contains only the viewing donor's own response, protecting the privacy of other candidate donors.
  - Returns `requesterName` and `requesterPhone`, enabling accepted donors to contact the requester directly.
  - Returns `maxRadiusKm` and `myDonated` indicating whether the donor marked their donation as completed.
- **Donor responses (`POST /api/responses/:requestId`)**:
  - Accepts `{ "status": "accepted" | "declined", "message": "optional note" }`.
  - Response on acceptance returns `{ "success": true, "requesterName": "...", "requesterPhone": "...", "unitsAccepted": 1, "requestStatus": "open" | "matched" }`.
  - HTTP `409` signifies the donor already responded or the request units are already fulfilled.
  - HTTP `403` signifies the donor does not match the blood group compatibility or city criteria.
- **Donation Status Toggle (`PATCH /api/responses/:requestId/donation-status`)**:
  - Accepts `{ "donated": true | false }`.
  - When marked as completed (`donated: true`):
    - Sets `donatedAt` timestamp on the `DonorResponse` record.
    - Atomically updates the donor's `Donor` document: sets `lastDonationDate = new Date()` and increments `totalDonations` by 1.
    - Automatically creates a real-time notification (`type: "donation_update"`) for the requester: *"Donor has confirmed completing their blood donation for your request."*
- **Privacy & Masking Rules**:
  - In `GET /api/requests/:requestId/potential-donors`, candidate donors' phone numbers are redacted (`phone: null`) to prevent unsolicited contact.
  - In `GET /api/requests/:requestId`, phone and email are only exposed for donors whose status is `"accepted"`.
  - Requesters' phone numbers are exposed to donors only after the donor accepts the dispatch request.
- **Dynamic Radius Matching Rules**:
  - Distance is evaluated between hospital coordinates and donor GPS coordinates using the Haversine formula.
  - Matching threshold tiers:
    - **Critical / Emergency**: `maxRadiusKm = 5.0` km.
    - **Urgent**: `maxRadiusKm = 10.0` km.
    - **Normal**: `maxRadiusKm = 20.0` km.
  - Donors outside the respective radius or with unverified coordinates are excluded from emergency dispatches.
- **Donor ML details**:
  - `PATCH /api/donors/ml-details` takes `{ "age": number, "weightKg": number, "hemoglobinGDl": number }`.
  - Range validation: `age` (18–100), `weightKg` (30–300), `hemoglobinGDl` (3–25).
- **Notifications**:
  - The backend stores read state under `isRead`. The app's `AppNotification.fromJson` maps both `isRead` and `read` for seamless compatibility.
- **Errors & Session expiry**:
  - Errors: `ApiClient` parses `message`, `error`, or the first validation item in `errors`.
  - HTTP `401` triggers `onUnauthorized`, clearing providers and redirecting to `/login`.

## ML engine (called by the backend, not by the app)
LifeLink integrates two ML models hosted on Render:

1. **Donor Ranking Service (Model 1)**:
   - Direct ML URL: `https://model1-1-l5kq.onrender.com/rank-donors`
   - Backend integration: `POST /api/ml/rank-donors` and automatically invoked during `GET /api/requests/:requestId/potential-donors`.
   - Input schema:
     ```json
     {
       "donors": [
         {
           "donorId": "651a...",
           "age": 28,
           "weight_kg": 70.0,
           "hemoglobin_g_dL": 14.5,
           "total_donations": 4,
           "days_since_last_donation": 115
         }
       ]
     }
     ```
   - The model returns ranked donors sorted by `response_probability`. Note: field names require `donorId`, `weight_kg`, and `hemoglobin_g_dL`.

2. **Urgency Prediction Service (Model 2)**:
   - Direct ML URL: `https://model-2-lbjw.onrender.com/predict`
   - Backend integration: `POST /api/ml/predict-urgency` and automatically invoked during `POST /api/requests` when patient details are provided.
   - Evaluates patient vitals (systolic BP, heart rate, SpO2, active bleeding, hemoglobin) and returns:
     ```json
     {
       "status": "success",
       "predicted_urgency_level": "Critical"
     }
     ```

## Verification and test procedure
1. **Server Wakeup**: Ping `GET /api/health` to confirm the Render web service is active.
2. **Authentication**: Register a new requester and a new donor (`O-`, Ghaziabad). Log in to verify JWT issuance and session restore on app restart.
3. **Request Lifecycle**: Create an urgent request as a requester. Verify it displays in "My Requests" and tracking screens.
4. **Donor Matching & Notification**: Verify matching donors receive an in-app notification and the alert appears in the donor alert feed within the urgency radius.
5. **Donor Response & Contact Reveal**: Accept the alert as donor. Verify the app navigates to the live tracking screen with requester contact details and hospital map.
6. **Donation Completion**: Check "Mark as Donated" as the donor. Verify `PATCH /api/responses/:requestId/donation-status` executes, updating donor profile metrics and sending a completion notification to the requester.
7. **Mock Fallback**: Toggle `kUseMockApi = true` to test the full flow offline without internet access.