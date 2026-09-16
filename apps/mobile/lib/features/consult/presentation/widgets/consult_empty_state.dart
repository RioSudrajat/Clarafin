import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/consult_list_provider.dart';

class ConsultEmptyState extends ConsumerWidget {
  const ConsultEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusXl),
          border: NeoBrutalism.border(width: 2.0),
          boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: NeoBrutalism.surfaceWarm,
                shape: BoxShape.circle,
                border: NeoBrutalism.border(width: 2.0),
                boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 30,
                color: NeoBrutalism.dark,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Konsultan Tidak Ditemukan',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: NeoBrutalism.dark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba gunakan kata kunci pencarian lain atau pilih kategori spesialisasi yang berbeda.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: NeoBrutalism.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () {
                ref.read(consultSearchQueryProvider.notifier).setQuery('');
                ref.read(consultSelectedCategoryProvider.notifier).setCategory('Semua');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: NeoBrutalism.lime,
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                  border: NeoBrutalism.border(width: 2.0),
                  boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                ),
                child: const Text(
                  'Reset Pencarian & Filter',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: NeoBrutalism.dark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
