import 'package:flutter/material.dart';
import '../../../../core/institutions/institution_logo_widget.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import 'payment_method_selection_sheet.dart';

class BookingPaymentMethodsCard extends StatelessWidget {
  final String selectedMethodId;
  final VoidCallback onTapChangeMethod;

  const BookingPaymentMethodsCard({
    super.key,
    required this.selectedMethodId,
    required this.onTapChangeMethod,
  });

  @override
  Widget build(BuildContext context) {
    final selectedOption = PaymentMethodOption.options.firstWhere(
      (opt) => opt.id == selectedMethodId,
      orElse: () => PaymentMethodOption.options.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeoBrutalism.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: onTapChangeMethod,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NeoBrutalism.lime,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: const Text(
                    'Ubah Metode',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Semua pembayaran dijamin aman dengan verifikasi otomatis.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onTapChangeMethod,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3FCC7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (selectedOption.institutionId != null)
                    InstitutionLogoWidget(
                      institutionId: selectedOption.institutionId,
                      size: 40,
                      borderWidth: 1.5,
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: NeoBrutalism.lime,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Icon(
                        selectedOption.icon,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedOption.name,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedOption.description,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w500,
                            fontSize: 10.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: Colors.black,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
