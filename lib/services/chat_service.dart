import '../core/api_service.dart';

class ChatService {
  ChatService({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Future<String> ask({
    required String documentId,
    required String question,
    String? language,
    Map<String, dynamic>? analysisJson,
  }) async {
    final res = await _api.postJson(
      '/chat',
      body: {
        'document_id': documentId,
        'question': question,
        ...?((language == null) ? null : {'language': language}),
        ...?((analysisJson == null) ? null : {'analysis_json': analysisJson}),
      },
    );

    final data = res.data;
    if (data is Map) {
      final answer = data['answer'] ?? data['response'] ?? data['message'];
      if (answer != null) return answer.toString();
    }
    if (data is String) return data;
    throw const FormatException('Chat response missing answer.');
  }
}
