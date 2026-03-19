import 'dart:math' as math;

import 'package:flutter/material.dart';

class AudioWaveform extends StatelessWidget {
  const AudioWaveform({super.key, this.isActive = false});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(18, (i) {
          final base = 6 + (i % 5) * 3.0;
          final h = isActive ? base + 8 * math.sin(i * 0.9) : base;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 4,
            height: h.clamp(6, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: cs.primary.withValues(alpha: 0.85),
            ),
          );
        }),
      ),
    );
  }
}

