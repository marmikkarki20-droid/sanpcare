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

class _OpenStreetMapTiles extends StatelessWidget {
  const _OpenStreetMapTiles({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    const zoom = 15;
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
