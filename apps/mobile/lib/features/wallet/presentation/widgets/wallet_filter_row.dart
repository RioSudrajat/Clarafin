import 'package:flutter/material.dart';

/// Horizontal filter pills for the Wallet list adhering to Neo-Brutalist design.
class WalletFilterRow extends StatelessWidget {
  final List<String> filters;
  final String activeFilter;
  final ValueChanged<String> onFilterSelected;

  const WalletFilterRow({
    super.key,
    this.filters = const ['Semua', 'E-Wallet', 'Bank', 'Investasi', 'Lainnya'],
    required this.activeFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: filters.map((filter) {
          final isSelected = activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onFilterSelected(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFCCFF00) : Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: Colors.black, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(0, isSelected ? 2.0 : 1.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
