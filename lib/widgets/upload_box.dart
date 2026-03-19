import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme.dart';

class UploadBox extends StatelessWidget {
  const UploadBox({
    super.key,
    required this.file,
    required this.isPicking,
    required this.onPick,
  });

  final File? file;
  final bool isPicking;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brand = Theme.of(context).extension<KyyBrand>();
    final fileName = file?.path.split(Platform.pathSeparator).last;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: isPicking ? null : onPick,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: brand?.primaryGradient,
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 26,
              spreadRadius: 1,
              color: cs.primary.withValues(alpha: isDark ? 0.22 : 0.16),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.onPrimary.withValues(alpha: isDark ? 0.18 : 0.14),
                ),
              ),
              child: Icon(Icons.photo_camera_rounded, color: cs.onPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? 'Tap to add a document',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Camera or upload (PDF/Image)',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onPrimary.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            if (isPicking)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(Icons.add_a_photo_rounded, color: cs.onPrimary),
          ],
        ),
      ),
    );
  }
}
