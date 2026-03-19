import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class KyyBackground extends StatelessWidget {
  const KyyBackground({super.key, this.intensity = 1});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF0A0A0F) : cs.surface;
    final purple = cs.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: base,
            gradient: LinearGradient(
              colors: [
                base,
                Color.lerp(base, purple, isDark ? 0.15 : 0.08)!,
                base,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.16 * intensity,
            child: CustomPaint(
              painter: _LegalPatternPainter(
                color: cs.onSurfaceVariant.withValues(alpha: 0.42),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: (isDark ? 0.28 : 0.14) * intensity,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.7, -0.85),
                      radius: 1.25,
                      colors: [
                        cs.primary.withValues(alpha: isDark ? 0.45 : 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalPatternPainter extends CustomPainter {
  _LegalPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    const spacing = 72.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final cx = x * spacing + (y.isEven ? 18 : 0);
        final cy = y * spacing + 18;
        final r = 10.0 + (x + y) % 3 * 2.0;
        canvas.drawCircle(Offset(cx, cy), 1.6, dotPaint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          -math.pi * 0.15,
          math.pi * 0.3,
          false,
          paint,
        );
        canvas.drawLine(
          Offset(cx - r * 0.55, cy + r * 0.45),
          Offset(cx + r * 0.55, cy + r * 0.45),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LegalPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

