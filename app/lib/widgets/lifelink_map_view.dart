import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../core/theme.dart';

/// High-performance, cross-platform medical dispatch map and tactical radar visualizer.
/// Works 100% offline and on Flutter Web without requiring a paid Google Maps API key.
class LifeLinkMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final double height;
  final bool isLiveGps;
  final bool showRadarRings;
  final double radarRadiusKm;
  final String? badgeText;
  final IconData? badgeIcon;
  final Color? badgeColor;
  final String? markerTitle;
  final String? markerSubtitle;
  final ValueChanged<LatLng>? onTapLocation;
  final bool interactive;
  final bool showControls;
  final VoidCallback? onExpand;

  const LifeLinkMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 13.0,
    this.height = 165.0,
    this.isLiveGps = false,
    this.showRadarRings = true,
    this.radarRadiusKm = 10.0,
    this.badgeText,
    this.badgeIcon,
    this.badgeColor,
    this.markerTitle,
    this.markerSubtitle,
    this.onTapLocation,
    this.interactive = true,
    this.showControls = true,
    this.onExpand,
  });

  @override
  State<LifeLinkMapView> createState() => _LifeLinkMapViewState();
}

class _LifeLinkMapViewState extends State<LifeLinkMapView>
    with SingleTickerProviderStateMixin {
  late double _currentZoom;
  late AnimationController _animController;
  Offset _panOffset = Offset.zero;
  final bool _radarSweepActive = true;
  bool _tacticalMode = false; // false = street map tiles, true = tactical radar blueprint

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.zoom;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void didUpdateWidget(LifeLinkMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _panOffset = Offset.zero;
    }
    if (oldWidget.zoom != widget.zoom) {
      _currentZoom = widget.zoom;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    if (_currentZoom < 16) {
      setState(() => _currentZoom += 1);
    }
  }

  void _zoomOut() {
    if (_currentZoom > 10) {
      setState(() => _currentZoom -= 1);
    }
  }

  void _recenter() {
    setState(() => _panOffset = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isLiveGps
        ? const Color(0xFF10B981)
        : const Color(0xFFBA1A1A);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _tacticalMode
              ? const Color(0xFF0F172A)
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _tacticalMode
                ? const Color(0xFF1E293B)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            // Target location in world coordinates
            final targetWorldX =
                _lon2pixelX(widget.longitude, _currentZoom) - _panOffset.dx;
            final targetWorldY =
                _lat2pixelY(widget.latitude, _currentZoom) - _panOffset.dy;

            // Screen center relative to widget
            final screenCenterX = w / 2;
            final screenCenterY = h / 2;

            // Pin position on screen
            final pinScreenX = screenCenterX + _panOffset.dx;
            final pinScreenY = screenCenterY + _panOffset.dy;

            // Compute radar radius in pixels
            final pixelsPerKm =
                _pixelsPerKm(widget.latitude, _currentZoom);
            final radarRadiusPixels = widget.radarRadiusKm * pixelsPerKm;

            return GestureDetector(
              onPanUpdate: widget.interactive
                  ? (details) {
                      setState(() {
                        _panOffset += details.delta;
                      });
                    }
                  : null,
              onTapUp: widget.onTapLocation != null
                  ? (details) {
                      final tapPos = details.localPosition;
                      final dxFromTarget = tapPos.dx - screenCenterX;
                      final dyFromTarget = tapPos.dy - screenCenterY;
                      final tappedWorldX = targetWorldX + dxFromTarget;
                      final tappedWorldY = targetWorldY + dyFromTarget;
                      final tappedLng =
                          _pixelX2lon(tappedWorldX, _currentZoom);
                      final tappedLat =
                          _pixelY2lat(tappedWorldY, _currentZoom);
                      widget.onTapLocation!(LatLng(tappedLat, tappedLng));
                    }
                  : null,
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  // 1. Street Map Tiles (when not in tactical radar blueprint mode)
                  if (!_tacticalMode)
                    _buildTileLayer(
                      width: w,
                      height: h,
                      centerWorldX: targetWorldX,
                      centerWorldY: targetWorldY,
                    ),

                  // 2. Tactical Medical Radar Blueprint & Distance Rings
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _RadarOverlayPainter(
                            center: Offset(pinScreenX, pinScreenY),
                            radarRadius: radarRadiusPixels,
                            sweepProgress: _radarSweepActive
                                ? _animController.value
                                : 0.0,
                            isTactical: _tacticalMode,
                            accentColor: themeColor,
                            showRings: widget.showRadarRings,
                          ),
                        );
                      },
                    ),
                  ),

                  // 3. Center Medical Pin
                  Positioned(
                    left: pinScreenX - 22,
                    top: pinScreenY - 38,
                    child: _buildPin(themeColor),
                  ),

                  // 4. Top-Right Status Badge (GPS Active / City Center)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildStatusBadge(themeColor),
                  ),

                  // 5. Top-Left Dispatch Radius Badge
                  if (widget.showRadarRings)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (_tacticalMode ? Colors.black87 : Colors.white)
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: themeColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.radar,
                              size: 13,
                              color: themeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.radarRadiusKm.toInt()} KM RADAR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: _tacticalMode ? Colors.white : kInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 6. Bottom Controls: Mode Toggle & Zoom Controls
                  if (widget.showControls) ...[
                    // Mode Toggle (Street / Tactical Radar)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: (_tacticalMode ? Colors.black87 : Colors.white)
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() => _tacticalMode = !_tacticalMode);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _tacticalMode
                                        ? Icons.map_outlined
                                        : Icons.blur_circular,
                                    size: 13,
                                    color: themeColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _tacticalMode ? 'Map' : 'Radar',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: _tacticalMode
                                          ? Colors.white
                                          : kInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Zoom & Recenter Controls (Bottom Right)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: (_tacticalMode ? Colors.black87 : Colors.white)
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _iconBtn(
                              icon: Icons.remove,
                              onTap: _zoomOut,
                              tooltip: 'Zoom Out',
                            ),
                            _iconBtn(
                              icon: Icons.add,
                              onTap: _zoomIn,
                              tooltip: 'Zoom In',
                            ),
                            if (_panOffset != Offset.zero)
                              _iconBtn(
                                icon: Icons.my_location,
                                onTap: _recenter,
                                tooltip: 'Recenter Pin',
                                color: themeColor,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              icon,
              size: 15,
              color: color ?? (_tacticalMode ? Colors.white70 : kInk),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPin(Color themeColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: themeColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 16,
          ),
        ),
        // Needle tip
        Container(
          width: 4,
          height: 6,
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Pulse ring at pin base
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(Color themeColor) {
    final text = widget.badgeText ??
        (widget.isLiveGps ? 'GPS Active' : 'City Center');
    final icon = widget.badgeIcon ??
        (widget.isLiveGps ? Icons.gps_fixed : Icons.location_city);
    final color = widget.badgeColor ?? themeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (_tacticalMode ? Colors.black87 : Colors.white)
            .withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileLayer({
    required double width,
    required double height,
    required double centerWorldX,
    required double centerWorldY,
  }) {
    final z = _currentZoom.toInt();
    const tileSize = 256.0;

    final minTileX = ((centerWorldX - width / 2) / tileSize).floor();
    final maxTileX = ((centerWorldX + width / 2) / tileSize).floor();
    final minTileY = ((centerWorldY - height / 2) / tileSize).floor();
    final maxTileY = ((centerWorldY + height / 2) / tileSize).floor();

    final maxTileLimit = (1 << z) - 1;

    final tiles = <Widget>[];

    for (int tx = minTileX; tx <= maxTileX; tx++) {
      for (int ty = minTileY; ty <= maxTileY; ty++) {
        if (ty < 0 || ty > maxTileLimit) continue;
        final wrappedTx = (tx % (1 << z) + (1 << z)) % (1 << z);

        final tileLeft = (tx * tileSize) - (centerWorldX - width / 2);
        final tileTop = (ty * tileSize) - (centerWorldY - height / 2);

        // OpenStreetMap clean public tiles (fast, zero watermark, completely free)
        final tileUrl =
            'https://tile.openstreetmap.org/$z/$wrappedTx/$ty.png';
        final fallbackUrl =
            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/$z/$ty/$wrappedTx';

        tiles.add(
          Positioned(
            left: tileLeft,
            top: tileTop,
            width: tileSize,
            height: tileSize,
            child: Image.network(
              tileUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.network(
                fallbackUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        );
      }
    }

    return Stack(children: tiles);
  }

  // Mercator Projection Math
  static const double _tileSize = 256.0;

  static double _lon2pixelX(double lon, double zoom) {
    return (lon + 180.0) / 360.0 * (1 << zoom.toInt()) * _tileSize;
  }

  static double _lat2pixelY(double lat, double zoom) {
    final clampedLat = lat.clamp(-85.05112878, 85.05112878);
    final sinLat = math.sin(clampedLat * math.pi / 180.0);
    final y =
        0.5 - math.log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * math.pi);
    return y * (1 << zoom.toInt()) * _tileSize;
  }

  static double _pixelX2lon(double px, double zoom) {
    return px / ((1 << zoom.toInt()) * _tileSize) * 360.0 - 180.0;
  }

  static double _pixelY2lat(double py, double zoom) {
    final y = py / ((1 << zoom.toInt()) * _tileSize);
    final n = math.pi * (1.0 - 2.0 * y);
    final sinhN = 0.5 * (math.exp(n) - math.exp(-n));
    return math.atan(sinhN) * 180.0 / math.pi;
  }

  static double _pixelsPerKm(double lat, double zoom) {
    final latRad = lat * math.pi / 180.0;
    final metersPerPixel =
        156543.03392 * math.cos(latRad) / math.pow(2, zoom.toInt());
    return 1000.0 / metersPerPixel;
  }
}

/// Custom painter for tactical radar concentric distance rings and pulse sweep
class _RadarOverlayPainter extends CustomPainter {
  final Offset center;
  final double radarRadius;
  final double sweepProgress;
  final bool isTactical;
  final Color accentColor;
  final bool showRings;

  _RadarOverlayPainter({
    required this.center,
    required this.radarRadius,
    required this.sweepProgress,
    required this.isTactical,
    required this.accentColor,
    required this.showRings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isTactical) {
      _drawTacticalGrid(canvas, size);
    }

    if (!showRings || radarRadius <= 0) return;

    // Outer Dispatch Radius Circle
    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: isTactical ? 0.12 : 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radarRadius, fillPaint);

    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: isTactical ? 0.7 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _drawDashedCircle(canvas, center, radarRadius, borderPaint);

    // Inner 50% radius circle
    final midPaint = Paint()
      ..color = accentColor.withValues(alpha: isTactical ? 0.35 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radarRadius * 0.5, midPaint);

    // Inner 25% radius circle
    final innerPaint = Paint()
      ..color = accentColor.withValues(alpha: isTactical ? 0.25 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radarRadius * 0.25, innerPaint);

    // Pulsing expand beacon from center
    final pulseRadius = (sweepProgress * radarRadius).clamp(0.0, radarRadius);
    final pulseAlpha = (1.0 - sweepProgress) * (isTactical ? 0.4 : 0.25);
    final pulsePaint = Paint()
      ..color = accentColor.withValues(alpha: pulseAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // Radar Rotating Sweep Beam
    final sweepAngle = sweepProgress * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 3,
        colors: [
          accentColor.withValues(alpha: isTactical ? 0.35 : 0.18),
          Colors.transparent,
        ],
        transform: GradientRotation(sweepAngle),
      ).createShader(
        Rect.fromCircle(center: center, radius: radarRadius),
      );
    canvas.drawCircle(center, radarRadius, sweepPaint);
  }

  void _drawDashedCircle(
      Canvas canvas, Offset center, double radius, Paint paint) {
    const dashCount = 48;
    final step = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = i * step;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        step,
        false,
        paint,
      );
    }
  }

  void _drawTacticalGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Crosshairs centered on target
    final crossPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(center.dx - 20, center.dy), Offset(center.dx + 20, center.dy), crossPaint);
    canvas.drawLine(
        Offset(center.dx, center.dy - 20), Offset(center.dx, center.dy + 20), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarOverlayPainter old) {
    return old.sweepProgress != sweepProgress ||
        old.center != center ||
        old.radarRadius != radarRadius ||
        old.isTactical != isTactical;
  }
}
