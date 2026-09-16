import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import 'voucher_option_tile.dart';

class VoucherSelectionSheet extends StatefulWidget {
  final String currentCode;
  final ValueChanged<VoucherOption?> onVoucherSelected;

  const VoucherSelectionSheet({
    super.key,
    required this.currentCode,
    required this.onVoucherSelected,
  });

  static const List<VoucherOption> availableVouchers = [
    VoucherOption(
      code: 'HALOFINCFP',
      title: 'Diskon Sesi CFP® Komprehensif',
      discountText: 'Potongan Rp 18.000 langsung',
      discountAmount: 18000.0,
    ),
    VoucherOption(
      code: 'NEWUSER5',
      title: 'Promo Spesial Member Baru',
      discountText: 'Potongan Rp 25.000 tanpa min. transaksi',
      discountAmount: 25000.0,
    ),
    VoucherOption(
      code: 'HEMAT10',
      title: 'Finansial Mantap 10%',
      discountText: 'Potongan Rp 35.000 untuk konsultasi',
      discountAmount: 35000.0,
    ),
  ];

  static Future<void> show(
    BuildContext context, {
    required String currentCode,
    required ValueChanged<VoucherOption?> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoucherSelectionSheet(
        currentCode: currentCode,
        onVoucherSelected: onSelected,
      ),
    );
  }

  @override
  State<VoucherSelectionSheet> createState() => _VoucherSelectionSheetState();
}

class _VoucherSelectionSheetState extends State<VoucherSelectionSheet> {
  final TextEditingController _customCodeController = TextEditingController();

  @override
  void dispose() {
    _customCodeController.dispose();
    super.dispose();
  }

  void _applyCustomCode() {
    final code = _customCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final voucher = VoucherOption(
      code: code,
      title: 'Kupon Promo "$code"',
      discountText: 'Diskon kustom Rp 20.000 diterapkan',
      discountAmount: 20000.0,
    );
    widget.onVoucherSelected(voucher);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.5),
          left: BorderSide(color: Colors.black, width: 2.5),
          right: BorderSide(color: Colors.black, width: 2.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Voucher Promo',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: TextField(
                    controller: _customCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ketik kode promo...',
                      hintStyle: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _applyCustomCode,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NeoBrutalism.lime,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(0, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Pakai',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...VoucherSelectionSheet.availableVouchers.map((voucher) {
            return VoucherOptionTile(
              voucher: voucher,
              isSelected: widget.currentCode == voucher.code,
              onTap: () {
                widget.onVoucherSelected(voucher);
                Navigator.pop(context);
              },
            );
          }),
          InkWell(
            onTap: () {
              widget.onVoucherSelected(null);
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: const Text(
                'Batalkan Penggunaan Voucher',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
