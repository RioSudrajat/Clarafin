import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class RecentActivitySection extends ConsumerWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NeoBrutalism.dark,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/transaction/history'),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: NeoBrutalism.shadow(yOffset: 2),
                  ),
                  child: const Icon(Icons.search, size: 16, color: NeoBrutalism.dark),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Transaction List Items
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: transactions.take(3).length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isExpense = tx.type == 'expense' || tx.type == 'transfer';
              final amountText = '${isExpense ? "- " : "+ "}${currencyFormat.format(tx.amount)}';

              Color iconBg;
              Color iconColor;
              IconData txIcon;

              if (index == 0) {
                iconBg = NeoBrutalism.dark;
                iconColor = Colors.white;
                txIcon = Icons.directions_car;
              } else if (index == 1) {
                iconBg = NeoBrutalism.lime;
                iconColor = NeoBrutalism.dark;
                txIcon = Icons.coffee_outlined;
              } else {
                iconBg = NeoBrutalism.coral;
                iconColor = const Color(0xFFB91C1C);
                txIcon = Icons.play_circle_outline;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: NeoBrutalism.shadow(yOffset: 3),
                ),
                child: Row(
                  children: [
                    // Category Icon Badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Icon(txIcon, size: 20, color: iconColor),
                    ),
                    const SizedBox(width: 14),
                    // Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.title,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: NeoBrutalism.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('h:mm a').format(tx.date)} • ${DateFormat('d MMM').format(tx.date)}',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: NeoBrutalism.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Text(
                      amountText,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
