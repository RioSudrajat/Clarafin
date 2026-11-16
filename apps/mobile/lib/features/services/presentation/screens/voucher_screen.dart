import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFF0F758A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeoBrutalism.brandGradient,
        ),
        child: Column(
          children: [
            // Pinned Neo-Brutalist Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: NeoBrutalism.border(width: 2.0),
                          boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_rounded, size: 22, color: NeoBrutalism.dark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Kupon & Promo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main White Container with Curvature
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 2.0),
                    left: BorderSide(color: Colors.black, width: 2.0),
                    right: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Column(
                    children: [
                      // Category Pill Filter Row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
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
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: NeoBrutalism.surfaceWarm,
                                      borderRadius: BorderRadius.circular(16),
                                      border: NeoBrutalism.border(width: 2.0),
                                      boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.local_offer_outlined, size: 36, color: Colors.black54),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Tidak ada kupon tersedia di kategori ini.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: NeoBrutalism.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                physics: const ClampingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                                itemCount: vouchers.length,
                                itemBuilder: (context, index) =>
                                    VoucherCard(voucher: vouchers[index]),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
          color: isSelected ? NeoBrutalism.primary : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: NeoBrutalism.border(width: 1.8),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
