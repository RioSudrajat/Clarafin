import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/ai_category_normalizer.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import 'ai_draft_review_selectors.dart';

class EditableDraftItem {
  final TextEditingController amountController;
  final TextEditingController noteController;
  bool isExpense;
  String category;
  String? walletId;
  String? walletNameHint;

  EditableDraftItem({
    required double amount,
    required String title,
    required this.isExpense,
    required String category,
    this.walletId,
    this.walletNameHint,
  })  : amountController = TextEditingController(
          text: ThousandSeparatorFormatter()
              .formatEditUpdate(
                TextEditingValue.empty,
                TextEditingValue(text: amount.toInt().toString()),
              )
              .text,
        ),
        noteController = TextEditingController(text: title),
        category = AiCategoryNormalizer.normalize(
          category,
          isIncome: !isExpense,
          contextHint: title,
        );

  static List<EditableDraftItem> fromPrefillList(List<Map<String, dynamic>> rawItems) {
    if (rawItems.isEmpty) {
      return [
        EditableDraftItem(
          amount: 55000,
          title: 'Makan Malam HokBen',
          isExpense: true,
          category: AiCategoryNormalizer.normalize(
            'Makanan',
            contextHint: 'Makan Malam HokBen',
          ),
        ),
      ];
    }
    return rawItems.map((raw) {
      final title = (raw['title'] as String? ?? 'Transaksi AI').trim();
      final amount = (raw['amount'] as num?)?.toDouble() ?? 0.0;
      return EditableDraftItem(
        amount: amount > 0 ? amount : 50000.0,
        title: title.isNotEmpty ? title : 'Transaksi AI',
        isExpense: raw['isExpense'] as bool? ?? true,
        category: raw['category'] as String? ?? '',
        walletId: raw['walletId'] as String?,
        walletNameHint: raw['walletName'] as String?,
      );
    }).toList();
  }

  String? resolveWalletId(List<WalletModel> wallets) {
    if (wallets.isEmpty) return walletId;
    if (walletId != null && wallets.any((w) => w.id == walletId)) return walletId;
    final hint = (walletNameHint ?? '').toLowerCase();
    if (hint.isNotEmpty) {
      for (final w in wallets) {
        if (w.name.toLowerCase().contains(hint) || hint.contains(w.name.toLowerCase())) {
          return w.id;
        }
      }
    }
    return wallets.first.id;
  }

  void dispose() {
    amountController.dispose();
    noteController.dispose();
  }
}

class AiDraftReviewFormCard extends StatelessWidget {
  final EditableDraftItem draft;
  final List<WalletModel> wallets;
  final ValueChanged<bool> onTypeChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onWalletChanged;

  const AiDraftReviewFormCard({
    super.key,
    required this.draft,
    required this.wallets,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onWalletChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _TypePill(
                  label: 'Pengeluaran',
                  selected: draft.isExpense,
                  onTap: () => onTypeChanged(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TypePill(
                  label: 'Pemasukan',
                  selected: !draft.isExpense,
                  onTap: () => onTypeChanged(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Nominal Transaksi',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: NeoBrutalism.surfaceWarm,
              borderRadius: BorderRadius.circular(12),
              border: NeoBrutalism.border(width: 1.8),
            ),
            child: Row(
              children: [
                Text(
                  'Rp ',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                ),
                Expanded(
                  child: TextField(
                    controller: draft.amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandSeparatorFormatter()],
                    style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Catatan / Merchant',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: NeoBrutalism.border(width: 1.8),
            ),
            child: TextField(
              controller: draft.noteController,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Nama transaksi'),
            ),
          ),
          const SizedBox(height: 16),
          DraftCategorySelector(
            isExpense: draft.isExpense,
            selectedCategory: draft.category,
            onCategoryChanged: onCategoryChanged,
          ),
          const SizedBox(height: 16),
          DraftWalletSelector(
            wallets: wallets,
            selectedWalletId: draft.walletId,
            walletNameHint: draft.walletNameHint,
            onWalletChanged: onWalletChanged,
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypePill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          color: selected ? NeoBrutalism.lime : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: NeoBrutalism.border(width: 1.8),
          boxShadow: NeoBrutalism.shadow(yOffset: selected ? 2.0 : 1.0),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: NeoBrutalism.dark),
        ),
      ),
    );
  }
}
