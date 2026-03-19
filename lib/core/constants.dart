class AppConfig {
  static const String baseUrl = 'http://10.144.123.217:8000';
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 180);

  // For local testing without backend (NOT recommended for production).
  // Run with: `flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY`
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  // Supabase (safe for client). Do NOT use database connection strings in Flutter.
  static const String supabaseUrl = 'https://eqelkebjwzwcqsjxktza.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxZWxrZWJqd3p3Y3FzanhrdHphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzNDk2MTYsImV4cCI6MjA4ODkyNTYxNn0.bPN0xL0jlLk7VgEdC119R-qB4eCHGd4gY0nBPSK1rew';
}

class AppStrings {
  static const String appTitle = 'KYY – Know Your Rights';
  static const String appSubtitle =
      'Understand Legal Documents in Your Language';

  static const List<String> supportedLanguages = <String>[
    'English',
    'Hindi',
    'Kannada',
    'Marathi',
    'Tamil',
    'Telugu',
    'Bengali',
  ];
}
