import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_service.dart';
import '../models/chat_model.dart';
import '../models/history_model.dart';

class SupabaseHistoryService {
  SupabaseClient get _client => SupabaseService.client;

  String get _userId {
    final u = _client.auth.currentUser;
    if (u == null) throw const AuthException('Not authenticated');
    return u.id;
  }

  Future<List<UploadHistoryItem>> fetchUploads() async {
    final rows = await _client
        .from('documents')
        .select(
          'backend_document_id,filename,language,risk_level,safety_score,created_at,analysis_json',
        )
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (rows as List)
        .whereType<Map>()
        .map((r) {
          return UploadHistoryItem(
            documentId: (r['backend_document_id'] ?? '').toString(),
            fileName: (r['filename'] ?? '').toString(),
            language: (r['language'] ?? '').toString(),
            createdAt:
                DateTime.tryParse((r['created_at'] ?? '').toString()) ?? DateTime.now(),
            riskLevel: (r['risk_level'] ?? 'Unknown').toString(),
            safetyScore: (r['safety_score'] is num)
                ? (r['safety_score'] as num).toDouble()
                : 0,
            analysisJson: (r['analysis_json'] is Map)
                ? (r['analysis_json'] as Map).cast<String, dynamic>()
                : null,
          );
        })
        .toList();
  }

  Future<void> addUpload(UploadHistoryItem item) async {
    final base = {
      'user_id': _userId,
      'backend_document_id': item.documentId,
      'filename': item.fileName,
      'language': item.language,
      'risk_level': item.riskLevel,
      'safety_score': item.safetyScore,
      'created_at': item.createdAt.toIso8601String(),
    };
    try {
      await _client.from('documents').insert({
        ...base,
        if (item.analysisJson != null) 'analysis_json': item.analysisJson,
      });
    } on PostgrestException catch (e) {
      // If the column doesn't exist yet (migration not applied), retry without it.
      final msg = e.message.toLowerCase();
      final details = (e.details ?? '').toString().toLowerCase();
      if (msg.contains('analysis_json') || details.contains('analysis_json')) {
        await _client.from('documents').insert(base);
        return;
      }
      rethrow;
    }
  }

  Future<List<ChatThread>> fetchThreads() async {
    // Get distinct backend_document_id threads by ordering messages.
    final rows = await _client
        .from('chat_messages')
        .select('backend_document_id,role,content,created_at')
        .eq('user_id', _userId)
        .order('created_at', ascending: true);

    final grouped = <String, List<ChatMessage>>{};
    final updatedAt = <String, DateTime>{};
    for (final row in (rows as List).whereType<Map>()) {
      final docId = (row['backend_document_id'] ?? '').toString();
      if (docId.isEmpty) continue;
      final roleStr = (row['role'] ?? 'user').toString();
      final created = DateTime.tryParse((row['created_at'] ?? '').toString()) ??
          DateTime.now();
      grouped.putIfAbsent(docId, () => []);
      grouped[docId]!.add(
        ChatMessage(
          role: roleStr == 'assistant' ? ChatRole.assistant : ChatRole.user,
          content: (row['content'] ?? '').toString(),
          createdAt: created,
        ),
      );
      updatedAt[docId] = created;
    }

    return grouped.entries
        .map((e) => ChatThread(documentId: e.key, messages: e.value, updatedAt: updatedAt[e.key] ?? DateTime.now()))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> addChatMessages({
    required String backendDocumentId,
    required List<ChatMessage> messages,
  }) async {
    final payload = messages
        .map(
          (m) => {
            'user_id': _userId,
            'backend_document_id': backendDocumentId,
            'role': m.role.name,
            'content': m.content,
            'created_at': m.createdAt.toIso8601String(),
          },
        )
        .toList();
    await _client.from('chat_messages').insert(payload);
  }
}
