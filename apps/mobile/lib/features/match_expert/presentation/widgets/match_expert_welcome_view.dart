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
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Scrollable content with pristine margins matching reference
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),

                // 3D Glossy Celestial Crystal Pearl Orb matching reference
                _buildGlowingOrb(),

                const SizedBox(height: 32),

                // Title
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.35,
                      letterSpacing: -0.3,
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

                const SizedBox(height: 22),

                // Body text: one cohesive, elegant paragraph matching reference (36px margin)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    'Setiap langkah finansialmu berharga, dan kamu nggak perlu jalan sendirian. Dengan Match Expert, kamu akan dipertemukan dengan konsultan keuangan yang siap menemani perjalanan finansialmu, di ruang yang aman, nyaman, dan ditangani secara profesional. Karena perjalanan ini milikmu, dan Clarafin selalu ada untuk mendampingimu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFE2E8F0),
                      height: 1.6,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bold closing callout on two centered lines matching reference
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Yuk, mulai perjalanan finansialmu\nbersama Clarafin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // CTA Button with 24px horizontal padding
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
                          Icon(Icons.arrow_forward_rounded, color: NeoBrutalism.dark, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Vertically stacked brand footer matching reference
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Powered by',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
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

  /// 3D Glossy Crystal Pearl Orb matching the reference aesthetic
  Widget _buildGlowingOrb() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 32,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Base 3D celestial sphere with rich multi-color iridescence
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.25, -0.28),
                radius: 0.95,
                colors: [
                  Color(0xFFFFFFFF), // Specular light core
                  Color(0xFFBAE6FD), // Soft ice cyan reflection
                  Color(0xFF38BDF8), // Vivid celestial blue
                  Color(0xFF3B82F6), // Deep electric blue
                  Color(0xFF8B5CF6), // Royal purple swirl
                  Color(0xFFD946EF), // Radiant magenta
                  Color(0xFFF472B6), // Soft rose outer rim
                ],
                stops: [0.0, 0.18, 0.38, 0.58, 0.76, 0.88, 1.0],
              ),
            ),
          ),
          // Top-left specular highlight sheen
          Positioned(
            top: 13,
            left: 19,
            child: Container(
              width: 34,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
