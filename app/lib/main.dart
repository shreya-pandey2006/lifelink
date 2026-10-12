import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/request_provider.dart';
import 'router/app_router.dart';
void main() {
  final auth = AuthProvider()..init();
  final router = buildRouter(auth);
  runApp(
    MultiProvider(
      providers: [ ChangeNotifierProvider<AuthProvider>.value(value: auth), ChangeNotifierProvider(create: (_) => RequestProvider()),],
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