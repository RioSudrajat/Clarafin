import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/vouchers_provider.dart';
import '../widgets/voucher_card.dart';

class VoucherScreen extends ConsumerWidget {
  const VoucherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchers = ref.watch(filteredVouchersProvider);
    final selectedCategory = ref.watch(selectedVoucherCategoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 2.0),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, size: 18, color: Colors.black),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Kupon & Promo',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Category Pill Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryPill(
                    label: 'Semua',
                    keyName: 'all',
                    isSelected: selectedCategory == 'all',
                    onTap: () => ref
                        .read(selectedVoucherCategoryProvider.notifier)
                        .setCategory('all'),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryPill(
                    label: 'Konsultasi Finansial',
                    keyName: 'counseling',
                    isSelected: selectedCategory == 'counseling',
                    onTap: () => ref
                        .read(selectedVoucherCategoryProvider.notifier)
                        .setCategory('counseling'),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryPill(
                    label: 'Investasi & Cashback',
                    keyName: 'investment',
                    isSelected: selectedCategory == 'investment',
                    onTap: () => ref
                        .read(selectedVoucherCategoryProvider.notifier)
                        .setCategory('investment'),
                  ),
                ],
              ),
            ),
          ),

          // Vouchers List
          Expanded(
            child: vouchers.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada kupon tersedia di kategori ini.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    itemCount: vouchers.length,
                    itemBuilder: (context, index) =>
                        VoucherCard(voucher: vouchers[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required String label,
    required String keyName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NeoBrutalism.lime : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: Colors.black, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: isSelected ? const Offset(0, 2) : const Offset(0, 1),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
