import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/ui.dart';

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

  void _showHotlineDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded,
                      color: kPrimaryDark, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Dispatch Line',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                      ),
                    ),
                    Text(
                      '24/7 Rapid Emergency Response Coordinator',
                      style: TextStyle(fontSize: 12, color: kMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.health_and_safety_outlined,
                      color: kPrimaryDark, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Toll-Free Dispatch: 1800-LIFE-LINK (+91 800 543 3546)\nDirect Trauma Desk is active.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Close',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  String? _extractBloodGroup(String title, String message) {
    for (final bg in kBloodGroups) {
      final pattern = RegExp(r'\b' + RegExp.escape(bg) + r'\b');
      if (pattern.hasMatch(title) || pattern.hasMatch(message)) {
        return bg;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();
    DonorProvider? donor;
    try {
      donor = Provider.of<DonorProvider>(context);
    } catch (_) {}
    final user = auth.user;
    final initial = (user?.name != null && user!.name.isNotEmpty)
        ? user.name[0].toUpperCase()
        : '?';
    final isDonor = user?.isDonor ?? false;
    final isAvailable = (donor?.available ?? true) && isDonor;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FB),
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimary,
          onRefresh: () => p.load(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =======================================================
                      // 1. Top Header Bar: LifeLink + Emergency Notifications
                      // =======================================================
                      Row(
                        children: [
                          const BrandLogo(size: 38),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LifeLink',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: kInk,
                                ),
                              ),
                              Text(
                                'Emergency Notifications',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: kPrimaryDark,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (p.unread > 0)
                            TextButton(
                              onPressed: () => p.markAllRead(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                              child: const Text(
                                'Mark all read',
                                style: TextStyle(
                                  color: kPrimaryDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          Tooltip(
                            message: 'Emergency Hotline',
                            child: Material(
                              color: const Color(0xFFFDE8E8),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _showHotlineDialog,
                                child: const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.phone_in_talk_rounded,
                                    color: kPrimaryDark,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Tooltip(
                            message: 'View Profile',
                            child: Material(
                              color: kPrimarySoft,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => context.go('/profile'),
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: kPrimaryDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // =======================================================
                      // 2. Top Live Triage Banner
                      // =======================================================
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFBA1A1A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAvailable
                                    ? 'Live triage network active \u2022 Emergency alerts enabled'
                                    : 'Live triage network connected \u2022 Monitoring dispatch radar',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8B1225),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.podcasts,
                                color: Color(0xFFBA1A1A), size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // ===============================================================
              // 3. Notification List or States
              // ===============================================================
              if (p.loading && p.items.isEmpty) ...[
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  ),
                ),
              ] else if (p.unsupported) ...[
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Notifications are not available from the server yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kMuted),
                      ),
                    ),
                  ),
                ),
              ] else if (p.error != null && p.items.isEmpty) ...[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () =>
                              p.load(silent: false, refresh: true),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (p.items.isEmpty) ...[
                // Empty state when database has 0 notifications
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 52, color: Color(0xFF10B981)),
                        SizedBox(height: 14),
                        Text(
                          "You're all caught up",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kInk,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'No emergency alerts or request updates right now.\nLive triage network is actively monitoring for urgent requests.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i == p.items.length) {
                          if (p.loadingMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: kPrimary,
                                  ),
                                ),
                              ),
                            );
                          }
                          // Caught-up footer card at the bottom of the feed
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1EEF3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: kInk,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "You're all caught up",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: kInk,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'No older notifications in the last 30 days.\nEmergency push alerts remain active.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11.5, color: kMuted),
                                ),
                              ],
                            ),
                          );
                        }

                        final n = p.items[i];
                        final bloodGroup =
                            _extractBloodGroup(n.title, n.message);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: Key('notif-${n.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBA1A1A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: Colors.white, size: 22),
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
                            child: _NotificationCard(
                              n: n,
                              bloodGroup: bloodGroup,
                              isDonor: isDonor,
                              onTap: () => _open(n),
                              onDelete: () => _delete(n),
                              onMarkRead: !n.read
                                  ? () => context
                                      .read<NotificationProvider>()
                                      .markAsRead(n.id)
                                  : null,
                            ),
                          ),
                        );
                      },
                      childCount: p.items.length + 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationStyle {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;

  const _NotificationStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
  });
}

_NotificationStyle _styleFor(String type, String title) {
  final lowerType = type.toLowerCase();
  final lowerTitle = title.toLowerCase();

  if (lowerTitle.contains('accepted') || lowerType == 'accepted') {
    return const _NotificationStyle(
      icon: Icons.check,
      iconColor: Color(0xFF1E7A3C),
      iconBgColor: Color(0xFFE8F5E9),
      label: 'DONOR EN ROUTE',
    );
  }

  if (lowerTitle.contains('matched') || lowerType == 'matched') {
    return const _NotificationStyle(
      icon: Icons.shield_outlined,
      iconColor: Color(0xFFBA1A1A),
      iconBgColor: Color(0xFFFDE8E8),
      label: 'PROTOCOL MATCH',
    );
  }

  if (lowerTitle.contains('fulfilled') || lowerType == 'fulfilled') {
    return const _NotificationStyle(
      icon: Icons.star_border_rounded,
      iconColor: Color(0xFF5B21B6),
      iconBgColor: Color(0xFFF3E8FF),
      label: 'FULFILLED',
    );
  }

  if (lowerTitle.contains('re-route') ||
      lowerTitle.contains('reroute') ||
      lowerType == 'cancelled') {
    return const _NotificationStyle(
      icon: Icons.sync,
      iconColor: Color(0xFFB45309),
      iconBgColor: Color(0xFFFEF3C7),
      label: 'AUTOMATED RE-ROUTE',
    );
  }

  if (lowerTitle.contains('appointment') || lowerTitle.contains('reminder')) {
    return const _NotificationStyle(
      icon: Icons.calendar_today_outlined,
      iconColor: Color(0xFF475569),
      iconBgColor: Color(0xFFF1F5F9),
      label: 'APPOINTMENT',
    );
  }

  switch (lowerType) {
    case 'emergency':
    case 'alert':
      return const _NotificationStyle(
        icon: Icons.emergency,
        iconColor: kPrimaryDark,
        iconBgColor: Color(0xFFFDE8E8),
        label: 'EMERGENCY REQUEST',
      );
    case 'blood_request':
      return const _NotificationStyle(
        icon: Icons.water_drop,
        iconColor: Color(0xFFBA1A1A),
        iconBgColor: Color(0xFFFDE8E8),
        label: 'BLOOD REQUEST',
      );
    case 'request_update':
      return const _NotificationStyle(
        icon: Icons.sync,
        iconColor: Color(0xFFB45309),
        iconBgColor: Color(0xFFFEF3C7),
        label: 'REQUEST UPDATE',
      );
    case 'general':
    default:
      return const _NotificationStyle(
        icon: Icons.notifications_outlined,
        iconColor: kMuted,
        iconBgColor: Color(0xFFF1EEF3),
        label: 'NOTIFICATION',
      );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification n;
  final String? bloodGroup;
  final bool isDonor;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onMarkRead;

  const _NotificationCard({
    required this.n,
    this.bloodGroup,
    required this.isDonor,
    required this.onTap,
    required this.onDelete,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(n.type, n.title);
    final hasRequest = n.requestId != null && n.requestId!.isNotEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: !n.read
              ? const Color(0xFFBA1A1A).withValues(alpha: 0.35)
              : const Color(0xFFEDE7EA),
          width: !n.read ? 1.3 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unread Red Indicator Stripe on Left
                if (!n.read)
                  Container(
                    width: 4,
                    color: const Color(0xFFBA1A1A),
                  ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header Row: Icon + Unread Dot + Label + Blood Group + Time
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: s.iconBgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(s.icon, color: s.iconColor, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  if (!n.read) ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFBA1A1A),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      s.label,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        letterSpacing: 0.7,
                                        fontWeight: FontWeight.w800,
                                        color: s.iconColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (bloodGroup != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDE8E8),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        bloodGroup!,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFBA1A1A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              timeAgo(n.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: kMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  size: 16, color: kMuted),
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
                                        Icon(
                                            Icons.mark_email_read_outlined,
                                            size: 16,
                                            color: kPrimaryDark),
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
                                          size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(
                                              color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Title
                        Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: n.read
                                ? FontWeight.w700
                                : FontWeight.w800,
                            color: kInk,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Message body
                        Text(
                          n.message,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: kMuted,
                            height: 1.35,
                          ),
                        ),

                        // Contextual Action Button
                        if (hasRequest) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                (n.type == 'emergency' ||
                                        n.type == 'alert' ||
                                        n.type == 'blood_request')
                                    ? (isDonor
                                        ? 'View Alert & Accept'
                                        : 'View Emergency Request')
                                    : (n.type == 'accepted' ||
                                            n.title
                                                .toLowerCase()
                                                .contains('accepted'))
                                        ? 'Track Donor Live'
                                        : 'View Request Details',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: kPrimaryDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                (n.type == 'accepted' ||
                                        n.title
                                            .toLowerCase()
                                            .contains('accepted'))
                                    ? Icons.navigation_outlined
                                    : Icons.arrow_forward_rounded,
                                size: 14,
                                color: kPrimaryDark,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}