import 'package:flutter/material.dart';

class CareSnapMark extends StatelessWidget {
  const CareSnapMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12313D), Color(0xFF087C89)],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087C89).withValues(alpha: 0.24),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.58,
            height: size * 0.58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: size * 0.52,
          ),
          Positioned(
            right: size * 0.16,
            bottom: size * 0.16,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: const Color(0xFFF1A73A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: size * 0.035),
              ),
              child: Icon(
                Icons.check_rounded,
                color: const Color(0xFF12313D),
                size: size * 0.14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CareSnapWordmark extends StatelessWidget {
  const CareSnapWordmark({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : const Color(0xFF12313D);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CareSnapMark(size: compact ? 42 : 64),
        const SizedBox(width: 12),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CareSnap',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 23 : 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 6),
                Text(
                  'Shift check-in and care reporting',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: light
                        ? Colors.white.withValues(alpha: 0.78)
                        : const Color(0xFF607783),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
