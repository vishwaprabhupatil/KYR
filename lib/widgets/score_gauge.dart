import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScoreGauge extends StatelessWidget {
  const ScoreGauge({super.key, required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final normalized = (score.clamp(0, 100)) / 100.0;
    final color = score >= 70
        ? cs.primary
        : score >= 40
            ? cs.tertiary
            : cs.error;

    return Row(
      children: [
        SizedBox(
          height: 64,
          width: 64,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RingPainter(
                    value: normalized,
                    color: color,
                    track: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                    glow: cs.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    score.toStringAsFixed(0),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score out of 100',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                _label(score),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _label(double s) {
    if (s >= 85) return 'Looks safe';
    if (s >= 70) return 'Mostly safe';
    if (s >= 40) return 'Needs review';
    return 'High risk';
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.glow,
  });

  final double value;
  final Color color;
  final Color track;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * value.clamp(0, 1);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      0,
      2 * math.pi,
      false,
      trackPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      start,
      sweep,
      false,
      glowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      start,
      sweep,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.track != track ||
        oldDelegate.glow != glow;
  }
}
