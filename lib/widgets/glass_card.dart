import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.onTap,
    this.tint,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brand = Theme.of(context).extension<KyyBrand>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = tint ??
        cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.48 : 0.62);

    final border = Border.all(
      color: cs.outlineVariant.withValues(alpha: isDark ? 0.7 : 0.55),
    );

    final glow = brand == null
        ? null
        : BoxShadow(
            blurRadius: 26,
            spreadRadius: 1,
            color: brand.purple.withValues(alpha: isDark ? 0.18 : 0.12),
          );

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
            boxShadow: glow == null ? const [] : [glow],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: onTap,
      child: content,
    );
  }
}

