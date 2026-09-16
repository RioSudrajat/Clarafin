import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class TransactionHistoryListItem extends StatelessWidget {
  final TransactionModel transaction;
  final String walletName;
  final VoidCallback? onTap;

  const TransactionHistoryListItem({
    super.key,
    required this.transaction,
    required this.walletName,
    this.onTap,
  });

  static IconData getCategoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'makan' || 'makanan & minuman' || 'food & bev' || 'food' => Icons.restaurant_rounded,
      'transport' || 'transportasi' => Icons.directions_car_rounded,
      'belanja' || 'shopping' || 'groceries' => Icons.shopping_bag_rounded,
      'hiburan' || 'entertainment' => Icons.sports_esports_rounded,
      'tagihan' || 'subscription' || 'bills' => Icons.receipt_long_rounded,
      'pendidikan' || 'education' => Icons.school_rounded,
      'kesehatan' || 'health' => Icons.medical_services_rounded,
      'gaji' || 'income' || 'penjualan' => Icons.payments_rounded,
      'investasi' || 'investment' => Icons.trending_up_rounded,
      'transfer' => Icons.swap_horiz_rounded,
      _ => Icons.account_balance_wallet_rounded,
    };
  }

  static Color getCategoryColor(String category) {
    return switch (category.toLowerCase()) {
      'makan' || 'makanan & minuman' || 'food & bev' || 'food' => const Color(0xFFFFB703),
      'transport' || 'transportasi' => const Color(0xFF0F758A),
      'belanja' || 'shopping' || 'groceries' => const Color(0xFFFB8500),
      'hiburan' || 'entertainment' => const Color(0xFF8338EC),
      'tagihan' || 'subscription' || 'bills' => const Color(0xFF3A86FF),
      'pendidikan' || 'education' => const Color(0xFF38B000),
      'kesehatan' || 'health' => const Color(0xFFE63946),
      'gaji' || 'income' || 'penjualan' => const Color(0xFF10B981),
      'investasi' || 'investment' => const Color(0xFF8338EC),
      'transfer' => const Color(0xFF028090),
      _ => const Color(0xFF6B7280),
    };
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final categoryColor = getCategoryColor(transaction.category);
    final categoryIcon = getCategoryIcon(transaction.category);
    final timeStr = DateFormat('HH:mm').format(transaction.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
              border: Border.all(
                color: NeoBrutalism.borderBlack,
                width: 2.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: NeoBrutalism.borderBlack,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                    border: Border.all(
                      color: NeoBrutalism.borderBlack,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(categoryIcon, color: categoryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: NeoBrutalism.dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: NeoBrutalism.borderBlack,
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              walletName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: NeoBrutalism.dark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: NeoBrutalism.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isIncome
                        ? const Color(0xFF10B981)
                        : (isTransfer ? const Color(0xFF0F758A) : const Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
