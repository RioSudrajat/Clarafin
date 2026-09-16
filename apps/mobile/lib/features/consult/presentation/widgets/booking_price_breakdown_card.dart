import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingPriceBreakdownCard extends StatelessWidget {
  final String packageTitle;
  final double subtotal;
  final double platformFee;
  final double transactionFee;
  final double discount;
  final double totalPayable;

  const BookingPriceBreakdownCard({
    super.key,
    required this.packageTitle,
    required this.subtotal,
    required this.platformFee,
    this.transactionFee = 0.0,
    required this.discount,
    required this.totalPayable,
  });

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final displayTitle = packageTitle.isNotEmpty
        ? '1 Sesi $packageTitle'
        : '1 Sesi Konsultasi';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pembayaran',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          _buildItemRow(displayTitle, format.format(subtotal)),
          const SizedBox(height: 10),
          _buildItemRow('Platform Fee', format.format(platformFee)),
          if (transactionFee > 0) ...[
            const SizedBox(height: 10),
            _buildItemRow('Transaction Fee', format.format(transactionFee)),
          ],
          if (discount > 0) ...[
            const SizedBox(height: 10),
            _buildItemRow(
              'Diskon Promo',
              '- ${format.format(discount)}',
              valueColor: const Color(0xFF0F758A),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                format.format(totalPayable),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: valueColor ?? const Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
