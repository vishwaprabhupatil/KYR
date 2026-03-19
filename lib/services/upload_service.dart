import 'dart:io';
import 'dart:convert';

import '../core/api_service.dart';

class UploadService {
  UploadService({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Future<String> uploadDocument({
    required File file,
    required String language,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final isImage = ext == 'png' || ext == 'jpg' || ext == 'jpeg';

    final res = isImage
        ? await _api.postJson(
            '/upload',
            body: {
              'language': language,
              'filename': file.path.split(Platform.pathSeparator).last,
              // Some backends accept base64 for images for OCR.
              'image_base64': base64Encode(await file.readAsBytes()),
            },
          )
        : await _api.postMultipart(
            '/upload',
            file: file,
            fileField: 'file',
            fields: {'language': language},
          );

    final data = res.data;
    if (data is Map) {
      final id = data['document_id'] ?? data['id'] ?? data['doc_id'];
      if (id != null) return id.toString();
    }
    throw const FormatException('Upload response missing document id.');
  }
}
