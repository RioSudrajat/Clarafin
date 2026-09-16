import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Neo-Brutalist card containing Auto-pay and Mark as Paid switch toggles.
class BillSwitchesCard extends StatelessWidget {
  final bool isAutoPay;
  final bool isPaid;
  final ValueChanged<bool> onAutoPayChanged;
  final ValueChanged<bool> onPaidChanged;

  const BillSwitchesCard({
    super.key,
    required this.isAutoPay,
    required this.isPaid,
    required this.onAutoPayChanged,
    required this.onPaidChanged,
  });

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: NeoBrutalism.circleDecoration(
            backgroundColor: value ? NeoBrutalism.lime : const Color(0xFFF3F4F6),
            shadowOffset: 1.5,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: Colors.black,
          activeTrackColor: NeoBrutalism.lime,
          inactiveThumbColor: Colors.black,
          inactiveTrackColor: const Color(0xFFE5E7EB),
          trackOutlineColor: WidgetStateProperty.all(Colors.black),
          trackOutlineWidth: WidgetStateProperty.all(1.5),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: 20,
        shadowOffset: 3.0,
      ),
      child: Column(
        children: [
          _buildSwitchRow(
            icon: Icons.autorenew_rounded,
            title: 'Bayar Otomatis (Auto-Pay)',
            subtitle: 'Simulasi autodebet dari saldo dompet utama',
            value: isAutoPay,
            onChanged: onAutoPayChanged,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: Color(0xFFE5E7EB),
              thickness: 1.5,
              height: 1,
            ),
          ),
          _buildSwitchRow(
            icon: Icons.check_circle_outline_rounded,
            title: 'Tandai Sudah Dibayar',
            subtitle: 'Tagihan untuk periode ini telah diselesaikan',
            value: isPaid,
            onChanged: onPaidChanged,
          ),
        ],
      ),
    );
  }
}
