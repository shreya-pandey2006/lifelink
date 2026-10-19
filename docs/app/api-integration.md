# LifeLink App: API Integration

## Backend
- Base URL: `https://lifelink-backend-8onj.onrender.com`
- All routes are under `/api`.
- Protected routes need `Authorization: Bearer <JWT>`.
- The service runs on Render's free tier, so the first request after a pause can take up to a minute. Open `/api/health` first to wake it.

## How the app switches between mock and real
In `lib/core/config.dart`:

```dart
const bool kUseMockApi = false;   // false = real backend, true = built-in mock API
const String kBaseUrl = 'https://lifelink-backend-8onj.onrender.com';
```

The screens and providers always call the same internal paths (for example `/auth/login`). `ApiClient` either answers from `MockApi` or sends the request to the real server, adding the base URL and the `/api` prefix. A route that differs on the real server is mapped inside `ApiClient`, so no screen has to change.

## Endpoint status
Status values: **Live** = tested against the deployed server and works. **Partial** = reaches the server but a field or response needs adjusting. **Mock** = no route in the backend yet, so the app uses the mock API.

**TODO: fill the Status column from your own live test, and delete this line.**

| Feature | App uses | Real endpoint | Status |
|---|---|---|---|
| Register | `POST /auth/register` | `POST /api/auth/register` | TODO |
| Login | `POST /auth/login` | `POST /api/auth/login` | TODO |
| Current user (stay logged in) | `GET /auth/me` | `GET /api/auth/me` | TODO |
| Create blood request | `POST /requests` | `POST /api/requests` | TODO |
| My requests list | `GET /requests` | `GET /api/requests` | TODO |
| Donor profile | `GET /donors/me` | `GET /api/donors/me` | TODO |
| Donor availability switch | `PATCH /donors/me/availability` | `PATCH /api/donors/availability` | TODO |
| Available donor count (requester Home) | `GET /donors/available/count` | `GET /api/donors/available/count` | TODO |
| Donor health details (for ML ranking) | `PATCH /donors/ml-details` | `PATCH /api/donors/ml-details` | TODO |
| Matching donors for a request | `GET /requests/:id/potential-donors` | `GET /api/requests/:requestId/potential-donors` | TODO |
| Donor accepts or declines | `POST /responses/:id` | `POST /api/responses/:requestId` | TODO |
| Donor's own responses | `GET /responses/my` | `GET /api/responses/my` | TODO |
| Donor alert feed | `GET /alerts` | none (closest: `GET /api/responses/my`) | Mock |
| Request tracking detail | `GET /requests/:id` | none (the app falls back to the list plus potential donors) | Mock / Partial |
| Cancel or fulfil a request | `PATCH /requests/:id/status` | none | Mock |
| Notifications | `GET /notifications`, `PATCH /notifications/read-all` | none | Mock |
| Donation history | `GET /donations/me` | none | Mock |
| Donor location update | `PUT /donors/me` | none | Mock |

## Request and response notes
- Errors: the app shows the server's `message` field when there is one, or `Request failed (status)`.
- `401` logs the user out automatically.
- `409` on a donor response means the request is already covered or already answered. The app removes it from the list and shows the message.
- **TODO: list the exact JSON field names the real server uses (for example the token field name, and the accepted `status` values for a donor response), and how the app's models map them.**

## ML engine (called by the backend, not by the app)
- Base URL: `https://lifelink-1-ej74.onrender.com`
- `POST /rank-donors` takes `donor_id`, `age`, `weight`, `hemoglobin`, `days_since_last_donation` for each donor and returns them sorted by `response_probability`.
- The app's **Donor Health Details** screen collects exactly these four values and sends them to `PATCH /api/donors/ml-details`, so the backend can rank donors.
- A separate urgency model (`POST /predict`) estimates how urgent a request is from clinical values. The app does not call it.

## How this was tested
1. Wake the server with `GET /api/health`.
2. Register and log in with the requester and donor accounts used in the demo.
3. Create a request, then check it in the list.
4. Donor responds to a request.
5. **TODO: add what you tested, the date, and what failed or needed adjusting.**