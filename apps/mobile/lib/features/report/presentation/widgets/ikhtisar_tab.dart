import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../features/budget/presentation/providers/finance_providers.dart';
import '../../../../shared/widgets/period_selector_widget.dart';

class IkhtisarTab extends ConsumerStatefulWidget {
  const IkhtisarTab({super.key});

  @override
  ConsumerState<IkhtisarTab> createState() => _IkhtisarTabState();
}

class _IkhtisarTabState extends ConsumerState<IkhtisarTab> {
  PeriodType _periodType = PeriodType.month;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isAssetVisible = true;
  String _selectedAssetFilter = 'Semua';
  double? _touchedBalance;
  DateTime? _touchedDate;

  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  String _formatTouchedDate(DateTime date) {
    if (_periodType == PeriodType.day) {
      return DateFormat('HH:mm').format(date);
    } else if (_periodType == PeriodType.week) {
      try {
        return DateFormat('EEEE, dd MMM', 'id_ID').format(date);
      } catch (_) {
        return DateFormat('EEEE, dd MMM').format(date);
      }
    } else if (_periodType == PeriodType.year) {
      try {
        return DateFormat('dd MMM yyyy', 'id_ID').format(date);
      } catch (_) {
        return DateFormat('dd MMM yyyy').format(date);
      }
    } else {
      try {
        return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
      } catch (_) {
        return DateFormat('dd MMMM yyyy').format(date);
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider);
    final goals = ref.watch(goalsProvider);
    final transactions = ref.watch(transactionsProvider);
    final textTheme = Theme.of(context).textTheme;

    // Calculate total assets
    final totalWalletBalance = wallets.fold(0.0, (sum, w) => sum + w.balance);
    final totalGoalsSaved = goals.fold(0.0, (sum, g) => sum + g.savedAmount);
    final totalAssets = totalWalletBalance + totalGoalsSaved;

    // Filter transactions in range
    final filteredTxs = transactions.where((tx) {
      return tx.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(_endDate.add(const Duration(seconds: 1)));
    }).toList();

    // Calculate income / expense in selected period
    final periodIncome = filteredTxs.where((tx) => tx.type == 'income').fold(0.0, (sum, tx) => sum + tx.amount);
    final periodExpense = filteredTxs.where((tx) => tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
    final netCashflow = periodIncome - periodExpense;

    // Percentage change in selected period
    final changePercentage = totalAssets > 0 ? (netCashflow / totalAssets) * 100 : 0.0;
    final isPositive = netCashflow >= 0;

    // Pre-calculate line spots for the chart and touch indexing
    final spots = <FlSpot>[];
    final spotTimes = <DateTime>[];
    const numPoints = 100;
    final rangeDuration = _endDate.difference(_startDate);
    final stepMs = rangeDuration.inMilliseconds / (numPoints - 1);

    // Filter and sort transactions chronologically
    final sortedTxs = List<TransactionModel>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (int i = 0; i < numPoints; i++) {
      final pointTime = _startDate.add(Duration(milliseconds: (stepMs * i).toInt()));
      spotTimes.add(pointTime);
      
      // Calculate running balance at pointTime
      double runningBal = totalAssets;
      for (final tx in sortedTxs) {
        if (tx.date.isAfter(pointTime)) {
          if (tx.type == 'income') {
            runningBal -= tx.amount;
          } else if (tx.type == 'expense') {
            runningBal += tx.amount;
          }
        }
      }
      spots.add(FlSpot(i.toDouble(), runningBal / 1000000.0)); // scale to millions
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Net Worth (No Container card)
          Row(
            children: [
              Text(
                _touchedBalance != null ? 'Aset pada ${_formatTouchedDate(_touchedDate!)}' : 'Total Aset',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_touchedBalance == null) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    _isAssetVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _isAssetVisible = !_isAssetVisible;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isAssetVisible ? currencyFormat.format(_touchedBalance ?? totalAssets) : '••••••••',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _touchedBalance != null
              ? const SizedBox(height: 18) // Spacing placeholder
              : Row(
                  children: [
                    Text(
                      'PnL Periode Ini: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${currencyFormat.format(netCashflow)} (${isPositive ? '+' : ''}${changePercentage.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
          const SizedBox(height: 16),

          // Area Line Chart
          _buildAreaChart(spots, spotTimes, stepMs),
          const SizedBox(height: 10),

          // Period Selector Widget (moved here below line chart)
          PeriodSelectorWidget(
            initialType: _periodType,
            onPeriodChanged: (type, start, end) {
              setState(() {
                _periodType = type;
                _startDate = start;
                _endDate = end;
                _touchedBalance = null;
                _touchedDate = null;
              });
            },
          ),
          const SizedBox(height: 20),

          // Asset Breakdown Section (Revisian: di bawah Chart)
          Text('Rincian Aset', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildAssetFilters(),
          const SizedBox(height: 12),
          _buildAssetBreakdownList(wallets, goals, totalAssets),
          const SizedBox(height: 24),

          // Balance Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Net Balance (Wallet)', currencyFormat.format(totalWalletBalance), icon: Icons.account_balance_wallet, iconColor: AppColors.primaryDark),
                Divider(height: 24, color: Colors.grey.shade100),
                _buildSummaryRow('Tabungan Goals', currencyFormat.format(totalGoalsSaved), icon: Icons.track_changes, iconColor: Colors.amber),
                Divider(height: 24, color: Colors.grey.shade100),
                _buildSummaryRow('Pemasukan Periode Ini', currencyFormat.format(periodIncome), icon: Icons.arrow_downward, iconColor: AppColors.success),
                const SizedBox(height: 12),
                _buildSummaryRow('Pengeluaran Periode Ini', currencyFormat.format(periodExpense), icon: Icons.arrow_upward, iconColor: AppColors.error),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recommendations
          Row(
            children: [
              const Icon(Icons.tips_and_updates, size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text('Rekomendasi AI', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            text: 'Pengeluaran makan kamu naik 15% dari bulan lalu. Coba set budget Rp 1.500.000 untuk bulan depan.',
            ctaText: 'Set Budget Makan',
            ctaColor: AppColors.primary,
            onTap: () => context.go('/budget'),
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            text: 'Tabungan kamu sudah naik Rp 2.300.000 dalam 3 bulan. Pertimbangkan investasi reksa dana pasar uang.',
            ctaText: 'Lihat Konsultan Investasi',
            ctaColor: Colors.blue,
            onTap: () => context.go('/consult'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAreaChart(List<FlSpot> spots, List<DateTime> spotTimes, double stepMs) {
    double maxVal = 1.0;
    if (spots.isNotEmpty) {
      maxVal = spots.map((s) => s.y.abs()).reduce((a, b) => a > b ? a : b);
    }
    if (maxVal == 0) maxVal = 1.0;
    final double maxY = maxVal * 1.15;
    final double minY = -maxY;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: spots.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchSpotThreshold: 1000.0,
                    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.lineBarSpots == null ||
                          response.lineBarSpots!.isEmpty) {
                        setState(() {
                          _touchedBalance = null;
                          _touchedDate = null;
                        });
                        return;
                      }

                      final spot = response.lineBarSpots!.first;
                      final index = spot.spotIndex;
                      if (index >= 0 && index < spotTimes.length) {
                        setState(() {
                          _touchedBalance = spot.y * 1000000.0;
                          _touchedDate = spotTimes[index];
                        });
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) => null).toList();
                      },
                    ),
                    getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: AppColors.success.withValues(alpha: 0.5),
                            strokeWidth: 2,
                            dashArray: [4, 4],
                          ),
                          FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 6,
                                color: AppColors.success,
                                strokeWidth: 3,
                                strokeColor: AppColors.success.withValues(alpha: 0.3),
                              );
                            },
                          ),
                        );
                      }).toList();
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.success,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.success.withValues(alpha: 0.15),
                            AppColors.success.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAssetFilters() {
    final filters = ['Semua', 'Bank', 'E-Wallet', 'Investasi', 'Goals'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedAssetFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedAssetFilter = filter;
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
                filter,
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
    );
  }

  Widget _buildAssetBreakdownList(List<dynamic> wallets, List<GoalModel> goals, double totalAssets) {
    final items = <Widget>[];

    if (_selectedAssetFilter == 'Semua') {
      // Show all wallets + one aggregated goals item if goals are saved
      for (final wallet in wallets) {
        items.add(_buildAssetRow(
          name: wallet.name,
          category: wallet.type,
          balance: wallet.balance,
          totalAssets: totalAssets,
          icon: _getWalletIcon(wallet.type),
          iconColor: _getWalletColor(wallet.type),
        ));
      }
      if (goals.isNotEmpty) {
        final totalSaved = goals.fold(0.0, (sum, g) => sum + g.savedAmount);
        if (totalSaved > 0) {
          items.add(_buildAssetRow(
            name: 'Goals Keuangan',
            category: 'Tabungan Target',
            balance: totalSaved,
            totalAssets: totalAssets,
            icon: Icons.track_changes,
            iconColor: Colors.amber,
          ));
        }
      }
    } else if (_selectedAssetFilter == 'Bank') {
      final bankWallets = wallets.where((w) => w.type == 'Bank').toList();
      for (final wallet in bankWallets) {
        items.add(_buildAssetRow(
          name: wallet.name,
          category: 'Bank Account',
          balance: wallet.balance,
          totalAssets: totalAssets,
          icon: Icons.account_balance,
          iconColor: Colors.blue,
        ));
      }
    } else if (_selectedAssetFilter == 'E-Wallet') {
      final eWallets = wallets.where((w) => w.type == 'E-Wallet').toList();
      for (final wallet in eWallets) {
        items.add(_buildAssetRow(
          name: wallet.name,
          category: 'E-Wallet',
          balance: wallet.balance,
          totalAssets: totalAssets,
          icon: Icons.account_balance_wallet,
          iconColor: Colors.purple,
        ));
      }
    } else if (_selectedAssetFilter == 'Investasi') {
      final investmentTypes = ['Mutual Fund', 'Stock', 'Crypto', 'Bond', 'Deposit'];
      final investWallets = wallets.where((w) => investmentTypes.contains(w.type)).toList();
      for (final wallet in investWallets) {
        items.add(_buildAssetRow(
          name: wallet.name,
          category: wallet.type,
          balance: wallet.balance,
          totalAssets: totalAssets,
          icon: Icons.trending_up,
          iconColor: Colors.teal,
        ));
      }
    } else if (_selectedAssetFilter == 'Goals') {
      for (final goal in goals) {
        // Individual goal with progress indicator
        final percent = goal.targetAmount > 0 ? (goal.savedAmount / goal.targetAmount) : 0.0;
        items.add(_buildGoalRow(goal, percent));
      }
    }

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: const Center(
          child: Text(
            'Tidak ada aset di kategori ini',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) => items[index],
      ),
    );
  }

  Widget _buildAssetRow({
    required String name,
    required String category,
    required double balance,
    required double totalAssets,
    required IconData icon,
    required Color iconColor,
  }) {
    final portionPct = totalAssets > 0 ? (balance / totalAssets) : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withValues(alpha: 0.1),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(category, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(
                _isAssetVisible ? currencyFormat.format(balance) : '••••••',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: portionPct,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(portionPct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(GoalModel goal, double progress) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.amber.withValues(alpha: 0.1),
                child: Icon(goal.icon, color: Colors.amber.shade700, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Target: ${currencyFormat.format(goal.targetAmount)}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isAssetVisible ? currencyFormat.format(goal.savedAmount) : '••••••',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% tercapai',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.success),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWalletIcon(String type) {
    switch (type) {
      case 'Bank':
        return Icons.account_balance;
      case 'E-Wallet':
        return Icons.account_balance_wallet;
      case 'Cash':
        return Icons.money;
      default:
        return Icons.trending_up;
    }
  }

  Color _getWalletColor(String type) {
    switch (type) {
      case 'Bank':
        return Colors.blue;
      case 'E-Wallet':
        return Colors.purple;
      case 'Cash':
        return Colors.orange;
      default:
        return Colors.teal;
    }
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

  Widget _buildRecommendationCard({required String text, required String ctaText, required Color ctaColor, VoidCallback? onTap}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ctaColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: ctaColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.5)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ctaColor,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Text(ctaText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}
