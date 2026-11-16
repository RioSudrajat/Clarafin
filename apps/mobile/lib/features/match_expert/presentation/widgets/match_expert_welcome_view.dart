import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class MatchExpertWelcomeView extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onBack;

  const MatchExpertWelcomeView({
    super.key,
    required this.onStart,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // Top bar with back button strictly left-aligned with 24px padding
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
                  SizedBox(width: 4),
                  Text(
                    'Kembali',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 36),

                // Authentic Clarafin Neo-Brutalism Badge Illustration (No generic AI glowing orb!)
                _buildNeoBrutalismMatchBadge(),

                const SizedBox(height: 30),

                // Title
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.35,
                      letterSpacing: -0.3,
                    ),
                    children: const [
                      TextSpan(text: 'Hai, Selamat datang di\n'),
                      TextSpan(
                        text: 'Match Expert.',
                        style: TextStyle(
                          color: NeoBrutalism.lime,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Body text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Setiap langkah finansialmu berharga, dan kamu tidak perlu melangkah sendirian. Melalui Match Expert, kamu akan dipasangkan dengan konsultan keuangan yang paling sesuai dengan tujuan dan gaya finansialmu, di ruang konsultasi yang aman dan profesional.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFE2E8F0),
                      height: 1.6,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Bold callout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Yuk, mulai perjalanan finansialmu\nbersama Clarafin.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // CTA Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: onStart,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: NeoBrutalism.lime,
                        borderRadius: BorderRadius.circular(16),
                        border: NeoBrutalism.border(width: 2.5),
                        boxShadow: NeoBrutalism.shadow(yOffset: 4),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Mulai Kuis Cocokkan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: NeoBrutalism.dark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: NeoBrutalism.dark, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Vertically stacked brand footer
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Powered by',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo_clarafin_symbol.png',
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'clarafin',
                          style: GoogleFonts.quicksand(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: bottomPadding + 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Authentic Neo-Brutalism Clarafin Hero Badge (Lime + Mint + 2.5px solid border + hard shadow)
  Widget _buildNeoBrutalismMatchBadge() {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background rotated accent card (Mint)
          Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: NeoBrutalism.mint,
                borderRadius: BorderRadius.circular(24),
                border: NeoBrutalism.border(width: 2.5),
                boxShadow: NeoBrutalism.shadow(yOffset: 4),
              ),
            ),
          ),

          // Foreground main circular card (Lime Neon)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: NeoBrutalism.lime,
              shape: BoxShape.circle,
              border: NeoBrutalism.border(width: 2.5),
              boxShadow: NeoBrutalism.shadow(yOffset: 3),
            ),
            child: const Center(
              child: Icon(
                Icons.psychology_rounded,
                size: 52,
                color: Colors.black,
              ),
            ),
          ),

          // Small micro tag chip at bottom right
          Positioned(
            bottom: 4,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: NeoBrutalism.border(width: 1.8),
                boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.handshake_rounded, size: 12, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    'CFP® MATCH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
