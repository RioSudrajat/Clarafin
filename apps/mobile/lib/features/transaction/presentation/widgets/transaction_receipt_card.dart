import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class TransactionReceiptCard extends StatelessWidget {
  final TransactionModel? transaction;
  final String? walletName;

  const TransactionReceiptCard({
    super.key,
    this.transaction,
    this.walletName,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final amountStr = transaction != null
        ? currencyFormat.format(transaction!.amount)
        : 'Rp 45.000';
    final categoryStr = transaction?.category ?? 'Pengeluaran Umum';
    final titleStr = transaction?.title ?? 'Transaksi Baru';
    final walletStr = walletName ?? 'BCA Utama';
    final dateStr = transaction != null
        ? DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(transaction!.date)
        : DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now());
    final refId = transaction != null
        ? 'TXN-${transaction!.id.toUpperCase().replaceAll('-', '').substring(0, 8)}'
        : 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
        border: Border.all(
          color: NeoBrutalism.borderBlack,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: NeoBrutalism.borderBlack,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BUKTI TRANSAKSI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: NeoBrutalism.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F9E0),
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                  border: Border.all(
                    color: NeoBrutalism.borderBlack,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'TERCATAT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            titleStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: NeoBrutalism.dark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            amountStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: NeoBrutalism.dark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1.5,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 14),
          _buildReceiptRow('Kategori', categoryStr),
          const SizedBox(height: 8),
          _buildReceiptRow('Dompet / Sumber', walletStr),
          const SizedBox(height: 8),
          _buildReceiptRow('Waktu', dateStr),
          const SizedBox(height: 8),
          _buildReceiptRow('ID Referensi', refId),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: NeoBrutalism.textMuted,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: NeoBrutalism.dark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
