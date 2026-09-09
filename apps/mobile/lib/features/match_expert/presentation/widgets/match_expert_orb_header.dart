import 'package:flutter/material.dart';

class MatchExpertOrbHeader extends StatelessWidget {
  final VoidCallback onBack;
  final bool showOrb;

  const MatchExpertOrbHeader({
    super.key,
    required this.onBack,
    this.showOrb = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button strictly left-aligned
          GestureDetector(
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
          if (showOrb) ...[
            const SizedBox(height: 36), // Generous breathing room matching reference
            _buildOrb(),
          ],
        ],
      ),
    );
  }

  Widget _buildOrb() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.25, -0.28),
                radius: 0.95,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFBAE6FD),
                  Color(0xFF38BDF8),
                  Color(0xFF3B82F6),
                  Color(0xFF8B5CF6),
                  Color(0xFFD946EF),
                  Color(0xFFF472B6),
                ],
                stops: [0.0, 0.18, 0.38, 0.58, 0.76, 0.88, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 11,
            child: Container(
              width: 18,
              height: 11,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
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
