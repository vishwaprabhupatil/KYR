import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/supabase_service.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/document_provider.dart';
import 'screens/landing_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/get_started_screen.dart';
import 'providers/history_provider.dart';
import 'services/supabase_history_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Supabase init must succeed to use auth/history. Provide key at runtime.
  // flutter run --dart-define=SUPABASE_ANON_KEY=...
  await SupabaseService.init();
  runApp(const KyyApp());
}

class KyyApp extends StatelessWidget {
  const KyyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProxyProvider<AuthProvider, HistoryProvider>(
          create: (_) => HistoryProvider(),
          update: (context, auth, prev) {
            final next = prev ?? HistoryProvider();
            if (!auth.isReady) return next;
            if (auth.user == null) {
              next.reset();
              return next;
            }
            next.configure(service: SupabaseHistoryService());
            return next;
          },
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildKyyTheme(Brightness.light),
        darkTheme: buildKyyTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const SplashScreen(next: _SupabaseGate()),
      ),
    );
  }
}

class _SupabaseGate extends StatelessWidget {
  const _SupabaseGate();

  @override
  Widget build(BuildContext context) {
    final err = SupabaseService.initError;
    if (err == null) return const _AuthGate();

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.appTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Supabase is not configured.',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                err,
                style: TextStyle(color: cs.error),
              ),
              const SizedBox(height: 18),
              Text(
                'Run with:',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              SelectableText(
                'flutter run --dart-define=SUPABASE_ANON_KEY="YOUR_KEY"',
                style: TextStyle(color: cs.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.user != null) return const LandingScreen();
        return auth.isFirstLaunch ? const GetStartedScreen() : const LoginScreen();
      },
    );
  }
}
