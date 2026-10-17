import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});
  @override
  State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<NotificationProvider>().load();
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) context.read<NotificationProvider>().load();
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unread;
    return Scaffold( body: widget.navigationShell,
      bottomNavigationBar: NavigationBar( selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (i) => widget.navigationShell.goBranch( i, initialLocation: i == widget.navigationShell.currentIndex,
        ),
        destinations: [
          const NavigationDestination( icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination( icon: Icon(Icons.emergency_outlined), selectedIcon: Icon(Icons.emergency), label: 'Requests'),
          NavigationDestination( icon: Badge( isLabelVisible: unread > 0, label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge( isLabelVisible: unread > 0, label: Text('$unread'),
                child: const Icon(Icons.notifications),
              ),
              label: 'Alerts'),
          const NavigationDestination( icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}