import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/onboarding_carousel_slide.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<Map<String, dynamic>> _slides = [
    {
      'tag': 'CFP® CERTIFIED',
      'title': 'Konsultasi Bareng Ahli',
      'desc': 'Terhubung langsung dengan perencana keuangan berlisensi resmi untuk strategi finansialmu.',
      'icon': Icons.verified_user_outlined,
      'bg': NeoBrutalism.mint,
    },
    {
      'tag': 'MULTI-WALLET TRACKING',
      'title': 'Pantau Kas & Aset Seketika',
      'desc': 'Catat mutasi bank, e-wallet, tagihan, dan budget bulanan dalam satu dasbor rapi.',
      'icon': Icons.account_balance_wallet_outlined,
      'bg': Color(0xFFEFF6FF),
    },
    {
      'tag': 'MEASURABLE GOALS',
      'title': 'Wujudkan Target Finansial',
      'desc': 'Rancang target tabungan terukur dari dana darurat sampai impian masa depan.',
      'icon': Icons.track_changes_outlined,
      'bg': Color(0xFFF7FEE7),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _buildBrandHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final item = _slides[index];
                    return OnboardingCarouselSlide(
                      tag: item['tag'] as String,
                      title: item['title'] as String,
                      desc: item['desc'] as String,
                      icon: item['icon'] as IconData,
                      bg: item['bg'] as Color,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildPageIndicators(),
              const SizedBox(height: 24),
              _buildPrimaryButton(context),
              const SizedBox(height: 12),
              _buildLoginLink(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo_clarafin_symbol.png',
          height: 28,
          color: NeoBrutalism.dark,
          colorBlendMode: BlendMode.srcIn,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Text(
          'clarafin',
          style: GoogleFonts.quicksand(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: NeoBrutalism.dark,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? NeoBrutalism.lime : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: NeoBrutalism.border(width: 1.5),
          ),
        );
      }),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: NeoBrutalism.lime,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
          border: NeoBrutalism.border(width: 2.0),
          boxShadow: NeoBrutalism.shadow(yOffset: 3.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
            onTap: () => context.go('/onboarding/wallet-setup'),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mulai Setup Sekarang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.dark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18, color: NeoBrutalism.dark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/login'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sudah punya akun? ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Masuk di Sini',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: NeoBrutalism.dark,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
