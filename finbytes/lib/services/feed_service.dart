import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/byte_model.dart';

/// Fetches cards from the `finbytes` table, joined with `news_articles`
/// for headline and source, sorted by impact_score descending.
class FeedService {
  static final _db = Supabase.instance.client;

  // ── Fetch all cards for a single named category ───────────────────────────

  static Future<List<Byte>> fetchByCategory(String category) async {
    final rows = await _db
        .from('finbytes')
        .select('*, news_articles!inner(headline, source_name)')
        .eq('category', category)
        .order('impact_score', ascending: false);

    return (rows as List)
        .map((r) => Byte.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch MyDigest: cards from any of the user's chosen categories ────────

  static Future<List<Byte>> fetchMyDigest(List<String> categories) async {
    if (categories.isEmpty) return [];

    final rows = await _db
        .from('finbytes')
        .select('*, news_articles!inner(headline, source_name)')
        .inFilter('category', categories)
        .order('impact_score', ascending: false);

    return (rows as List)
        .map((r) => Byte.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch the current user's chosen categories from profiles ─────────────

  static Future<List<String>> fetchUserCategories(String userId) async {
    final row = await Supabase.instance.client
        .from('profiles')
        .select('categories')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return [];
    final raw = row['categories'];
    if (raw == null) return [];
    // Supabase returns text[] as a List<dynamic>
    return List<String>.from(raw as List);
  }
}
