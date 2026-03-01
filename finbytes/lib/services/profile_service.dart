import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all profile read/write operations:
/// - loading the user's profile
/// - updating categories
/// - tracking streak and cards_read
///
/// SQL to run once in Supabase SQL Editor to add the new columns:
/// ─────────────────────────────────────────────────────────────
/// alter table public.profiles
///   add column if not exists streak_days     int4 default 0,
///   add column if not exists cards_read      int4 default 0,
///   add column if not exists last_opened_at  date;
/// ─────────────────────────────────────────────────────────────
class ProfileService {
  static final _db = Supabase.instance.client;

  static String? get _uid => _db.auth.currentUser?.id;

  // ── Load full profile ─────────────────────────────────────────────────────

  static Future<UserProfile?> loadProfile() async {
    final uid = _uid;
    if (uid == null) return null;

    final row = await _db
        .from('profiles')
        .select('email, categories, streak_days, cards_read, last_opened_at')
        .eq('id', uid)
        .maybeSingle();

    if (row == null) return null;
    return UserProfile.fromMap(row);
  }

  // ── Update categories ──────────────────────────────────────────────────────

  static Future<void> updateCategories(List<String> categories) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .from('profiles')
        .update({'categories': categories}).eq('id', uid);
  }

  // ── Increment cards read ───────────────────────────────────────────────────

  static Future<void> incrementCardsRead() async {
    final uid = _uid;
    if (uid == null) return;
    // Use rpc for atomic increment; falls back to read-then-write
    try {
      await _db.rpc('increment_cards_read', params: {'user_id': uid});
    } catch (_) {
      // Fallback: read current value then increment
      final row = await _db
          .from('profiles')
          .select('cards_read')
          .eq('id', uid)
          .maybeSingle();
      final current = (row?['cards_read'] as num?)?.toInt() ?? 0;
      await _db
          .from('profiles')
          .update({'cards_read': current + 1}).eq('id', uid);
    }
  }

  // ── Update streak on app open ─────────────────────────────────────────────
  // Increments streak if last open was yesterday; resets to 1 if gap > 1 day;
  // does nothing if already opened today.

  static Future<void> refreshStreak() async {
    final uid = _uid;
    if (uid == null) return;

    final row = await _db
        .from('profiles')
        .select('streak_days, last_opened_at')
        .eq('id', uid)
        .maybeSingle();

    if (row == null) return;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastStr = row['last_opened_at'] as String?;
    final current = (row['streak_days'] as num?)?.toInt() ?? 0;

    int newStreak = current;

    if (lastStr != null) {
      final last = DateTime.parse(lastStr);
      final lastDate = DateTime(last.year, last.month, last.day);
      final diff = todayDate.difference(lastDate).inDays;

      if (diff == 0) return; // already counted today
      if (diff == 1) {
        newStreak = current + 1; // consecutive day
      } else {
        newStreak = 1; // streak broken
      }
    } else {
      newStreak = 1; // first open
    }

    await _db.from('profiles').update({
      'streak_days': newStreak,
      'last_opened_at': todayDate.toIso8601String().substring(0, 10),
    }).eq('id', uid);
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class UserProfile {
  final String email;
  final List<String> categories;
  final int streakDays;
  final int cardsRead;

  const UserProfile({
    required this.email,
    required this.categories,
    required this.streakDays,
    required this.cardsRead,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      email: map['email'] as String? ?? '',
      categories: map['categories'] != null
          ? List<String>.from(map['categories'] as List)
          : [],
      streakDays: (map['streak_days'] as num?)?.toInt() ?? 0,
      cardsRead: (map['cards_read'] as num?)?.toInt() ?? 0,
    );
  }
}
