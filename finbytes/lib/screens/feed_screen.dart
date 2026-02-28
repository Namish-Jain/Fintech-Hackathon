import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiktoklikescroller/tiktoklikescroller.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/byte_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final Controller _scrollController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = Controller()
      ..addListener((ScrollEvent event) {
        if (event.pageNo != null) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = event.pageNo!);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(
        children: [
          // ── TikTok-style vertical snap feed ──────────────────────────────
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

          // ── AppBar sits on top — pushed higher via SafeArea + custom top ─
          Positioned(
            top: 0, left: 0, right: 0,
            child: _FinBytesAppBar(),
          ),

          // ── Progress dots (bottom center) ────────────────────────────────
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _ProgressDots(
              total: mockBytes.length,
              current: _currentIndex,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinBytesAppBar extends StatelessWidget {
  const _FinBytesAppBar();

  @override
  Widget build(BuildContext context) {
    // Render above all card content; use SafeArea so it clears the notch,
    // then add a little extra bottom padding so it sits well above the card top.
    return SafeArea(
      bottom: false,
      child: Padding(
        // Extra top padding lifts the bar up from the card title
        padding: const EdgeInsets.only(top: 8, left: 16, right: 8),
        child: Row(
          children: [
            // Logo mark
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.neonGreen,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
                  'F',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FinBytes',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded,
                  color: AppColors.textSecondary),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;

  const _ProgressDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.neonGreen
                : AppColors.textSecondary.withOpacity(0.4),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
