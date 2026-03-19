import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/document_model.dart';
import '../providers/history_provider.dart';
import '../providers/document_provider.dart';
import '../widgets/glass_card.dart';
import 'analysis_screen.dart';
import 'chat_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('History'),
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, history, _) {
          final items = history.uploads;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              Text(
                'Recent documents',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (!history.isReady)
                Text(
                  'Loading…',
                  style: TextStyle(color: cs.onSurfaceVariant),
                )
              else if (items.isEmpty)
                Text(
                  'No uploads yet for this account.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                )
              else
                ...items.map((it) {
                  final color = it.safetyScore >= 70
                      ? cs.primary
                      : it.safetyScore >= 40
                          ? cs.tertiary
                          : cs.error;
                  final hasAnalysis = it.analysisJson != null;
                  return GlassCard(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: hasAnalysis
                          ? () {
                              final analysis =
                                  DocumentAnalysis.fromJson(it.analysisJson!);
                              context.read<DocumentProvider>().setFromHistory(
                                    documentId: it.documentId,
                                    fileName: it.fileName,
                                    language: it.language,
                                    analysis: analysis,
                                  );
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AnalysisScreen(),
                                ),
                              );
                            }
                          : null,
                      child: Row(
                        children: [
                          _docIcon(context, color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Safety score: ${it.safetyScore.toStringAsFixed(0)} • ${it.riskLevel} • ${it.language}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Vaani AI',
                            onPressed: () {
                              context.read<DocumentProvider>().setFromHistory(
                                    documentId: it.documentId,
                                    fileName: it.fileName,
                                    language: it.language,
                                    analysis: hasAnalysis
                                        ? DocumentAnalysis.fromJson(
                                            it.analysisJson!,
                                          )
                                        : DocumentAnalysis.empty(),
                                  );
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ChatScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.forum_rounded),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _docIcon(BuildContext context, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Icon(Icons.description_rounded, color: color),
    );
  }
}
