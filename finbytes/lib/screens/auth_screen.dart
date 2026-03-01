import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'feed_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  bool _loading = false;
  bool _obscurePassword = true;

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _fadeCtrl.reset();
    setState(() => _isSignUp = !_isSignUp);
    _fadeCtrl.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (_isSignUp) {
      final result = await AuthService.signUp(email: email, password: password);
      if (!mounted) return;
      if (result.isSuccess) {
        // Pass the userId directly so onboarding doesn't rely on currentUser,
        // which may be null if Supabase email confirmation is enabled.
        Navigator.of(context).pushReplacement(
          _slide(OnboardingScreen(userId: result.user!.id, userEmail: email)),
        );
      } else {
        _showError(result.errorMessage!);
      }
    } else {
      final result = await AuthService.signIn(email: email, password: password);
      if (!mounted) return;
      if (result.isSuccess) {
        Navigator.of(context).pushReplacement(_slide(const FeedScreen()));
      } else {
        _showError(result.errorMessage!);
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.negative,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Route _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeInOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: SizedBox(
              height: size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),

                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: AppColors.neonGreen, size: 32),
                          const SizedBox(width: 6),
                          const Text(
                            'FinBytes',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      Text(
                        _isSignUp ? 'Create your\naccount' : 'Welcome\nback',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1.15,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _isSignUp
                            ? 'Financial news, jargon-free.'
                            : 'Your daily financial digest awaits.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 40),

                      _FieldLabel(label: 'Email'),
                      const SizedBox(height: 8),
                      _AuthField(
                        controller: _emailCtrl,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      _FieldLabel(label: 'Password'),
                      const SizedBox(height: 8),
                      _AuthField(
                        controller: _passwordCtrl,
                        hint: _isSignUp
                            ? 'At least 8 characters'
                            : 'Your password',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your password';
                          if (_isSignUp && v.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),

                      const Spacer(),

                      _GreenButton(
                        label: _isSignUp ? 'Create Account' : 'Sign In',
                        loading: _loading,
                        onTap: _submit,
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: _toggleMode,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: _isSignUp
                                      ? 'Already have an account? '
                                      : "Don't have an account? ",
                                ),
                                TextSpan(
                                  text: _isSignUp ? 'Sign in' : 'Sign up',
                                  style: const TextStyle(
                                    color: AppColors.neonGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.5),
          fontSize: 15,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.cardSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neonGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.negative, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.negative, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.negative, fontSize: 12),
      ),
    );
  }
}

class _GreenButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _GreenButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: loading
              ? AppColors.neonGreen.withOpacity(0.5)
              : AppColors.neonGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.deepNavy,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.deepNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
