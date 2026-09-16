import 'package:flutter/material.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../budget/presentation/providers/finance_providers.dart';
import 'goal_source_wallet_item.dart';

/// Neo-Brutalism section displaying the sources of funds contributed to this Goal.
class GoalSourceFundsSection extends StatelessWidget {
  final GoalModel goal;
  final List<WalletModel> wallets;
  final VoidCallback onAddSource;
  final void Function(
    String walletId,
    String walletName,
    double amount,
  ) onTapSource;

  const GoalSourceFundsSection({
    super.key,
    required this.goal,
    required this.wallets,
    required this.onAddSource,
    required this.onTapSource,
  });

  @override
  Widget build(BuildContext context) {
    final contributions = goal.contributions.entries.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Section Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SUMBER DANA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: onAddSource,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: NeoBrutalism.cardDecoration(
                    backgroundColor: NeoBrutalism.lime,
                    borderRadius: 10,
                    shadowOffset: 2.0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontSize: 12,
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
          const SizedBox(height: 12),

          // 2. Contributions List or Empty State
          if (contributions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: NeoBrutalism.cardDecoration(
                backgroundColor: Colors.white,
                borderRadius: 16,
                shadowOffset: 2.5,
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: NeoBrutalism.circleDecoration(
                      backgroundColor: const Color(0xFFF3F4F6),
                      shadowOffset: 2.0,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 26,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum Ada Sumber Dana',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tekan tombol Tambah untuk menyetor dana\ndari salah satu dompet atau rekeningmu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            ...contributions.map((entry) {
              final walletId = entry.key;
              final amount = entry.value;
              final wallet = wallets.where((w) => w.id == walletId).isNotEmpty
                  ? wallets.firstWhere((w) => w.id == walletId)
                  : null;
              final walletName = wallet?.name ?? 'Wallet';
              final walletType = wallet?.type ?? 'Akun';

              final percent = goal.savedAmount > 0
                  ? ((amount / goal.savedAmount) * 100).toInt()
                  : 0;

              return GoalSourceWalletItem(
                walletName: walletName,
                walletType: walletType,
                amount: amount,
                percent: percent,
                onTap: () => onTapSource(walletId, walletName, amount),
              );
            }),
        ],
      ),
    );
  }
}
