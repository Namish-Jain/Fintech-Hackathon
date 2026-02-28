import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/byte_model.dart';
import '../theme/app_theme.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

/// Which content tab is active: 0=Overview 1=ELI5 2=Takeaway 3=Social
final contentTabProvider = StateProvider.family<int, String>((ref, id) => 0);

/// Whether the category dropdown is open
final categoryDropdownProvider = StateProvider<bool>((ref) => false);

// ─── Constants ────────────────────────────────────────────────────────────────

const List<String> _kCategories = [
  'MyDigest',
  'Markets',
  'Economy',
  'Policy',
  'Company Moves',
  'Money & Credit',
  'Personal Finance',
  'Crypto Currency',
];

const List<Map<String, String>> _kTabs = [
  {'icon': '📰', 'label': 'Actual Overview'},
  {'icon': '🧒', 'label': "Explain Like I'm 5"},
  {'icon': '⚡', 'label': 'Actionable Takeaway'},
  {'icon': '💬', 'label': 'Social Views'},
];

// ─── ByteCard ─────────────────────────────────────────────────────────────────

class ByteCard extends ConsumerWidget {
  final Byte byte;

  const ByteCard({super.key, required this.byte});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(contentTabProvider(byte.id));
    final dropdownOpen = ref.watch(categoryDropdownProvider);
    final categoryColor =
        AppColors.categoryColors[byte.category] ?? AppColors.neonGreen;
    final size = MediaQuery.of(context).size;
    // Top safe area + appbar height — card starts below the title bar
    final topPadding = MediaQuery.of(context).padding.top + 60;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          // ── Main card ────────────────────────────────────────────────────
          Positioned(
            top: topPadding,
            left: 16,
            right: 16,
            bottom: 10,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.08),
                    blurRadius: 40,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Top glow
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              categoryColor.withOpacity(0.12),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Category + Source row (slightly lower than before) ──
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _CategoryBadge(
                                label: byte.category,
                                color: categoryColor,
                                onTap: () => ref
                                    .read(categoryDropdownProvider.notifier)
                                    .state = !dropdownOpen,
                              ),
                              _SourceBadge(source: byte.source),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // ── Title ───────────────────────────────────────
                          Text(
                            byte.title,
                            style: Theme.of(context).textTheme.headlineLarge,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 20),

                          // ── Divider ──────────────────────────────────────
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  categoryColor.withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Content area ─────────────────────────────────
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.04),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: _buildContent(
                                context, activeTab, categoryColor),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── 4-tab switcher bar ───────────────────────────
                          _ContentTabBar(
                            activeTab: activeTab,
                            color: categoryColor,
                            onTabSelected: (i) => ref
                                .read(contentTabProvider(byte.id).notifier)
                                .state = i,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Category dropdown overlay ─────────────────────────────────────
          if (dropdownOpen) ...[
            // Scrim — tapping outside closes the dropdown
            Positioned.fill(
              child: GestureDetector(
                onTap: () => ref
                    .read(categoryDropdownProvider.notifier)
                    .state = false,
                child: AnimatedOpacity(
                  opacity: dropdownOpen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(color: Colors.black.withOpacity(0.6)),
                ),
              ),
            ),
            // Dropdown panel
            Positioned(
              top: topPadding + 20,
              left: 16,
              child: _CategoryDropdown(
                categoryColor: categoryColor,
                onClose: () => ref
                    .read(categoryDropdownProvider.notifier)
                    .state = false,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, int tab, Color color) {
    switch (tab) {
      case 0:
        return _BulletList(
          key: const ValueKey('overview'),
          bullets: byte.summaryBullets,
          color: color,
        );
      case 1:
        return _Eli5Content(
          key: const ValueKey('eli5'),
          content: byte.eli5Content,
          color: color,
        );
      case 2:
        return _EmptyTabBox(
          key: const ValueKey('takeaway'),
          icon: '⚡',
          label: 'Actionable Takeaway',
          color: color,
        );
      case 3:
        return _EmptyTabBox(
          key: const ValueKey('social'),
          icon: '💬',
          label: 'Social Views',
          color: color,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryBadge({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: color),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonGreen,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          source,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> bullets;
  final Color color;

  const _BulletList({super.key, required this.bullets, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bullets.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2, right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color.withOpacity(0.5), width: 1),
                ),
                child: Center(
                  child: Text(
                    '${entry.key + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Eli5Content extends StatelessWidget {
  final String content;
  final Color color;

  const _Eli5Content({super.key, required this.content, required this.color});

  @override
  Widget build(BuildContext context) {
    return _StyledBox(
      color: color,
      icon: '🧒',
      label: 'Explained Simply',
      child: Text(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontStyle: FontStyle.italic,
              height: 1.7,
            ),
      ),
    );
  }
}

/// Placeholder box for tabs not yet wired to content (Takeaway, Social)
class _EmptyTabBox extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _EmptyTabBox({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _StyledBox(
      color: color,
      icon: icon,
      label: label,
      child: const SizedBox.shrink(),
    );
  }
}

/// Shared styled container used by ELI5, Takeaway, Social tabs
class _StyledBox extends StatelessWidget {
  final Color color;
  final String icon;
  final String label;
  final Widget child;

  const _StyledBox({
    required this.color,
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: color, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─── 4-tab content switcher bar ───────────────────────────────────────────────

class _ContentTabBar extends StatelessWidget {
  final int activeTab;
  final Color color;
  final ValueChanged<int> onTabSelected;

  const _ContentTabBar({
    required this.activeTab,
    required this.color,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(_kTabs.length, (i) {
          final isActive = i == activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _kTabs[i]['icon']!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _shortLabel(i),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: isActive
                            ? AppColors.deepNavy
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Shortened label so tabs fit on narrow screens
  String _shortLabel(int i) {
    const short = ['Overview', "ELI5", 'Takeaway', 'Social'];
    return short[i];
  }
}

// ─── Category dropdown ────────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final Color categoryColor;
  final VoidCallback onClose;

  const _CategoryDropdown({
    required this.categoryColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF111830),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'SWITCH FEED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 4),
            ..._kCategories.map((cat) => _DropdownItem(
                  label: cat,
                  isMyDigest: cat == 'MyDigest',
                  // TODO: wire to DB/state in Phase 3
                  onTap: onClose,
                )),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _DropdownItem extends StatelessWidget {
  final String label;
  final bool isMyDigest;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.label,
    required this.isMyDigest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              _categoryIcon(label),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isMyDigest ? FontWeight.w700 : FontWeight.w500,
                  color: isMyDigest
                      ? AppColors.neonGreen
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isMyDigest)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DEFAULT',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.neonGreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _categoryIcon(String cat) {
    const icons = {
      'MyDigest': '⭐',
      'Markets': '📈',
      'Economy': '🏛️',
      'Policy': '📋',
      'Company Moves': '🏢',
      'Money & Credit': '💳',
      'Personal Finance': '💰',
      'Crypto Currency': '₿',
    };
    return icons[cat] ?? '📰';
  }
}
