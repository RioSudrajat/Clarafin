import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Individual wallet contribution item card for GoalSourceFundsSection.
class GoalSourceWalletItem extends StatelessWidget {
  final String walletName;
  final String walletType;
  final double amount;
  final int percent;
  final VoidCallback onTap;

  const GoalSourceWalletItem({
    super.key,
    required this.walletName,
    required this.walletType,
    required this.amount,
    required this.percent,
    required this.onTap,
  });

  IconData _getWalletIcon(String type) {
    switch (type) {
      case 'Bank':
        return Icons.account_balance_rounded;
      case 'E-Wallet':
        return Icons.account_balance_wallet_rounded;
      case 'Cash':
        return Icons.payments_rounded;
      case 'Stock':
      case 'Mutual Fund':
        return Icons.show_chart_rounded;
      case 'Crypto':
        return Icons.currency_bitcoin_rounded;
      case 'Deposit':
        return Icons.savings_rounded;
      default:
        return Icons.wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: NeoBrutalism.cardDecoration(
            backgroundColor: Colors.white,
            borderRadius: 16,
            shadowOffset: 2.5,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: NeoBrutalism.circleDecoration(
                  backgroundColor: NeoBrutalism.lime,
                  shadowOffset: 2.0,
                ),
                child: Icon(
                  _getWalletIcon(walletType),
                  size: 22,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      walletName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      walletType,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency.format(amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$percent% dari total',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
