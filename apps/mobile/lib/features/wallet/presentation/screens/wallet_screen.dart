import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../shared/widgets/interactive_donut_chart.dart';
import '../widgets/wallet_filter_row.dart';
import '../widgets/wallet_gradient_header.dart';
import '../widgets/wallet_grid_card.dart';

/// Orchestrator screen for the Wallet feature.
/// Features a Halofin brand gradient header with interactive donut chart card,
/// followed by a Neo-Brutalist white canvas holding the user's wallet cards.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _activeFilter = 'Semua';
  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _mapTypeToFilter(String type) {
    if (type == 'Bank') return 'Bank';
    if (type == 'E-Wallet') return 'E-Wallet';
    if (['Mutual Fund', 'Stock', 'Bond', 'Deposit', 'Crypto'].contains(type)) {
      return 'Investasi';
    }
    return 'Lainnya';
  }

  @override
  Widget build(BuildContext context) {
    final topSafeArea = MediaQuery.of(context).padding.top;
    final wallets = ref.watch(walletsProvider);

    // Compute chart data (exact logic preserved)
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
              totalBalanceFormatted: formatCurrency.format(totalBalance),
              chartData: chartData,
            ),

            // 2. White Canvas holding the user's wallet cards
            Expanded(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header: "Your Wallets" + Neo-Brutalist "Sort by Value" button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Wallets',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: -0.3,
                              ),
                            ),
                            // Neo-Brutalist Sort Pill Button
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black,
                                      offset: Offset(0, 1.5),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.swap_vert,
                                      size: 14,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Sort by Value',
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
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter Pills
                      WalletFilterRow(
                        activeFilter: _activeFilter,
                        onFilterSelected: (filter) =>
                            setState(() => _activeFilter = filter),
                      ),
                      const SizedBox(height: 14),

                      // Wallet Cards 2-Column Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.12,
                          ),
                          itemCount: filteredWallets.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return const WalletAddCard();
                            }
                            final wallet = filteredWallets[index - 1];
                            return WalletAccountCard(
                              wallet: wallet,
                              totalBalance: totalBalance,
                              formatCurrency: formatCurrency,
                            );
                          },
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
}
