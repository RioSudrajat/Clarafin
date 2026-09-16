import 'package:flutter/material.dart';

class BookingPromoCard extends StatelessWidget {
  final String voucherCode;
  final double discountAmount;
  final VoidCallback onTap;

  const BookingPromoCard({
    super.key,
    required this.voucherCode,
    required this.discountAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasVoucher = voucherCode.isNotEmpty && discountAmount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.percent_rounded,
                color: Color(0xFF0F758A),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasVoucher ? 'Promo: $voucherCode' : 'Promo New User',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasVoucher
                        ? 'Hemat Rp ${discountAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'
                        : 'Potongan 5% (max Rp 18.000)',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF111827),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
