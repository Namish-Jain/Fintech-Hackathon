import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/byte_model.dart';
import '../services/feed_service.dart';

/// The category currently shown in the feed. Defaults to MyDigest.
final activeCategoryProvider = StateProvider<String>((ref) => 'MyDigest');

/// The authenticated user's saved category preferences from profiles table.
final userCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];
  return FeedService.fetchUserCategories(uid);
});

/// The live list of Byte cards. Re-fetches whenever the active category changes.
final feedProvider = FutureProvider.autoDispose<List<Byte>>((ref) async {
  final activeCategory = ref.watch(activeCategoryProvider);
  final userCats = await ref.watch(userCategoriesProvider.future);

  if (activeCategory == 'MyDigest') {
    return FeedService.fetchMyDigest(userCats);
  }
  return FeedService.fetchByCategory(activeCategory);
});
