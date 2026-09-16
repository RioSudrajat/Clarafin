import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class TransactionHistoryFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final String selectedTimeRange;
  final ValueChanged<String> onTimeRangeChanged;

  const TransactionHistoryFilterBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedTimeRange,
    required this.onTimeRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
              border: Border.all(color: NeoBrutalism.borderBlack, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: NeoBrutalism.borderBlack,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: NeoBrutalism.dark,
              ),
              decoration: InputDecoration(
                hintText: 'Cari transaksi atau catatan...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: NeoBrutalism.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: NeoBrutalism.dark,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 18, color: NeoBrutalism.dark),
                        onPressed: onClearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
              border: Border.all(color: NeoBrutalism.borderBlack, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: NeoBrutalism.borderBlack,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTypeTab('Semua', 'all'),
                _buildTypeTab('Keluar', 'expense'),
                _buildTypeTab('Masuk', 'income'),
                _buildTypeTab('Transfer', 'transfer'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildTimeChip('Semua Waktu', 'all'),
              const SizedBox(width: 8),
              _buildTimeChip('Bulan Ini', 'month'),
              const SizedBox(width: 8),
              _buildTimeChip('30 Hari Terakhir', '30days'),
              const SizedBox(width: 8),
              _buildTimeChip('7 Hari Terakhir', '7days'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeTab(String title, String type) {
    final isSelected = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? NeoBrutalism.lime : Colors.transparent,
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm - 2),
            border: isSelected
                ? Border.all(color: NeoBrutalism.borderBlack, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: NeoBrutalism.dark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, String value) {
    final isSelected = selectedTimeRange == value;
    return GestureDetector(
      onTap: () => onTimeRangeChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? NeoBrutalism.dark : Colors.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
          border: Border.all(color: NeoBrutalism.borderBlack, width: 1.5),
          boxShadow: isSelected
              ? null
              : const [
                  BoxShadow(
                    color: NeoBrutalism.borderBlack,
                    offset: Offset(0, 1.5),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : NeoBrutalism.dark,
            ),
          ),
        ),
      ),
    );
  }
}
