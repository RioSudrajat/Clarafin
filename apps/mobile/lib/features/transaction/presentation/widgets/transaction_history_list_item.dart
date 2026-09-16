import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/transaction_category_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final display = TransactionCategories.getCategoryDisplay(
      transaction.category.isNotEmpty ? transaction.category : transaction.title,
    );
    final displayTitle = transaction.category.isNotEmpty ? transaction.category : transaction.title;
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
                // Synchronized Notion Emoji / Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: display.bgColor,
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                    border: Border.all(
                      color: NeoBrutalism.borderBlack,
                      width: 1.5,
                    ),
                  ),
                  child: display.emoji.isNotEmpty
                      ? Text(display.emoji, style: const TextStyle(fontSize: 20))
                      : Icon(display.icon, color: display.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Name as Primary Title
                      Text(
                        displayTitle,
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
                          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '• ${transaction.notes!}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: NeoBrutalism.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
