import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Neo-Brutalism action bottom sheet for managing contributions from a specific wallet.
class GoalSourceActionSheet extends StatelessWidget {
  final String walletName;
  final double currentAmount;
  final VoidCallback onAddFunds;
  final VoidCallback onWithdrawFunds;

  const GoalSourceActionSheet({
    super.key,
    required this.walletName,
    required this.currentAmount,
    required this.onAddFunds,
    required this.onWithdrawFunds,
  });

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: NeoBrutalism.cardDecoration(
          backgroundColor: bgColor,
          borderRadius: 16,
          shadowOffset: 2.5,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: NeoBrutalism.circleDecoration(
                backgroundColor: color,
                shadowOffset: 1.5,
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.black,
            ),
          ],
        ),
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

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.0),
          left: BorderSide(color: Colors.black, width: 2.0),
          right: BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Text(
            walletName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kontribusi saat ini: ${formatCurrency.format(currentAmount)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),

          // Action: Tambah Dana
          _buildActionTile(
            icon: Icons.add_rounded,
            label: 'Tambah Dana',
            subtitle: 'Transfer dana tambahan dari dompet ini ke goal',
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFF0FDF4),
            onTap: () {
              Navigator.pop(context);
              onAddFunds();
            },
          ),
          const SizedBox(height: 12),

          // Action: Tarik Dana
          _buildActionTile(
            icon: Icons.arrow_downward_rounded,
            label: 'Tarik Dana',
            subtitle: 'Kembalikan sebagian dana ke dompet asal',
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEF2F2),
            onTap: () {
              Navigator.pop(context);
              onWithdrawFunds();
            },
          ),
        ],
      ),
    );
  }
}
