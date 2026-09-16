import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../budget/presentation/providers/finance_providers.dart';

class ProfileStatsBento extends ConsumerWidget {
  const ProfileStatsBento({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider);
    final goals = ref.watch(goalsProvider);

    return Row(
      children: [
        // 1. Sesi Konsultasi
        Expanded(
          child: _buildBentoItem(
            icon: Icons.support_agent_outlined,
            title: 'Sesi',
            value: '4',
            subtitle: 'Selesai',
            accentColor: const Color(0xFFFFB74D),
          ),
        ),
        const SizedBox(width: 10),

        // 2. Target Aktif
        Expanded(
          child: _buildBentoItem(
            icon: Icons.flag_outlined,
            title: 'Target',
            value: '${goals.length}',
            subtitle: 'Aktif',
            accentColor: NeoBrutalism.lime,
          ),
        ),
        const SizedBox(width: 10),

        // 3. Akun Terhubung
        Expanded(
          child: _buildBentoItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Akun',
            value: '${wallets.length}',
            subtitle: 'Terhubung',
            accentColor: const Color(0xFF4FC3F7),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoItem({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, size: 16, color: Colors.black),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
