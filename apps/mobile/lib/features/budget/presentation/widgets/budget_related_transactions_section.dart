import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/transaction_category_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class BudgetRelatedTransactionsSection extends ConsumerStatefulWidget {
  final String categoryName;

  const BudgetRelatedTransactionsSection({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<BudgetRelatedTransactionsSection> createState() =>
      _BudgetRelatedTransactionsSectionState();
}

class _BudgetRelatedTransactionsSectionState
    extends ConsumerState<BudgetRelatedTransactionsSection> {
  int _currentPage = 1;
  static const int _pageSize = 10;
  bool _filterThisMonth = true;

  String _formatRupiah(num value) {
    final str = value.toInt().toString();
    final chars = str.split('').reversed.toList();
    final result = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(chars[i]);
    }
    return 'Rp ${result.reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final now = DateTime.now();
    final target = widget.categoryName.toLowerCase().trim();

    final allCategoryTxs = transactions.where((t) {
      if (t.type != 'expense') return false;
      final cat = t.category.toLowerCase().trim();
      final mainPart = cat.split('•').first.trim();
      return cat == target ||
          cat.startsWith('$target •') ||
          cat.startsWith('$target -') ||
          cat.startsWith('$target:') ||
          mainPart == target;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final thisMonthTxs = allCategoryTxs
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    final activeList = _filterThisMonth ? thisMonthTxs : allCategoryTxs;
    final totalItems = activeList.length;
    final totalPages = totalItems == 0 ? 1 : ((totalItems - 1) ~/ _pageSize) + 1;

    final effectivePage = _currentPage.clamp(1, totalPages);
    final startIndex = (effectivePage - 1) * _pageSize;
    final pageItems = activeList.skip(startIndex).take(_pageSize).toList();
    final endIndex = startIndex + pageItems.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, size: 18, color: Colors.black),
                  const SizedBox(width: 8),
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: NeoBrutalism.lime,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    child: Text(
                      '$totalItems',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Segmented Filter
          Row(
            children: [
              _buildFilterChip(
                label: 'Bulan Ini (${thisMonthTxs.length})',
                isSelected: _filterThisMonth,
                onTap: () {
                  if (!_filterThisMonth) {
                    setState(() {
                      _filterThisMonth = true;
                      _currentPage = 1;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Semua (${allCategoryTxs.length})',
                isSelected: !_filterThisMonth,
                onTap: () {
                  if (_filterThisMonth) {
                    setState(() {
                      _filterThisMonth = false;
                      _currentPage = 1;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // List or Empty
          if (pageItems.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12, width: 1.0),
              ),
              child: Text(
                _filterThisMonth
                    ? 'Belum ada pengeluaran untuk kategori ini di bulan ini.'
                    : 'Belum ada riwayat transaksi di kategori ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pageItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tx = pageItems[index];
                final display = TransactionCategories.getCategoryDisplay(
                  tx.category.isNotEmpty ? tx.category : tx.title,
                );
                final displayTitle = tx.category.isNotEmpty ? tx.category : tx.title;

                return GestureDetector(
                  onTap: () => context.push(
                    '/transaction/success',
                    extra: {'transaction': tx},
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: display.bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black, width: 1.0),
                          ),
                          child: Text(
                            display.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayTitle,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tx.notes != null && tx.notes!.isNotEmpty
                                    ? '${tx.notes} • ${DateFormat('d MMM yyyy, HH:mm').format(tx.date)}'
                                    : DateFormat('d MMM yyyy, HH:mm').format(tx.date),
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10.5,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '- ${_formatRupiah(tx.amount)}',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Pagination Controls
            if (totalPages > 1) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPageNavButton(
                    icon: Icons.chevron_left,
                    label: 'Prev',
                    isEnabled: effectivePage > 1,
                    onTap: () {
                      if (effectivePage > 1) {
                        setState(() => _currentPage = effectivePage - 1);
                      }
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    child: Text(
                      'Hal $effectivePage dari $totalPages',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  _buildPageNavButton(
                    icon: Icons.chevron_right,
                    label: 'Next',
                    isForward: true,
                    isEnabled: effectivePage < totalPages,
                    onTap: () {
                      if (effectivePage < totalPages) {
                        setState(() => _currentPage = effectivePage + 1);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Menampilkan ${startIndex + 1}-$endIndex dari $totalItems transaksi',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? NeoBrutalism.lime : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1.2),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 1.5),
                    blurRadius: 0,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildPageNavButton({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
    bool isForward = false,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isEnabled ? NeoBrutalism.lime : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 1.2),
            boxShadow: isEnabled
                ? const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isForward) Icon(icon, size: 16, color: Colors.black),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              if (isForward) Icon(icon, size: 16, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
