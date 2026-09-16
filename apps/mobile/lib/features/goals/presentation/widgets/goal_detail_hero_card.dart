import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../budget/presentation/providers/finance_providers.dart';

/// Neo-Brutalist Hero Card showing savings progress, amounts, and metadata.
class GoalDetailHeroCard extends StatelessWidget {
  final GoalModel goal;

  const GoalDetailHeroCard({super.key, required this.goal});

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 1.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;
    final isComplete = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: const Color(0xFFF9FDF5),
        borderRadius: 24,
        shadowOffset: 4.0,
      ),
      child: Column(
        children: [
          // 1. Progress Gauge & Icon
          SizedBox(
            height: 110,
            width: 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 9,
                  backgroundColor: const Color(0xFFE5E7EB),
                  color: isComplete ? const Color(0xFF10B981) : NeoBrutalism.lime,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: NeoBrutalism.circleDecoration(
                      backgroundColor: Colors.white,
                      shadowOffset: 2.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(goal.icon, size: 28, color: Colors.black),
                        const SizedBox(height: 2),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 13,
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
          ),
          const SizedBox(height: 18),

          // 2. Saved & Target Amounts
          const Text(
            'TOTAL DANA TERKUMPUL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF6B7280),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency.format(goal.savedAmount),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'dari target ${formatCurrency.format(goal.targetAmount)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Metadata Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildInfoChip(
                icon: Icons.calendar_today_rounded,
                label: '$daysLeft hari lagi',
                color: daysLeft < 30 ? const Color(0xFFBA1A1A) : Colors.black,
                bgColor: daysLeft < 30 ? const Color(0xFFFFDAD6) : Colors.white,
              ),
              _buildInfoChip(
                icon: Icons.flag_rounded,
                label: goal.priority,
                color: goal.priority == 'Urgent'
                    ? const Color(0xFFBA1A1A)
                    : (goal.priority == 'Wants'
                        ? const Color(0xFF1976D2)
                        : const Color(0xFFD97706)),
                bgColor: goal.priority == 'Urgent'
                    ? const Color(0xFFFFDAD6)
                    : (goal.priority == 'Wants'
                        ? const Color(0xFFE3F2FD)
                        : const Color(0xFFFFF3E0)),
              ),
              if (isComplete)
                _buildInfoChip(
                  icon: Icons.check_circle_rounded,
                  label: 'Selesai!',
                  color: const Color(0xFF065F46),
                  bgColor: const Color(0xFFD1FAE5),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
