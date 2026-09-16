import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'mock_providers.dart';

class DailyPnlState {
  final double income;
  final double expense;
  final double netPnl;
  final double percentage;
  final bool isPositive;
  final String formattedPnl;
  final String formattedPercentage;

  const DailyPnlState({
    required this.income,
    required this.expense,
    required this.netPnl,
    required this.percentage,
    required this.isPositive,
    required this.formattedPnl,
    required this.formattedPercentage,
  });

  factory DailyPnlState.empty() {
    return const DailyPnlState(
      income: 0,
      expense: 0,
      netPnl: 0,
      percentage: 0,
      isPositive: true,
      formattedPnl: 'Rp 0',
      formattedPercentage: '0.0%',
    );
  }
}

final dailyPnlProvider = Provider<DailyPnlState>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final wallets = ref.watch(walletsProvider);

  final totalBalance = wallets.fold<double>(0, (sum, w) => sum + w.balance);
  final now = DateTime.now();

  // Filter transactions that occurred today
  final todayTransactions = transactions.where((t) {
    return t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day;
  }).toList();

  final income = todayTransactions
      .where((t) => t.type == 'income')
      .fold<double>(0, (sum, t) => sum + t.amount);

  final expense = todayTransactions
      .where((t) => t.type == 'expense' || t.type == 'transfer')
      .fold<double>(0, (sum, t) => sum + t.amount);

  final netPnl = income - expense;
  final percentage = totalBalance > 0 ? (netPnl / totalBalance * 100) : 0.0;
  final isPositive = netPnl >= 0;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final formattedPnl = '${isPositive ? "+" : ""}${currencyFormat.format(netPnl)}';
  final formattedPercentage = '${isPositive ? "+" : ""}${percentage.toStringAsFixed(1)}%';

  return DailyPnlState(
    income: income,
    expense: expense,
    netPnl: netPnl,
    percentage: percentage,
    isPositive: isPositive,
    formattedPnl: formattedPnl,
    formattedPercentage: formattedPercentage,
  );
});
