import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/blood_request.dart';
import '../../models/potential_donor.dart';
import '../../models/responder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../widgets/hospital_map.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/urgency_pill.dart';
import '../../widgets/ui.dart';
enum _StepState { done, active, pending }
class RequestTrackingScreen extends StatefulWidget {
  final String requestId;
  const RequestTrackingScreen({super.key, required this.requestId});
  @override
  State<RequestTrackingScreen> createState() => _RequestTrackingScreenState();
}
class _RequestTrackingScreenState extends State<RequestTrackingScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final reqs = context.read<RequestProvider>().requests;
      final match = reqs.where((r) => r.id == widget.requestId);
      final p = context.read<TrackingProvider>();
      if (match.isNotEmpty) {
        p.seed(match.first);
      } else {
        p.clear();
      }
      p.load(widget.requestId);
    });
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        context.read<TrackingProvider>().load(widget.requestId, silent: true);
      }
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  Future<void> _changeStatus(String status) async {
    final error = await context
        .read<TrackingProvider>()
        .setStatus(widget.requestId, status);
    if (!mounted) return;
    if (error == null) context.read<RequestProvider>().load(silent: true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ??
          (status == 'fulfilled'
              ? 'Marked as fulfilled. Thank you!'
              : 'Request cancelled.')),
    ));
  }

  Future<void> _confirmFulfill() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Transfusion as Fulfilled?'),
        content: const Text(
          'Have you successfully received the required blood units from the donor? This will finalize the request as fulfilled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Transfusion Fulfilled'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    await _changeStatus('fulfilled');
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text(
            'Donors who were alerted will be notified that this request is no longer active.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep request')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kPrimaryDark),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel request')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;

    final error = await context
        .read<TrackingProvider>()
        .cancelRequest(widget.requestId);
    if (!mounted) return;
    if (error == null) {
      context.read<RequestProvider>().load(silent: true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Blood request cancelled.'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
      ));
    }
  }
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TrackingProvider>();
    final r = p.request;
    Widget body;
    if (r == null) {
      body = p.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.error!, textAlign: TextAlign.center),
                  TextButton(
                      onPressed: () => p.load(widget.requestId),
                      child: const Text('Try again')),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator(color: kPrimary));
    } else {
      body = RefreshIndicator(
        color: kPrimary,
        onRefresh: () => p.load(widget.requestId, silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _summary(r),
            const SizedBox(height: 14),
            HospitalMap(
              lat: r.lat,
              lng: r.lng,
              title: r.hospitalName,
              city: r.city,
            ),
            const SizedBox(height: 14),
            _progress(r),
            const SizedBox(height: 18),
            _responders(p),
            const SizedBox(height: 18),
            _availableDonors(p, r),
            const SizedBox(height: 18),
            ..._actions(r),
          ],
        ),
      );
    }

    final String pageTitle = r == null
        ? 'Request Tracking'
        : (r.status == 'open' ? 'Live Request Tracking' : 'Request Details');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(pageTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: body,
    );
  }

  Widget _summary(BloodRequest r) {
    final progress = r.units == 0
        ? 0.0
        : (r.unitsAccepted / r.units).clamp(0.0, 1.0).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: kPrimaryDark,
                    borderRadius: BorderRadius.circular(18)),
                child: Text(
                    r.bloodGroup.trim().isNotEmpty
                        ? r.bloodGroup.trim()
                        : 'Blood',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        UrgencyPill(r.urgency),
                        StatusChip(r.status),
                        if (r.predictedUrgency != null)
                          Pill('AI: ${r.predictedUrgency!.toUpperCase()}',
                              background: const Color(0xFFFFEBEE),
                              foreground: const Color(0xFFC62828)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        r.hospitalName.trim().isNotEmpty
                            ? r.hospitalName.trim()
                            : (r.city.trim().isNotEmpty
                                ? 'Hospital in ${r.city.trim()}'
                                : 'Emergency Blood Request'),
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: kInk)),
                    const SizedBox(height: 2),
                    () {
                      final meta = [
                        if (r.city.trim().isNotEmpty) r.city.trim(),
                        if (r.createdAt != null) timeAgo(r.createdAt),
                      ];
                      if (meta.isEmpty) return const SizedBox.shrink();
                      return Text(meta.join(' \u2022 '),
                          style: const TextStyle(fontSize: 12, color: kMuted));
                    }(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEFEBF0),
                    color: kPrimaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${r.unitsAccepted} of ${r.units} units matched',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progress(BloodRequest r) {
    final closed = r.status == 'cancelled' || r.status == 'expired';
    final matched = r.status == 'matched' || r.status == 'fulfilled';
    final fulfilled = r.status == 'fulfilled';

    final steps = <_TimelineStep>[
      _TimelineStep(
        title: 'Broadcast Sent',
        subtitle: [
          'Alert sent to matching donors in ${r.city.trim().isNotEmpty ? r.city.trim() : 'this city'}',
          if (r.createdAt != null) timeAgo(r.createdAt),
        ].join(' \u2022 '),
        state: _StepState.done,
      ),
      _TimelineStep(
        title: 'Donors Accepted',
        subtitle: r.unitsAccepted > 0
            ? '${r.unitsAccepted} ${r.unitsAccepted == 1 ? 'donor has' : 'donors have'} accepted your request'
            : 'Waiting for donors to respond',
        state: r.unitsAccepted > 0 ? _StepState.done : _StepState.active,
      ),
      _TimelineStep(
        title: 'Units Matched',
        subtitle: '${r.unitsAccepted} of ${r.units} units matched',
        state: matched
            ? _StepState.done
            : (r.unitsAccepted > 0 ? _StepState.active : _StepState.pending),
      ),
      _TimelineStep(
        title: 'Blood Transfusion Fulfilled',
        subtitle: fulfilled
            ? 'Completed. Thank you to every donor!'
            : (matched
                ? 'Mark as fulfilled once the donation is complete'
                : 'Pending'),
        state: fulfilled
            ? _StepState.done
            : (matched ? _StepState.active : _StepState.pending),
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tracking Progress',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
          if (closed) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFEFEBF0),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: kMuted, size: 18),
                  const SizedBox(width: 8),
                  Text(
                      r.status == 'cancelled'
                          ? 'This request was cancelled.'
                          : 'This request expired.',
                      style: const TextStyle(color: kInk)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++)
            _StepTile(step: steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }

  Widget _responders(TrackingProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Responded Donors',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
            const SizedBox(width: 8),
            Pill('${p.responders.length}'),
          ],
        ),
        if (p.limited) ...[
          const SizedBox(height: 6),
          const Text(
              'Showing matching donors. The server does not report individual responses yet.',
              style: TextStyle(fontSize: 12, color: kMuted)),
        ],
        const SizedBox(height: 10),
        if (p.responders.isEmpty)
          Text(
              (p.request != null && p.request!.city.trim().isNotEmpty)
                  ? 'No donor has responded yet. Matching donors in ${p.request!.city.trim()} have been alerted.'
                  : 'No donor has responded yet. Matching donors in your city have been alerted.',
              style: const TextStyle(color: kMuted))
        else
          for (final d in p.responders) ...[
            _ResponderTile(d),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _availableDonors(TrackingProvider p, BloodRequest r) {
    final radius = p.maxRadiusKm ?? maxRadiusKmForUrgency(r.urgency);
    final radiusStr = radius.toStringAsFixed(0);

    final Pill urgencyRadiusPill;
    final String radiusSubtitle;
    switch (r.urgency) {
      case 3:
        urgencyRadiusPill = const Pill(
          '≤ 5 km radius',
          background: Color(0xFFFEE2E2),
          foreground: Color(0xFFDC2626),
        );
        radiusSubtitle =
            'Critical emergency: Showing available donors within 5 km radius.';
        break;
      case 2:
        urgencyRadiusPill = const Pill(
          '≤ 10 km radius',
          background: Color(0xFFFEF3C7),
          foreground: Color(0xFFD97706),
        );
        radiusSubtitle =
            'Urgent status: Showing available donors within 10 km radius.';
        break;
      case 1:
      default:
        urgencyRadiusPill = const Pill(
          '≤ 20 km radius',
          background: Color(0xFFE0F2FE),
          foreground: Color(0xFF0369A1),
        );
        radiusSubtitle =
            'Normal urgency: Showing available donors within 20 km radius.';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Available Donors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kInk,
              ),
            ),
            const SizedBox(width: 8),
            Pill('${p.availableDonors.length}'),
            const Spacer(),
            urgencyRadiusPill,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          radiusSubtitle,
          style: const TextStyle(fontSize: 12, color: kMuted),
        ),
        const SizedBox(height: 12),
        if (p.loadingAvailableDonors && p.availableDonors.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: kPrimary),
            ),
          )
        else if (p.availableDonors.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9E5EC)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.radar_outlined, color: kMuted, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No available donors within $radiusStr km',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Only compatible donors within $radiusStr km of ${r.hospitalName.isNotEmpty ? r.hospitalName : (r.city.isNotEmpty ? r.city : 'the location')} are displayed. Donors across distant regions are excluded.',
                        style: const TextStyle(
                            fontSize: 12, color: kMuted, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          for (final d in p.availableDonors) ...[
            _AvailableDonorTile(d: d, request: r),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  List<Widget> _actions(BloodRequest r) {
    final user = context.read<AuthProvider>().user;
    final isCancellable = r.status == 'open' || r.status == 'matched';
    final isOwner = user != null &&
        (r.requesterId == null ||
            r.requesterId!.isEmpty ||
            r.requesterId == user.id);
    final canCancel = isCancellable && (isOwner || user?.isAdmin == true);
    final canFulfill =
        (isOwner || user?.isAdmin == true) && r.status == 'matched';

    return [
      if (canFulfill) ...[
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle_outline,
                      color: Color(0xFF16A34A), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Received the Required Blood?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14532D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'After receiving the blood units from the donor, confirm below to finalize this request as fulfilled.',
                style: TextStyle(fontSize: 13, color: Color(0xFF166534)),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _confirmFulfill,
                icon: const Icon(Icons.done_all_rounded, size: 20),
                label: const Text(
                  'Mark Transfusion as Fulfilled',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      if (r.status == 'fulfilled') ...[
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            children: const [
              Icon(Icons.verified, color: Color(0xFF16A34A), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blood Transfusion Fulfilled',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14532D),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'The donation and transfusion have been successfully completed.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      if (canCancel)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimaryDark,
            side: const BorderSide(color: kPrimaryDark, width: 1.5),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _confirmCancel,
          icon: const Icon(Icons.cancel_outlined, size: 20),
          label: const Text(
            'Cancel Blood Request',
            style: TextStyle(
              color: kPrimaryDark,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
    ];
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final _StepState state;
  const _TimelineStep(
      {required this.title, required this.subtitle, required this.state});
}

class _StepTile extends StatelessWidget {
  final _TimelineStep step;
  final bool isLast;
  const _StepTile({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final Widget dot;
    switch (step.state) {
      case _StepState.done:
        dot = const CircleAvatar(
            radius: 12,
            backgroundColor: kPrimaryDark,
            child: Icon(Icons.check, size: 14, color: Colors.white));
      case _StepState.active:
        dot = const CircleAvatar(
            radius: 12,
            backgroundColor: kPrimarySoft,
            child: CircleAvatar(radius: 5, backgroundColor: kPrimaryDark));
      case _StepState.pending:
        dot = const CircleAvatar(
            radius: 12,
            backgroundColor: Color(0xFFEFEBF0),
            child: Icon(Icons.hourglass_empty, size: 12, color: kMuted));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            dot,
            if (!isLast)
              Container(width: 2, height: 36, color: const Color(0xFFE6E1E8)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: step.state == _StepState.pending
                            ? kMuted
                            : (step.state == _StepState.active
                                ? kPrimaryDark
                                : kInk))),
                const SizedBox(height: 2),
                Text(step.subtitle,
                    style: const TextStyle(fontSize: 12.5, color: kMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponderTile extends StatelessWidget {
  final Responder d;
  const _ResponderTile(this.d);

  @override
  Widget build(BuildContext context) {
    final Pill pill;
    switch (d.status) {
      case 'accepted':
        pill = const Pill('ACCEPTED',
            background: Color(0xFFE3F4E8), foreground: Color(0xFF1E7A3C));
      case 'declined':
        pill = const Pill('DECLINED',
            background: Color(0xFFFEE2E2), foreground: Color(0xFFDC2626));
      default:
        pill = const Pill('MATCHED DONOR');
    }
    final phone = d.phone;
    final isDeclined = d.status == 'declined';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isDeclined
                    ? const Color(0xFFFEE2E2)
                    : kPrimarySoft,
                child: Text(
                    d.name.trim().isEmpty ? 'D' : d.name.trim()[0].toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDeclined
                            ? const Color(0xFFDC2626)
                            : kPrimaryDark)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: kInk)),
                    if (d.respondedAt != null)
                      Text(timeAgo(d.respondedAt),
                          style: const TextStyle(fontSize: 12, color: kMuted)),
                  ],
                ),
              ),
              pill,
            ],
          ),
          if (d.bloodGroup != null || d.city != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (d.bloodGroup != null && d.bloodGroup!.trim().isNotEmpty) ...[
                  Pill(d.bloodGroup!.trim()),
                  const SizedBox(width: 6),
                ],
                if (d.city != null && d.city!.trim().isNotEmpty)
                  Text(
                    d.city!.trim(),
                    style: const TextStyle(fontSize: 12, color: kMuted),
                  ),
              ],
            ),
          ],
          if (d.accepted) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFF4F1F6),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: kPrimaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (phone != null && phone.trim().isNotEmpty)
                          ? phone.trim()
                          : 'No mobile number provided',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: (phone != null && phone.trim().isNotEmpty)
                            ? kInk
                            : kMuted,
                      ),
                    ),
                  ),
                  if (phone != null && phone.trim().isNotEmpty) ...[
                    IconButton(
                      tooltip: 'Copy mobile number',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phone.trim()));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mobile number copied')));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (isDeclined) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.cancel_outlined, size: 15, color: Color(0xFFE11D48)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Donor declined this blood request.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFBE123C)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvailableDonorTile extends StatelessWidget {
  final PotentialDonor d;
  final BloodRequest request;
  const _AvailableDonorTile({required this.d, required this.request});

  @override
  Widget build(BuildContext context) {
    final distText = d.distanceKm != null
        ? '${d.distanceKm!.toStringAsFixed(1)} km away'
        : 'Nearby';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kPrimarySoft,
                child: Text(
                  d.name.trim().isEmpty ? 'D' : d.name.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kPrimaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: kMuted),
                        const SizedBox(width: 3),
                        Text(
                          d.city.isNotEmpty ? d.city : 'Nearby',
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        ),
                        if (d.totalDonations > 0) ...[
                          const SizedBox(width: 6),
                          const Text('\u2022',
                              style: TextStyle(color: kMuted, fontSize: 10)),
                          const SizedBox(width: 6),
                          Text(
                            '${d.totalDonations} ${d.totalDonations == 1 ? 'donation' : 'donations'}',
                            style:
                                const TextStyle(fontSize: 12, color: kMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Pill(
                    d.bloodGroup.isNotEmpty ? d.bloodGroup : 'Match',
                    background: const Color(0xFFFDF2F2),
                    foreground: const Color(0xFFBA1A1A),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_outlined,
                            size: 12, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(
                          distText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              const Pill(
                'AVAILABLE',
                background: Color(0xFFF3F4F6),
                foreground: Color(0xFF374151),
              ),
              if (d.responseProbability != null)
                Pill(
                  '${(d.responseProbability! * 100).round()}% ML MATCH',
                  background: const Color(0xFFEEF2FF),
                  foreground: const Color(0xFF4338CA),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 12, color: kMuted),
                SizedBox(width: 5),
                Text(
                  'Donor phone private until request accepted',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}