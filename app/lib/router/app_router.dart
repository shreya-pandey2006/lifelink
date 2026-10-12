import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/placeholder_screen.dart';

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
                path: '/requests',
                builder: (c, s) => const PlaceholderScreen(title: 'Requests')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/alerts',
                builder: (c, s) => const PlaceholderScreen(title: 'Alerts')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
}