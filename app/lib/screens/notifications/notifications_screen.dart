import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}
class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<NotificationProvider>().load(silent: false);
    });
  }
  void _open(AppNotification n) {
    final id = n.requestId;
    if (id == null || id.isEmpty) return;
    final isDonor = context.read<AuthProvider>().user?.isDonor ?? false;
    if (isDonor && n.type == 'alert') {
      context.push('/alert/$id');
    } else if (!isDonor) {
      context.push('/request/$id');
    }
  }
  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationProvider>();
    Widget body;
    if (p.loading && p.items.isEmpty) {
      body = const Center(child: CircularProgressIndicator(color: kPrimary));
    } else if (p.unsupported) {
      body = const Center(
        child: Padding( padding: EdgeInsets.all(24),
          child: Text( 'Notifications are not available from the server yet.',
              textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
        ),
      );
    } else if (p.error != null && p.items.isEmpty) {
      body = Center(
        child: Column( mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.error!, textAlign: TextAlign.center),
            TextButton( onPressed: () => p.load(silent: false), child: const Text('Try again')),
          ],
        ),
      );
    } else if (p.items.isEmpty) {
      body = const Center(
        child: Column( mainAxisSize: MainAxisSize.min,
          children: [ Icon(Icons.notifications_none, size: 56, color: kMuted), SizedBox(height: 12),
            Text("You're all caught up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), SizedBox(height: 4),
            Text('New alerts and updates will appear here.', style: TextStyle(color: kMuted)),
          ],
        ),
      );
    } else {
      body = RefreshIndicator( color: kPrimary, onRefresh: () => p.load(),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: p.items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            if (i == p.items.length) {
              return const Padding( padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: Text("You're all caught up", style: TextStyle(color: kMuted)),
                ),
              );
            }
            final n = p.items[i];
            return _NotificationTile(n: n, onTap: () => _open(n));
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar( backgroundColor: kBackground, surfaceTintColor: Colors.transparent,
        title: const Text('Emergency Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        actions: [ if (p.unread > 0)
            TextButton( onPressed: () => p.markAllRead(),
              child: const Text('Mark all read', style: TextStyle( color: kPrimaryDark, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: body,
    );
  }
}
class _Style {
  final IconData icon;
  final Color color;
  final String label;
  const _Style(this.icon, this.color, this.label);
}
_Style _styleFor(String type) {
  switch (type) {
    case 'alert':
      return const _Style(Icons.emergency, kPrimaryDark, 'NEW REQUEST NEARBY');
    case 'accepted':
      return const _Style(Icons.check_circle_outline, kAmber, 'DONOR ACCEPTED');
    case 'declined':
      return const _Style(Icons.person_off_outlined, kMuted, 'DONOR DECLINED');
    case 'matched':
      return const _Style(Icons.verified_user_outlined, kPrimaryDark, 'UNITS MATCHED');
    case 'fulfilled':
      return const _Style(Icons.favorite, Color(0xFF1E7A3C), 'REQUEST FULFILLED');
    case 'cancelled':
      return const _Style(Icons.cancel_outlined, kMuted, 'REQUEST CANCELLED');
    default:
      return const _Style(Icons.notifications_outlined, kMuted, 'UPDATE');
  }
}
class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotificationTile({required this.n, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = _styleFor(n.type);
    return GestureDetector( onTap: onTap,
      child: Container( clipBehavior: Clip.antiAlias, decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: const [ BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row( crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [ Container(width: 5, color: s.color),
              Expanded( child: Padding( padding: const EdgeInsets.all(14),
                  child: Row( crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar( radius: 22, backgroundColor: s.color.withValues(alpha: 0.12), child: Icon(s.icon, color: s.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row( children: [
                                Expanded( child: Text(s.label,
                                      style: TextStyle( fontSize: 11, letterSpacing: 0.6, fontWeight: FontWeight.w800, color: s.color)),
                                ),
                                Text(timeAgo(n.createdAt), style: const TextStyle( fontSize: 11, color: kMuted)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row( children: [
                                if (!n.read) ...[ const CircleAvatar( radius: 4, backgroundColor: kPrimary), const SizedBox(width: 6) ],
                                Expanded( child: Text(n.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: kInk)) ),
                              ],
                            ),
                            const SizedBox(height: 4), Text(n.message, style: const TextStyle( fontSize: 13, color: kMuted, height: 1.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}