import 'package:flutter/material.dart';

import '../models/risk_model.dart';

class ClauseCard extends StatelessWidget {
  const ClauseCard({super.key, required this.clause});

  final RiskClause clause;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final severity = clause.severity.toLowerCase();
    final color = severity.contains('high')
        ? cs.error
        : severity.contains('medium')
            ? cs.tertiary
            : cs.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    clause.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    clause.severity,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              clause.summary.isEmpty ? 'No details returned.' : clause.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

