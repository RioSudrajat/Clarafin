import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/transaction_category_model.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/ai_category_normalizer.dart';
import 'category_picker_bottom_sheet.dart';

class DraftCategorySelector extends StatelessWidget {
  final bool isExpense;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const DraftCategorySelector({
    super.key,
    required this.isExpense,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  List<String> _buildCanonicalChips() {
    final source = isExpense
        ? TransactionCategories.expenseCategories
        : TransactionCategories.incomeCategories;
    final defaults = source.take(6).map((c) => c.name).toList();
    if (!defaults.contains(selectedCategory)) {
      return [selectedCategory, ...defaults];
    }
    return defaults;
  }

  Future<void> _openPicker(BuildContext context) async {
    final parts = selectedCategory.split('•');
    final mainName = parts.first.trim();
    final subName = parts.length > 1 ? parts[1].trim() : null;
    final picked = await CategoryPickerBottomSheet.show(
      context,
      isIncome: !isExpense,
      selectedCategoryName: mainName,
      selectedSubcategoryName: subName,
    );
    if (picked != null) {
      onCategoryChanged(
        AiCategoryNormalizer.normalize(
          picked.displayName,
          isIncome: !isExpense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = _buildCanonicalChips();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isExpense ? 'Kategori Pengeluaran' : 'Kategori Pemasukan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openPicker(context),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  'Semua Kategori',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: NeoBrutalism.teal,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips.map((cat) {
            final isSelected = selectedCategory == cat;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onCategoryChanged(cat),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? NeoBrutalism.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: NeoBrutalism.border(width: 1.5),
                  boxShadow: NeoBrutalism.shadow(yOffset: isSelected ? 2.0 : 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        cat,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class DraftWalletSelector extends StatelessWidget {
  final List<WalletModel> wallets;
  final String? selectedWalletId;
  final String? walletNameHint;
  final ValueChanged<String> onWalletChanged;

  const DraftWalletSelector({
    super.key,
    required this.wallets,
    required this.selectedWalletId,
    required this.walletNameHint,
    required this.onWalletChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dompet Sumber Dana',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        if (wallets.isEmpty)
          Text(
            walletNameHint != null && walletNameHint!.isNotEmpty
                ? 'Dompet terdeteksi: $walletNameHint. Transaksi dicatat ke dompet default.'
                : 'Belum ada dompet. Transaksi akan dicatat ke dompet default.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF4B5563),
            ),
          )
        else
          Column(
            children: wallets.map((wallet) {
              final isSelected = selectedWalletId == wallet.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onWalletChanged(wallet.id),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? NeoBrutalism.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: NeoBrutalism.border(width: 1.8),
                      boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            wallet.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rp ${wallet.balance.toInt()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
