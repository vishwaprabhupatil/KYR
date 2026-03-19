import 'package:flutter/material.dart';

import '../models/chat_model.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onSpeak,
    this.isTtsActive = false,
    this.isTtsLoading = false,
    this.isTtsPlaying = false,
    this.isTtsPaused = false,
  });

  final ChatMessage message;
  final VoidCallback? onSpeak;
  final bool isTtsActive;
  final bool isTtsLoading;
  final bool isTtsPlaying;
  final bool isTtsPaused;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.role == ChatRole.user;

    final bg = isUser
        ? cs.primaryContainer.withValues(alpha: 0.9)
        : cs.surfaceContainerHighest.withValues(alpha: 0.65);
    final fg = isUser ? cs.onPrimaryContainer : cs.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SelectableText(
                message.content,
                style: TextStyle(color: fg, height: 1.35),
              ),
            ),
            if (!isUser && onSpeak != null) ...[
              const SizedBox(width: 6),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                tooltip: 'Speak',
                onPressed: onSpeak,
                icon: isTtsActive && isTtsLoading
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: fg.withValues(alpha: 0.85),
                        ),
                      )
                    : Icon(
                        isTtsActive && isTtsPlaying
                            ? Icons.pause_rounded
                            : isTtsActive && isTtsPaused
                                ? Icons.play_arrow_rounded
                                : Icons.volume_up_rounded,
                        color: fg,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
