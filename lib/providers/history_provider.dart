import 'package:flutter/foundation.dart';

import '../models/history_model.dart';
import '../services/supabase_history_service.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider({
    SupabaseHistoryService? service,
  }) : _service = service;

  SupabaseHistoryService? _service;

  List<UploadHistoryItem> uploads = [];
  List<ChatThread> threads = [];

  bool get isReady => _service != null;

  void configure({required SupabaseHistoryService service}) {
    _service = service;
    // Fire-and-forget refresh.
    load();
  }

  void reset() {
    _service = null;
    uploads = [];
    threads = [];
    notifyListeners();
  }

  Future<void> load() async {
    final s = _service;
    if (s == null) return;
    try {
      uploads = await s.fetchUploads();
      threads = await s.fetchThreads();
    } finally {
      notifyListeners();
    }
  }

  Future<void> addUpload(UploadHistoryItem item) async {
    final s = _service;
    if (s == null) return;
    await s.addUpload(item);
    uploads = [item, ...uploads];
    notifyListeners();
  }

  Future<void> upsertThread(ChatThread thread) async {
    final s = _service;
    if (s == null) return;
    // Persist only the delta messages is complex; easiest hackathon approach:
    // insert all messages again is not ideal; so insert just new messages by length.
    final existing = threads.where((t) => t.documentId == thread.documentId).toList();
    final existingCount = existing.isEmpty ? 0 : existing.first.messages.length;
    final newMessages = thread.messages.skip(existingCount).toList();
    if (newMessages.isNotEmpty) {
      await s.addChatMessages(
        backendDocumentId: thread.documentId,
        messages: newMessages,
      );
    }
    // Update in-memory list
    threads = [
      ...threads.where((t) => t.documentId != thread.documentId),
      thread,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }
}
