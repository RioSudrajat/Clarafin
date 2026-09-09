import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/consultant.dart';

class ConsultDetailStatsRow extends StatelessWidget {
  final Consultant consultant;

  const ConsultDetailStatsRow({
    super.key,
    required this.consultant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
      ),
      child: Row(
        children: [
          // 1. Sesi Selesai
          Expanded(
            child: _buildStatItem(
              title: '${consultant.totalSessions}+',
              subtitle: 'SESI SELESAI',
              icon: Icons.check_circle_outline_rounded,
              iconColor: NeoBrutalism.darkTeal,
            ),
          ),
          Container(width: 2, height: 36, color: Colors.black12),

          // 2. Rating & Ulasan
          Expanded(
            child: _buildStatItem(
              title: consultant.rating.toStringAsFixed(2),
              subtitle: '${consultant.reviewCount} ULASAN',
              icon: Icons.star_rounded,
              iconColor: Colors.amber.shade700,
            ),
          ),
          Container(width: 2, height: 36, color: Colors.black12),

          // 3. Pengalaman
          Expanded(
            child: _buildStatItem(
              title: consultant.experienceYears,
              subtitle: 'PENGALAMAN',
              icon: Icons.workspace_premium_outlined,
              iconColor: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: NeoBrutalism.dark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: NeoBrutalism.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
