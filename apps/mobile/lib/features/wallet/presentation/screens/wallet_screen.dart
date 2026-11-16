import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/interactive_donut_chart.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../widgets/wallet_filter_row.dart';
import '../widgets/wallet_gradient_header.dart';
import '../widgets/wallet_stacked_deck.dart';

/// Orchestrator screen for the Wallet feature.
/// Features a Clarafin brand gradient header with interactive donut chart card,
/// followed by an Interactive Stacked ATM Deck on a Neo-Brutalist white canvas.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _activeFilter = 'Semua';
  bool? _sortByValueAsc; // null: normal, false: highest first, true: lowest first

  String _mapTypeToFilter(String type) {
    if (type == 'Bank') return 'Bank';
    if (type == 'E-Wallet') return 'E-Wallet';
    if (['Mutual Fund', 'Stock', 'Bond', 'Deposit', 'Crypto', 'CEX', 'DEX', 'Web3 Wallet'].contains(type)) {
      return 'Investasi';
    }
    return 'Lainnya';
  }

  void _toggleSort() {
    setState(() {
      if (_sortByValueAsc == null) {
        _sortByValueAsc = false; // default first click: Tertinggi ke Terendah
      } else if (_sortByValueAsc == false) {
        _sortByValueAsc = true; // Terendah ke Tertinggi
      } else {
        _sortByValueAsc = null; // reset to original
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topSafeArea = MediaQuery.of(context).padding.top;
    final wallets = ref.watch(walletsProvider);
    final userProfile = ref.watch(userProfileProvider);
    final currencyCode = userProfile.currency;

    // Compute chart data
    double totalBank = 0, totalEwallet = 0, totalInvest = 0, totalOther = 0;
    double totalBalance = 0;
    for (var w in wallets) {
      totalBalance += w.balance;
      final f = _mapTypeToFilter(w.type);
      if (f == 'Bank') {
        totalBank += w.balance;
      } else if (f == 'E-Wallet') {
        totalEwallet += w.balance;
      } else if (f == 'Investasi') {
        totalInvest += w.balance;
      } else {
        totalOther += w.balance;
      }
    }

    final rawChartData = <ChartData>[
      if (totalEwallet > 0) ChartData('E-Wallet', totalEwallet, Colors.black),
      if (totalBank > 0) ChartData('Bank', totalBank, Colors.black),
      if (totalInvest > 0) ChartData('Investasi', totalInvest, Colors.black),
      if (totalOther > 0) ChartData('Lainnya', totalOther, Colors.black),
    ];
    rawChartData.sort((a, b) => b.value.compareTo(a.value));
    final shades = InteractiveDonutChart.generateLimeShades(rawChartData.length);
    final chartData = <ChartData>[];
    for (int i = 0; i < rawChartData.length; i++) {
      chartData.add(ChartData(
        rawChartData[i].label,
        rawChartData[i].value,
        shades[i],
      ));
    }
    if (chartData.isEmpty) {
      chartData.add(ChartData('Tidak ada data', 1.0, Colors.grey.shade300));
    }

    final filteredWallets = wallets.where((w) {
      if (_activeFilter == 'Semua') return true;
      return _mapTypeToFilter(w.type) == _activeFilter;
    }).toList();

    if (_sortByValueAsc != null) {
      if (_sortByValueAsc!) {
        filteredWallets.sort((a, b) => a.balance.compareTo(b.balance));
      } else {
        filteredWallets.sort((a, b) => b.balance.compareTo(a.balance));
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeoBrutalism.brandGradient,
        ),
        child: Column(
          children: [
            // 1. Top Gradient Header & Donut Chart (Pinned at top)
            WalletGradientHeader(
              topSafeArea: topSafeArea,
              totalBalanceFormatted: CurrencyFormatter.format(
                totalBalance,
                currencyCode: currencyCode,
              ),
              chartData: chartData,
              onAddTap: () => context.push('/wallet/add'),
              onSortTap: _toggleSort,
              sortByValueAsc: _sortByValueAsc,
            ),

            // 2. White Canvas holding fixed category pills and scrollable card deck
            Expanded(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Fixed Category Filter Pills (Never scroll, stay on top)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(top: 2, bottom: 6),
                      child: WalletFilterRow(
                        activeFilter: _activeFilter,
                        onFilterSelected: (filter) =>
                            setState(() => _activeFilter = filter),
                      ),
                    ),

                    // Scrollable Deck of ATM Cards (Scrolls under the filter row)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 6, bottom: 160),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: WalletStackedDeck(
                            wallets: filteredWallets,
                            formatAmount: (amt) => CurrencyFormatter.format(
                              amt,
                              currencyCode: currencyCode,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
