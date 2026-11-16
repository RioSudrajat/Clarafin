import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

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
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          if (showOrb) ...[
            const SizedBox(height: 24),
            _buildNeoBrutalismStepBadge(),
          ],
        ],
      ),
    );
  }

  /// Compact Neo-Brutalism Step Badge (Replaces generic AI glowing orb)
  Widget _buildNeoBrutalismStepBadge() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: NeoBrutalism.lime,
        shape: BoxShape.circle,
        border: NeoBrutalism.border(width: 2.2),
        boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
      ),
      child: const Center(
        child: Icon(
          Icons.psychology_alt_rounded,
          size: 28,
          color: Colors.black,
        ),
      ),
    );
  }
}
