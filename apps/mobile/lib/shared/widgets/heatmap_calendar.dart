import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/transaction_model.dart';
import 'period_selector_widget.dart';

class HeatmapDayData {
  final double totalIncome;
  final double totalExpense;
  final List<TransactionModel> transactions;

  HeatmapDayData({
    required this.totalIncome,
    required this.totalExpense,
    required this.transactions,
  });

  factory HeatmapDayData.empty() {
    return HeatmapDayData(totalIncome: 0.0, totalExpense: 0.0, transactions: []);
  }
}

class HeatmapCalendarWidget extends StatefulWidget {
  final Map<DateTime, HeatmapDayData> data;
  final DateTime startDate;
  final DateTime endDate;
  final PeriodType periodType;
  final Function(DateTime month)? onMonthChanged;

  const HeatmapCalendarWidget({
    super.key,
    required this.data,
    required this.startDate,
    required this.endDate,
    required this.periodType,
    this.onMonthChanged,
  });

  @override
  State<HeatmapCalendarWidget> createState() => _HeatmapCalendarWidgetState();
}

class _HeatmapCalendarWidgetState extends State<HeatmapCalendarWidget> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.startDate.year, widget.startDate.month, 1);
  }

  @override
  void didUpdateWidget(covariant HeatmapCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDate.month != oldWidget.startDate.month ||
        widget.startDate.year != oldWidget.startDate.year) {
      setState(() {
        _currentMonth = DateTime(widget.startDate.year, widget.startDate.month, 1);
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
    if (widget.onMonthChanged != null) {
      widget.onMonthChanged!(_currentMonth);
    }
  }

  Color _getCellColor(DateTime date, HeatmapDayData dayData) {
    if (widget.periodType == PeriodType.custom) {
      // For custom, only highlight dates inside the range
      if (date.isBefore(widget.startDate) || date.isAfter(widget.endDate)) {
        return Colors.transparent;
      }
    }

    if (dayData.transactions.isEmpty) {
      return Colors.grey.shade100;
    }

    final netFlow = dayData.totalIncome - dayData.totalExpense;
    if (netFlow > 0) {
      if (netFlow < 100000) return AppColors.success.withValues(alpha: 0.15);
      if (netFlow < 1000000) return AppColors.success.withValues(alpha: 0.5);
      return AppColors.success;
    } else if (netFlow < 0) {
      final absFlow = netFlow.abs();
      if (absFlow < 100000) return AppColors.error.withValues(alpha: 0.15);
      if (absFlow < 1000000) return AppColors.error.withValues(alpha: 0.5);
      return AppColors.error;
    } else {
      // Net flow is exactly 0
      return Colors.grey.shade300;
    }
  }

  Color _getTextColor(DateTime date, HeatmapDayData dayData) {
    if (widget.periodType == PeriodType.custom) {
      if (date.isBefore(widget.startDate) || date.isAfter(widget.endDate)) {
        return Colors.grey.shade300;
      }
    }

    if (dayData.transactions.isEmpty) {
      return AppColors.textPrimary;
    }

    final netFlow = dayData.totalIncome - dayData.totalExpense;
    if (netFlow.abs() >= 1000000) {
      return Colors.white; // high intensity text readability
    }
    return AppColors.textPrimary;
  }

  void _showDayDetails(BuildContext context, DateTime date, HeatmapDayData dayData) {
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    String dateStr;
    try {
      dateStr = dateFormat.format(date);
    } catch (e) {
      dateStr = DateFormat('EEEE, d MMMM yyyy').format(date);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        final netFlow = dayData.totalIncome - dayData.totalExpense;
        final isSurplus = netFlow >= 0;

        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(dateStr, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pemasukan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(currencyFormat.format(dayData.totalIncome), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Pengeluaran', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(currencyFormat.format(dayData.totalExpense), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Net: ${isSurplus ? '+' : ''}${currencyFormat.format(netFlow)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSurplus ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Daftar Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: dayData.transactions.isEmpty
                        ? const Center(
                            child: Text('Tidak ada transaksi hari ini', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: dayData.transactions.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, index) {
                              final tx = dayData.transactions[index];
                              final isIncome = tx.type == 'income';
                              final isTransfer = tx.type == 'transfer';
                              final txColor = isIncome ? AppColors.success : (isTransfer ? AppColors.info : AppColors.error);
                              final prefix = isIncome ? '+' : (isTransfer ? '' : '-');

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: txColor.withValues(alpha: 0.1),
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_downward
                                        : (isTransfer ? Icons.swap_horiz : Icons.arrow_upward),
                                    color: txColor,
                                    size: 16,
                                  ),
                                ),
                                title: Text(tx.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: Text('${tx.category} • Wallet: ${tx.walletId}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                trailing: Text(
                                  '$prefix${currencyFormat.format(tx.amount)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: txColor,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.periodType == PeriodType.day || widget.periodType == PeriodType.year) {
      // Mode Hari & Tahun: Do not show heatmap calendar
      return const SizedBox.shrink();
    }

    if (widget.periodType == PeriodType.week) {
      // Mode Minggu: Single row of 7 days
      return _buildWeekView();
    }

    // Default: Mode Bulan & Mode Custom (Month Grid)
    return _buildMonthView();
  }

  Widget _buildWeekView() {
    final days = <Widget>[];
    final now = DateTime.now();
    final df = DateFormat('E', 'id_ID');

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      final dayData = widget.data[dateKey] ?? HeatmapDayData.empty();

      String dayLabel;
      try {
        dayLabel = df.format(date)[0];
      } catch (e) {
        dayLabel = DateFormat('E').format(date)[0];
      }

      final isToday = date.day == now.day && date.month == now.month && date.year == now.year;

      days.add(
        Expanded(
          child: Column(
            children: [
              Text(dayLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showDayDetails(context, dateKey, dayData),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getCellColor(dateKey, dayData),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday ? AppColors.primaryDark : Colors.transparent,
                      width: isToday ? 2 : 0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(dateKey, dayData),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
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
            'Aktivitas Keuangan Mingguan',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days,
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    final monthFormat = DateFormat('MMMM yyyy', 'id_ID');
    String monthStr;
    try {
      monthStr = monthFormat.format(_currentMonth);
    } catch (e) {
      monthStr = DateFormat('MMMM yyyy').format(_currentMonth);
    }

    // Calendar generation
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final weekdayOfFirst = firstDay.weekday; // 1 = Mon, 7 = Sun

    final prefixEmptyCells = weekdayOfFirst - 1;

    final weekLabels = ['Se', 'Se', 'Ra', 'Ka', 'Ju', 'Sa', 'Mi'];
    final gridItems = <Widget>[];

    // Day labels
    for (var label in weekLabels) {
      gridItems.add(
        Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    // Empty cells
    for (int i = 0; i < prefixEmptyCells; i++) {
      gridItems.add(const SizedBox.shrink());
    }

    final today = DateTime.now();

    // Actual calendar days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateKey = DateTime(date.year, date.month, date.day);
      final dayData = widget.data[dateKey] ?? HeatmapDayData.empty();

      final isToday = date.day == today.day && date.month == today.month && date.year == today.year;
      final isFuture = date.isAfter(today);

      gridItems.add(
        GestureDetector(
          onTap: isFuture ? null : () => _showDayDetails(context, dateKey, dayData),
          child: Opacity(
            opacity: isFuture ? 0.3 : 1.0,
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isFuture ? Colors.grey.shade50 : _getCellColor(dateKey, dayData),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isToday ? Colors.black : Colors.transparent,
                  width: isToday ? 2.0 : 0,
                ),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isFuture ? Colors.grey.shade400 : _getTextColor(dateKey, dayData),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
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
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _changeMonth(-1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(0, 1.5), blurRadius: 0),
                    ],
                  ),
                  child: const Icon(Icons.chevron_left, size: 18, color: Colors.black),
                ),
              ),
              Text(
                monthStr,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              InkWell(
                onTap: () => _changeMonth(1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(0, 1.5), blurRadius: 0),
                    ],
                  ),
                  child: const Icon(Icons.chevron_right, size: 18, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grid
          GridView.custom(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            childrenDelegate: SliverChildListDelegate(gridItems),
          ),
          const SizedBox(height: 14),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(AppColors.success, 'Surplus'),
        const SizedBox(width: 12),
        _buildLegendItem(AppColors.error, 'Defisit'),
        const SizedBox(width: 12),
        _buildLegendItem(Colors.grey.shade100, 'Kosong'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black, width: 1.2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 10,
            color: Color(0xFF4B5563),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
