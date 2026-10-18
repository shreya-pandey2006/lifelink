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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (mounted) {
        context.read<NotificationProvider>().load(silent: false, refresh: true);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _open(AppNotification n) {
    if (!n.read) {
      context.read<NotificationProvider>().markAsRead(n.id);
    }
    final id = n.requestId;
    if (id == null || id.isEmpty) return;
    final isDonor = context.read<AuthProvider>().user?.isDonor ?? false;
    final isAlertLike = n.type == 'alert' ||
        n.type == 'emergency' ||
        n.type == 'blood_request';

    if (isDonor && isAlertLike) {
      context.push('/alert/$id');
    } else {
      context.push('/request/$id');
    }
  }

  void _delete(AppNotification n) async {
    final success =
        await context.read<NotificationProvider>().deleteNotification(n.id);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted.'),
          duration: Duration(seconds: 2),
        ),
      );
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
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Notifications are not available from the server yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted),
          ),
        ),
      );
    } else if (p.error != null && p.items.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.error!, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => p.load(silent: false, refresh: true),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    } else if (p.items.isEmpty) {
      body = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 56, color: kMuted),
            SizedBox(height: 12),
            Text(
              "You're all caught up",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'New alerts and updates will appear here.',
              style: TextStyle(color: kMuted),
            ),
          ],
        ),
      );
    } else {
      final totalItemCount =
          p.items.length + (p.hasMore || p.loadingMore ? 1 : 1);
      body = RefreshIndicator(
        color: kPrimary,
        onRefresh: () => p.load(refresh: true),
        child: ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: totalItemCount,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == p.items.length) {
              if (p.loadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: kPrimary),
                    ),
                  ),
                );
              }
              return const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    "You're all caught up",
                    style: TextStyle(color: kMuted),
                  ),
                ),
              );
            }
            final n = p.items[i];
            return Dismissible(
              key: Key('notif-${n.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.white, size: 22),
                    SizedBox(width: 6),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              onDismissed: (_) => _delete(n),
              child: _NotificationTile(
                n: n,
                onTap: () => _open(n),
                onDelete: () => _delete(n),
                onMarkRead: !n.read
                    ? () => context.read<NotificationProvider>().markAsRead(n.id)
                    : null,
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Emergency Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (p.unread > 0)
            TextButton(
              onPressed: () => p.markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: kPrimaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
    case 'emergency':
    case 'alert':
      return const _Style(Icons.emergency, kPrimaryDark, 'EMERGENCY REQUEST');
    case 'blood_request':
      return const _Style(Icons.bloodtype, Color(0xFFD42A40), 'BLOOD REQUEST');
    case 'request_update':
      return const _Style(Icons.sync_outlined, kAmber, 'REQUEST UPDATE');
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
    case 'general':
    default:
      return const _Style(Icons.notifications_outlined, kMuted, 'NOTIFICATION');
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onMarkRead;

  const _NotificationTile({
    required this.n,
    required this.onTap,
    required this.onDelete,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(n.type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: !n.read
              ? Border.all(color: kPrimary.withValues(alpha: 0.25), width: 1.2)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: s.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: s.color.withValues(alpha: 0.12),
                        child: Icon(s.icon, color: s.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 0.6,
                                      fontWeight: FontWeight.w800,
                                      color: s.color,
                                    ),
                                  ),
                                ),
                                Text(
                                  timeAgo(n.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (!n.read) ...[
                                  const CircleAvatar(
                                    radius: 4,
                                    backgroundColor: kPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: n.read
                                          ? FontWeight.w700
                                          : FontWeight.w800,
                                      color: kInk,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.message,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: kMuted),
                        padding: EdgeInsets.zero,
                        onSelected: (val) {
                          if (val == 'read' && onMarkRead != null) {
                            onMarkRead!();
                          } else if (val == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (ctx) => [
                          if (!n.read)
                            const PopupMenuItem(
                              value: 'read',
                              child: Row(
                                children: [
                                  Icon(Icons.mark_email_read_outlined,
                                      size: 18, color: kPrimaryDark),
                                  SizedBox(width: 8),
                                  Text('Mark as read'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
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