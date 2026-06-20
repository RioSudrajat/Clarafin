import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../features/budget/presentation/providers/finance_providers.dart';
import '../../../../shared/widgets/period_selector_widget.dart';
import '../../../../shared/widgets/interactive_donut_chart.dart';

class PengeluaranTab extends ConsumerStatefulWidget {
  const PengeluaranTab({super.key});

  @override
  ConsumerState<PengeluaranTab> createState() => _PengeluaranTabState();
}

class _PengeluaranTabState extends ConsumerState<PengeluaranTab> {
  PeriodType _periodType = PeriodType.month;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedCategoryFilter = 'Semua';

  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Makan':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Tagihan':
        return Colors.purple;
      case 'Hiburan':
        return Colors.pink;
      case 'Belanja':
        return Colors.teal;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Makan':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Tagihan':
        return Icons.receipt_long;
      case 'Hiburan':
        return Icons.movie;
      case 'Belanja':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final budgets = ref.watch(budgetsProvider);
    final textTheme = Theme.of(context).textTheme;

    // Filter transactions in range
    final filteredTxs = transactions.where((tx) {
      return tx.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(_endDate.add(const Duration(seconds: 1)));
    }).toList();

    // Filter to expense only
    final expenseTxs = filteredTxs.where((tx) => tx.type == 'expense').toList();
    final periodExpense = expenseTxs.fold(0.0, (sum, tx) => sum + tx.amount);

    // Calculate previous period of same length for comparison
    final daysCount = _endDate.difference(_startDate).inDays + 1;
    final previousStartDate = _startDate.subtract(Duration(days: daysCount));
    final previousEndDate = _startDate.subtract(const Duration(seconds: 1));

    final previousTxs = transactions.where((tx) {
      return tx.date.isAfter(previousStartDate.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(previousEndDate.add(const Duration(seconds: 1)));
    }).toList();
    final previousExpense = previousTxs.where((tx) => tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);

    final isExpenseIncreased = periodExpense > previousExpense;
    final pctIncrease = previousExpense > 0 ? ((periodExpense - previousExpense) / previousExpense * 100) : 0.0;

    // Group categories
    final categoryTotals = <String, double>{};
    for (final tx in expenseTxs) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0.0) + tx.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Donut chart data
    final chartData = <ChartData>[];
    if (periodExpense == 0) {
      chartData.add(ChartData('Tidak ada data', 1.0, Colors.grey.shade300));
    } else {
      for (final entry in sortedCategories) {
        chartData.add(ChartData(
          entry.key,
          entry.value,
          _getCategoryColor(entry.key),
        ));
      }
    }

    // List of categories for category filter chips
    final availableCategories = ['Semua', ...categoryTotals.keys];

    // Filtered transactions to show in list
    final listTxs = expenseTxs.where((tx) {
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

          // Total Pengeluaran Card with Comparison Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Pengeluaran',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyFormat.format(periodExpense),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                    if (isExpenseIncreased && previousExpense > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Naik ${pctIncrease.toStringAsFixed(0)}% ⚠️',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Donut Chart (REUSE)
          Center(
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: InteractiveDonutChart(
                data: chartData,
                centerTitle: 'Pengeluaran',
                centerAmount: currencyFormat.format(periodExpense),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category Breakdown List with Budget progress indicator integration
          if (periodExpense > 0) ...[
            Text('Proporsi Kategori & Anggaran', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCategories.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final entry = sortedCategories[index];
                  final pct = (entry.value / periodExpense) * 100;
                  final catColor = _getCategoryColor(entry.key);
                  final catIcon = _getCategoryIcon(entry.key);

                  // Find matching budget if exists
                  BudgetCategoryModel? matchingBudget;
                  try {
                    matchingBudget = budgets.firstWhere(
                      (b) => b.name.toLowerCase().contains(entry.key.toLowerCase()) || 
                             entry.key.toLowerCase().contains(b.name.toLowerCase()) ||
                             (entry.key == 'Makan' && b.name == 'Food & Drink')
                    );
                  } catch (_) {
                    matchingBudget = null;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: catColor.withValues(alpha: 0.1),
                              child: Icon(catIcon, color: catColor, size: 14),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  if (matchingBudget != null)
                                    Text(
                                      'Anggaran: ${currencyFormat.format(matchingBudget.totalAmount)}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(currencyFormat.format(entry.value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                        if (matchingBudget != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (entry.value / matchingBudget.totalAmount).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                (entry.value > matchingBudget.totalAmount) ? AppColors.error : AppColors.warning,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Transaction List — Expense
          Text('Riwayat Pengeluaran', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                        color: isSelected ? AppColors.primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryDark : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: const Center(
                child: Text('Tidak ada riwayat pengeluaran', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: txs.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, txIdx) {
                          final tx = txs[txIdx];
                          final catColor = _getCategoryColor(tx.category);
                          final catIcon = _getCategoryIcon(tx.category);

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: catColor.withValues(alpha: 0.1),
                              child: Icon(catIcon, color: catColor, size: 16),
                            ),
                            title: Text(tx.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(tx.category, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            trailing: Text(
                              '-${currencyFormat.format(tx.amount)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
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
