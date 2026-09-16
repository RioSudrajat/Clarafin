import 'package:flutter/material.dart';
import 'payment_method_selection_sheet.dart';

class BookingPaymentMethodTriggerCard extends StatelessWidget {
  final String selectedMethodId;
  final VoidCallback onTap;

  const BookingPaymentMethodTriggerCard({
    super.key,
    required this.selectedMethodId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedOption = PaymentMethodOption.options.firstWhere(
      (opt) => opt.id == selectedMethodId,
      orElse: () => PaymentMethodOption.options.first,
    );

    final isDefaultOrEmpty = selectedMethodId.isEmpty;
    final label = isDefaultOrEmpty ? 'Pilih Metode Pembayaran' : selectedOption.name;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F758A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  if (!isDefaultOrEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      selectedOption.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
