import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../shared/widgets/period_selector_widget.dart';
import '../../../../shared/widgets/heatmap_calendar.dart';

class CashflowTab extends ConsumerStatefulWidget {
  const CashflowTab({super.key});

  @override
  ConsumerState<CashflowTab> createState() => _CashflowTabState();
}

class _CashflowTabState extends ConsumerState<CashflowTab> {
  PeriodType _periodType = PeriodType.month;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Map<DateTime, HeatmapDayData> _buildHeatmapData(List<dynamic> transactions) {
    final map = <DateTime, HeatmapDayData>{};
    for (final tx in transactions) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (!map.containsKey(dateKey)) {
        map[dateKey] = HeatmapDayData(totalIncome: 0.0, totalExpense: 0.0, transactions: []);
      }
      final data = map[dateKey]!;
      double inc = data.totalIncome;
      double exp = data.totalExpense;
      if (tx.type == 'income') {
        inc += tx.amount;
      } else if (tx.type == 'expense') {
        exp += tx.amount;
      }
      data.transactions.add(tx);
      map[dateKey] = HeatmapDayData(
        totalIncome: inc,
        totalExpense: exp,
        transactions: data.transactions,
      );
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final textTheme = Theme.of(context).textTheme;

    // Filter transactions in range
    final filteredTxs = transactions.where((tx) {
      return tx.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(_endDate.add(const Duration(seconds: 1)));
    }).toList();

    // Calculate totals
    final periodIncome = filteredTxs.where((tx) => tx.type == 'income').fold(0.0, (sum, tx) => sum + tx.amount);
    final periodExpense = filteredTxs.where((tx) => tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
    final netCashflow = periodIncome - periodExpense;
    final savingRate = periodIncome > 0 ? (netCashflow / periodIncome) * 100 : 0.0;
    final isSurplus = netCashflow >= 0;

    // Calculate Heatmap Data
    final heatmapData = _buildHeatmapData(transactions);

    // Calculate Daily Averages
    final daysCount = _endDate.difference(_startDate).inDays + 1;
    final avgIncome = periodIncome / (daysCount > 0 ? daysCount : 1);
    final avgExpense = periodExpense / (daysCount > 0 ? daysCount : 1);

    // Calculate Top Spenders
    final expenseTxs = filteredTxs.where((tx) => tx.type == 'expense').toList();
    final categoryTotals = <String, double>{};
    for (final tx in expenseTxs) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0.0) + tx.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(5).toList();

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

          // Heatmap Activity Calendar
          HeatmapCalendarWidget(
            data: heatmapData,
            startDate: _startDate,
            endDate: _endDate,
            periodType: _periodType,
          ),
          if (_periodType != PeriodType.day) const SizedBox(height: 20),

          // Cashflow Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ikhtisar Arus Kas',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryItem('Total Pemasukan', currencyFormat.format(periodIncome), AppColors.success),
                const SizedBox(height: 12),
                _buildSummaryItem('Total Pengeluaran', currencyFormat.format(periodExpense), AppColors.error),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Arus Kas Bersih (Net)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                    ),
                    Text(
                      '${isSurplus ? '+' : ''}${currencyFormat.format(netCashflow)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSurplus ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saving Rate',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    Text(
                      '${savingRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: savingRate >= 20 ? AppColors.success : (savingRate > 0 ? AppColors.warning : AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bar Chart: Income vs Expense
          _buildBarChart(filteredTxs),
          const SizedBox(height: 20),

          // Top Spender Section
          Text('Top Pengeluaran Kategori', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTopSpenders(topCategories, periodExpense),
          const SizedBox(height: 20),

          // Daily Average Card
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
                Text(
                  _periodType == PeriodType.day ? 'Rata-rata per Jam' : 'Rata-rata Harian',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  _periodType == PeriodType.day ? 'Pemasukan / Jam' : 'Pemasukan / Hari',
                  currencyFormat.format(_periodType == PeriodType.day ? avgIncome / 24 : avgIncome),
                  icon: Icons.arrow_downward,
                  iconColor: AppColors.success,
                ),
                Divider(height: 24, color: Colors.grey.shade100),
                _buildSummaryRow(
                  _periodType == PeriodType.day ? 'Pengeluaran / Jam' : 'Pengeluaran / Hari',
                  currencyFormat.format(_periodType == PeriodType.day ? avgExpense / 24 : avgExpense),
                  icon: Icons.arrow_upward,
                  iconColor: AppColors.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {required IconData icon, required Color iconColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBarChart(List<TransactionModel> transactions) {
    int numBars = 6;
    if (_periodType == PeriodType.week) {
      numBars = 7;
    } else if (_periodType == PeriodType.month) {
      numBars = _endDate.difference(_startDate).inDays + 1;
      if (numBars <= 0) numBars = 30;
    } else if (_periodType == PeriodType.year) {
      numBars = 12;
    }

    final barGroups = <BarChartGroupData>[];
    final rangeDuration = _endDate.difference(_startDate);
    final stepMs = rangeDuration.inMilliseconds / numBars;

    double maxVal = 0.5;
    double minVal = -0.5;

    for (int i = 0; i < numBars; i++) {
      final startInt = _startDate.add(Duration(milliseconds: (stepMs * i).toInt()));
      final endInt = _startDate.add(Duration(milliseconds: (stepMs * (i + 1)).toInt()));

      final txs = transactions.where((tx) {
        return tx.date.isAfter(startInt.subtract(const Duration(seconds: 1))) &&
            tx.date.isBefore(endInt);
      });

      final inc = txs.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount) / 1000000.0;
      final exp = txs.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount) / 1000000.0;
      final net = inc - exp;

      if (net > maxVal) maxVal = net;
      if (net < minVal) minVal = net;

      final isPositive = net >= 0;
      final barWidth = numBars > 20 ? 5.5 : (numBars > 10 ? 9.0 : 14.0);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: net,
              color: isPositive ? const Color(0xFF386B11) : const Color(0xFF8CE824),
              width: barWidth,
              borderRadius: isPositive
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    )
                  : const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Cashflow Harian',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.15,
                minY: minVal * 1.15,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    if (value == 0) {
                      return FlLine(color: Colors.grey.shade300, strokeWidth: 1.5);
                    }
                    return FlLine(color: Colors.grey.shade100, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value.abs() < 0.1) return const SizedBox.shrink();
                        return Text(
                          '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}jt',
                          style: TextStyle(fontSize: 8, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= numBars) return const SizedBox.shrink();
                        final pointTime = _startDate.add(Duration(milliseconds: (stepMs * idx).toInt()));

                        String label = '';
                        if (_periodType == PeriodType.day) {
                          label = DateFormat('HH:mm').format(pointTime);
                        } else if (_periodType == PeriodType.week) {
                          label = DateFormat('E', 'id_ID').format(pointTime);
                        } else if (_periodType == PeriodType.month) {
                          final day = pointTime.day;
                          if (day % 2 != 0) {
                            label = '$day';
                          } else {
                            return const SizedBox.shrink();
                          }
                        } else if (_periodType == PeriodType.year) {
                          try {
                            label = DateFormat('MMM', 'id_ID').format(pointTime);
                          } catch (_) {
                            label = DateFormat('MMM').format(pointTime);
                          }
                        } else {
                          label = 'W${idx + 1}';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label,
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSpenders(List<MapEntry<String, double>> topCategories, double totalExpense) {
    if (topCategories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: const Center(
          child: Text(
            'Tidak ada pengeluaran di periode ini',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topCategories.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final cat = topCategories[index];
          final amount = cat.value;
          final pct = totalExpense > 0 ? (amount / totalExpense) : 0.0;
          final catColor = _getCategoryColor(cat.key);
          final catIcon = _getCategoryIcon(cat.key);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
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
                      child: Text(cat.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currencyFormat.format(amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(catColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
}
