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
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // Top bar with back button
        Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.chevron_left, color: Colors.white, size: 24),
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

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 36),

                // Large Glowing Orb
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFA7E8FF),
                        Color(0xFF67B5FE),
                        Color(0xFF8B5CF6),
                        Color(0xFFEC4899),
                      ],
                      stops: [0.1, 0.35, 0.65, 0.85, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF67B5FE).withValues(alpha: 0.5),
                        blurRadius: 32,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.35,
                    ),
                    children: [
                      const TextSpan(text: 'Hai, Selamat datang di\n'),
                      TextSpan(
                        text: 'Match Expert.',
                        style: TextStyle(
                          color: NeoBrutalism.lime,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Body text in Clarafin context
                const Text(
                  'Setiap langkah finansialmu berharga, dan kamu nggak perlu jalan sendirian. Dengan Match Expert, kamu akan dipertemukan dengan konsultan keuangan tersertifikasi (CFP / Financial Planner) yang paling cocok dengan tujuan hidupmu.\n\nDi ruang konsultasi yang aman, nyaman, transparan, dan ditangani secara profesional oleh para ahli keuangan independen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFE2E8F0),
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Yuk, temukan konsultan keuangan terbaikmu bersama Clarafin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // CTA Button
                GestureDetector(
                  onTap: onStart,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: NeoBrutalism.lime,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: NeoBrutalism.shadow(yOffset: 3),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Mulai',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: NeoBrutalism.dark, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Footer "Powered by clarafin"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Powered by ',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      'clarafin',
                      style: GoogleFonts.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: bottomPadding + 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
