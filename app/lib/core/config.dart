// The address of your backend. Change it to match where the server runs:
//   Android emulator:        http://10.0.2.2:5000
//   Real phone, same Wi-Fi:  http://<your-PC-IPv4>:5000
//   Deployed (Render):       https://your-service.onrender.com
// Use your backend's real port. If the backend uses an /api prefix, add it here.
// true  = use the fake backend built into the app (no server needed)
// false = use the real backend at kBaseUrl
const bool kUseMockApi = true;
const String kBaseUrl = 'http://10.0.2.2:5000';