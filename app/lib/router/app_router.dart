import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/requests/create_request_screen.dart';
import '../screens/requests/my_requests_screen.dart';
import '../widgets/placeholder_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../screens/map/location_picker_screen.dart';
GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash', refreshListenable: auth, redirect: (context, state) {
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
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/requests', builder: (c, s) {
                final isDonor = c.read<AuthProvider>().user?.isDonor ?? false;
                return isDonor ? const PlaceholderScreen(title: 'Blood Donation Alerts') : const MyRequestsScreen();
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute( path: '/alerts', builder: (c, s) => const PlaceholderScreen(title: 'Alerts')),
          ]),
          StatefulShellBranch(routes: [ GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()), ]),
        ],
      ),
            GoRoute(
        path: '/pick-location', builder: (c, s) {
          final extra = s.extra as Map<String, dynamic>?;
          return LocationPickerScreen( initial: extra?['pin'] as LatLng?, city: extra?['city'] as String?);
        },
      ),
    ],
  );
}