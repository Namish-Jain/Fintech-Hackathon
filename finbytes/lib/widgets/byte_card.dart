import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/byte_model.dart';
import '../theme/app_theme.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final contentTabProvider = StateProvider.family<int, String>((ref, id) => 0);
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

class ByteCard extends ConsumerStatefulWidget {
  final Byte byte;

  const ByteCard({super.key, required this.byte});

  @override
  ConsumerState<ByteCard> createState() => _ByteCardState();
}

class _ByteCardState extends ConsumerState<ByteCard> {
  late final PageController _tabPageController;

  /// Fractional page position: 0.0 = tab 0 fully visible, 1.0 = tab 1, etc.
  /// Drives the animated divider gradient.
  double _swipeProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabPageController = PageController();
    _tabPageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (_tabPageController.hasClients && _tabPageController.page != null) {
      setState(() => _swipeProgress = _tabPageController.page!);
    }
  }

  @override
  void dispose() {
    _tabPageController.removeListener(_onPageScroll);
    _tabPageController.dispose();
    super.dispose();
  }

  void _onTabSwiped(int page) {
    HapticFeedback.selectionClick();
    ref.read(contentTabProvider(widget.byte.id).notifier).state = page;
  }

  @override
  Widget build(BuildContext context) {
    final dropdownOpen = ref.watch(categoryDropdownProvider);
    final categoryColor =
        AppColors.categoryColors[widget.byte.category] ?? AppColors.neonGreen;
    final size = MediaQuery.of(context).size;
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

                    // Main content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Badges row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _CategoryBadge(
                                label: widget.byte.category,
                                color: categoryColor,
                                onTap: () => ref
                                    .read(categoryDropdownProvider.notifier)
                                    .state = !dropdownOpen,
                              ),
                              _SourceBadge(source: widget.byte.source),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Title
                          Text(
                            widget.byte.title,
                            style: Theme.of(context).textTheme.headlineLarge,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 18),

                          // Animated divider — bright spot travels left→right
                          // as _swipeProgress goes 0→(tabCount-1)
                          _AnimatedDivider(
                            color: categoryColor,
                            progress: _swipeProgress,
                            tabCount: _kTabs.length,
                          ),

                          const SizedBox(height: 14),

                          // Swipeable content PageView
                          Expanded(
                            child: PageView.builder(
                              controller: _tabPageController,
                              itemCount: _kTabs.length,
                              onPageChanged: _onTabSwiped,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return _buildTabContent(
                                    context, index, categoryColor);
                              },
                            ),
                          ),
                          // No bottom bar — removed
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
            Positioned.fill(
              child: GestureDetector(
                onTap: () => ref
                    .read(categoryDropdownProvider.notifier)
                    .state = false,
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),
            ),
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

  Widget _buildTabContent(BuildContext context, int tab, Color color) {
    switch (tab) {
      case 0:
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: _BulletList(bullets: widget.byte.summaryBullets, color: color),
        );
      case 1:
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: _Eli5Content(content: widget.byte.eli5Content, color: color),
        );
      case 2:
        return _EmptyTabBox(icon: '⚡', label: 'Actionable Takeaway', color: color);
      case 3:
        return _EmptyTabBox(icon: '💬', label: 'Social Views', color: color);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Animated divider ─────────────────────────────────────────────────────────

/// The bright stop of the gradient travels from the left edge (progress=0)
/// to the right edge (progress=tabCount-1), tracking the PageView scroll
/// continuously — not just on snapped page changes.
class _AnimatedDivider extends StatelessWidget {
  final Color color;
  final double progress;   // 0.0 … tabCount-1
  final int tabCount;

  const _AnimatedDivider({
    required this.color,
    required this.progress,
    required this.tabCount,
  });

  @override
  Widget build(BuildContext context) {
    // Normalise to 0.0–1.0
    final t = (progress / (tabCount - 1)).clamp(0.0, 1.0);

    // Bright spot width as fraction of total line
    const spotWidth = 0.30;

    // Centre of the bright spot travels from 0 to 1
    final spotCenter = t;
    final spotLeft  = (spotCenter - spotWidth / 2).clamp(0.0, 1.0);
    final spotRight = (spotCenter + spotWidth / 2).clamp(0.0, 1.0);

    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          stops: [
            0.0,
            spotLeft,
            spotCenter,
            spotRight,
            1.0,
          ],
          colors: [
            Colors.transparent,
            color.withOpacity(0.08),
            color.withOpacity(0.75),
            color.withOpacity(0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
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

  const _BulletList({required this.bullets, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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

  const _Eli5Content({required this.content, required this.color});

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

class _EmptyTabBox extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _EmptyTabBox({
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Text(_categoryIcon(label), style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isMyDigest ? FontWeight.w700 : FontWeight.w500,
                  color: isMyDigest ? AppColors.neonGreen : AppColors.textPrimary,
                ),
              ),
            ),
            if (isMyDigest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
