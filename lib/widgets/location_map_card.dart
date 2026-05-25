import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationMapCard extends StatelessWidget {
  const LocationMapCard({
    super.key,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.badge,
  });

  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _OpenStreetMapTiles(latitude: latitude, longitude: longitude),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF122F3F),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: 32,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF17262E),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 18,
                          color: Color(0xFF0E8A97),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Care visit map',
                          style: TextStyle(
                            color: Color(0xFF122F3F),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    ?badge,
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  address,
                  style: const TextStyle(
                    color: Color(0xFF536E7A),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openInGoogleMaps(context),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open in Google Maps'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInGoogleMaps(BuildContext context) async {
    final encodedAddress = Uri.encodeComponent(address);
    final geoUri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude($encodedAddress)',
    );
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await _tryOpenMapUri(geoUri)) {
      return;
    }
    if (await _tryOpenMapUri(webUri)) {
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Maps is unavailable.')),
      );
    }
  }

  Future<bool> _tryOpenMapUri(Uri uri) async {
    try {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

class LiveLocationMapCard extends StatelessWidget {
  const LiveLocationMapCard({
    super.key,
    required this.assignedAddress,
    required this.assignedLatitude,
    required this.assignedLongitude,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.distanceMetres,
    required this.accuracyMetres,
    required this.verified,
  });

  final String assignedAddress;
  final double assignedLatitude;
  final double assignedLongitude;
  final double currentLatitude;
  final double currentLongitude;
  final double distanceMetres;
  final double accuracyMetres;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final centerLatitude = (assignedLatitude + currentLatitude) / 2;
    final centerLongitude = (assignedLongitude + currentLongitude) / 2;
    final zoom = _zoomForDistance(distanceMetres);
    final statusColor = verified
        ? const Color(0xFF327A60)
        : const Color(0xFFC43D32);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _OpenStreetMapTiles(
                  latitude: centerLatitude,
                  longitude: centerLongitude,
                  zoom: zoom,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.black.withValues(alpha: 0.16),
                      ],
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final assignedOffset = _mapOffsetForLatLng(
                      size: constraints.biggest,
                      centerLatitude: centerLatitude,
                      centerLongitude: centerLongitude,
                      latitude: assignedLatitude,
                      longitude: assignedLongitude,
                      zoom: zoom,
                    );
                    final currentOffset = _mapOffsetForLatLng(
                      size: constraints.biggest,
                      centerLatitude: centerLatitude,
                      centerLongitude: centerLongitude,
                      latitude: currentLatitude,
                      longitude: currentLongitude,
                      zoom: zoom,
                    );
                    return Stack(
                      children: [
                        Positioned(
                          left: assignedOffset.dx - 31,
                          top: assignedOffset.dy - 54,
                          child: const _LiveMapMarker(
                            label: 'Assigned',
                            icon: Icons.place_rounded,
                            color: Color(0xFF12313D),
                          ),
                        ),
                        Positioned(
                          left: currentOffset.dx - 31,
                          top: currentOffset.dy - 54,
                          child: const _LiveMapMarker(
                            label: 'You',
                            icon: Icons.my_location_rounded,
                            color: Color(0xFF008C95),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          verified
                              ? Icons.verified_rounded
                              : Icons.location_off_rounded,
                          color: statusColor,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            verified ? 'Location verified' : 'Location failed',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Live location check',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    _MapStatusPill(
                      label: verified ? 'Matched' : 'Failed',
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _LiveMapMetric(
                  icon: Icons.place_outlined,
                  label: 'Assigned',
                  value: assignedAddress,
                ),
                _LiveMapMetric(
                  icon: Icons.my_location_outlined,
                  label: 'Current GPS',
                  value:
                      '${currentLatitude.toStringAsFixed(5)}, ${currentLongitude.toStringAsFixed(5)}',
                ),
                _LiveMapMetric(
                  icon: Icons.social_distance_outlined,
                  label: 'Distance',
                  value:
                      '${distanceMetres.toStringAsFixed(0)} m away, GPS accuracy ${accuracyMetres.toStringAsFixed(0)} m',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openRouteInGoogleMaps(context),
                    icon: const Icon(Icons.assistant_direction_outlined),
                    label: const Text('Open route in Google Maps'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRouteInGoogleMaps(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$currentLatitude,$currentLongitude'
      '&destination=$assignedLatitude,$assignedLongitude'
      '&travelmode=walking',
    );
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Fall through to snackbar.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Maps is unavailable.')),
      );
    }
  }
}

class _LiveMapMarker extends StatelessWidget {
  const _LiveMapMarker({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 23),
        ),
      ],
    );
  }
}

class _LiveMapMetric extends StatelessWidget {
  const _LiveMapMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF087C89)),
          const SizedBox(width: 9),
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF536E7A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF17262E),
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStatusPill extends StatelessWidget {
  const _MapStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _OpenStreetMapTiles extends StatelessWidget {
  const _OpenStreetMapTiles({
    required this.latitude,
    required this.longitude,
    this.zoom = 15,
  });

  final double latitude;
  final double longitude;
  final int zoom;

  @override
  Widget build(BuildContext context) {
    const tileSize = 256.0;
    final tile = _MapTileCoordinate.fromLatLng(latitude, longitude, zoom);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _CareMapPainter()),
          LayoutBuilder(
            builder: (context, constraints) {
              final gridSize = tileSize * 3;
              return OverflowBox(
                maxWidth: gridSize,
                maxHeight: gridSize,
                child: Transform.translate(
                  offset: Offset(
                    tileSize * (0.5 - tile.xFraction),
                    tileSize * (0.5 - tile.yFraction),
                  ),
                  child: SizedBox(
                    width: gridSize,
                    height: gridSize,
                    child: GridView.count(
                      crossAxisCount: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: [
                        for (var y = tile.y - 1; y <= tile.y + 1; y++)
                          for (var x = tile.x - 1; x <= tile.x + 1; x++)
                            Image.network(
                              'https://tile.openstreetmap.org/$zoom/$x/$y.png',
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (context, error, stackTrace) {
                                return const ColoredBox(
                                  color: Color(0xFFEAF1EA),
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MapTileCoordinate {
  const _MapTileCoordinate({
    required this.x,
    required this.y,
    required this.xFraction,
    required this.yFraction,
  });

  final int x;
  final int y;
  final double xFraction;
  final double yFraction;

  factory _MapTileCoordinate.fromLatLng(
    double latitude,
    double longitude,
    int zoom,
  ) {
    final latRad = latitude * math.pi / 180;
    final scale = math.pow(2, zoom).toDouble();
    final xFloat = (longitude + 180) / 360 * scale;
    final yFloat =
        (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
        2 *
        scale;
    final x = xFloat.floor();
    final y = yFloat.floor();
    return _MapTileCoordinate(
      x: x,
      y: y,
      xFraction: xFloat - x,
      yFraction: yFloat - y,
    );
  }
}

Offset _mapOffsetForLatLng({
  required Size size,
  required double centerLatitude,
  required double centerLongitude,
  required double latitude,
  required double longitude,
  required int zoom,
}) {
  final center = _globalPixelForLatLng(centerLatitude, centerLongitude, zoom);
  final target = _globalPixelForLatLng(latitude, longitude, zoom);
  final offset = Offset(
    size.width / 2 + target.dx - center.dx,
    size.height / 2 + target.dy - center.dy,
  );
  return Offset(
    offset.dx.clamp(36.0, size.width - 36.0),
    offset.dy.clamp(70.0, size.height - 36.0),
  );
}

Offset _globalPixelForLatLng(double latitude, double longitude, int zoom) {
  final safeLatitude = latitude.clamp(-85.05112878, 85.05112878);
  final latRad = safeLatitude * math.pi / 180;
  final scale = 256 * math.pow(2, zoom).toDouble();
  final x = (longitude + 180) / 360 * scale;
  final y =
      (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
      2 *
      scale;
  return Offset(x, y);
}

int _zoomForDistance(double distanceMetres) {
  if (distanceMetres <= 300) return 17;
  if (distanceMetres <= 1200) return 16;
  if (distanceMetres <= 3500) return 15;
  if (distanceMetres <= 10000) return 13;
  if (distanceMetres <= 50000) return 11;
  if (distanceMetres <= 200000) return 9;
  return 7;
}

class _CareMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEFF5EB),
    );

    final green = Paint()..color = const Color(0xFFCBE6B8);
    canvas.drawOval(
      Rect.fromLTWH(-40, size.height * 0.52, size.width * 0.7, 120),
      green,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.58, -24, size.width * 0.5, 110),
      green,
    );

    final roadEdge = Paint()
      ..color = const Color(0xFFD5D9DA)
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paths = [
      Path()
        ..moveTo(-20, 42)
        ..cubicTo(
          size.width * 0.22,
          82,
          size.width * 0.42,
          8,
          size.width + 20,
          52,
        ),
      Path()
        ..moveTo(-20, 155)
        ..cubicTo(
          size.width * 0.26,
          112,
          size.width * 0.58,
          214,
          size.width + 20,
          160,
        ),
      Path()
        ..moveTo(54, -12)
        ..cubicTo(132, 68, 90, 146, 160, size.height + 18),
      Path()
        ..moveTo(size.width * 0.68, -10)
        ..cubicTo(
          size.width * 0.52,
          70,
          size.width * 0.78,
          148,
          size.width * 0.63,
          size.height + 20,
        ),
    ];

    for (final path in paths) {
      canvas.drawPath(path, roadEdge);
      canvas.drawPath(path, road);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
