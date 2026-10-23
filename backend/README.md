# LifeLink Backend API Documentation

**Audience:** Frontend web and Flutter/mobile app developers  
**Backend Base URL:** `https://lifelink-backend-8onj.onrender.com`  
**Status:** Deployed on Render  
**Last updated:** 2026-10-23

> This document describes the API routes confirmed in the backend route code shared by the backend developer. Route availability is confirmed from route definitions, but not every endpoint's request schema or successful behavior has been verified. Check controller validation and actual Postman responses before relying on example request fields.

---

## 1. Base URL and conventions

Production base URL:

```text
https://lifelink-backend-8onj.onrender.com
```

All endpoint paths below are relative to this base URL. For example:

```text
GET https://lifelink-backend-8onj.onrender.com/api/health
```

- Send and receive JSON where applicable.
- Use the HTTP method shown for each endpoint.
- Protected endpoints require a valid access token.
- Unless a controller specifies otherwise, send JSON request bodies with `Content-Type: application/json`.
- Do not hard-code private backend secrets into frontend or mobile application code.

## 2. Authentication

### Register

`POST /api/auth/register`

Creates an account. The exact fields, allowed roles, and response shape are defined by `controllers/authController.js` and must be confirmed there.

Example request template only — replace fields with the backend's actual schema:

```json
{
  "name": "Example User",
  "email": "user@example.com",
  "password": "Use-A-Strong-Password",
  "role": "requester"
}
```

Do not assume `"role": "donor"` is accepted until the registration controller confirms it.

### Login

`POST /api/auth/login`

Authenticates an existing account. Exact fields and response shape must be confirmed in `authController.js`.

Example request template only:

```json
{
  "email": "user@example.com",
  "password": "Use-The-Account-Password"
}
```

On successful login, read the token field from the actual response and send it as a Bearer token to protected endpoints. The field name may be `token`, `accessToken`, or another name defined by the controller.

### Current user

`GET /api/auth/me`

**Authorization:** Any authenticated user accepted by `auth` middleware.

Returns the logged-in user's profile according to `getMe`.

## 3. Authorization header

For protected endpoints, send:

```http
Authorization: Bearer <ACCESS_TOKEN>
```

In Postman, select **Authorization → Bearer Token** and paste only the token value.

Roles enforced by the route definitions:

- **Donor:** donor profile, availability, ML details, and donor responses.
- **Requester:** create blood requests; view requests and potential donors.
- **Admin:** may view requests, potential donors, and available donor count as defined below.

The `auth` middleware and controller determine the exact error response for missing/invalid tokens or insufficient permissions.

## 4. Health check

### Check service health

`GET /api/health`

**Authorization:** None in the shared route definition.

Example response from the shared route:

```json
{
  "success": true,
  "message": "LifeLink API is healthy"
}
```

## 5. Donor endpoints

All donor-specific endpoints below require a valid **donor** access token, unless noted otherwise.

### Get my donor profile

`GET /api/donors/me`

Returns the authenticated donor's profile.

### Update donor availability

`PATCH /api/donors/availability`

Updates the authenticated donor's availability. The request body fields and accepted values must be confirmed in `controllers/donorController.js`.

Example body template only — use the exact schema expected by the controller:

```json
{
  "available": true
}
```

### Save donor ML details

`PATCH /api/donors/ml-details`

Saves donor fields used by the ML matching/ranking workflow. Required field names, types, and allowed values must be confirmed in `controllers/donorController.js`.

Example body template only — replace with the actual controller schema:

```json
{
  "age": 25
}
```

This is illustrative only and is not a complete ML input schema.

### Get available donor count

`GET /api/donors/available/count`

**Authorization:** Requester or admin token.

Returns the available donor count as implemented by `getAvailableDonorCount`. Confirm the exact response format in `controllers/donorController.js`.

## 6. Blood request endpoints

### Create a blood request

`POST /api/requests`

**Authorization:** Requester token.

Creates a blood request. Required fields, validation rules, and response shape must be confirmed in `controllers/bloodRequestController.js`.

Illustrative request body only — do not send without checking the controller's expected schema:

```json
{
  "bloodGroup": "O+",
  "units": 1,
  "hospital": "City Hospital",
  "location": "Ghaziabad",
  "urgency": "high"
}
```

The example field names may differ from the actual backend schema.

### List blood requests

`GET /api/requests`

**Authorization:** Requester, admin, or donor token (`requireRole("requester", "admin", "donor")`).

Requesters view their own requests, donors view open requests in their operational domain, and admins view all requests. Supports pagination (`?page=1&limit=10`).

### Get blood request by ID (Tracking & Dispatch)

`GET /api/requests/:requestId`

**Authorization:** Requester, admin, or donor token (`requireRole("requester", "admin", "donor")`).

Returns full blood request details, hospital coordinates, units matched, and donor responses:
- **Privacy Enforcement**: When accessed by a donor, the `responses` array only includes that donor's own response, protecting the privacy of other candidate donors.
- **Requester Contact Access**: Returns `requesterName` and `requesterPhone` so dispatched donors can coordinate arrival directly.
- **Donation Verification**: Returns `myDonated` and `maxRadiusKm` based on the request's clinical urgency.

### Find potential donors for a request

`GET /api/requests/:requestId/potential-donors`

**Authorization:** Requester or admin token (`requireRole("requester", "admin")`).

Returns eligible candidate donors within the clinical urgency radius (5 km for Critical, 10 km for Urgent, 20 km for Normal), sorted by ML response probability ranking (Model 1):
- **Donor Privacy**: Candidate donors' phone numbers and emails are masked (`null`) to protect volunteer privacy until voluntary alert acceptance.

### Cancel own blood request

`PATCH /api/requests/:requestId/cancel`

**Authorization:** Requester token (`requireRole("requester")`).

Allows the creating requester to cancel an open or matched blood request.

---

## 7. Donor response endpoints

These endpoints require a valid **donor** token.

### Accept or decline a blood request

`POST /api/responses/:requestId`

**Authorization:** Donor token (`requireRole("donor")`).

Accepts `{ "status": "accepted" | "declined", "message": "optional note" }`.
- Synchronizes `unitsAccepted` on the blood request and transitions status to `matched` when all required units are fulfilled.
- Returns `requesterPhone` and `requesterName` to the accepting donor for hospital dispatch coordination.
- Creates an in-app notification for the requester informing them of the donor's dispatch.

### Update donation completion status

`PATCH /api/responses/:requestId/donation-status`

**Authorization:** Donor token (`requireRole("donor")`).

Accepts `{ "donated": true | false }`.
- When set to `true`, logs `donatedAt` on the `DonorResponse` record.
- Updates the donor's `Donor` profile: sets `lastDonationDate` to current timestamp and increments `totalDonations` by 1.
- Automatically dispatches an in-app notification to the requester: *"Donor has confirmed completing their blood donation for your request."*

### Get my responses

`GET /api/responses/my`

**Authorization:** Donor token (`requireRole("donor")`).

Returns the authenticated donor's own request responses and donation history with pagination.

---

## 8. Endpoint summary

| Method | Endpoint | Access |
|---|---|---|
| GET | `/api/health` | Public |
| POST | `/api/auth/register` | Public |
| POST | `/api/auth/login` | Public |
| GET | `/api/auth/me` | Authenticated user |
| GET | `/api/donors/me` | Donor |
| PUT / PATCH | `/api/donors/me` | Donor |
| PATCH | `/api/donors/availability` | Donor |
| PATCH | `/api/donors/ml-details` | Donor |
| GET | `/api/donors/available/count` | Requester or admin |
| POST | `/api/requests` | Requester |
| GET | `/api/requests` | Requester, admin, donor |
| GET | `/api/requests/:requestId` | Requester, admin, donor |
| PATCH | `/api/requests/:requestId/cancel` | Requester (creator) |
| GET | `/api/requests/:requestId/potential-donors` | Requester or admin |
| POST | `/api/responses/:requestId` | Donor |
| PATCH | `/api/responses/:requestId/donation-status` | Donor |
| GET | `/api/responses/my` | Donor |
| GET | `/api/notifications` | Authenticated user |
| GET | `/api/notifications/unread-count` | Authenticated user |
| PATCH | `/api/notifications/:id/read` | Authenticated user |
| PATCH | `/api/notifications/read-all` | Authenticated user |
| DELETE | `/api/notifications/:id` | Authenticated user |

## 9. Error handling

Handle HTTP status codes appropriately. The exact JSON error format depends on the middleware and controllers.

- `200 OK`: request succeeded.
- `201 Created`: resource created successfully, if used by the controller.
- `400 Bad Request`: invalid or missing input.
- `401 Unauthorized`: missing, invalid, or expired token.
- `403 Forbidden`: authenticated user lacks the required role/permission.
- `404 Not Found`: route or resource was not found.
- `500 Internal Server Error`: unexpected backend error.

Frontend/mobile clients should show a useful user-facing message and avoid exposing internal stack traces.

## 10. Integration notes for frontend and Flutter

1. Keep the base URL in environment/configuration rather than repeating it throughout the app.
2. After login, retain the access token using platform-appropriate secure storage. Do not store it in source code.
3. Attach the Bearer token to protected requests.
4. Handle expired sessions and `401` responses by asking the user to sign in again.
5. Handle `403` by showing a permission message; do not assume every logged-in user is a donor or requester.
6. Use the real `requestId` returned by the create/list request APIs.
7. Confirm request and response schemas with the controller implementations before implementing UI forms.
8. Never ship MongoDB credentials, JWT secrets, or private server-side API keys in a browser bundle or mobile app.
9. If the Render service is sleeping or starting, the first request may take longer; handle network timeouts and retries gracefully.

## 11. Items to confirm before final app integration

The route definitions establish endpoint paths and role middleware, but these details require controller-level verification:

- Exact registration fields, accepted roles, and response structure.
- Exact login fields and token property name.
- Blood request create body and response structure.
- Availability update body and accepted values.
- ML-details fields and validation.
- Donor response body and accepted statuses.
- Exact success/error response JSON for each endpoint.
- Whether any additional API key is required by the ML service. Do not assume the backend API itself requires a separate API key; the shared routes show Bearer-token authentication for protected routes.

## 12. Backend developer handoff checklist

- [ ] Share this README and the Render base URL with frontend and app developers.
- [ ] Confirm all body schemas against controller code.
- [ ] Provide safe sample responses for each endpoint.
- [ ] Verify donor registration and obtain a donor test token.
- [ ] Test all donor-only routes with that donor token.
- [ ] Confirm the ML Engine URL and its authentication requirements if the app calls it directly.
- [ ] Never share production secrets in README, GitHub, or frontend/mobile source.

---

## 13. Machine Learning (ML) APIs

LifeLink uses two ML services: donor ranking and blood-request urgency prediction. The direct ML endpoints are documented below for testing and backend integration.

> **Recommended for frontend/Flutter:** Call the authenticated LifeLink backend endpoints where available. Do not call the direct ML services from the app unless the backend team specifically asks you to. The backend can perform authentication, donor eligibility filtering, and response handling.

### 13.1 Donor Ranking — Model 1

**Purpose:** Ranks eligible/shortlisted donors using donor features.

**Direct ML endpoint**

`POST https://model1-1-l5kq.onrender.com/rank-donors`

**Headers**

```http
Content-Type: application/json
```

**Request body**

Use these exact field names:

```json
{
  "donors": [
    {
      "donorId": "D101",
      "age": 25,
      "weight_kg": 68.5,
      "hemoglobin_g_dL": 14.2,
      "total_donations": 5,
      "days_since_last_donation": 110
    },
    {
      "donorId": "D102",
      "age": 30,
      "weight_kg": 52.0,
      "hemoglobin_g_dL": 12.8,
      "total_donations": 2,
      "days_since_last_donation": 120
    }
  ]
}
```

**Field reference**

| Field | Type | Meaning |
|---|---|---|
| `donorId` | string | Donor identifier |
| `age` | number | Donor age |
| `weight_kg` | number | Donor weight in kilograms |
| `hemoglobin_g_dL` | number | Hemoglobin level in g/dL |
| `total_donations` | number | Number of previous donations |
| `days_since_last_donation` | number | Days since last donation |

The direct Model 1 endpoint returned HTTP `200 OK` in Postman with this request format. Confirm the actual successful response JSON before relying on specific score or identifier fields.

**Important field-name note:** Send `donorId`, `weight_kg`, and `hemoglobin_g_dL`. Do not send the old field names `donor_id`, `weight`, or `hemoglobin`.

**LifeLink backend endpoint**

`POST /api/ml/rank-donors`

Local example:

```text
POST http://localhost:5000/api/ml/rank-donors
```

Send a valid backend JWT:

```http
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: application/json
```

Use a role permitted by the backend route. The backend returns the ML result on success and may return `502` if the upstream ML service fails.

The existing potential-donor flow also calls Model 1 internally. The potential-donors endpoint documented in Section 6 can return `rankingApplied` and `potentialDonors`. If `rankingApplied` is `false`, inspect the backend logs for `Rank donors ML error`.

### 13.2 Blood Request Urgency Prediction — Model 2

**Purpose:** Predicts an urgency level using patient and blood-request information.

**Direct ML endpoint**

`POST https://model-2-lbjw.onrender.com/predict`

**Headers**

```http
Content-Type: application/json
```

**Request body example**

This payload was tested successfully in Postman:

```json
{
  "age": 34,
  "gender": "Male",
  "weight_kg": 72.5,
  "blood_group": "O+",
  "city": "Delhi",
  "health_issue": "Accident / Trauma",
  "hemoglobin_g_dl": 9.2,
  "platelet_count": 140000,
  "systolic_bp": 110,
  "heart_rate": 95,
  "spo2_percent": 96,
  "active_bleeding": 1,
  "previous_transfusions": 0,
  "blood_component_needed": "Packed Red Blood Cells",
  "units_required": 2,
  "required_within_hours": 4
}
```

**Field reference**

| Field | Type | Meaning |
|---|---|---|
| `age` | number | Patient age |
| `gender` | string | Patient gender |
| `weight_kg` | number | Weight in kilograms |
| `blood_group` | string | Requested blood group |
| `city` | string | City for the request |
| `health_issue` | string | Reason/health issue |
| `hemoglobin_g_dl` | number | Hemoglobin in g/dL |
| `platelet_count` | number | Platelet count |
| `systolic_bp` | number | Systolic blood pressure |
| `heart_rate` | number | Heart rate |
| `spo2_percent` | number | Oxygen saturation percentage |
| `active_bleeding` | number | Example uses `1` for active bleeding and `0` for no active bleeding |
| `previous_transfusions` | number | Previous transfusions in the model's expected format |
| `blood_component_needed` | string | Requested blood component |
| `units_required` | number | Units required |
| `required_within_hours` | number | Time until blood is needed, in hours |

Confirm mandatory fields and accepted category values with the ML developer.

**Confirmed example response**

```json
{
  "status": "success",
  "predicted_urgency_level": "Low"
}
```

The example above was returned with HTTP `200 OK` during direct Postman testing.

**LifeLink backend endpoint**

`POST /api/ml/predict-urgency`

Local example:

```text
POST http://localhost:5000/api/ml/predict-urgency
```

Send the urgency JSON payload and a valid backend JWT:

```http
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: application/json
```

The backend returns the ML response on success and may return `502` if the upstream ML service fails.

The existing blood-request creation flow can also call urgency prediction when patient details are supplied. That flow maps patient/request properties to the model input and is designed to save the blood request even if the optional ML prediction fails.

### 13.3 Backend environment setting

The backend uses this environment variable for Model 2:

```env
URGENCY_ML_BASE_URL=https://model-2-lbjw.onrender.com
```

The backend appends `/predict` to this base URL. Set it in the local backend `.env` file and in the backend service's Render environment settings. Do not commit `.env` files or secrets to GitHub.

Model 1's URL is currently configured in the backend service code:

```text
https://model1-1-l5kq.onrender.com/rank-donors
```

### 13.4 ML API errors and troubleshooting

| Status/issue | What to check |
|---|---|
| `400 Bad Request` | Check JSON syntax, required fields, and data types |
| `401 Unauthorized` | Backend JWT is missing, invalid, or expired |
| `403 Forbidden` | User role or request ownership does not permit the operation |
| `422 Unprocessable Entity` | Compare ML request field names and types with the examples above |
| `502 Bad Gateway` from backend | Inspect backend logs and confirm the upstream ML service is reachable |
| Timeout | Check Render service health/logs and retry after confirming availability |
| `rankingApplied: false` | Check for eligible ML-ready donors and inspect the backend log `Rank donors ML error` |

### 13.5 ML integration verification status

- **Model 1 direct ML endpoint:** returned HTTP `200 OK` in Postman with the documented donor fields.
- **Model 2 direct ML endpoint:** returned HTTP `200 OK` with `predicted_urgency_level` in the sample response.
- **Backend end-to-end integration:** test the backend ML endpoints and full blood-request/potential-donor flow separately before claiming production integration is fully verified.


