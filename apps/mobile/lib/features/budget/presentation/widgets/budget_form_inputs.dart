import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Neo-Brutalism input fields for Budget category selection and plafon allocation.
class BudgetFormInputs extends StatelessWidget {
  final String categoryName;
  final String? categoryEmoji;
  final String? categoryGroup;
  final Color? categoryColor;
  final Color? categoryBgColor;
  final IconData? categoryIcon;
  final VoidCallback onSelectCategory;
  final TextEditingController totalAmountController;
  final double maxAllocatable;
  final double totalBudget;
  final double spentAmount;

  const BudgetFormInputs({
    super.key,
    required this.categoryName,
    this.categoryEmoji,
    this.categoryGroup,
    this.categoryColor,
    this.categoryBgColor,
    this.categoryIcon,
    required this.onSelectCategory,
    required this.totalAmountController,
    required this.maxAllocatable,
    required this.totalBudget,
    this.spentAmount = 0,
  });

  String _formatRupiah(num value) {
    final str = value.toInt().toString();
    final chars = str.split('').reversed.toList();
    final result = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(chars[i]);
    }
    return 'Rp ${result.reversed.join()}';
  }

  Widget _buildFieldLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        color: Color(0xFF374151),
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCategory = categoryName.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Allocation Banner Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FDF5),
            borderRadius: BorderRadius.circular(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NeoBrutalism.lime,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sisa Alokasi Tersedia',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatRupiah(maxAllocatable),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'dari Total Anggaran ${_formatRupiah(totalBudget)}',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Main Category Selection Tile
        _buildFieldLabel('KATEGORI UTAMA PENGELUARAN'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onSelectCategory,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                // Category Badge (Emoji or Icon)
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasCategory
                        ? (categoryBgColor ?? const Color(0xFFF3F4F6))
                        : const Color(0xFFCCFF00),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: hasCategory
                      ? Text(
                          categoryEmoji ?? '🍜',
                          style: const TextStyle(fontSize: 22),
                        )
                      : const Icon(
                          Icons.category_rounded,
                          size: 22,
                          color: Colors.black,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasCategory && categoryGroup != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: NeoBrutalism.lime,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.black, width: 1.0),
                          ),
                          child: Text(
                            categoryGroup!,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        hasCategory
                            ? categoryName
                            : 'Pilih Kategori Utama Pengeluaran...',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: hasCategory
                              ? Colors.black
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      if (hasCategory) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Otomatis melacak semua transaksi turunannya',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.2),
                  ),
                  child: Text(
                    hasCategory ? 'Ganti' : 'Pilih',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 3. Plafon Anggaran Input
        _buildFieldLabel('TOTAL PLAFON ANGGARAN'),
        const SizedBox(height: 8),
        TextFormField(
          controller: totalAmountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _RupiahDotFormatter(),
          ],
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: '500.000',
            prefixIcon: Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: NeoBrutalism.lime,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: const Text(
                'Rp',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black, width: 2.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFDC2626),
                width: 2.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFDC2626),
                width: 2.5,
              ),
            ),
          ),
          validator: (val) {
            if (categoryName.trim().isEmpty) {
              return 'Pilih kategori utama terlebih dahulu';
            }
            if (val == null || val.trim().isEmpty) {
              return 'Nominal plafon wajib diisi';
            }
            final clean = val.replaceAll('.', '').trim();
            final amount = double.tryParse(clean) ?? 0;
            if (amount <= 0) {
              return 'Nominal plafon harus lebih dari 0';
            }
            if (amount > maxAllocatable) {
              return 'Melebihi alokasi tersedia (Maks: ${_formatRupiah(maxAllocatable)})';
            }
            return null;
          },
        ),

        if (spentAmount > 0) ...[
          const SizedBox(height: 12),
          Text(
            'Realisasi pengeluaran bulan ini: ${_formatRupiah(spentAmount)} (terhubung otomatis dari transaksi turunan)',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _RupiahDotFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('.', '');
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    final len = text.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
