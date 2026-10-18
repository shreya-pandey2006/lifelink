import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/alert_item.dart';
import '../../models/app_user.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/request_card.dart';
import '../../widgets/ui.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }
  Future<void> _refresh() async {
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    if (user.isDonor) {
      final alerts = context.read<AlertProvider>();
      final donor = context.read<DonorProvider>();
      await Future.wait([
        alerts.load(
          silent: true,
          city: user.city,
          bloodGroup: user.bloodGroup,
        ),
        donor.load(),
      ]);
    } else {
      final reqs = context.read<RequestProvider>();
      await Future.wait([
        reqs.load(silent: true),
        reqs.fetchAvailableDonorCount(),
      ]);
    }
  }
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    return Scaffold( body: SafeArea(
        child: RefreshIndicator( color: kPrimary, onRefresh: _refresh,
          child: ListView( physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _header(user), const SizedBox(height: 16),
              ...(user.isDonor ? _donorSections(user) : _requesterSections()),
              const SizedBox(height: 16), _CompatibilityCard(initial: user.bloodGroup ?? 'O-'),
              const SizedBox(height: 14), const _TipCard(),
            ],
          ),
        ),
      ),
    );
  }
  Widget _header(AppUser user) {
    return Row(
      children: [
        const BrandLogo(size: 46), const SizedBox(width: 12),
        const Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start,
            children: [ Text('LifeLink', style: TextStyle( fontSize: 20, fontWeight: FontWeight.w800, color: kPrimaryDark)),
              Text('HOME DASHBOARD', style: TextStyle( fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: kMuted)),
            ],
          ),
        ),
        Tooltip(
          message: 'View Profile',
          child: InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(24),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: kPrimarySoft,
              child: Text(
                user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: kPrimaryDark),
              ),
            ),
          ),
        ),
      ],
    );
  }
  List<Widget> _requesterSections() {
    final p = context.watch<RequestProvider>();
    final active = p.requests.where((r) => r.status == 'open' || r.status == 'matched');
    final fulfilled = p.requests.where((r) => r.status == 'fulfilled').length;
    final recent = p.requests.take(2).toList();
    return [
      const _UrgentBanner(), const SizedBox(height: 14),
      Row( children: [
          _StatTile( icon: Icons.track_changes, value: '${active.length}', label: 'Active\nRequests'), const SizedBox(width: 10),
          _StatTile( icon: Icons.volunteer_activism_outlined, value: '${p.availableDonorCount}', label: 'Available\nDonors'),
          const SizedBox(width: 10),  _StatTile( icon: Icons.check_circle_outline, value: '$fulfilled', label: 'Fulfilled\nRequests'),
        ],
      ),
      const SizedBox(height: 22),
       _SectionHeader( title: 'Your Recent Requests', trailing: 'See all', onTrailingTap: () => context.go('/requests') ), const SizedBox(height: 10),
      if (recent.isEmpty)
        const Text('No requests yet. Tap "Create Urgent Request" above.', style: TextStyle(color: kMuted))
      else
        for (final r in recent) ...[ RequestCard(r), const SizedBox(height: 12),
        ],
    ];
  }
  List<Widget> _donorSections(AppUser user) {
    final alerts = context.watch<AlertProvider>();
    final top = alerts.alerts.take(2).toList();
    return [
      _AvailabilityCard(city: user.city),  const SizedBox(height: 14),
      Row( children: [
          _StatTile( icon: Icons.notifications_active_outlined, value: '${alerts.alerts.length}', label: 'Requests\nNearby'),
          const SizedBox(width: 10),
          _StatTile( icon: Icons.priority_high, value: '${alerts.criticalCount}', label: 'Critical\nLevel'),
          const SizedBox(width: 10),
          _StatTile( icon: Icons.bloodtype_outlined, value: user.bloodGroup ?? '-', label: 'Your Blood\nGroup'),
        ],
      ),
      const SizedBox(height: 22),
      _SectionHeader( title: 'Priority Dispatches', trailing: '${alerts.alerts.length} live' ),
      const SizedBox(height: 10),
      if (alerts.error != null && alerts.alerts.isEmpty)
        Text(alerts.error!, style: const TextStyle(color: Colors.red))
      else if (top.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDE7EA)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No urgent blood requests in ${user.city} right now.',
                  style: const TextStyle(
                      fontSize: 13,
                      color: kMuted,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        )
      else
        for (final a in top) ...[_DispatchCard(a), const SizedBox(height: 12)],
    ];
  }
}
class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner();
  @override
  Widget build(BuildContext context) {
    return Container( padding: const EdgeInsets.all(20),
      decoration: BoxDecoration( borderRadius: BorderRadius.circular(24), 
      gradient: const LinearGradient( begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD42A40), Color(0xFFA50F2D)] ),
        boxShadow: const [ BoxShadow(color: Color(0x33A50F2D), blurRadius: 18, offset: Offset(0, 8)) ],
      ),
      child: Column( crossAxisAlignment: CrossAxisAlignment.start,
        children: [ const Pill('INSTANT MEDICAL BROADCAST', background: Colors.white24, foreground: Colors.white),
          const SizedBox(height: 14),
          const Text('Need Blood Urgently?', style: TextStyle( fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          const Text( 'Broadcast a request to matching donors in your city, within a minute.', style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.35) ),
          const SizedBox(height: 18),
          SizedBox( width: double.infinity, height: 52,
            child: FilledButton.icon( onPressed: () => context.push('/request/new'),
              style: FilledButton.styleFrom( backgroundColor: Colors.white, foregroundColor: kPrimaryDark, shape: const StadiumBorder() ),
              icon: const Icon(Icons.add_circle), label: const Text('Create Urgent Request', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
class _AvailabilityCard extends StatelessWidget {
  final String city;
  const _AvailabilityCard({required this.city});
  @override
  Widget build(BuildContext context) {
    final donor = context.watch<DonorProvider>();
    return AppCard( child: Row(
        children: [
          Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start,
              children: [ const Text('Available for Emergency', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
                const SizedBox(height: 4),
                Row( children: [
                    CircleAvatar( radius: 4, backgroundColor: donor.available ? kPrimary : kMuted), const SizedBox(width: 6),
                    Expanded(
                      child: Text( donor.available ? '$city \u2022 alerts are on' : '$city \u2022 alerts are paused',
                          style: const TextStyle(fontSize: 13, color: kMuted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch( value: donor.available, onChanged: (value) async {
              final error = await context.read<DonorProvider>().setAvailable(value);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              }
            },
          ),
        ],
      ),
    );
  }
}
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatTile({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded( child: AppCard( padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [ Icon(icon, color: kPrimaryDark, size: 22), const SizedBox(height: 6),
            Text(value, style: const TextStyle( fontSize: 22, fontWeight: FontWeight.w800, color: kInk)), const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: kMuted)),
          ],
        ),
      ),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;  final VoidCallback? onTrailingTap;
  const _SectionHeader({required this.title, this.trailing, this.onTrailingTap});
  @override
  Widget build(BuildContext context) {
    return Row( children: [
        Expanded( child: Text(title, style: const TextStyle( fontSize: 18, fontWeight: FontWeight.w800, color: kInk)) ),
        if (trailing != null)
          GestureDetector( onTap: onTrailingTap,
            child: Text(trailing!, style: const TextStyle( fontSize: 13, fontWeight: FontWeight.w800, color: kPrimaryDark)),
          ),
      ],
    );
  }
}
class _DispatchCard extends StatelessWidget {
  final AlertItem a;
  const _DispatchCard(this.a);
  @override
  Widget build(BuildContext context) {
    final String label;
    final Color accent;
    final Color soft;
    switch (a.urgency) {
      case 3: label = 'CRITICAL LEVEL'; accent = kPrimaryDark; soft = kPrimarySoft;
      case 2: label = 'URGENT'; accent = kAmber; soft = kAmberSoft;
      default: label = 'STANDARD'; accent = kMuted; soft = const Color(0xFFEFEBF0);
    }
    return Container( clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: const [ BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [ Container(width: 5, color: accent),
            Expanded( child: Padding( padding: const EdgeInsets.all(16),
                child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row( children: [ Pill(label, background: soft, foreground: accent), const Spacer(),
                        Text(timeAgo(a.createdAt), style: const TextStyle(fontSize: 12, color: kMuted)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row( children: [
                        Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.hospitalName, style: const TextStyle( fontSize: 16, fontWeight: FontWeight.w800, color: kInk)), const SizedBox(height: 2),
                              Row( children: [ const Icon(Icons.location_on_outlined, size: 14, color: kMuted), const SizedBox(width: 2),
                                  Text(a.city, style: const TextStyle( fontSize: 13, color: kMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container( padding: const EdgeInsets.symmetric(  horizontal: 14, vertical: 10),
                          decoration: BoxDecoration( color: soft, borderRadius: BorderRadius.circular(14)),
                          child: Text(a.bloodGroup, style: TextStyle( fontSize: 20, fontWeight: FontWeight.w800, color: accent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row( children: [
                        Text('${a.units} ${a.units == 1 ? 'unit' : 'units'} required',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kMuted)),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => _showResponseDialog(context, a),
                          style: FilledButton.styleFrom(
                            backgroundColor: kPrimaryDark,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Respond Now'),
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
    );
  }

  static void _showResponseDialog(BuildContext context, AlertItem a) {
    final msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Respond to Request (${a.bloodGroup})',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${a.city} • ${a.units} unit(s) needed',
                style: const TextStyle(color: kMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: msgController,
              decoration: const InputDecoration(
                labelText: 'Optional message / ETA',
                hintText: 'e.g. Can be there in 30 mins',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await context.read<RequestProvider>().respondToRequest(
                    a.requestId,
                    accept: false,
                    message: msgController.text,
                  );
              if (context.mounted && error != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Response saved.')));
              }
            },
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await context.read<RequestProvider>().respondToRequest(
                    a.requestId,
                    accept: true,
                    message: msgController.text,
                  );
              if (context.mounted && error != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Thank you! Your acceptance has been recorded.')));
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Accept Request'),
          ),
        ],
      ),
    );
  }
}

class _CompatibilityCard extends StatefulWidget {
  final String initial;
  const _CompatibilityCard({required this.initial});

  @override
  State<_CompatibilityCard> createState() => _CompatibilityCardState();
}

class _CompatibilityCardState extends State<_CompatibilityCard> {
  late String _group = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_horiz, color: kPrimaryDark),
              SizedBox(width: 8),
              Expanded(
                child: Text('Blood Compatibility Quick Check',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kBloodGroups.map((g) {
              final on = g == _group;
              return GestureDetector(
                onTap: () => setState(() => _group = g),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: on ? kPrimaryDark : const Color(0xFFF1EEF3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(g,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: on ? Colors.white : kInk)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _line('$_group can donate to', kDonatesTo[_group]!),
          const SizedBox(height: 6),
          _line('$_group can receive from', donorsFor(_group)),
        ],
      ),
    );
  }

  Widget _line(String label, List<String> groups) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: kPrimaryDark)),
          TextSpan(text: groups.join(', '), style: const TextStyle(color: kInk)),
        ],
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}
class _TipCard extends StatelessWidget {
  const _TipCard();
  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row( crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar( radius: 22, backgroundColor: kAmberSoft, child: Icon(Icons.lightbulb_outline, color: kAmber)  ),
          SizedBox(width: 14),
          Expanded( child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [ Text('Emergency Tip', style: TextStyle( fontSize: 15, fontWeight: FontWeight.w800, color: kInk)),
                SizedBox(height: 4), Text( 'Always confirm the hospital and patient details by phone before a donor travels.',
                  style: TextStyle(fontSize: 13, color: kMuted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}