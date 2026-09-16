import 'package:flutter/material.dart';
import '../../../../core/institutions/institution_logo_widget.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class PaymentMethodOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String? institutionId;

  const PaymentMethodOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.institutionId,
  });

  static const List<PaymentMethodOption> options = [
    PaymentMethodOption(
      id: 'qris',
      name: 'QRIS Instant (Semua Bank & E-Wallet)',
      description: 'BCA, Mandiri, GoPay, OVO, ShopeePay, DANA',
      icon: Icons.qr_code_2_rounded,
      institutionId: null,
    ),
    PaymentMethodOption(
      id: 'bca_va',
      name: 'BCA Virtual Account',
      description: 'Verifikasi instan otomatis 24 jam',
      icon: Icons.account_balance_rounded,
      institutionId: 'bca',
    ),
    PaymentMethodOption(
      id: 'mandiri_va',
      name: 'Mandiri Virtual Account',
      description: 'Verifikasi instan via Livin / ATM',
      icon: Icons.credit_card_rounded,
      institutionId: 'mandiri',
    ),
    PaymentMethodOption(
      id: 'gopay',
      name: 'GoPay / Saldo E-Wallet',
      description: 'Langsung hubungkan ke aplikasi GoPay',
      icon: Icons.account_balance_wallet_rounded,
      institutionId: 'gopay',
    ),
  ];
}

class PaymentMethodSelectionSheet extends StatelessWidget {
  final String selectedMethodId;
  final ValueChanged<PaymentMethodOption> onSelectMethod;

  const PaymentMethodSelectionSheet({
    super.key,
    required this.selectedMethodId,
    required this.onSelectMethod,
  });

  static Future<PaymentMethodOption?> show(
    BuildContext context, {
    required String selectedMethodId,
  }) {
    return showModalBottomSheet<PaymentMethodOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentMethodSelectionSheet(
        selectedMethodId: selectedMethodId,
        onSelectMethod: (option) => Navigator.of(context).pop(option),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.5),
          left: BorderSide(color: Colors.black, width: 2.0),
          right: BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Metode Pembayaran',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...PaymentMethodOption.options.map((option) {
              final isSelected = option.id == selectedMethodId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => onSelectMethod(option),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF3FCC7) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.black,
                        width: isSelected ? 2.0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          offset: isSelected ? const Offset(0, 3) : const Offset(0, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (option.institutionId != null)
                          InstitutionLogoWidget(
                            institutionId: option.institutionId,
                            size: 40,
                            borderWidth: 1.5,
                          )
                        else
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? NeoBrutalism.lime : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: Icon(option.icon, color: Colors.black, size: 24),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.name,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                option.description,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: NeoBrutalism.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
