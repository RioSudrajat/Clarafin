import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/consult_list_provider.dart';

class ConsultCategoryFilterRow extends ConsumerWidget {
  const ConsultCategoryFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(consultSelectedCategoryProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: consultCategories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                ref.read(consultSelectedCategoryProvider.notifier).setCategory(category);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? NeoBrutalism.lime : Colors.white,
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                  border: NeoBrutalism.border(width: 2.0),
                  boxShadow: isSelected
                      ? NeoBrutalism.shadow(yOffset: 2.0)
                      : null,
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: NeoBrutalism.dark,
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
