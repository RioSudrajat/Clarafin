import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

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
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildVisualCollage(),
                      const SizedBox(height: 24),
                      _buildCopySection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildPrimaryButton(context),
              const SizedBox(height: 10),
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
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.account_balance_wallet,
            size: 28,
            color: NeoBrutalism.dark,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'CLARAFIN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: NeoBrutalism.dark,
          ),
        ),
      ],
    );
  }

  Widget _buildVisualCollage() {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Card: Mint Income Notification
          Positioned(
            top: 15,
            left: 10,
            child: Transform.rotate(
              angle: -0.06,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: NeoBrutalism.mint,
                  borderRadius: BorderRadius.circular(12),
                  border: NeoBrutalism.border(width: 2.0),
                  boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 16, color: NeoBrutalism.dark),
                    const SizedBox(width: 6),
                    Text(
                      'Gajian! +Rp 8.500.000',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Yellow Sticky Note: Cash Expense
          Positioned(
            top: 60,
            right: 15,
            child: Transform.rotate(
              angle: 0.08,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF08A),
                  borderRadius: BorderRadius.circular(10),
                  border: NeoBrutalism.border(width: 2.0),
                  boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_parking_rounded, size: 15, color: NeoBrutalism.dark),
                    const SizedBox(width: 5),
                    Text(
                      'Parkir Rp 5.000',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Center Receipt Snippet: Coffee
          Positioned(
            top: 95,
            left: 25,
            child: Transform.rotate(
              angle: 0.03,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: NeoBrutalism.border(width: 2.0),
                  boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.coffee_rounded, size: 16, color: NeoBrutalism.dark),
                    const SizedBox(width: 6),
                    Text(
                      'Kopi Susu Rp 28.000 (Struk OCR)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main Pillar Teal Badge: Certified Advisors
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: NeoBrutalism.teal,
                borderRadius: BorderRadius.circular(14),
                border: NeoBrutalism.border(width: 2.0),
                boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: NeoBrutalism.lime,
                      borderRadius: BorderRadius.circular(8),
                      border: NeoBrutalism.border(width: 1.5),
                    ),
                    child: const Icon(Icons.verified_rounded, size: 16, color: NeoBrutalism.dark),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KONSULTAN RESMI BERLISENSI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: NeoBrutalism.lime,
                        ),
                      ),
                      Text(
                        'CFP® • CFA® • QWP® • AWP® • BKP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: NeoBrutalism.lime,
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
            border: NeoBrutalism.border(width: 2.0),
            boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
          ),
          child: Text(
            'TRACKER + FINANCIAL ADVISORY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: NeoBrutalism.dark,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Kopi, gajian, tagihan,\nsampai konsultasi ahli.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            height: 1.2,
            color: NeoBrutalism.dark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ucapkan, foto struk, atau ketik pengeluaran harianmu. Butuh strategi lebih dalam? Diskusikan langsung bareng konsultan berlisensi resmi (CFP®, CFA®, QWP®, AWP®, CPA, & BKP).',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () => context.go('/onboarding/history'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: NeoBrutalism.lime,
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
            border: NeoBrutalism.border(width: 2.0),
            boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mulai Sekarang',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalism.dark,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 20, color: NeoBrutalism.dark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/login'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            children: [
              const TextSpan(text: 'Sudah punya akun? '),
              TextSpan(
                text: 'Masuk di sini',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalism.dark,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
