import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/byte_model.dart';
import '../providers/feed_providers.dart';
import '../theme/app_theme.dart';

// ─── Per-card providers ───────────────────────────────────────────────────────

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

// Tab definitions — icons only; labels shown in the animated divider
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
          // ── Card ─────────────────────────────────────────────────────────
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

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Category badge + source — both Flexible to prevent overflow
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: _CategoryBadge(
                                  label: widget.byte.category,
                                  color: categoryColor,
                                  onTap: () => ref
                                      .read(categoryDropdownProvider.notifier)
                                      .state = !dropdownOpen,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: _SourceBadge(
                                    source: widget.byte.sourceName),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Impact score chip
                          _ImpactChip(score: widget.byte.impactScore),

                          const SizedBox(height: 12),

                          // Headline
                          Text(
                            widget.byte.headline,
                            style:
                                Theme.of(context).textTheme.headlineLarge,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 18),

                          // Animated divider
                          _AnimatedDivider(
                            color: categoryColor,
                            progress: _swipeProgress,
                            tabCount: _kTabs.length,
                          ),

                          const SizedBox(height: 14),

                          // Swipeable content
                          Expanded(
                            child: PageView.builder(
                              controller: _tabPageController,
                              itemCount: _kTabs.length,
                              onPageChanged: _onTabSwiped,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) =>
                                  _buildTabContent(
                                      context, index, categoryColor),
                            ),
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
            Positioned.fill(
              child: GestureDetector(
                onTap: () => ref
                    .read(categoryDropdownProvider.notifier)
                    .state = false,
                child:
                    Container(color: Colors.black.withOpacity(0.6)),
              ),
            ),
            Positioned(
              top: topPadding + 20,
              left: 16,
              child: _CategoryDropdown(
                categoryColor: categoryColor,
                onSelect: (cat) {
                  // Update active feed category via provider
                  ref.read(activeCategoryProvider.notifier).state = cat;
                  ref
                      .read(categoryDropdownProvider.notifier)
                      .state = false;
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, int tab, Color color) {
    switch (tab) {
      case 0: // Actual Overview
        return _ScrollableText(
          key: const ValueKey('overview'),
          text: widget.byte.summaryOverview,
          color: color,
          icon: '📰',
          label: 'Actual Overview',
        );
      case 1: // ELI5
        return _ScrollableText(
          key: const ValueKey('eli5'),
          text: widget.byte.summaryEli5,
          color: color,
          icon: '🧒',
          label: 'Explained Simply',
          italic: true,
        );
      case 2: // Actionable Takeaway
        return _ScrollableText(
          key: const ValueKey('takeaway'),
          text: widget.byte.actionableTakeaway,
          color: color,
          icon: '⚡',
          label: 'Actionable Takeaway',
        );
      case 3: // Social Views
        return _ScrollableText(
          key: const ValueKey('social'),
          text: widget.byte.simulatedPublicReaction,
          color: color,
          icon: '💬',
          label: 'Social Views',
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Impact score chip ────────────────────────────────────────────────────────

class _ImpactChip extends StatelessWidget {
  final int score;
  const _ImpactChip({required this.score});

  Color _chipColor() {
    if (score >= 75) return AppColors.negative;
    if (score >= 50) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String _chipLabel() {
    if (score >= 75) return '🔥 HIGH IMPACT';
    if (score >= 50) return '⚡ MED IMPACT';
    return '📊 $score/100';
  }

  @override
  Widget build(BuildContext context) {
    final color = _chipColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        _chipLabel(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

// ─── Animated divider ─────────────────────────────────────────────────────────

class _AnimatedDivider extends StatelessWidget {
  final Color color;
  final double progress;
  final int tabCount;

  const _AnimatedDivider({
    required this.color,
    required this.progress,
    required this.tabCount,
  });

  @override
  Widget build(BuildContext context) {
    final t = (progress / (tabCount - 1)).clamp(0.0, 1.0);
    const spotWidth = 0.30;
    final spotCenter = t;
    final spotLeft = (spotCenter - spotWidth / 2).clamp(0.0, 1.0);
    final spotRight = (spotCenter + spotWidth / 2).clamp(0.0, 1.0);

    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          stops: [0.0, spotLeft, spotCenter, spotRight, 1.0],
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

// ─── Scrollable text content box ──────────────────────────────────────────────

class _ScrollableText extends StatelessWidget {
  final String text;
  final Color color;
  final String icon;
  final String label;
  final bool italic;

  const _ScrollableText({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
    required this.label,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text.isEmpty ? 'No content available.' : text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle:
                        italic ? FontStyle.italic : FontStyle.normal,
                    height: 1.65,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category badge ───────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: color),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}

// ─── Source badge ─────────────────────────────────────────────────────────────

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
        Flexible(
          child: Text(
            source,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

// ─── Category dropdown ────────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final Color categoryColor;
  final ValueChanged<String> onSelect;

  const _CategoryDropdown({
    required this.categoryColor,
    required this.onSelect,
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
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
                  onTap: () => onSelect(cat),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(_icon(label), style: const TextStyle(fontSize: 16)),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
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

  String _icon(String cat) {
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
