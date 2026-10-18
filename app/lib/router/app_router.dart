import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/alerts/alert_detail_screen.dart';
import '../screens/alerts/blood_alerts_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/map/location_picker_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/donor_details_screen.dart';
import '../screens/profile/history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/requests/create_request_screen.dart';
import '../screens/requests/my_requests_screen.dart';
import '../screens/requests/request_tracking_screen.dart';
GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',  refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (auth.initializing) return loc == '/splash' ? null : '/splash';
      final onAuthPage = loc == '/login' || loc == '/register';
      if (!auth.isLoggedIn) return onAuthPage ? null : '/login';
      if (onAuthPage || loc == '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [ StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute( path: '/requests', builder: (c, s) {
                final isDonor = c.read<AuthProvider>().user?.isDonor ?? false;
                return isDonor ? const BloodAlertsScreen() : const MyRequestsScreen();
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute( path: '/alerts', builder: (c, s) => const NotificationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute( path: '/request/new', builder: (c, s) => const CreateRequestScreen() ),
      GoRoute( path: '/request/:id', builder: (c, s) => RequestTrackingScreen(requestId: s.pathParameters['id']!) ),
      GoRoute( path: '/pick-location', builder: (c, s) {
          final extra = s.extra as Map<String, dynamic>?;
          return LocationPickerScreen( initial: extra?['pin'] as LatLng?, city: extra?['city'] as String?,
          );
        },
      ),
      GoRoute( path: '/alert/:requestId', builder: (c, s) => AlertDetailScreen(requestId: s.pathParameters['requestId']!) ),
      GoRoute( path: '/donor-details', builder: (c, s) => const DonorDetailsScreen() ),
      GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
    ],
  );
}