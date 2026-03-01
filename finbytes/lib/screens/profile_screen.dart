import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/feed_providers.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

const List<String> _kAllCategories = [
  'Markets',
  'Economy',
  'Personal Finance',
  'Crypto Currency',
  'Policy',
  'Money & Credit',
  'Company Moves',
];

// ─── Provider ─────────────────────────────────────────────────────────────────

final profileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  return ProfileService.loadProfile();
});

// ─── ProfileScreen ────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Set<String> _selectedCategories = {};
  bool _categoriesLoaded = false;
  bool _savingCategories = false;

  void _initCategories(UserProfile profile) {
    if (!_categoriesLoaded) {
      _selectedCategories = Set.from(profile.categories);
      _categoriesLoaded = true;
    }
  }

  Future<void> _saveCategories() async {
    setState(() => _savingCategories = true);
    await ProfileService.updateCategories(_selectedCategories.toList());
    // Invalidate the feed so MyDigest reloads with new categories
    ref.invalidate(userCategoriesProvider);
    ref.invalidate(feedProvider);
    if (mounted) setState(() => _savingCategories = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Categories saved!',
              style: TextStyle(color: AppColors.deepNavy)),
          backgroundColor: AppColors.neonGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 60;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.neonGreen, strokeWidth: 2.5),
        ),
        error: (e, _) => Center(
          child: Text('Error loading profile: $e',
              style: const TextStyle(color: AppColors.negative)),
        ),
        data: (profile) {
          if (profile != null) _initCategories(profile);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, topPadding + 24, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar + email + logout ───────────────────────────────
                Row(
                  children: [
                    // Avatar circle
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardSurface,
                        border: Border.all(
                            color: AppColors.neonGreen.withOpacity(0.4),
                            width: 2),
                      ),
                      child: Center(
                        child: Text(
                          profile != null && profile.email.isNotEmpty
                              ? profile.email[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neonGreen,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Signed in as',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              )),
                          const SizedBox(height: 2),
                          Text(
                            profile?.email ?? '—',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Logout button
                    GestureDetector(
                      onTap: _logout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.cardBorder, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout_rounded,
                                size: 14,
                                color: AppColors.textSecondary),
                            SizedBox(width: 6),
                            Text('Logout',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Stats row ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.cardBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCell(
                          value: profile?.cardsRead.toString() ?? '0',
                          label: 'Cards Read',
                          icon: '📖',
                        ),
                      ),
                      Container(
                          width: 1, height: 44, color: AppColors.cardBorder),
                      Expanded(
                        child: _StatCell(
                          value: profile != null
                              ? '${profile.streakDays}d'
                              : '0d',
                          label: 'Streak',
                          icon: '🔥',
                          valueColor: profile != null &&
                                  profile.streakDays >= 3
                              ? AppColors.warning
                              : null,
                        ),
                      ),
                      Container(
                          width: 1, height: 44, color: AppColors.cardBorder),
                      Expanded(
                        child: _StatCell(
                          value:
                              _selectedCategories.length.toString(),
                          label: 'Categories',
                          icon: '🗂️',
                          valueColor: AppColors.neonGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── My Categories ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${_selectedCategories.length}/${_kAllCategories.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                const Text(
                  'These categories appear in your MyDigest feed.',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4),
                ),

                const SizedBox(height: 16),

                // Category checkboxes
                ..._kAllCategories.map((cat) {
                  final isSelected = _selectedCategories.contains(cat);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategoryTile(
                      label: cat,
                      isSelected: isSelected,
                      onTap: () => setState(() {
                        isSelected
                            ? _selectedCategories.remove(cat)
                            : _selectedCategories.add(cat);
                      }),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // Save categories button
                GestureDetector(
                  onTap: _savingCategories ? null : _saveCategories,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _savingCategories
                          ? AppColors.neonGreen.withOpacity(0.5)
                          : AppColors.neonGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _savingCategories
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.deepNavy,
                              ),
                            )
                          : const Text(
                              'Save Categories',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepNavy,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Stat cell ────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final String icon;
  final Color? valueColor;

  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Category tile ────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const Map<String, String> _icons = {
    'Markets': '📈',
    'Economy': '🏛️',
    'Personal Finance': '💰',
    'Crypto Currency': '₿',
    'Policy': '📋',
    'Money & Credit': '💳',
    'Company Moves': '🏢',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonGreen.withOpacity(0.10)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? AppColors.neonGreen : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(_icons[label] ?? '📰',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.neonGreen
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? AppColors.neonGreen
                      : AppColors.textSecondary,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: AppColors.deepNavy)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
