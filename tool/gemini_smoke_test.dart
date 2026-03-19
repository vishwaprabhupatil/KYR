import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> main(List<String> args) async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln(
      'Missing GEMINI_API_KEY.\n'
      'Run like:\n'
      '  GEMINI_API_KEY="YOUR_KEY" dart run tool/gemini_smoke_test.dart\n',
    );
    exitCode = 2;
    return;
  }

  final modelName = args.isNotEmpty ? args.first : 'gemini-2.5-flash';
  final model = GenerativeModel(model: modelName, apiKey: apiKey.trim());

  try {
    final res = await model.generateContent([
      Content.text('Reply with exactly: OK'),
    ]);
    stdout.writeln('Model: $modelName');
    stdout.writeln('Response: ${res.text ?? '(no text)'}');
  } catch (e) {
    stderr.writeln('Gemini call failed: $e');
    exitCode = 1;
  }
}
