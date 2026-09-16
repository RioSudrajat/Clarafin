import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';

class WalletTypeOption {
  final String key;
  final String label;
  final IconData icon;

  const WalletTypeOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

/// Neo-Brutalist horizontal or chip selector for wallet types.
class ManualWalletTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeSelected;

  static const List<WalletTypeOption> options = [
    WalletTypeOption(key: 'Bank', label: 'Bank', icon: Icons.account_balance_rounded),
    WalletTypeOption(key: 'E-Wallet', label: 'E-Wallet', icon: Icons.account_balance_wallet_rounded),
    WalletTypeOption(key: 'Mutual Fund', label: 'Reksadana', icon: Icons.trending_up_rounded),
    WalletTypeOption(key: 'Stock', label: 'Saham', icon: Icons.candlestick_chart_rounded),
    WalletTypeOption(key: 'Crypto', label: 'Crypto', icon: Icons.currency_bitcoin_rounded),
    WalletTypeOption(key: 'Cash', label: 'Kas Tunai', icon: Icons.payments_rounded),
  ];

  const ManualWalletTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.key == selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onTypeSelected(opt.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: NeoBrutalism.pillDecoration(
                  backgroundColor: isSelected ? NeoBrutalism.lime : Colors.white,
                  shadowOffset: isSelected ? 2.5 : 0.0,
                  borderWidth: 2.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt.icon,
                      size: 16,
                      color: NeoBrutalism.dark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      opt.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
