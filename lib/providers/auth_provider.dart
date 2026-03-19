import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/supabase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider();

  final SupabaseAuthService _auth = SupabaseAuthService();

  UserAccount? user;
  bool isReady = false;
  bool isBusy = false;
  bool isFirstLaunch = true;
  String? errorMessage;

  String get email => user?.email ?? '';
  String get name => user?.name ?? '';

  Future<void> init() async {
    // Supabase persists session automatically; if present, treat as logged in.
    user = _auth.currentUser == null
        ? null
        : UserAccount(
            name: (_auth.currentUser!.userMetadata?['name'] ?? '').toString(),
            email: _auth.currentUser!.email ?? '',
            password: '',
          );
    // Keep "first launch" behavior simple for hackathon: always show Get Started
    // only when no session exists on fresh installs.
    isFirstLaunch = user == null;
    isReady = true;
    notifyListeners();

    _auth.onAuthStateChange.listen((state) {
      final u = state.session?.user ?? _auth.currentUser;
      user = u == null
          ? null
          : UserAccount(
              name: (u.userMetadata?['name'] ?? '').toString(),
              email: u.email ?? '',
              password: '',
            );
      notifyListeners();
    });
  }

  Future<void> completeFirstLaunch() async {
    isFirstLaunch = false;
    notifyListeners();
  }

  Future<void> signup(String name, String email, String password) async {
    errorMessage = null;
    isBusy = true;
    notifyListeners();
    try {
      await _auth.signUp(name: name, email: email, password: password);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    errorMessage = null;
    isBusy = true;
    notifyListeners();
    try {
      await _auth.signIn(email: email, password: password);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    user = null;
    notifyListeners();
  }
}
