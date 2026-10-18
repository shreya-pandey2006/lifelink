import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/alert_item.dart';

class AlertCard extends StatelessWidget {
  final AlertItem alert;
  final double? distanceKm;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;

  const AlertCard({
    super.key,
    required this.alert,
    required this.distanceKm,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = alert.urgency == 3;
    final isUrgent = alert.urgency == 2;
    final accent = isCritical
        ? kPrimaryDark
        : (isUrgent ? const Color(0xFFD97706) : kMuted);

    final la = alert.lat;
    final ln = alert.lng;

    // Estimate miles and drive minutes
    final String distText;
    if (distanceKm != null) {
      final miles = (distanceKm! * 0.621371).toStringAsFixed(1);
      final driveMin = (distanceKm! * 2.2).round().clamp(4, 45);
      distText = '$miles mi \u2022 $driveMin min drive';
    } else {
      distText = 'In radar range';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1EEF3)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left colored vertical accent stripe
              Container(width: 5, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top header row: Urgency badge + timeago & Blood Group + Units
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                if (isCritical)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kPrimaryDark,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.warning_amber_rounded,
                                            size: 13, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'CRITICAL LEVEL 1',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (isUrgent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time_filled,
                                            size: 13,
                                            color: Color(0xFFD97706)),
                                        SizedBox(width: 4),
                                        Text(
                                          'URGENT (<6 HRS)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            color: Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1EEF3),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'STANDARD',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: kMuted,
                                      ),
                                    ),
                                  ),
                                Text(
                                  '\u2022 ${timeAgo(alert.createdAt)}',
                                  style: const TextStyle(
                                      fontSize: 11.5, color: kMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isCritical
                                      ? const Color(0xFFFFE4E6)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  alert.bloodGroup,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${alert.units} ${alert.units == 1 ? 'Unit' : 'Units'} Required',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Hospital Name
                      Text(
                        alert.hospitalName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Clinical Subtitle
                      Text(
                        alert.department,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: kMuted,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Location & Distance Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F7FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 15, color: kPrimaryDark),
                            const SizedBox(width: 4),
                            Text(
                              alert.city,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: kInk,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.near_me_outlined,
                                size: 14, color: kPrimaryDark),
                            const SizedBox(width: 4),
                            Text(
                              distText,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: kInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Urgent Matching in Progress & Donors Pinged
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Urgent Matching in Progress',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE8E8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${alert.donorsPinged} Other Donors Pinged',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: kPrimaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Mini Map Route Preview Snippet (if coordinates available)
                      if (la != null && ln != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            height: 95,
                            width: double.infinity,
                            child: Stack(
                              children: [
                                GoogleMap(
                                  key: ValueKey(
                                      'card_map_${alert.requestId}_$la,$ln'),
                                  initialCameraPosition: CameraPosition(
                                      target: LatLng(la, ln), zoom: 14.5),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('hosp_pin'),
                                      position: LatLng(la, ln),
                                    ),
                                  },
                                  liteModeEnabled: true,
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                  mapToolbarEnabled: false,
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black
                                              .withValues(alpha: 0.72),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 10,
                                  right: 10,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.directions_car_outlined,
                                          size: 15, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          alert.routeSnippet,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: onTap,
                                        child: const Text(
                                          'Expand Map',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Action Buttons: Accept & Decline
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: busy ? null : onAccept,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryDark,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(46),
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              icon: busy
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline,
                                      size: 18),
                              label: const Text(
                                'Accept',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              onPressed: busy ? null : onDecline,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1EEF3),
                                foregroundColor: const Color(0xFF736B78),
                                side: BorderSide.none,
                                minimumSize: const Size.fromHeight(46),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text(
                                'Decline',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
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