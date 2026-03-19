import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';

class SupabaseService {
  static String? initError;

  static Future<void> init() async {
    if (AppConfig.supabaseAnonKey.trim().isEmpty) {
      initError =
          'Missing Supabase anon key in AppConfig.supabaseAnonKey.';
      return;
    }
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      initError = null;
    } catch (e) {
      initError = 'Supabase init failed: $e';
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
