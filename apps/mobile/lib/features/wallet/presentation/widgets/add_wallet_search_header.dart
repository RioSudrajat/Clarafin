import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Search and filter header for AddWalletInstitutionScreen.
class AddWalletSearchHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onManualEntryTap;
  final VoidCallback onClearSearch;

  const AddWalletSearchHeader({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onManualEntryTap,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    const categories = ['Semua', 'Bank', 'E-Wallet', 'Investasi'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Manual Input Banner
        GestureDetector(
          onTap: onManualEntryTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: NeoBrutalism.cardDecoration(
              backgroundColor: const Color(0xFFEFFCC7),
              borderRadius: 18,
              shadowOffset: 2.5,
              borderWidth: 2.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: NeoBrutalism.circleDecoration(
                    backgroundColor: NeoBrutalism.lime,
                    borderWidth: 2.0,
                    shadowOffset: 0,
                  ),
                  child: const Icon(Icons.edit_note_rounded, size: 22, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tidak menemukan akunmu?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                      Text(
                        'Input dompet atau aset secara manual ➔',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F758A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Search Bar
        Container(
          decoration: NeoBrutalism.cardDecoration(
            backgroundColor: const Color(0xFFF8FAFC),
            borderRadius: 18,
            shadowOffset: 2.5,
            borderWidth: 2.0,
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Cari bank, e-wallet, atau aset...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: NeoBrutalism.textMuted,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.black, size: 22),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.black),
                      onPressed: onClearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: categories.map((cat) {
              final isSelected = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onCategorySelected(cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: NeoBrutalism.pillDecoration(
                      backgroundColor: isSelected ? NeoBrutalism.lime : Colors.white,
                      shadowOffset: isSelected ? 2.0 : 0.0,
                      borderWidth: 1.5,
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 12,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
