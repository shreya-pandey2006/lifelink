import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/alert_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/donor_provider.dart';
import 'providers/history_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/request_provider.dart';
import 'providers/tracking_provider.dart';
import 'router/app_router.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider()..init();
  final router = buildRouter(auth);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => DonorProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
      ],
      child: LifeLinkApp(router: router),
    ),
  );
}
class LifeLinkApp extends StatelessWidget {
  final GoRouter router;
  const LifeLinkApp({super.key, required this.router});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router( title: 'LifeLink', theme: buildTheme(), routerConfig: router, debugShowCheckedModeBanner: false );
  }
}