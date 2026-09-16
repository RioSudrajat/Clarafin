import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class SessionQuickActions extends StatelessWidget {
  final VoidCallback onTapPaket;
  final VoidCallback onTapTransaksi;
  final VoidCallback onTapGift;

  const SessionQuickActions({
    super.key,
    required this.onTapPaket,
    required this.onTapTransaksi,
    required this.onTapGift,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildActionCard(
          icon: Icons.percent_rounded,
          label: 'Paket',
          onTap: onTapPaket,
        ),
        const SizedBox(width: 12),
        _buildActionCard(
          icon: Icons.access_time_filled_rounded,
          label: 'Transaksi',
          onTap: onTapTransaksi,
        ),
        const SizedBox(width: 12),
        _buildActionCard(
          icon: Icons.card_giftcard_rounded,
          label: 'Gift',
          onTap: onTapGift,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
            border: NeoBrutalism.border(width: 2.0),
            boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: const Color(0xFF0F758A)),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: NeoBrutalism.dark,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
