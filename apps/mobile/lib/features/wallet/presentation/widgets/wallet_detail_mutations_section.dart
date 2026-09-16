import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class WalletDetailMutationsSection extends StatelessWidget {
  final String walletId;
  final List<TransactionModel> transactions;

  const WalletDetailMutationsSection({
    super.key,
    required this.walletId,
    required this.transactions,
  });

  IconData _getIcon(String cat) => switch (cat.toLowerCase()) {
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

  Color _getColor(String cat) => switch (cat.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final walletTx = transactions
        .where((tx) => tx.walletId == walletId || tx.targetWalletId == walletId)
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mutasi Terakhir',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: NeoBrutalism.dark),
            ),
            GestureDetector(
              onTap: () => context.push('/transaction/history'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                  border: Border.all(color: NeoBrutalism.borderBlack, width: 1.5),
                  boxShadow: const [BoxShadow(color: NeoBrutalism.borderBlack, offset: Offset(0, 1.5), blurRadius: 0)],
                ),
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: NeoBrutalism.dark),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (walletTx.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
              border: Border.all(color: NeoBrutalism.borderBlack, width: 2.0),
              boxShadow: const [BoxShadow(color: NeoBrutalism.borderBlack, offset: Offset(0, 2), blurRadius: 0)],
            ),
            child: Column(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 36, color: NeoBrutalism.textMuted),
                const SizedBox(height: 8),
                Text(
                  'Belum ada riwayat mutasi untuk dompet ini.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: NeoBrutalism.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...walletTx.map((tx) {
            final isExpense = tx.type == 'expense' || (tx.type == 'transfer' && tx.walletId == walletId);
            final isIncome = tx.type == 'income';
            final color = _getColor(tx.category);
            final icon = _getIcon(tx.category);
            final dateStr = DateFormat('d MMM yyyy, HH:mm').format(tx.date);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/transaction/success', extra: {'transaction': tx}),
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
                      border: Border.all(color: NeoBrutalism.borderBlack, width: 2.0),
                      boxShadow: const [BoxShadow(color: NeoBrutalism.borderBlack, offset: Offset(0, 2), blurRadius: 0)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                            border: Border.all(color: NeoBrutalism.borderBlack, width: 1.5),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: NeoBrutalism.dark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: NeoBrutalism.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isIncome
                                ? const Color(0xFF10B981)
                                : (isExpense ? const Color(0xFFDC2626) : const Color(0xFF0F758A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
