import 'chat_model.dart';

class UploadHistoryItem {
  const UploadHistoryItem({
    required this.documentId,
    required this.fileName,
    required this.language,
    required this.createdAt,
    required this.riskLevel,
    required this.safetyScore,
    this.analysisJson,
  });

  final String documentId;
  final String fileName;
  final String language;
  final DateTime createdAt;
  final String riskLevel;
  final double safetyScore;
  final Map<String, dynamic>? analysisJson;

  Map<String, dynamic> toJson() => {
        'document_id': documentId,
        'file_name': fileName,
        'language': language,
        'created_at': createdAt.toIso8601String(),
        'risk_level': riskLevel,
        'safety_score': safetyScore,
        if (analysisJson != null) 'analysis_json': analysisJson,
      };

  factory UploadHistoryItem.fromJson(Map<String, dynamic> json) =>
      UploadHistoryItem(
        documentId: (json['document_id'] ?? '').toString(),
        fileName: (json['file_name'] ?? '').toString(),
        language: (json['language'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        riskLevel: (json['risk_level'] ?? 'Unknown').toString(),
        safetyScore: (json['safety_score'] is num)
            ? (json['safety_score'] as num).toDouble()
            : 0,
        analysisJson: (json['analysis_json'] is Map)
            ? (json['analysis_json'] as Map).cast<String, dynamic>()
            : null,
      );
}

class ChatThread {
  const ChatThread({
    required this.documentId,
    required this.messages,
    required this.updatedAt,
  });

  final String documentId;
  final List<ChatMessage> messages;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'document_id': documentId,
        'updated_at': updatedAt.toIso8601String(),
        'messages': messages
            .map(
              (m) => {
                'role': m.role.name,
                'content': m.content,
                'created_at': m.createdAt.toIso8601String(),
              },
            )
            .toList(),
      };

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final msgs = (json['messages'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (e) => ChatMessage(
            role: (e['role']?.toString() == 'assistant')
                ? ChatRole.assistant
                : ChatRole.user,
            content: (e['content'] ?? '').toString(),
            createdAt: DateTime.tryParse((e['created_at'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0),
          ),
        )
        .toList();

    return ChatThread(
      documentId: (json['document_id'] ?? '').toString(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      messages: msgs,
    );
  }
}
