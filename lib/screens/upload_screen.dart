import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/history_model.dart';
import '../providers/document_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/upload_box.dart';
import 'analysis_screen.dart';
import 'pdf_reader_screen.dart';

enum UploadScreenMode { dashboard, upload }

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key, this.mode = UploadScreenMode.upload});

  final UploadScreenMode mode;

  Future<void> _pickSource(BuildContext context, DocumentProvider doc) async {
    if (doc.isPicking) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Add document',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_rounded),
                title: const Text('Upload'),
                subtitle: const Text('PDF or image'),
                onTap: () => Navigator.of(context).pop('upload'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (choice == null) return;
    if (choice == 'camera') {
      await doc.pickFromCamera();
    } else if (choice == 'upload') {
      await doc.pickFromUpload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, doc, _) {
        final cs = Theme.of(context).colorScheme;
        final brand = Theme.of(context).extension<KyyBrand>();
        final canUpload =
            doc.selectedFile != null && !(doc.isUploading || doc.isAnalyzing);
        final selected = doc.selectedFile;
        final fileName = selected?.path.split(Platform.pathSeparator).last ?? '';
        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
        final isPdf = ext == 'pdf';

        return Scaffold(
          backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Text(mode == UploadScreenMode.dashboard ? 'Home' : 'Upload'),
              actions: const [],
            ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
              children: [
                if (mode == UploadScreenMode.dashboard) ...[
                  Text(
                    'Know Your Rights',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a legal document for simplified explanation, risk detection, and audio summaries.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                ],

                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        UploadBox(
                          file: doc.selectedFile,
                          isPicking: doc.isPicking,
                          onPick: () => _pickSource(context, doc),
                        ),
                        if (selected != null && isPdf) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PdfReaderScreen(file: selected),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              label: const Text('Open PDF'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _pill(
                              context,
                              label: 'PDF',
                              icon: Icons.picture_as_pdf_rounded,
                              color: cs.onSurfaceVariant,
                            ),
                            _pill(
                              context,
                              label: 'Images',
                              icon: Icons.image_rounded,
                              color: cs.onSurfaceVariant,
                            ),
                            _pill(
                              context,
                              label: 'Secure',
                              icon: Icons.verified_user_rounded,
                              color: (brand?.success ?? cs.primary).withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Local Gemini test UI removed.

                const SizedBox(height: 14),
                Text(
                  'Preferred language',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: doc.selectedLanguage,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.language_rounded),
                          hintText: 'Choose your language',
                        ),
                        items: AppStrings.supportedLanguages
                            .map(
                              (l) => DropdownMenuItem(
                                value: l,
                                child: Text('${_flagFor(l)}  $l'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) doc.setLanguage(v);
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final l in AppStrings.supportedLanguages.take(6))
                            ChoiceChip(
                              label: Text('${_flagFor(l)}  $l'),
                              selected: doc.selectedLanguage == l,
                              onSelected: (_) => doc.setLanguage(l),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Local Gemini test toggle removed.
                if (doc.errorMessage != null)
                  GlassCard(
                    tint: cs.errorContainer.withValues(alpha: 0.55),
                    child: Row(
                      children: [
                        Icon(Icons.error_rounded, color: cs.onErrorContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            doc.errorMessage!,
                            style: TextStyle(color: cs.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: canUpload
                              ? () async {
                                  final ok = await doc.uploadAndAnalyze();
                                  if (!context.mounted) return;
                                  if (ok) {
                                    final d = doc.document;
                                    final a = doc.analysis;
                                    if (d != null) {
                                      // History should never block showing results.
                                      try {
                                        final history =
                                            context.read<HistoryProvider>();
                                        await history.addUpload(
                                          UploadHistoryItem(
                                            documentId: d.id,
                                            fileName: d.fileName,
                                            language: d.language,
                                            createdAt: DateTime.now(),
                                            riskLevel: a.riskLevel,
                                            safetyScore: a.safetyScore,
                                            analysisJson: a.toJson(),
                                          ),
                                        );
                                      } catch (_) {}
                                    }
                                    if (!context.mounted) return;
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const AnalysisScreen(),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          child: doc.isUploading || doc.isAnalyzing
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        doc.analysisStageLabel,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  doc.useLocalGemini
                                      ? 'Analyze with Gemini'
                                      : 'Upload & Analyze',
                                ),
                        ),
                      ),
                      if (doc.isUploading || doc.isAnalyzing) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: doc.analysisProgress,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: cs.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          color: cs.primary,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _badge(context, 'Analyzing document…'),
                              _badge(context, 'Detecting risky clauses…'),
                              _badge(context, 'Simplifying explanation…'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Backend status card removed for production/demo cleanliness.

                if (mode == UploadScreenMode.dashboard) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Features',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  _featureGrid(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _flagFor(String language) {
    switch (language.toLowerCase()) {
      case 'english':
        return '🌐';
      case 'hindi':
        return '🇮🇳';
      case 'tamil':
        return '🇮🇳';
      case 'telugu':
        return '🇮🇳';
      case 'bengali':
        return '🇮🇳';
      case 'marathi':
        return '🇮🇳';
      case 'kannada':
        return '🇮🇳';
      default:
        return '🌐';
    }
  }

  Widget _featureGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.12,
          children: const [
            _FeatureCard(
              icon: '🌐',
              title: 'Translation',
              subtitle: 'Understand it in your language',
            ),
            _FeatureCard(
              icon: '📝',
              title: 'Simple explanation',
              subtitle: 'Plain-language summary',
            ),
            _FeatureCard(
              icon: '⚠️',
              title: 'Risk detection',
              subtitle: 'Safety score + red flags',
            ),
            _FeatureCard(
              icon: '🎧',
              title: 'Audio',
              subtitle: 'Listen to the explanation',
            ),
          ],
        );
      },
    );
  }

  Widget _badge(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _pill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
          ),
        ],
      ),
    );
  }
}
