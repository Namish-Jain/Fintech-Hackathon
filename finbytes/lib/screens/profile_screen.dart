import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 60;

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Padding(
        padding: EdgeInsets.only(top: topPadding, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),

            // Avatar placeholder
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardSurface,
                border: Border.all(color: AppColors.cardBorder, width: 2),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 44,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            // Name placeholder
            Container(
              width: 140,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(9),
              ),
            ),

            const SizedBox(height: 8),

            // Handle placeholder
            Container(
              width: 90,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.cardBorder.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),

            const SizedBox(height: 40),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatPlaceholder(label: 'Cards Read'),
                _Divider(),
                _StatPlaceholder(label: 'Streak'),
                _Divider(),
                _StatPlaceholder(label: 'Categories'),
              ],
            ),

            const SizedBox(height: 40),

            // Coming soon notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder, width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    '🚧',
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Profile coming soon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connect to Supabase in Phase 3 to unlock reading history and streaks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPlaceholder extends StatelessWidget {
  final String label;
  const _StatPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.cardBorder,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.cardBorder,
    );
  }
}
