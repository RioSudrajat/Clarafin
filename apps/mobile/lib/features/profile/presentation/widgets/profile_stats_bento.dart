import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../budget/presentation/providers/finance_providers.dart';
import '../../../session/presentation/providers/consultation_session_provider.dart';

class ProfileStatsBento extends ConsumerWidget {
  const ProfileStatsBento({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(consultationSessionProvider);
    final goals = ref.watch(goalsProvider);
    final wallets = ref.watch(walletsProvider);

    final completedSessionsCount = sessionState.pastSessions.length;

    return Row(
      children: [
        // 1. Sesi Konsultasi Selesai -> /session
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/session'),
            child: _buildBentoItem(
              icon: Icons.support_agent_rounded,
              title: 'Sesi',
              value: '$completedSessionsCount',
              subtitle: 'Selesai',
              backgroundColor: NeoBrutalism.mint,
              iconBgColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 2. Target / Goals Aktif -> /budget?tab=0
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/budget?tab=0'),
            child: _buildBentoItem(
              icon: Icons.flag_rounded,
              title: 'Target',
              value: '${goals.length}',
              subtitle: 'Aktif',
              backgroundColor: NeoBrutalism.surfaceWarm,
              iconBgColor: NeoBrutalism.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 3. Akun / Dompet Terhubung -> /wallet
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/wallet'),
            child: _buildBentoItem(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Dompet',
              value: '${wallets.length}',
              subtitle: 'Terhubung',
              backgroundColor: NeoBrutalism.primaryLight,
              iconBgColor: Colors.white,
            ),
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
    required Color backgroundColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
              border: NeoBrutalism.border(width: 1.5),
            ),
            child: Icon(icon, size: 16, color: Colors.black),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: NeoBrutalism.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
