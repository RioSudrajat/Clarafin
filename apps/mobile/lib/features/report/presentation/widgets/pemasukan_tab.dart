import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../shared/widgets/period_selector_widget.dart';
import '../../../../shared/widgets/interactive_donut_chart.dart';

class PemasukanTab extends ConsumerStatefulWidget {
  const PemasukanTab({super.key});

  @override
  ConsumerState<PemasukanTab> createState() => _PemasukanTabState();
}

class _PemasukanTabState extends ConsumerState<PemasukanTab> {
  PeriodType _periodType = PeriodType.month;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedCategoryFilter = 'Semua';

  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Gaji':
        return AppColors.success;
      case 'Freelance':
        return Colors.teal;
      case 'Investasi':
        return Colors.indigo;
      case 'Transfer':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Gaji':
        return Icons.work;
      case 'Freelance':
        return Icons.computer;
      case 'Investasi':
        return Icons.trending_up;
      case 'Transfer':
        return Icons.swap_horiz;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);

    // Filter transactions in range
    final filteredTxs = transactions.where((tx) {
      return tx.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(_endDate.add(const Duration(seconds: 1)));
    }).toList();

    // Filter to income only
    final incomeTxs = filteredTxs.where((tx) => tx.type == 'income').toList();
    final periodIncome = incomeTxs.fold(0.0, (sum, tx) => sum + tx.amount);

    // Group categories
    final categoryTotals = <String, double>{};
    for (final tx in incomeTxs) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0.0) + tx.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Generate monochromatic shades of lime green
    final shades = InteractiveDonutChart.generateLimeShades(sortedCategories.length);

    // Donut chart data
    final chartData = <ChartData>[];
    if (periodIncome == 0) {
      chartData.add(ChartData('Tidak ada data', 1.0, Colors.grey.shade300));
    } else {
      for (int i = 0; i < sortedCategories.length; i++) {
        final entry = sortedCategories[i];
        chartData.add(ChartData(
          entry.key,
          entry.value,
          shades[i],
        ));
      }
    }

    // List of categories for category filter chips
    final availableCategories = ['Semua', ...categoryTotals.keys];

    // Filtered transactions to show in list
    final listTxs = incomeTxs.where((tx) {
      if (_selectedCategoryFilter == 'Semua') return true;
      return tx.category == _selectedCategoryFilter;
    }).toList();

    // Group transactions by date
    final groupedTransactions = <DateTime, List<TransactionModel>>{};
    for (final tx in listTxs) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(tx);
    }
    final sortedDates = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          PeriodSelectorWidget(
            initialType: _periodType,
            onPeriodChanged: (type, start, end) {
              setState(() {
                _periodType = type;
                _startDate = start;
                _endDate = end;
              });
            },
          ),
          const SizedBox(height: 16),

          // Total Pemasukan Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pemasukan',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NeoBrutalism.lime,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(0, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_downward, size: 14, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'Pemasukan',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  currencyFormat.format(periodIncome),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Donut Chart in Neo-Brutalism Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distribusi Pemasukan',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: InteractiveDonutChart(
                    data: chartData,
                    centerTitle: 'Pemasukan',
                    centerAmount: currencyFormat.format(periodIncome),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Category Breakdown List
          if (periodIncome > 0) ...[
            const Text(
              'Proporsi Kategori',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCategories.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12, thickness: 1),
                itemBuilder: (context, index) {
                  final entry = sortedCategories[index];
                  final pct = (entry.value / periodIncome) * 100;
                  final catColor = periodIncome > 0 ? shades[index] : Colors.grey.shade400;
                  final catIcon = _getCategoryIcon(entry.key);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Icon(catIcon, color: Colors.black, size: 16),
                    ),
                    title: Text(
                      entry.key,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '${(incomeTxs.where((tx) => tx.category == entry.key).length)} transaksi',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(entry.value),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Transaction List — Income
          const Text(
            'Riwayat Pemasukan',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // Category filter chips
          if (categoryTotals.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: availableCategories.map((cat) {
                  final isSelected = _selectedCategoryFilter == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryFilter = cat;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? NeoBrutalism.lime : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.black,
                          width: isSelected ? 2.0 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(0, 2),
                                  blurRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: Colors.black,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Grouped by Date
          if (sortedDates.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Tidak ada riwayat pemasukan',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedDates.length,
              itemBuilder: (context, idx) {
                final date = sortedDates[idx];
                final txs = groupedTransactions[date]!;
                final dateLabel = _formatGroupDate(date);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Text(
                        dateLabel,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: txs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12, thickness: 1),
                        itemBuilder: (context, txIdx) {
                          final tx = txs[txIdx];
                          final catColor = _getCategoryColor(tx.category);
                          final catIcon = _getCategoryIcon(tx.category);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: Icon(catIcon, color: Colors.black, size: 16),
                            ),
                            title: Text(
                              tx.title,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              tx.category,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Text(
                              '+${currencyFormat.format(tx.amount)}',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: NeoBrutalism.teal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Hari Ini';
    } else if (checkDate == yesterday) {
      return 'Kemarin';
    } else {
      try {
        return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
      } catch (e) {
        return DateFormat('d MMMM yyyy').format(date);
      }
    }
  }
}
