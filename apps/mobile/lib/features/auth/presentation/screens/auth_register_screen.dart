import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_google_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_social_divider.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_terms_checkbox.dart';
import '../widgets/auth_text_field.dart';

class AuthRegisterScreen extends ConsumerStatefulWidget {
  const AuthRegisterScreen({super.key});

  @override
  ConsumerState<AuthRegisterScreen> createState() => _AuthRegisterScreenState();
}

class _AuthRegisterScreenState extends ConsumerState<AuthRegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final success = await ref.read(authProvider.notifier).register(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (success) {
        context.go('/onboarding');
      } else {
        final error = ref.read(authProvider).errorMessage ?? 'Pendaftaran gagal';
        _showErrorSnackBar(error);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Terjadi kesalahan saat pendaftaran. Silakan coba lagi.');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final success = await ref.read(authProvider.notifier).register(
      name: 'Google User',
      email: 'user@gmail.com',
      password: 'google_oauth_pass',
    );
    if (!success) {
      await ref.read(authProvider.notifier).login(
        email: 'user@gmail.com',
        password: 'google_oauth_pass',
      );
    }
    if (mounted) context.go('/onboarding');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF094E58),
              Color(0xFF147D8C),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.edgeMargin,
                  vertical: AppSpacing.md,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (AppSpacing.md * 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(
                        subtitle: 'Mulai perjalanan finansial cerdasmu hari ini.',
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Neo-Brutalism Form Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(NeoBrutalism.radiusXl),
                          border: NeoBrutalism.border(width: 2.0),
                          boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthTextField(
                              label: 'NAMA LENGKAP',
                              hint: 'Ahmad Fauzi',
                              icon: Icons.person_outline_rounded,
                              controller: _nameController,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AuthTextField(
                              label: 'EMAIL',
                              hint: 'nama@email.com',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              controller: _emailController,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AuthTextField(
                              label: 'KATA SANDI',
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              obscureText: _obscurePassword,
                              controller: _passwordController,
                              onTogglePassword: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AuthTermsCheckbox(
                              isChecked: _agreedToTerms,
                              onChanged: (val) {
                                setState(() {
                                  _agreedToTerms = val;
                                });
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AuthSubmitButton(
                              label: 'Daftar Sekarang',
                              isEnabled: _agreedToTerms,
                              onPressed: _agreedToTerms ? _handleRegister : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const AuthSocialDivider(label: 'ATAU DAFTAR DENGAN'),
                            const SizedBox(height: AppSpacing.md),
                            AuthGoogleButton(
                              onPressed: _handleGoogleSignIn,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Login Navigation Link on Gradient
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah punya akun? ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              'Masuk di Sini',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: NeoBrutalism.lime,
                                decoration: TextDecoration.underline,
                                decorationColor: NeoBrutalism.lime,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
