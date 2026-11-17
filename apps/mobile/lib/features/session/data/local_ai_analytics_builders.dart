import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../../core/models/transaction_model.dart';
import '../../../core/network/tracker_remote_sync_service.dart';
import '../../../core/utils/ai_category_normalizer.dart';
import '../domain/models/ai_chat_models.dart';
import 'ai_chat_repository.dart';
import 'local_ai_nlp_helpers.dart';

/// Deterministic offline builders for analytics cards and planning drafts.
class LocalAiAnalyticsBuilders {
  static const Uuid _uuid = Uuid();

  LocalAiAnalyticsBuilders._();

  static ({AiMoneyFlowData card, String narrative, int txCount}) buildMoneyFlow({
    required String prompt,
    required AiChatContextSnapshot snapshot,
    required DateTime now,
  }) {
    final scopedTxs = filterTxsByPeriod(prompt, snapshot.transactions, now);
    final label = prompt.toLowerCase().contains('bulan lalu')
        ? 'Bulan Lalu'
        : 'Bulan Ini';

    var totalIncome = 0.0;
    var totalExpense = 0.0;
    final incomeByCat = <String, double>{};
    final expenseByCat = <String, double>{};

    for (final tx in scopedTxs) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
        incomeByCat[tx.category] = (incomeByCat[tx.category] ?? 0) + tx.amount;
      } else if (tx.type == 'expense') {
        totalExpense += tx.amount;
        expenseByCat[tx.category] = (expenseByCat[tx.category] ?? 0) + tx.amount;
      }
    }

    final sortedIncome = incomeByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedExpense = expenseByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final incomeNodes = sortedIncome
        .map(
          (e) => AiMoneyFlowNode(
            label: e.key,
            amount: e.value,
            colorHex: '#10B981',
            percentage: totalIncome > 0
                ? double.parse(((e.value * 100.0) / totalIncome).toStringAsFixed(1))
                : 0.0,
          ),
        )
        .toList();
    final expenseNodes = sortedExpense
        .map(
          (e) => AiMoneyFlowNode(
            label: e.key,
            amount: e.value,
            colorHex: '#0F758A',
            percentage: totalExpense > 0
                ? double.parse(((e.value * 100.0) / totalExpense).toStringAsFixed(1))
                : 0.0,
          ),
        )
        .toList();

    final edges = <AiMoneyFlowEdge>[];
    if (totalIncome > 0 && totalExpense > 0) {
      for (var sIdx = 0; sIdx < incomeNodes.length; sIdx++) {
        final srcShare = incomeNodes[sIdx].amount / totalIncome;
        for (var tIdx = 0; tIdx < expenseNodes.length; tIdx++) {
          final flowAmt = (expenseNodes[tIdx].amount * srcShare).roundToDouble();
          if (flowAmt > 0) {
            edges.add(AiMoneyFlowEdge(
              sourceIndex: sIdx,
              targetIndex: tIdx,
              amount: flowAmt,
            ));
          }
        }
      }
    }

    final netCashflow = totalIncome - totalExpense;
    final topExpText = expenseNodes.isEmpty
        ? 'Belum ada pengeluaran tercatat pada periode ini.'
        : 'Pos pengeluaran terbesar adalah ${expenseNodes.first.label} sebesar ${LocalAiNlpHelpers.formatIdr(expenseNodes.first.amount)} (${expenseNodes.first.percentage}%).';

    final card = AiMoneyFlowData(
      periodLabel: label,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netCashflow: netCashflow,
      transactionCount: scopedTxs.length,
      incomeSources: incomeNodes,
      expenseCategories: expenseNodes,
      flows: edges,
      breakdownSummary: topExpText,
    );

    final narrative = scopedTxs.isEmpty
        ? 'Belum ada transaksi tercatat untuk $label. Catat pemasukan atau pengeluaran pertamamu di sini agar arus kas tampil lengkap.'
        : 'Ringkasan $label: pemasukan ${LocalAiNlpHelpers.formatIdr(totalIncome)}, pengeluaran ${LocalAiNlpHelpers.formatIdr(totalExpense)}, dan arus kas bersih ${LocalAiNlpHelpers.formatIdr(netCashflow)} dari ${scopedTxs.length} transaksi. $topExpText';

    return (card: card, narrative: narrative, txCount: scopedTxs.length);
  }

  static ({AiSpendingTableData table, String narrative, String keyword})
  buildSpendingTable({
    required String prompt,
    required AiChatContextSnapshot snapshot,
    required DateTime now,
  }) {
    final keyword = extractSpendingKeyword(prompt);
    final scoped = filterTxsByPeriod(prompt, snapshot.transactions, now)
        .where((t) => t.type == 'expense')
        .where((t) => keyword.isEmpty || _matchesSpendingKeyword(t, keyword))
        .toList();

    final grouped = <String, ({int count, double total})>{};
    final walletNames = <String>{};
    final categoriesUsed = <String>{};
    final walletLookup = {for (final w in snapshot.wallets) w.id: w.name};

    for (final tx in scoped) {
      final cur = grouped[tx.title] ?? (count: 0, total: 0.0);
      grouped[tx.title] = (count: cur.count + 1, total: cur.total + tx.amount);
      walletNames.add(walletLookup[tx.walletId] ?? 'Dompet');
      categoriesUsed.add(tx.category);
    }

    final rows = grouped.entries
        .map(
          (e) => AiSpendingMerchantRow(
            merchant: e.key,
            transactionCount: e.value.count,
            totalAmount: e.value.total,
          ),
        )
        .toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final totalAmount = rows.fold<double>(0.0, (s, r) => s + r.totalAmount);
    final totalCount = rows.fold<int>(0, (s, r) => s + r.transactionCount);

    final table = AiSpendingTableData(
      title: keyword.isEmpty
          ? 'Rincian pengeluaran'
          : 'Rincian pengeluaran $keyword',
      rows: rows,
      totalAmount: totalAmount,
      totalTransactions: totalCount,
      footnote: walletNames.isEmpty
          ? 'Belum ada transaksi cocok pada periode ini.'
          : 'Sumber dompet: ${walletNames.join(', ')}. Kategori: ${categoriesUsed.join(', ')}.',
    );

    final narrative = totalCount == 0
        ? 'Belum ditemukan pengeluaran ${keyword.isEmpty ? '' : 'untuk $keyword '}pada periode ini.'
        : 'Total pengeluaran ${keyword.isEmpty ? '' : '$keyword '}tercatat ${LocalAiNlpHelpers.formatIdr(totalAmount)} dari $totalCount transaksi.';

    return (table: table, narrative: narrative, keyword: keyword);
  }

  static ({AiGoalDraft draft, String narrative, int months}) buildGoalDraft({
    required String prompt,
    required AiChatContextSnapshot snapshot,
    required DateTime now,
  }) {
    final targetAmount = LocalAiNlpHelpers.parseAmount(prompt) ?? 5000000.0;
    final monthsMatch = RegExp(r'(\d+)\s*bulan').firstMatch(prompt.toLowerCase());
    final months = int.tryParse(monthsMatch?.group(1) ?? '') ?? 6;
    final deadline = DateTime(now.year, now.month + months, now.day);
    final monthlyEstimate = (targetAmount / max(1, months)).ceilToDouble();

    final titleMatch = RegExp(
      r'goal\s+([a-zA-Z0-9\s]{3,32}?)(?=\s+\d|\s+target|\s+prioritas|$)',
      caseSensitive: false,
    ).firstMatch(prompt);
    final goalName = (titleMatch?.group(1)?.trim().isNotEmpty ?? false)
        ? titleMatch!.group(1)!.trim()
        : 'Dana Darurat';
    final formattedName = goalName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    final draft = AiGoalDraft(
      clientMutationId: TrackerRemoteSyncService.sanitizeClientMutationId(
        'goal_${_uuid.v4()}',
      ),
      name: formattedName,
      targetAmount: targetAmount,
      deadline: deadline,
      linkedWalletId: snapshot.wallets.isNotEmpty ? snapshot.wallets.first.id : null,
      monthlySavingEstimate: monthlyEstimate,
    );

    final narrative =
        'Draf target $formattedName sebesar ${LocalAiNlpHelpers.formatIdr(targetAmount)} untuk $months bulan sudah siap dengan estimasi tabungan ${LocalAiNlpHelpers.formatIdr(monthlyEstimate)} per bulan.';
    return (draft: draft, narrative: narrative, months: months);
  }

  static ({AiBudgetDraft draft, String narrative}) buildBudgetDraft({
    required String prompt,
    required AiChatContextSnapshot snapshot,
  }) {
    final limitAmount = LocalAiNlpHelpers.parseAmount(prompt) ?? 1500000.0;
    final categoryHint = prompt
        .replaceAll(
          RegExp(
            r'\b(aturin|atur|buatin|buat|set|budget|anggaran|dong)\b',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    final mainCategory = AiCategoryNormalizer.normalizeBudgetCategory(
      categoryHint.isEmpty ? prompt : categoryHint,
    );
    final avgSpend = snapshot.transactions
        .where((t) => t.type == 'expense' && t.category.startsWith(mainCategory))
        .fold<double>(0.0, (s, t) => s + t.amount);
    final isUpdate = snapshot.budgets.any(
      (b) => b.name.toLowerCase() == mainCategory.toLowerCase(),
    );

    final draft = AiBudgetDraft(
      clientMutationId: TrackerRemoteSyncService.sanitizeClientMutationId(
        'budget_${_uuid.v4()}',
      ),
      category: mainCategory,
      limitAmount: limitAmount,
      avg30dSpend: avgSpend,
      isUpdate: isUpdate,
    );

    final narrative =
        'Draf anggaran $mainCategory sebesar ${LocalAiNlpHelpers.formatIdr(limitAmount)} sudah siap untuk kamu konfirmasi.';
    return (draft: draft, narrative: narrative);
  }

  static ({AiBillDraft draft, String narrative}) buildBillDraft({
    required String prompt,
    required DateTime now,
  }) {
    final amount = LocalAiNlpHelpers.parseAmount(prompt) ?? 200000.0;
    final dayMatch = RegExp(r'(?:tanggal|tgl)\s*(\d{1,2})', caseSensitive: false)
        .firstMatch(prompt);
    final dueDay = (int.tryParse(dayMatch?.group(1) ?? '') ?? 20).clamp(1, 31);
    final safeDay = min(dueDay, DateTime(now.year, now.month + 1, 0).day);
    final dueDate = now.day <= safeDay
        ? DateTime(now.year, now.month, safeDay)
        : DateTime(now.year, now.month + 1, safeDay);

    final lower = prompt.toLowerCase();
    final title = lower.contains('indihome')
        ? 'Wi-Fi IndiHome'
        : (lower.contains('listrik') || lower.contains('pln'))
        ? 'Listrik PLN'
        : 'Tagihan Rutin';
    final category = AiCategoryNormalizer.normalize(
      prompt,
      isIncome: false,
      allowCrossType: false,
      contextHint: title,
    );

    final draft = AiBillDraft(
      clientMutationId: TrackerRemoteSyncService.sanitizeClientMutationId(
        'bill_${_uuid.v4()}',
      ),
      title: title,
      amount: amount,
      dueDay: dueDay,
      dueDate: dueDate,
      frequency: lower.contains('minggu')
          ? 'weekly'
          : (lower.contains('tahun') ? 'yearly' : 'monthly'),
      category: category,
    );

    final narrative =
        'Draf pengingat tagihan $title sebesar ${LocalAiNlpHelpers.formatIdr(amount)} tiap tanggal $dueDay sudah siap.';
    return (draft: draft, narrative: narrative);
  }

  static List<TransactionModel> filterTxsByPeriod(
    String prompt,
    List<TransactionModel> all,
    DateTime now,
  ) {
    final isLastMonth = prompt.toLowerCase().contains('bulan lalu');
    final targetMonth = isLastMonth
        ? DateTime(now.year, now.month - 1, 1)
        : DateTime(now.year, now.month, 1);
    final filtered = all
        .where(
          (t) =>
              t.date.year == targetMonth.year &&
              t.date.month == targetMonth.month,
        )
        .toList();
    return filtered.isNotEmpty || isLastMonth ? filtered : all;
  }

  static String extractSpendingKeyword(String prompt) {
    final match = RegExp(
      r'(?:pengeluaran|buat|untuk|jajan)\s+([a-zA-Z0-9\s]{2,20}?)(?=\s+bulan|\s+minggu|\s+hari|\s+berapa|\?|$)',
      caseSensitive: false,
    ).firstMatch(prompt);
    final candidate = match?.group(1)?.trim().toLowerCase() ?? '';
    if (candidate == 'bulan' || candidate == 'hari') return '';
    if (candidate.isNotEmpty) return candidate;
    if (prompt.toLowerCase().contains('kopi')) return 'kopi';
    return '';
  }

  static bool _matchesSpendingKeyword(TransactionModel tx, String keyword) {
    final kw = keyword.toLowerCase();
    final hay = '${tx.title} ${tx.category} ${tx.notes ?? ''}'.toLowerCase();
    if (hay.contains(kw)) return true;
    if (kw == 'kopi' && hay.contains('coffee')) return true;
    return false;
  }
}
