import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/ai_chat_models.dart';

/// Unified Neo-Brutalist action card for AI Goal, Budget, and Bill drafts.
class AiPlanningActionCard extends StatelessWidget {
  final AiGoalDraft? goalDraft;
  final AiBudgetDraft? budgetDraft;
  final AiBillDraft? billDraft;
  final VoidCallback? onConfirmGoal;
  final VoidCallback? onCancelGoal;
  final VoidCallback? onEditGoal;
  final VoidCallback? onConfirmBudget;
  final VoidCallback? onCancelBudget;
  final VoidCallback? onViewBudget;
  final VoidCallback? onEditBudget;
  final VoidCallback? onConfirmBill;
  final VoidCallback? onCancelBill;
  final VoidCallback? onEditBill;
  final String Function(String walletId)? walletLabelResolver;

  const AiPlanningActionCard({
    super.key,
    this.goalDraft, this.budgetDraft, this.billDraft,
    this.onConfirmGoal, this.onCancelGoal, this.onEditGoal,
    this.onConfirmBudget, this.onCancelBudget, this.onViewBudget, this.onEditBudget,
    this.onConfirmBill, this.onCancelBill, this.onEditBill,
    this.walletLabelResolver,
  });

  factory AiPlanningActionCard.goal({Key? key, required AiGoalDraft goalDraft, VoidCallback? onConfirmGoal, VoidCallback? onCancelGoal, VoidCallback? onEditGoal, String Function(String walletId)? walletLabelResolver}) =>
      AiPlanningActionCard(key: key, goalDraft: goalDraft, onConfirmGoal: onConfirmGoal, onCancelGoal: onCancelGoal, onEditGoal: onEditGoal, walletLabelResolver: walletLabelResolver);

  factory AiPlanningActionCard.budget({Key? key, required AiBudgetDraft budgetDraft, VoidCallback? onConfirmBudget, VoidCallback? onCancelBudget, VoidCallback? onViewBudget, VoidCallback? onEditBudget}) =>
      AiPlanningActionCard(key: key, budgetDraft: budgetDraft, onConfirmBudget: onConfirmBudget, onCancelBudget: onCancelBudget, onViewBudget: onViewBudget, onEditBudget: onEditBudget);

  factory AiPlanningActionCard.bill({Key? key, required AiBillDraft billDraft, VoidCallback? onConfirmBill, VoidCallback? onCancelBill, VoidCallback? onEditBill}) =>
      AiPlanningActionCard(key: key, billDraft: billDraft, onConfirmBill: onConfirmBill, onCancelBill: onCancelBill, onEditBill: onEditBill);

  TextStyle _ts(double sz, FontWeight fw, [Color c = NeoBrutalism.dark]) =>
      TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: sz, fontWeight: fw, color: c);

  @override
  Widget build(BuildContext context) {
    final specs = [
      if (goalDraft != null) _goalSpec(context, goalDraft!),
      if (budgetDraft != null) _budgetSpec(context, budgetDraft!),
      if (billDraft != null) _billSpec(context, billDraft!),
    ];
    if (specs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: NeoBrutalism.cardDecoration(backgroundColor: NeoBrutalism.surfaceWarm, borderRadius: NeoBrutalism.radiusLg, shadowOffset: 2.0),
        child: Text('Draf perencanaan belum tersedia.', style: _ts(12.5, FontWeight.w600, const Color(0xFF4B5563))),
      );
    }
    if (specs.length == 1) return _renderSpec(specs.first);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (var i = 0; i < specs.length; i++) ...[if (i > 0) const SizedBox(height: 12), _renderSpec(specs[i])]]);
  }

  _PlanSpec _goalSpec(BuildContext context, AiGoalDraft g) {
    final wallet = (g.linkedWalletId ?? '').trim();
    return _PlanSpec(
      icon: Icons.flag_rounded, badge: 'Draf Target Tabungan', title: g.name,
      metrics: [('Target', CurrencyFormatter.format(g.targetAmount)), if (g.deadline != null) ('Target Waktu', _fmtDate(g.deadline!)), if (wallet.isNotEmpty) ('Dompet', walletLabelResolver?.call(wallet) ?? wallet)],
      note: (g.monthlySavingEstimate ?? 0) > 0 ? 'Estimasi nabung: ${CurrencyFormatter.format(g.monthlySavingEstimate!)}/bulan' : null,
      noteBg: AppColors.primaryLight,
      isSubmitting: g.isSubmitting, isConfirmed: g.isConfirmed, isCancelled: g.isCancelled,
      confirmedText: 'Goal "${g.name}" dibuat', cancelledText: 'Draf goal dibatalkan',
      confirmKey: const Key('goal_confirm_btn'), confirmLabel: '+ Buat Goal Ini', onConfirm: onConfirmGoal,
      secondary: [
        if (onCancelGoal != null) _SecondaryBtn(const Key('goal_cancel_btn'), 'Batal', const Color(0xFF9F1239), onCancelGoal!),
        _SecondaryBtn(const Key('goal_edit_btn'), 'Atur Detail', Colors.black, () => onEditGoal != null ? onEditGoal!() : _push(context, '/goal/add', extra: {'name': g.name, 'targetAmount': g.targetAmount, if (g.deadline != null) 'deadline': g.deadline!.toIso8601String()})),
      ],
    );
  }

  _PlanSpec _budgetSpec(BuildContext context, AiBudgetDraft b) {
    final avg = b.avg30dSpend;
    final over = avg != null && avg > b.limitAmount;
    return _PlanSpec(
      icon: Icons.pie_chart_rounded, badge: b.isUpdate ? 'Pembaruan Budget' : 'Draf Budget Baru', title: b.category,
      metrics: [('Batas Bulanan', CurrencyFormatter.format(b.limitAmount)), if (avg != null) ('Rata-rata 30 hari', CurrencyFormatter.format(avg))],
      note: avg == null ? null : (over ? 'Target hemat ${CurrencyFormatter.format(avg - b.limitAmount)} di bawah rata-rata 30 hari' : 'Masih di dalam rata-rata pengeluaran 30 hari'),
      noteBg: over ? const Color(0xFFFEF3C7) : NeoBrutalism.surfaceWarm,
      isSubmitting: b.isSubmitting, isConfirmed: b.isConfirmed, isCancelled: b.isCancelled,
      confirmedText: 'Budget ${b.category} aktif', cancelledText: 'Draf budget dibatalkan',
      confirmKey: const Key('budget_confirm_btn'), confirmLabel: '+ Pasang Budget', onConfirm: onConfirmBudget,
      secondary: [
        _SecondaryBtn(const Key('budget_view_btn'), 'Lihat Budget', Colors.black, () => onViewBudget != null ? onViewBudget!() : _push(context, '/budget?tab=1')),
        _SecondaryBtn(const Key('budget_edit_btn'), 'Edit Rinci', Colors.black, () => onEditBudget != null ? onEditBudget!() : _push(context, '/budget/add', extra: {'category': b.category, 'limitAmount': b.limitAmount})),
        if (onCancelBudget != null) _SecondaryBtn(const Key('budget_cancel_btn'), 'Batal', const Color(0xFF9F1239), onCancelBudget!),
      ],
    );
  }

  _PlanSpec _billSpec(BuildContext context, AiBillDraft bill) => _PlanSpec(
    icon: Icons.event_repeat_rounded, badge: 'Draf Pengingat Tagihan', title: bill.title,
    metrics: [('Nominal', CurrencyFormatter.format(bill.amount)), ('Frekuensi', _fmtFreq(bill.frequency)), if (bill.dueDate != null || bill.dueDay != null) ('Jatuh Tempo', _fmtDue(bill)), ('Kategori', bill.category)],
    isSubmitting: bill.isSubmitting, isConfirmed: bill.isConfirmed, isCancelled: bill.isCancelled,
    confirmedText: 'Pengingat "${bill.title}" aktif', cancelledText: 'Draf tagihan dibatalkan',
    confirmKey: const Key('bill_confirm_btn'), confirmLabel: '+ Aktifkan Pengingat', onConfirm: onConfirmBill,
    secondary: [
      if (onCancelBill != null) _SecondaryBtn(const Key('bill_cancel_btn'), 'Batal', const Color(0xFF9F1239), onCancelBill!),
      _SecondaryBtn(const Key('bill_edit_btn'), 'Atur Tagihan', Colors.black, () => onEditBill != null ? onEditBill!() : _push(context, '/bill/add', extra: {'title': bill.title, 'amount': bill.amount, if (bill.dueDay != null) 'dueDay': bill.dueDay, if (bill.dueDate != null) 'dueDate': bill.dueDate!.toIso8601String(), 'frequency': bill.frequency, 'category': bill.category})),
    ],
  );

  Widget _renderSpec(_PlanSpec spec) {
    final finalized = spec.isConfirmed || spec.isCancelled;
    final locked = spec.isSubmitting || finalized;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: NeoBrutalism.cardDecoration(borderRadius: NeoBrutalism.radiusLg, shadowOffset: 3.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(spec.icon, size: 18, color: Colors.black), const SizedBox(width: 8), Expanded(child: Text(spec.badge, style: _ts(12.5, FontWeight.w800, const Color(0xFF4B5563))))]),
          const SizedBox(height: 6),
          Text(spec.title, style: _ts(16, FontWeight.w900)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: NeoBrutalism.surfaceWarm, borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm), border: NeoBrutalism.border(width: 1.5)),
            child: Column(children: [
              for (var i = 0; i < spec.metrics.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(spec.metrics[i].$1, style: _ts(12, FontWeight.w600, const Color(0xFF4B5563))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(spec.metrics[i].$2, textAlign: TextAlign.right, style: _ts(12.5, FontWeight.w800, Colors.black))),
                ]),
              ],
            ]),
          ),
          if (spec.note != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: spec.noteBg, borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm), border: NeoBrutalism.border(width: 1.5)),
              child: Text(spec.note!, style: _ts(12, FontWeight.w700, Colors.black)),
            ),
          ],
          const SizedBox(height: 12),
          if (spec.isConfirmed) ...[_banner(NeoBrutalism.mint, Icons.check_circle_rounded, spec.confirmedText), const SizedBox(height: 10)],
          if (spec.isCancelled) ...[_banner(NeoBrutalism.coral, Icons.cancel_rounded, spec.cancelledText), const SizedBox(height: 10)],
          _btn(key: spec.confirmKey, label: spec.confirmLabel, bg: NeoBrutalism.lime, fg: Colors.black, fullW: true, primary: true, enabled: !locked, loading: spec.isSubmitting, onTap: spec.onConfirm),
          if (!finalized && spec.secondary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: spec.secondary.map((a) => _btn(key: a.key, label: a.label, bg: Colors.white, fg: a.color, enabled: !spec.isSubmitting, onTap: a.onTap)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _banner(Color bg, IconData icon, String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm), border: NeoBrutalism.border(width: 2.0)),
    child: Row(children: [Icon(icon, size: 18, color: Colors.black), const SizedBox(width: 8), Expanded(child: Text(text, style: _ts(12.5, FontWeight.w900, Colors.black)))]),
  );

  Widget _btn({required Key key, required String label, required Color bg, required Color fg, required bool enabled, VoidCallback? onTap, bool fullW = false, bool primary = false, bool loading = false}) {
    final textCol = enabled ? fg : const Color(0xFF4B5563);
    final borderCol = enabled ? Colors.black : (primary ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF));
    return Semantics(
      button: true, enabled: enabled, label: label,
      child: Container(
        width: fullW ? double.infinity : null,
        decoration: BoxDecoration(color: enabled ? bg : (primary ? const Color(0xFFE5E7EB) : Colors.white), borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm), border: NeoBrutalism.border(width: 2.0, color: borderCol), boxShadow: enabled ? NeoBrutalism.shadow(yOffset: 2.0) : null),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: key, borderRadius: BorderRadius.circular(10), onTap: (enabled && onTap != null) ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(mainAxisSize: fullW ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (loading) ...[const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black)), const SizedBox(width: 8)],
                  Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(primary ? 13 : 12.5, primary ? FontWeight.w900 : FontWeight.w800, textCol))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, String route, {Object? extra}) => GoRouter.maybeOf(context)?.push(route, extra: extra);
  String _fmtDate(DateTime d) => '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'][d.month - 1]} ${d.year}';
  String _fmtFreq(String raw) => switch (raw.trim().toLowerCase()) { 'monthly' => 'Bulanan', 'weekly' => 'Mingguan', 'yearly' => 'Tahunan', _ => raw.trim().isEmpty ? 'Bulanan' : raw.trim() };
  String _fmtDue(AiBillDraft b) => (b.dueDate != null && b.dueDay != null) ? 'Tgl ${b.dueDay} (${_fmtDate(b.dueDate!)})' : (b.dueDate != null ? _fmtDate(b.dueDate!) : 'Tanggal ${b.dueDay} tiap bulan');
}

class _SecondaryBtn {
  final Key key; final String label; final Color color; final VoidCallback onTap;
  const _SecondaryBtn(this.key, this.label, this.color, this.onTap);
}

class _PlanSpec {
  final IconData icon; final String badge; final String title; final List<(String, String)> metrics;
  final String? note; final Color noteBg; final bool isSubmitting; final bool isConfirmed; final bool isCancelled;
  final String confirmedText; final String cancelledText; final Key confirmKey; final String confirmLabel;
  final VoidCallback? onConfirm; final List<_SecondaryBtn> secondary;
  const _PlanSpec({required this.icon, required this.badge, required this.title, required this.metrics, this.note, this.noteBg = NeoBrutalism.surfaceWarm, required this.isSubmitting, required this.isConfirmed, required this.isCancelled, required this.confirmedText, required this.cancelledText, required this.confirmKey, required this.confirmLabel, required this.onConfirm, required this.secondary});
}
