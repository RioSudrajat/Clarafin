import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/transaction_category_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class SelectedCategoryResult {
  final String category;
  final String? subcategory;
  final String emoji;
  final IconData icon;
  final Color color;
  final Color? bgColor;

  const SelectedCategoryResult({
    required this.category,
    this.subcategory,
    required this.emoji,
    required this.icon,
    required this.color,
    this.bgColor,
  });

  String get displayName =>
      subcategory != null ? '$category • $subcategory' : category;
}

class CategoryPickerBottomSheet extends StatefulWidget {
  final bool isIncome;
  final String? selectedCategoryName;
  final String? selectedSubcategoryName;
  final bool mainOnly;

  const CategoryPickerBottomSheet({
    super.key,
    required this.isIncome,
    this.selectedCategoryName,
    this.selectedSubcategoryName,
    this.mainOnly = false,
  });

  static Future<SelectedCategoryResult?> show(
    BuildContext context, {
    required bool isIncome,
    String? selectedCategoryName,
    String? selectedSubcategoryName,
    bool mainOnly = false,
  }) {
    return showModalBottomSheet<SelectedCategoryResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategoryPickerBottomSheet(
        isIncome: isIncome,
        selectedCategoryName: selectedCategoryName,
        selectedSubcategoryName: selectedSubcategoryName,
        mainOnly: mainOnly,
      ),
    );
  }

  @override
  State<CategoryPickerBottomSheet> createState() =>
      _CategoryPickerBottomSheetState();
}

class _CategoryPickerBottomSheetState extends State<CategoryPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedCategoryIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Automatically expand the currently selected category if any (when not mainOnly)
    if (!widget.mainOnly && widget.selectedCategoryName != null) {
      final allCats = widget.isIncome
          ? TransactionCategories.incomeCategories
          : TransactionCategories.expenseCategories;
      for (final cat in allCats) {
        if (cat.name.toLowerCase() == widget.selectedCategoryName!.toLowerCase()) {
          _expandedCategoryIds.add(cat.id);
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.isIncome
        ? TransactionCategories.incomeCategories
        : TransactionCategories.expenseCategories;

    // Filter categories based on search query
    final filteredCategories = categories.where((cat) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final matchesCat = cat.name.toLowerCase().contains(query);
      if (widget.mainOnly) return matchesCat;
      final matchesSub = cat.subcategories.any(
        (sub) => sub.name.toLowerCase().contains(query),
      );
      return matchesCat || matchesSub;
    }).toList();

    // Group categories by group name
    final Map<String, List<TransactionCategory>> grouped = {};
    for (final cat in filteredCategories) {
      grouped.putIfAbsent(cat.group, () => []).add(cat);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.0),
          left: BorderSide(color: Colors.black, width: 2.0),
          right: BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.mainOnly
                      ? 'Pilih Kategori Utama'
                      : (widget.isIncome ? 'Kategori Pemasukan' : 'Manage Categories'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: NeoBrutalism.shadow(yOffset: 2),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search category',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Categories List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Text(
                      entry.key,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  for (final cat in entry.value) _buildCategoryTile(cat),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(TransactionCategory cat) {
    final isExpanded = _expandedCategoryIds.contains(cat.id) || _searchQuery.isNotEmpty;
    final isSelected = widget.selectedCategoryName?.toLowerCase() == cat.name.toLowerCase() &&
        widget.selectedSubcategoryName == null;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (widget.mainOnly) {
              _selectCategory(cat, null);
              return;
            }
            if (cat.hasSubcategories) {
              setState(() {
                if (_expandedCategoryIds.contains(cat.id)) {
                  _expandedCategoryIds.remove(cat.id);
                } else {
                  _expandedCategoryIds.add(cat.id);
                }
              });
            } else {
              _selectCategory(cat, null);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Notion-style Badge
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cat.bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(
                    cat.emoji,
                    style: const TextStyle(fontSize: 19),
                  ),
                ),
                const SizedBox(width: 14),

                // Name
                Expanded(
                  child: Text(
                    cat.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),

                // Trailing: Checkmark if selected, or Chevron for subcategories
                if (widget.mainOnly) ...[
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                ] else if (cat.hasSubcategories) ...[
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                    size: 22,
                  ),
                ] else if (isSelected) ...[
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                ],
              ],
            ),
          ),
        ),

        // Subcategories Accordion (Only when not mainOnly)
        if (!widget.mainOnly && cat.hasSubcategories && isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 6),
            child: Column(
              children: cat.subcategories.map((sub) {
                final isSubSelected = widget.selectedCategoryName?.toLowerCase() ==
                        cat.name.toLowerCase() &&
                    widget.selectedSubcategoryName?.toLowerCase() == sub.name.toLowerCase();

                return GestureDetector(
                  onTap: () => _selectCategory(cat, sub),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSubSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSubSelected ? Colors.black : Colors.grey.shade200,
                        width: isSubSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(sub.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sub.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isSubSelected ? FontWeight.w800 : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isSubSelected)
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _selectCategory(TransactionCategory cat, TransactionSubcategory? sub) {
    Navigator.of(context).pop(
      SelectedCategoryResult(
        category: cat.name,
        subcategory: sub?.name,
        emoji: sub?.emoji ?? cat.emoji,
        icon: sub?.icon ?? cat.icon,
        color: cat.color,
        bgColor: cat.bgColor,
      ),
    );
  }
}
