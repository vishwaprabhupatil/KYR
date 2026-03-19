import 'package:flutter/material.dart';

class RiskCard extends StatelessWidget {
  const RiskCard({
    super.key,
    required this.score,
    required this.riskLevel,
    required this.alerts,
  });

  final double score;
  final String riskLevel;
  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _riskColor(cs, riskLevel, score);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Summary',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_rounded, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    riskLevel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (alerts.isEmpty)
              Text(
                'No risk alerts returned.',
                style: TextStyle(color: cs.onSurfaceVariant),
              )
            else
              ...alerts.take(3).map(
                    (a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• $a'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Color _riskColor(ColorScheme cs, String riskLevel, double score) {
    final level = riskLevel.toLowerCase();
    if (level.contains('high') || score < 40) return cs.error;
    if (level.contains('medium') || score < 70) return cs.tertiary;
    if (level.contains('low') || score >= 70) return cs.primary;
    return cs.outline;
  }
}

