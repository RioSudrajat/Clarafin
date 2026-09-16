import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/transaction_category_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import 'recent_activity_empty_card.dart';

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
          child: transactions.isEmpty
              ? const RecentActivityEmptyCard()
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: transactions.take(3).length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isExpense = tx.type == 'expense' || tx.type == 'transfer';
              final amountText = '${isExpense ? "- " : "+ "}${currencyFormat.format(tx.amount)}';

              final display = TransactionCategories.getCategoryDisplay(
                tx.category.isNotEmpty ? tx.category : tx.title,
              );
              final displayTitle = tx.category.isNotEmpty ? tx.category : tx.title;

              return GestureDetector(
                onTap: () => context.push('/transaction/success', extra: {'transaction': tx}),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: NeoBrutalism.shadow(yOffset: 3),
                  ),
                  child: Row(
                    children: [
                      // Category Icon Badge (Synchronized Notion Emoji / Icon)
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: display.bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 1.8),
                        ),
                        child: Text(
                          display.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: NeoBrutalism.dark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tx.notes != null && tx.notes!.isNotEmpty
                                  ? '${tx.notes} • ${DateFormat('d MMM').format(tx.date)}'
                                  : '${DateFormat('h:mm a').format(tx.date)} • ${DateFormat('d MMM').format(tx.date)}',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: NeoBrutalism.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Amount
                      Text(
                        amountText,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isExpense ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
