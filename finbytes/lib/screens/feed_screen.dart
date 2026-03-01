import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktoklikescroller/tiktoklikescroller.dart';
import '../models/byte_model.dart';
import '../providers/feed_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/byte_card.dart';
import 'profile_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _navController = PageController();
  int _navIndex = 0;
  late Controller _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = Controller()
      ..addListener((ScrollEvent event) {
        if (event.pageNo != null) HapticFeedback.lightImpact();
      });
  }

  void _navigateTo(int index) {
    setState(() => _navIndex = index);
    _navController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);
    final activeCategory = ref.watch(activeCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(
        children: [
          PageView(
            controller: _navController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // ── Feed page ─────────────────────────────────────────────────
              feedAsync.when(
                loading: () => const _LoadingFeed(),
                error: (e, _) => _ErrorFeed(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(feedProvider),
                ),
                data: (bytes) {
                  if (bytes.isEmpty) {
                    return _EmptyFeed(category: activeCategory);
                  }
                  // Re-create the scroll controller when data changes so
                  // the scroller starts from card 0 on category switch.
                  return TikTokStyleFullPageScroller(
                    contentSize: bytes.length,
                    controller: _scrollController,
                    swipePositionThreshold: 0.2,
                    swipeVelocityThreshold: 2000,
                    animationDuration: const Duration(milliseconds: 350),
                    builder: (context, index) =>
                        ByteCard(byte: bytes[index]),
                  );
                },
              ),

              // ── Profile page ──────────────────────────────────────────────
              const ProfileScreen(),
            ],
          ),

          // App bar always on top
          Positioned(
            top: 0, left: 0, right: 0,
            child: _FinBytesAppBar(
              navIndex: _navIndex,
              onNavChanged: _navigateTo,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading state ────────────────────────────────────────────────────────────

class _LoadingFeed extends StatelessWidget {
  const _LoadingFeed();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.neonGreen,
            strokeWidth: 2.5,
          ),
          SizedBox(height: 16),
          Text(
            'Loading your feed...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorFeed extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorFeed({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            const Text('Could not load feed',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Try Again',
                    style: TextStyle(
                      color: AppColors.deepNavy,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final String category;

  const _EmptyFeed({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              category == 'MyDigest'
                  ? 'No cards in your digest yet'
                  : 'No cards in $category yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back soon — new articles are ingested regularly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _FinBytesAppBar extends StatelessWidget {
  final int navIndex;
  final ValueChanged<int> onNavChanged;

  const _FinBytesAppBar({
    required this.navIndex,
    required this.onNavChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded,
                color: AppColors.neonGreen, size: 26),
            const SizedBox(width: 4),
            const Text(
              'FinBytes',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            _NavToggle(navIndex: navIndex, onChanged: onNavChanged),
          ],
        ),
      ),
    );
  }
}

// ─── Sliding pill nav toggle ──────────────────────────────────────────────────

class _NavToggle extends StatelessWidget {
  final int navIndex;
  final ValueChanged<int> onChanged;

  const _NavToggle({required this.navIndex, required this.onChanged});

  static const double _segmentW = 70.0;
  static const double _pillH = 30.0;
  static const double _pad = 3.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _pillH + _pad * 2,
      width: _segmentW * 2 + _pad * 2,
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular((_pillH + _pad * 2) / 2),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            left: navIndex == 0 ? 0 : _segmentW,
            top: 0,
            bottom: 0,
            width: _segmentW,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.neonGreen,
                borderRadius: BorderRadius.circular(_pillH / 2),
              ),
            ),
          ),
          Row(
            children: [
              _Segment(
                label: 'Feed',
                icon: Icons.newspaper_rounded,
                isActive: navIndex == 0,
                width: _segmentW,
                onTap: () => onChanged(0),
              ),
              _Segment(
                label: 'Profile',
                icon: Icons.person_rounded,
                isActive: navIndex == 1,
                width: _segmentW,
                onTap: () => onChanged(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final double width;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? AppColors.deepNavy : AppColors.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
