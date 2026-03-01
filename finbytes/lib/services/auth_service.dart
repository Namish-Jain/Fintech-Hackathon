import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth + profiles table.
/// All callers get typed results — no raw exceptions leak into UI.
class AuthService {
  static final _client = Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user == null) {
        return AuthResult.error('Sign-up failed. Please try again.');
      }
      return AuthResult.success(res.user!);
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (_) {
      return AuthResult.error('An unexpected error occurred.');
    }
  }

  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) {
        return AuthResult.error('Login failed. Check your credentials.');
      }
      return AuthResult.success(res.user!);
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (_) {
      return AuthResult.error('An unexpected error occurred.');
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Session ───────────────────────────────────────────────────────────────

  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  /// Returns true when the user has logged in before and already has
  /// a profile row — i.e. they have completed onboarding.
  static Future<bool> hasCompletedOnboarding() async {
    final uid = currentUser?.id;
    if (uid == null) return false;
    final res = await _client
        .from('profiles')
        .select('id')
        .eq('id', uid)
        .maybeSingle();
    return res != null;
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  /// Called at the end of onboarding to create the profile row.
  ///
  /// SQL to run in Supabase Dashboard → SQL Editor (run once):
  /// ─────────────────────────────────────────────────────────
  /// create table if not exists public.profiles (
  ///   id                  uuid primary key references auth.users(id) on delete cascade,
  ///   email               text,
  ///   financial_literacy  text,          -- 'Beginner' | 'Intermediate' | 'Advanced'
  ///   investing_experience text,         -- '0-2 Years' | '2-5 Years' | '5+ Years'
  ///   categories          text[],        -- e.g. ['Markets','Crypto Currency']
  ///   created_at          timestamptz default now()
  /// );
  /// alter table public.profiles enable row level security;
  /// create policy "Users can manage own profile"
  ///   on public.profiles for all
  ///   using (auth.uid() = id)
  ///   with check (auth.uid() = id);
  /// ─────────────────────────────────────────────────────────
  static Future<void> saveProfile({
    required String financialLiteracy,
    required String investingExperience,
    required List<String> categories,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('No authenticated user.');
    await _client.from('profiles').upsert({
      'id': uid,
      'email': currentUser!.email,
      'financial_literacy': financialLiteracy,
      'investing_experience': investingExperience,
      'categories': categories,
    });
  }

  /// Takes an explicit [userId] — use this right after signUp when email
  /// confirmation is enabled and currentUser is still null.
  static Future<void> saveProfileById({
    required String userId,
    required String email,
    required String financialLiteracy,
    required String investingExperience,
    required List<String> categories,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'email': email,
      'financial_literacy': financialLiteracy,
      'investing_experience': investingExperience,
      'categories': categories,
    });
  }
}

// ── Result type ───────────────────────────────────────────────────────────────

class AuthResult {
  final User? user;
  final String? errorMessage;

  const AuthResult._({this.user, this.errorMessage});

  factory AuthResult.success(User user) => AuthResult._(user: user);
  factory AuthResult.error(String msg) => AuthResult._(errorMessage: msg);

  bool get isSuccess => user != null;
}
