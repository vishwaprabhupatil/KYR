import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/constants.dart';
import '../models/document_model.dart';

class GeminiService {
  GeminiService({String? apiKey})
      : _apiKey = (apiKey ?? AppConfig.geminiApiKey).trim();

  final String _apiKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<DocumentAnalysis> analyzeImage({
    required File imageFile,
    required String language,
  }) async {
    if (!isConfigured) {
      throw const FormatException(
        'Missing GEMINI_API_KEY. Run with --dart-define=GEMINI_API_KEY=YOUR_KEY',
      );
    }

    final bytes = await imageFile.readAsBytes();
    final mimeType = _guessImageMime(imageFile.path);
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

    final prompt = _analysisPrompt(language);
    final res = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart(mimeType, Uint8List.fromList(bytes)),
      ]),
    ]);

    final text = (res.text ?? '').trim();
    if (text.isEmpty) {
      throw const FormatException('Gemini returned empty response.');
    }

    final jsonStr = _extractJson(text);
    final map = jsonDecode(jsonStr);
    if (map is! Map) {
      throw const FormatException('Gemini response is not a JSON object.');
    }
    return DocumentAnalysis.fromJson(map.cast<String, dynamic>());
  }

  String _analysisPrompt(String language) {
    return '''
You are KYY (Know Your Rights). The user uploaded a legal document image.

Task:
1) Read the document from the image (OCR-like).
2) Produce a simple explanation in $language (very easy words for rural India).
3) Identify risky clauses and alerts.
4) Provide a contract safety score (0-100) and risk level (Low/Medium/High).

Output MUST be valid JSON only (no markdown, no extra text) with exactly these keys:
{
  "safety_score": number,
  "risk_level": "Low" | "Medium" | "High",
  "clauses": [{"title": string, "summary": string, "severity": "Low" | "Medium" | "High"}],
  "risk_alerts": [string],
  "translated_text": string,
  "simplified_explanation": string
}

Rules:
- If something is missing/unclear, state it in risk_alerts.
- translated_text should be the document content translated to $language (best effort).
- simplified_explanation must be in $language.
''';
  }

  String _guessImageMime(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }

  String _extractJson(String text) {
    // Some models may wrap JSON in text; extract the first {...} block.
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw FormatException('Could not find JSON in Gemini response: $text');
    }
    return text.substring(start, end + 1);
  }
}

