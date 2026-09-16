import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/consult_list_provider.dart';
import '../providers/consultant_filter_provider.dart';

/// Shows an informative Neo-Brutalist chip row when any filters, categories,
/// or search terms are applied, allowing users to see why results are filtered
/// and to reset filters with one tap.
class ConsultActiveFiltersBar extends ConsumerWidget {
  const ConsultActiveFiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(consultantFilterProvider);
    final category = ref.watch(consultSelectedCategoryProvider);
    final filterNotifier = ref.read(consultantFilterProvider.notifier);

    final bool hasCategory = category != 'All';
    final bool hasCustomFilter = filter.hasActiveFilters;

    if (!hasCategory && !hasCustomFilter) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Reset All pill button
            GestureDetector(
              onTap: () {
                filterNotifier.reset();
                ref.read(consultSelectedCategoryProvider.notifier).setCategory('All');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: NeoBrutalism.lime,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(0, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 13, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      'Reset Semua',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Category Chip (if active)
            if (hasCategory) ...[
              _buildFilterChip(
                label: 'Kategori: $category',
                onRemove: () {
                  ref.read(consultSelectedCategoryProvider.notifier).setCategory('All');
                },
              ),
              const SizedBox(width: 6),
            ],

            // Specialization Chips
            for (final spec in filter.specializations) ...[
              _buildFilterChip(
                label: spec,
                onRemove: () => filterNotifier.toggleSpecialization(spec),
              ),
              const SizedBox(width: 6),
            ],

            // Rating chip
            if (filter.minRating > 0) ...[
              _buildFilterChip(
                label: 'Rating ≥ ${filter.minRating.toStringAsFixed(1)}★',
                onRemove: () => filterNotifier.setMinRating(0.0),
              ),
              const SizedBox(width: 6),
            ],

            // Methods chip
            for (final method in filter.methods) ...[
              _buildFilterChip(
                label: method,
                onRemove: () => filterNotifier.toggleMethod(method),
              ),
              const SizedBox(width: 6),
            ],

            // Fee filter chip
            if (filter.minFee > 100000 || filter.maxFee < 1500000) ...[
              _buildFilterChip(
                label: 'Tarif Sesuai',
                onRemove: () => filterNotifier.setFeeRange(100000, 1500000),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 1.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 9,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
