import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'feed_screen.dart';

const _kLiteracy    = ['Beginner', 'Intermediate', 'Advanced'];
const _kExperience  = ['0-2 Years', '2-5 Years', '5+ Years'];
const _kCategories  = [
  'Markets',
  'Economy',
  'Personal Finance',
  'Crypto Currency',
  'Policy',
  'Money & Credit',
  'Company Moves',
];

class OnboardingScreen extends StatefulWidget {
  /// The uid comes directly from the signUp response so we never rely on
  /// Supabase.currentUser, which is null when email confirmation is enabled.
  final String userId;
  final String userEmail;

  const OnboardingScreen({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  String? _literacy;
  String? _experience;
  final Set<String> _categories = {};
  bool _saving = false;

  void _next() {
    if (_page < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  bool get _canProceed {
    if (_page == 0) return _literacy != null;
    if (_page == 1) return _experience != null;
    return _categories.isNotEmpty;
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      // Pass userId explicitly — works even when email confirmation is on
      await AuthService.saveProfileById(
        userId: widget.userId,
        email: widget.userEmail,
        financialLiteracy: _literacy!,
        investingExperience: _experience!,
        categories: _categories.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, a, __) => const FeedScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ));
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save profile: $e',
            style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.negative,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              child: _StepIndicator(current: _page, total: 3),
            ),

            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _QuestionPage(
                    question: 'What is your\nfinancial literacy?',
                    subtitle: 'This helps us personalise your card summaries.',
                    scrollable: false,
                    child: _SingleSelectGroup(
                      options: _kLiteracy,
                      selected: _literacy,
                      onChanged: (v) => setState(() => _literacy = v),
                    ),
                  ),
                  _QuestionPage(
                    question: 'Experience in\nInvesting',
                    subtitle: 'We use this to calibrate the depth of analysis.',
                    scrollable: false,
                    child: _SingleSelectGroup(
                      options: _kExperience,
                      selected: _experience,
                      onChanged: (v) => setState(() => _experience = v),
                    ),
                  ),
                  // Page 3 has 7 items — must be scrollable
                  _QuestionPage(
                    question: 'What categories\ninterest you?',
                    subtitle: 'Pick one or more. You can change this later.',
                    scrollable: true,
                    child: _MultiSelectGroup(
                      options: _kCategories,
                      selected: _categories,
                      onToggle: (v) => setState(() {
                        _categories.contains(v)
                            ? _categories.remove(v)
                            : _categories.add(v);
                      }),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _NextButton(
                    label: _page == 2 ? 'Get Started' : 'Next',
                    enabled: _canProceed,
                    loading: _saving,
                    onTap: _canProceed ? _next : null,
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

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              decoration: BoxDecoration(
                color: active ? AppColors.neonGreen : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Question page ────────────────────────────────────────────────────────────

class _QuestionPage extends StatelessWidget {
  final String question;
  final String subtitle;
  final Widget child;
  final bool scrollable;

  const _QuestionPage({
    required this.question,
    required this.subtitle,
    required this.child,
    required this.scrollable,
  });

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        Row(children: const [
          Icon(Icons.bolt_rounded, color: AppColors.neonGreen, size: 20),
          SizedBox(width: 4),
          Text('FinBytes',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              )),
        ]),
        const SizedBox(height: 28),
        Text(question,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.15,
            )),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            )),
        const SizedBox(height: 28),
      ],
    );

    if (scrollable) {
      // Page 3: header + scrollable options list
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [header, child],
        ),
      );
    }

    // Pages 1 & 2: fixed layout, no scroll needed
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, child],
      ),
    );
  }
}

// ─── Single-select ────────────────────────────────────────────────────────────

class _SingleSelectGroup extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onChanged;

  const _SingleSelectGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((opt) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _OptionTile(
          label: opt,
          isSelected: selected == opt,
          isMulti: false,
          onTap: () => onChanged(opt),
        ),
      )).toList(),
    );
  }
}

// ─── Multi-select ─────────────────────────────────────────────────────────────

class _MultiSelectGroup extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _MultiSelectGroup({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((opt) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _OptionTile(
          label: opt,
          isSelected: selected.contains(opt),
          isMulti: true,
          onTap: () => onToggle(opt),
        ),
      )).toList(),
    );
  }
}

// ─── Option tile ──────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isMulti;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.isMulti,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonGreen.withOpacity(0.10)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.neonGreen : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.neonGreen : Colors.transparent,
                borderRadius: isMulti
                    ? BorderRadius.circular(5)
                    : BorderRadius.circular(10),
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
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Next button ──────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  const _NextButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? AppColors.neonGreen : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: enabled ? AppColors.neonGreen : AppColors.cardBorder,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.deepNavy),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? AppColors.deepNavy
                            : AppColors.textSecondary,
                      )),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18,
                      color: enabled
                          ? AppColors.deepNavy
                          : AppColors.textSecondary),
                ],
              ),
      ),
    );
  }
}
