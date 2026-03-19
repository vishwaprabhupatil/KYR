import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../core/api_service.dart';

sealed class TtsResult {
  const TtsResult();
}

class TtsUrlResult extends TtsResult {
  const TtsUrlResult(this.url);
  final String url;
}

class TtsFileResult extends TtsResult {
  const TtsFileResult(this.file);
  final File file;
}

class TtsService {
  TtsService({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Map<String, dynamic>? _maybeLanguage(String? language) =>
      language == null ? null : <String, dynamic>{'language': language};

  Future<TtsResult> generate({
    required String documentId,
    String? language,
  }) async {
    // Prefer bytes first; if backend returns JSON, we fall back to URL parsing.
    try {
      final bytesRes = await _api.postBytes(
        '/tts',
        body: {
          'document_id': documentId,
          ...?_maybeLanguage(language),
        },
      );
      final contentType =
          (bytesRes.headers.value(Headers.contentTypeHeader) ?? '')
              .toLowerCase();

      if (contentType.contains('application/json')) {
        // Backend returned JSON even though we requested bytes.
        // Fall back to normal JSON call.
      } else {
        final bytes = Uint8List.fromList(bytesRes.data ?? const <int>[]);
        if (bytes.isEmpty) {
          throw const FormatException('TTS response returned empty audio.');
        }
        final dir = await getTemporaryDirectory();
        final out = File('${dir.path}/kyy_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await out.writeAsBytes(bytes, flush: true);
        return TtsFileResult(out);
      }
    } on DioException {
      // Fall back to JSON.
    } on FormatException {
      rethrow;
    }

    final jsonRes = await _api.postJson(
      '/tts',
      body: {
        'document_id': documentId,
        ...?_maybeLanguage(language),
      },
    );
    final data = jsonRes.data;
    if (data is Map) {
      final url = data['audio_url'] ?? data['url'] ?? data['audio'];
      if (url != null) return TtsUrlResult(url.toString());
    }
    throw const FormatException('TTS response missing audio url/bytes.');
  }

  Future<TtsResult> generateText({
    required String text,
    String? language,
  }) async {
    final bytesRes = await _api.postBytes(
      '/tts_text',
      body: {
        'text': text,
        ...?_maybeLanguage(language),
      },
    );
    final bytes = Uint8List.fromList(bytesRes.data ?? const <int>[]);
    if (bytes.isEmpty) {
      throw const FormatException('TTS response returned empty audio.');
    }
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/kyy_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await out.writeAsBytes(bytes, flush: true);
    return TtsFileResult(out);
  }
}
