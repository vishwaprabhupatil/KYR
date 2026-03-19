import 'package:flutter/foundation.dart';

import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  final List<ChatMessage> _messages = [];
  bool isSending = false;
  String? errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void loadMessages(List<ChatMessage> messages) {
    _messages
      ..clear()
      ..addAll(messages);
    errorMessage = null;
    isSending = false;
    notifyListeners();
  }

  void reset() {
    _messages.clear();
    isSending = false;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> send({
    required String documentId,
    required String question,
    String? language,
    Map<String, dynamic>? analysisJson,
  }) async {
    if (question.trim().isEmpty) return;
    errorMessage = null;
    isSending = true;

    _messages.add(
      ChatMessage(
        role: ChatRole.user,
        content: question.trim(),
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();

    try {
      final answer = await _chatService.ask(
        documentId: documentId,
        question: question.trim(),
        language: language,
        analysisJson: analysisJson,
      );
      _messages.add(
        ChatMessage(
          role: ChatRole.assistant,
          content: answer,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
