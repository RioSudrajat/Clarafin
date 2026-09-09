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
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 8),
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
          if (showOrb) ...[
            const SizedBox(height: 14),
            // Glowing AI financial orb (inspired by ref 2.jpg to 13.jpg)
            Container(
              width: 58,
              height: 58,
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
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
