import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'services/profile_service.dart';
import 'screens/feed_screen.dart';
import 'theme/app_theme.dart';

// ── Supabase credentials ──────────────────────────────────────────────────────
// Replace these values with your own from the Supabase Dashboard →
// Project Settings → API
const _kSupabaseUrl = 'https://xmnniehssmlhmxxicpsv.supabase.co';
const _kSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhtbm5pZWhzc21saG14eGljcHN2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjI5MTI0NywiZXhwIjoyMDg3ODY3MjQ3fQ.BAlrknbAuhMEFWlhnzRVDMjjhRzGrHv0OnUnlgpz6o0';
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Supabase before anything else
  await Supabase.initialize(
    url: _kSupabaseUrl,
    anonKey: _kSupabaseAnonKey,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.deepNavy,
    ),
  );

  runApp(const ProviderScope(child: FinBytesApp()));
}

class FinBytesApp extends StatelessWidget {
  const FinBytesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinBytes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _RootRouter(),
    );
  }
}

/// Decides the first screen. Also refreshes the streak on each app open.
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget streak update — only runs if the user is logged in
    ProfileService.refreshStreak();
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const FeedScreen();
    }
    return const AuthScreen();
  }
}
