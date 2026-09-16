import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class StickyBookingBottomBar extends StatelessWidget {
  final double price;
  final String buttonText;
  final VoidCallback? onTap;

  const StickyBookingBottomBar({
    super.key,
    required this.price,
    this.buttonText = 'Selanjutnya',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isEnabled = onTap != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Harga',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: NeoBrutalism.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  price <= 0 ? '-' : currencyFormat.format(price),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                constraints: const BoxConstraints(minWidth: 130, maxWidth: 170),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: isEnabled ? NeoBrutalism.lime : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isEnabled ? Colors.black : const Color(0xFFE5E7EB),
                    width: isEnabled ? 2.0 : 1.5,
                  ),
                  boxShadow: isEnabled
                      ? const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(0, 2.5),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    buttonText,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: isEnabled ? NeoBrutalism.dark : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
