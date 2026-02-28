import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiktoklikescroller/tiktoklikescroller.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/byte_card.dart';
import 'profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _navController = PageController();
  int _navIndex = 0;

  late final Controller _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = Controller()
      ..addListener((ScrollEvent event) {
        if (event.pageNo != null) {
          HapticFeedback.lightImpact();
        }
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
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(
        children: [
          PageView(
            controller: _navController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Page 0: Feed
              TikTokStyleFullPageScroller(
                contentSize: mockBytes.length,
                controller: _scrollController,
                swipePositionThreshold: 0.2,
                swipeVelocityThreshold: 2000,
                animationDuration: const Duration(milliseconds: 350),
                builder: (BuildContext context, int index) {
                  return ByteCard(byte: mockBytes[index]);
                },
              ),
              // Page 1: Profile
              const ProfileScreen(),
            ],
          ),

          // Top bar always on top
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo: lightning bolt icon in neon green, no box
            const Icon(
              Icons.bolt_rounded,
              color: AppColors.neonGreen,
              size: 26,
            ),
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

  // Each segment width — must match what we render below
  static const double _segmentW = 76.0;
  static const double _pillH = 32.0;
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
          // Animated green pill
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
          // Labels on top of pill
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
    final color = isActive ? AppColors.deepNavy : AppColors.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        // Match the pill height so tap target fills the pill
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
