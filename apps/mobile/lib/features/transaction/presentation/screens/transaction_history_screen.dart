import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/transaction_history_empty_state.dart';
import '../widgets/transaction_history_filter_bar.dart';
import '../widgets/transaction_history_filter_sheet.dart';
import '../widgets/transaction_history_group_header.dart';
import '../widgets/transaction_history_list_item.dart';
import '../widgets/transaction_history_summary_card.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'all';
  String _selectedTimeRange = 'all';
  Set<String> _selectedCategories = {};
  String? _selectedWalletId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> raw) {
    final now = DateTime.now();
    return raw.where((tx) {
      if (_selectedType != 'all' && tx.type != _selectedType) return false;
      if (_selectedWalletId != null && tx.walletId != _selectedWalletId) return false;
      if (_selectedCategories.isNotEmpty && !_selectedCategories.contains(tx.category)) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!tx.title.toLowerCase().contains(q) && !tx.category.toLowerCase().contains(q)) return false;
      }
      if (_selectedTimeRange == 'month' && (tx.date.year != now.year || tx.date.month != now.month)) return false;
      if (_selectedTimeRange == '30days' && now.difference(tx.date).inDays > 30) return false;
      if (_selectedTimeRange == '7days' && now.difference(tx.date).inDays > 7) return false;
      return true;
    }).toList();
  }

  Map<String, List<TransactionModel>> _groupByDate(List<TransactionModel> list) {
    final Map<String, List<TransactionModel>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    for (final tx in list) {
      final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final key = txDay == today
          ? 'Hari Ini, ${DateFormat('d MMM').format(tx.date)}'
          : (txDay == yesterday
              ? 'Kemarin, ${DateFormat('d MMM').format(tx.date)}'
              : DateFormat('d MMMM yyyy', 'id_ID').format(tx.date));
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  void _openFilterSheet(List<String> categories) {
    final wallets = ref.read(walletsProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionHistoryFilterSheet(
        wallets: wallets,
        allCategories: categories,
        selectedCategories: _selectedCategories,
        selectedWalletId: _selectedWalletId,
        onApply: (cats, wallet) => setState(() {
          _selectedCategories = cats;
          _selectedWalletId = wallet;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionsProvider);
    final wallets = ref.watch(walletsProvider);
    final walletMap = {for (final w in wallets) w.id: w.name};
    final allCategories = allTransactions.map((t) => t.category).toSet().toList()..sort();
    final filtered = _filterTransactions(allTransactions);
    final grouped = _groupByDate(filtered);

    double totalIn = 0, totalOut = 0;
    for (final tx in filtered) {
      if (tx.type == 'income') {
        totalIn += tx.amount;
      } else {
        totalOut += tx.amount;
      }
    }

    final hasAdvFilter = _selectedCategories.isNotEmpty || _selectedWalletId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Riwayat Transaksi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18, color: NeoBrutalism.dark)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: NeoBrutalism.circleDecoration(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: NeoBrutalism.dark, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: NeoBrutalism.circleDecoration(backgroundColor: hasAdvFilter ? NeoBrutalism.lime : Colors.white),
              child: IconButton(
                icon: const Icon(Icons.tune_rounded, color: NeoBrutalism.dark, size: 20),
                onPressed: () => _openFilterSheet(allCategories),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: TransactionHistorySummaryCard(totalIncome: totalIn, totalExpense: totalOut)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: TransactionHistoryFilterBar(
                searchController: _searchController,
                searchQuery: _searchQuery,
                onSearchChanged: (val) => setState(() => _searchQuery = val),
                onClearSearch: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                selectedType: _selectedType,
                onTypeChanged: (type) => setState(() => _selectedType = type),
                selectedTimeRange: _selectedTimeRange,
                onTimeRangeChanged: (range) => setState(() => _selectedTimeRange = range),
              ),
            ),
          ),
          if (filtered.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: TransactionHistoryEmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = grouped.entries.elementAt(index);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TransactionHistoryGroupHeader(dateTitle: entry.key),
                      ...entry.value.map((tx) => TransactionHistoryListItem(
                            transaction: tx,
                            walletName: walletMap[tx.walletId] ?? 'Akun Utama',
                            onTap: () => context.push('/transaction/success', extra: {'transaction': tx}),
                          )),
                    ],
                  );
                },
                childCount: grouped.entries.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
