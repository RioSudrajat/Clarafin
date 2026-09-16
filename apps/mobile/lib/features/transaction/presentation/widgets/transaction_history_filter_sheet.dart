import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class TransactionHistoryFilterSheet extends StatefulWidget {
  final List<WalletModel> wallets;
  final List<String> allCategories;
  final Set<String> selectedCategories;
  final String? selectedWalletId;
  final Function(Set<String> categories, String? walletId) onApply;

  const TransactionHistoryFilterSheet({
    super.key,
    required this.wallets,
    required this.allCategories,
    required this.selectedCategories,
    required this.selectedWalletId,
    required this.onApply,
  });

  @override
  State<TransactionHistoryFilterSheet> createState() => _TransactionHistoryFilterSheetState();
}

class _TransactionHistoryFilterSheetState extends State<TransactionHistoryFilterSheet> {
  late Set<String> _tempCategories;
  late String? _tempWalletId;

  @override
  void initState() {
    super.initState();
    _tempCategories = Set.from(widget.selectedCategories);
    _tempWalletId = widget.selectedWalletId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(NeoBrutalism.radiusLg),
          topRight: Radius.circular(NeoBrutalism.radiusLg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: NeoBrutalism.borderBlack,
                borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Riwayat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalism.dark,
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _tempCategories.clear();
                  _tempWalletId = null;
                }),
                child: Text(
                  'Reset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHeader('KATEGORI TRANSAKSI'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.allCategories.map((cat) {
              final isSel = _tempCategories.contains(cat);
              return _buildChip(cat, isSel, () {
                setState(() {
                  if (isSel) {
                    _tempCategories.remove(cat);
                  } else {
                    _tempCategories.add(cat);
                  }
                });
              });
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildHeader('DOMPET / AKUN SUMBER'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('Semua Dompet', _tempWalletId == null, () => setState(() => _tempWalletId = null)),
              ...widget.wallets.map((w) => _buildChip(w.name, _tempWalletId == w.id, () => setState(() => _tempWalletId = w.id))),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoBrutalism.lime,
                foregroundColor: NeoBrutalism.dark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                  side: const BorderSide(color: NeoBrutalism.borderBlack, width: 2.0),
                ),
              ),
              onPressed: () {
                widget.onApply(_tempCategories, _tempWalletId);
                Navigator.of(context).pop();
              },
              child: Text(
                'TERAPKAN FILTER',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: NeoBrutalism.textMuted, letterSpacing: 0.5),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? NeoBrutalism.lime : Colors.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
          border: Border.all(color: NeoBrutalism.borderBlack, width: 1.5),
          boxShadow: isSelected ? null : const [BoxShadow(color: NeoBrutalism.borderBlack, offset: Offset(0, 1.5), blurRadius: 0)],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: NeoBrutalism.dark),
        ),
      ),
    );
  }
}
