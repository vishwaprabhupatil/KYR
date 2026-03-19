import '../core/api_service.dart';
import '../models/document_model.dart';

class AnalysisService {
  AnalysisService({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Future<void> runOcr({required String documentId}) async {
    await _api.postJson('/ocr', body: {'document_id': documentId});
  }

  Future<DocumentAnalysis> analyze({
    required String documentId,
    required String language,
  }) async {
    final res = await _api.postJson(
      '/analyze',
      body: {'document_id': documentId, 'language': language},
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return DocumentAnalysis.fromJson(data);
    }
    if (data is Map) {
      return DocumentAnalysis.fromJson(data.cast<String, dynamic>());
    }
    throw const FormatException('Analyze response is not JSON.');
  }
}

