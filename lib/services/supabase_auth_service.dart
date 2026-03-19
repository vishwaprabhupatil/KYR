import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_service.dart';

class SupabaseAuthService {
  SupabaseClient get _client => SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim()},
    );
    // Many hackathon setups disable email confirmations; this will sign-in right away.
    // If your Supabase project requires email verification, sign-in will fail until verified.
    await signIn(email: email, password: password);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
