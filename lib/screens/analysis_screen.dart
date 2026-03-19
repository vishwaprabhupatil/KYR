// ignore_for_file: unused_element

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../providers/document_provider.dart';
import '../services/tts_service.dart';
import '../models/risk_model.dart';
import '../widgets/audio_waveform.dart';
import '../widgets/clause_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/risk_card.dart';
import '../widgets/score_gauge.dart';
import 'chat_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final AudioPlayer _player = AudioPlayer();
  final TtsService _tts = TtsService();

  bool _isSpeaking = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _audioError;
  StreamSubscription<PlayerState>? _playerSub;

  @override
  void initState() {
    super.initState();
    _playerSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        _isPaused = state == PlayerState.paused;
      });
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<DocumentProvider>(
      builder: (context, doc, _) {
        final analysis = doc.analysis;
        final riskLevel = analysis.riskLevel;
        final score = analysis.safetyScore;
        final fileName = doc.document?.fileName ?? 'Document';
        final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : '';

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Results'),
            actions: [
              IconButton(
                tooltip: 'New document',
                onPressed: () {
                  context.read<ChatProvider>().reset();
                  doc.reset();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: cs.primary.withValues(alpha: 0.16),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.65),
                              ),
                            ),
                            child: Icon(Icons.description_rounded, color: cs.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _badge(context, ext.isEmpty ? 'DOC' : ext),
                                    _badge(
                                      context,
                                      'Safety ${score.toStringAsFixed(0)}%',
                                      tone: _toneForScore(context, score),
                                    ),
                                    _badge(context, riskLevel),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: TabBar(
                            isScrollable: true,
                            tabs: [
                              Tab(text: 'Summary'),
                              Tab(text: 'Risks'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ChatScreen()),
                            );
                          },
                          icon: const Icon(Icons.forum_rounded),
                          label: const Text('Vaani AI'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _SimplifiedTab(text: analysis.simplifiedExplanation),
                        _RiskTab(
                          score: score,
                          riskLevel: riskLevel,
                          alerts: analysis.riskAlerts,
                          clauses: analysis.detectedClauses,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: _audioCard(context, doc),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _audioCard(BuildContext context, DocumentProvider doc) {
    final cs = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Audio explanation',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              _badge(context, '🎧', tone: cs.primary),
            ],
          ),
          const SizedBox(height: 10),
          AudioWaveform(isActive: _isSpeaking || _isPlaying),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    icon: _isSpeaking
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Icon(
                            _isPaused
                                ? Icons.play_arrow_rounded
                                : _isPlaying
                                    ? Icons.graphic_eq_rounded
                                    : Icons.play_arrow_rounded,
                          ),
                    label: Text(
                      _isSpeaking
                          ? 'Generating audio…'
                          : _isPaused
                              ? 'Resume'
                              : _isPlaying
                                  ? 'Playing'
                                  : 'Play',
                    ),
                    onPressed: doc.document == null || _isSpeaking
                        ? null
                        : () async {
                            setState(() => _audioError = null);
                            if (_isPaused) {
                              await _player.resume();
                              return;
                            }
                            if (_isPlaying) return;

                            setState(() => _isSpeaking = true);
                            try {
                              final res = await _tts.generate(
                                documentId: doc.document!.id,
                                language: doc.document!.language,
                              );
                              if (!mounted) return;
                              if (res is TtsUrlResult) {
                                await _player.play(UrlSource(res.url));
                              } else if (res is TtsFileResult) {
                                await _player.play(
                                  DeviceFileSource(res.file.path),
                                );
                              }
                            } catch (e) {
                              setState(() => _audioError = e.toString());
                            } finally {
                              if (mounted) setState(() => _isSpeaking = false);
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                width: 50,
                child: OutlinedButton(
                  onPressed:
                      (_isPlaying && !_isSpeaking) ? () => _player.pause() : null,
                  child: const Icon(Icons.pause_rounded),
                ),
              ),
            ],
          ),
          if (_audioError != null) ...[
            const SizedBox(height: 10),
            Text(_audioError!, style: TextStyle(color: cs.error)),
          ],
        ],
      ),
    );
  }

  Color _toneForScore(BuildContext context, double score) {
    final cs = Theme.of(context).colorScheme;
    if (score >= 70) return const Color(0xFF0ECB81);
    if (score >= 40) return cs.tertiary;
    return cs.error;
  }

  Widget _badge(BuildContext context, String text, {Color? tone}) {
    final cs = Theme.of(context).colorScheme;
    final color = tone ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _SimplifiedTab extends StatelessWidget {
  const _SimplifiedTab({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = text.trim().isEmpty
        ? 'No explanation returned.'
        : text.trim();

    final bullets = content
        .split(RegExp(r'[\n•]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (bullets.length <= 1)
                Text(content, style: Theme.of(context).textTheme.bodyMedium)
              else
                ...bullets.take(8).map(
                      (b) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(b)),
                          ],
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _TermChip(term: 'Indemnity', definition: 'You cover losses or claims.'),
                  _TermChip(term: 'Jurisdiction', definition: 'Where disputes are handled.'),
                  _TermChip(term: 'Termination', definition: 'How the contract can end.'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TermChip extends StatelessWidget {
  const _TermChip({required this.term, required this.definition});

  final String term;
  final String definition;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      collapsedBackgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.25),
      title: Text(term, style: const TextStyle(fontWeight: FontWeight.w800)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Text(
            definition,
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _RiskTab extends StatelessWidget {
  const _RiskTab({
    required this.score,
    required this.riskLevel,
    required this.alerts,
    required this.clauses,
  });

  final double score;
  final String riskLevel;
  final List<String> alerts;
  final List<RiskClause> clauses;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety score',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              ScoreGauge(score: score),
              const SizedBox(height: 14),
              RiskCard(score: score, riskLevel: riskLevel, alerts: alerts),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Risky clauses',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        if (clauses.isEmpty)
          Text(
            'No clauses returned by backend yet.',
            style: TextStyle(color: cs.onSurfaceVariant),
          )
        else
          ...clauses.map((c) => ClauseCard(clause: c)),
        if (clauses.isEmpty) ...[
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Example highlight',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: cs.error.withValues(alpha: 0.10),
                    border: Border.all(
                      color: cs.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“The Company may terminate this agreement at any time without notice.”',
                        style: TextStyle(color: cs.onSurface),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Why it’s risky: one-sided termination can leave you without remedies.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Suggestion: add a notice period and clear termination reasons.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TranslationTab extends StatelessWidget {
  const _TranslationTab({required this.translatedText, required this.language});

  final String translatedText;
  final String language;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Translation',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  if (language.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Text(
                        language,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                translatedText.isEmpty
                    ? 'No translated text returned.'
                    : translatedText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download translated PDF (demo)'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatTab extends StatelessWidget {
  const _ChatTab({required this.onOpenChat});

  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primary.withValues(alpha: 0.16),
                    child: Icon(Icons.auto_awesome_rounded, color: cs.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ask questions about your document',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _QuickQuestionChip('Summarize this document'),
                  _QuickQuestionChip('Define “indemnity”'),
                  _QuickQuestionChip('Is this clause risky?'),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: onOpenChat,
                  icon: const Icon(Icons.chat_bubble_rounded),
                  label: const Text('Open chat'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sample messages',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              _sampleBubble(context, false,
                  'What does “termination without notice” mean here?'),
              _sampleBubble(context, true,
                  'It means the other party can end the agreement immediately. Ask for a notice period (e.g., 15–30 days).'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sampleBubble(BuildContext context, bool isAssistant, String text) {
    final cs = Theme.of(context).colorScheme;
    final bg = isAssistant
        ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
        : cs.primary.withValues(alpha: 0.14);
    final fg = isAssistant ? cs.onSurface : cs.primary;
    return Align(
      alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: Text(text, style: TextStyle(color: fg, height: 1.35)),
      ),
    );
  }
}

class _QuickQuestionChip extends StatelessWidget {
  const _QuickQuestionChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
      ),
      child: Chip(label: Text(text)),
    );
  }
}
