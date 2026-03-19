import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/history_model.dart';
import '../models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../providers/document_provider.dart';
import '../providers/history_provider.dart';
import '../services/tts_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/glass_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _player = AudioPlayer();
  final TtsService _tts = TtsService();
  bool _loadedHistory = false;
  String? _ttsActiveMessageId;
  bool _ttsLoading = false;
  bool _ttsPlaying = false;
  bool _ttsPaused = false;
  String _chatLanguage = 'English';

  static const List<String> _languages = <String>[
    'English',
    'Hindi',
    'Kannada',
    'Marathi',
    'Tamil',
    'Telugu',
    'Bengali',
  ];

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _ttsLoading = false;
        _ttsPlaying = false;
        _ttsPaused = false;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedHistory) return;
    final docId = context.read<DocumentProvider>().document?.id;
    if (docId == null) return;
    final history = context.read<HistoryProvider>();
    ChatThread? thread;
    for (final t in history.threads) {
      if (t.documentId == docId) {
        thread = t;
        break;
      }
    }
    if (thread != null) context.read<ChatProvider>().loadMessages(thread.messages);
    _loadedHistory = true;
  }

  @override
  void dispose() {
    _player.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _messageId(ChatMessage msg) =>
      '${msg.role.name}_${msg.createdAt.millisecondsSinceEpoch}';

  Future<void> _toggleSpeak(ChatMessage msg) async {
    final id = _messageId(msg);

    // If user taps the active message, toggle pause/resume.
    if (_ttsActiveMessageId == id) {
      if (_ttsPlaying) {
        await _player.pause();
        if (!mounted) return;
        setState(() {
          _ttsPlaying = false;
          _ttsPaused = true;
        });
        return;
      }
      if (_ttsPaused) {
        await _player.resume();
        if (!mounted) return;
        setState(() {
          _ttsPlaying = true;
          _ttsPaused = false;
        });
        return;
      }
      // If we're loading, ignore extra taps.
      return;
    }

    // Switching to a different message: stop current audio first.
    try {
      await _player.stop();
    } catch (_) {}

    setState(() {
      _ttsActiveMessageId = id;
      _ttsLoading = true;
      _ttsPlaying = false;
      _ttsPaused = false;
    });

    try {
      final res = await _tts.generateText(
        text: msg.content,
        language: _chatLanguage,
      );
      if (!mounted) return;

      // If user switched messages while generating, don't play stale audio.
      if (_ttsActiveMessageId != id) return;

      if (res is TtsFileResult) {
        await _player.play(DeviceFileSource(res.file.path));
      } else if (res is TtsUrlResult) {
        await _player.play(UrlSource(res.url));
      }
      if (!mounted) return;
      setState(() {
        _ttsLoading = false;
        _ttsPlaying = true;
        _ttsPaused = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_ttsActiveMessageId == id) {
        setState(() {
          _ttsLoading = false;
          _ttsPlaying = false;
          _ttsPaused = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TTS failed: $e')),
      );
    }
  }

  Future<void> _pickLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              ListTile(
                title: const Text(
                  'Chat language',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  'Applies to new messages + voice.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
              ..._languages.map(
                (l) => ListTile(
                  onTap: () => Navigator.of(context).pop(l),
                  title: Text(l),
                  trailing: l == _chatLanguage
                      ? Icon(Icons.check_rounded, color: cs.primary)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    if (selected == null || selected.trim().isEmpty) return;
    setState(() => _chatLanguage = selected.trim());
  }

  Future<void> _send(BuildContext context) async {
    final docProvider = context.read<DocumentProvider>();
    final docId = docProvider.document?.id;
    final chatProvider = context.read<ChatProvider>();
    final historyProvider = context.read<HistoryProvider>();

    final text = _controller.text;
    _controller.clear();

    await chatProvider.send(
      documentId: docId ?? '',
      question: text,
      language: _chatLanguage,
      analysisJson: docId == null ? null : docProvider.analysis.toJson(),
    );
    if (!mounted) return;

    if (docId != null) {
      await historyProvider.upsertThread(
        ChatThread(
          documentId: docId,
          messages: chatProvider.messages,
          updatedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doc = context.watch<DocumentProvider>().document;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Chatbot'),
        actions: [
          IconButton(
            tooltip: 'Language',
            onPressed: _pickLanguage,
            icon: const Icon(Icons.translate_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primary.withValues(alpha: 0.16),
                      child: Icon(Icons.auto_awesome_rounded, color: cs.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KYY Assistant',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doc == null
                                ? 'No document selected'
                                : 'Context: ${doc.fileName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Language: $_chatLanguage',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
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
                        'Assistant',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _quick(context, 'Summarize', 'Summarize this document.'),
                    const SizedBox(width: 10),
                    _quick(context, 'Define term', 'Define “indemnity”.'),
                    const SizedBox(width: 10),
                    _quick(context, 'Risk check', 'Is this clause risky?'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chat, _) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.messages.length + (chat.isSending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (chat.isSending && i == chat.messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  cs.surfaceContainerHighest.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text('Thinking…'),
                          ),
                        );
                      }
                      final msg = chat.messages[i];
                      return ChatBubble(
                        message: msg,
                        isTtsActive: msg.role == ChatRole.assistant &&
                            _ttsActiveMessageId == _messageId(msg),
                        isTtsLoading: _ttsLoading,
                        isTtsPlaying: _ttsPlaying,
                        isTtsPaused: _ttsPaused,
                        onSpeak: msg.role == ChatRole.assistant
                            ? () => _toggleSpeak(msg)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            Consumer<ChatProvider>(
              builder: (context, chat, _) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(context),
                          decoration: const InputDecoration(
                            hintText: 'Ask anything…',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: chat.isSending ? null : () => _send(context),
                        icon: const Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quick(BuildContext context, String label, String prompt) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        _controller.text = prompt;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
