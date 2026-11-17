import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/ai_chat_models.dart';

/// Neo-Brutalist confirmation card for 1..N proposed transaction drafts.
class AiTransactionDraftCard extends StatelessWidget {
  final AiTransactionDraftGroup draft;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onEditDetail;

  const AiTransactionDraftCard({
    super.key,
    required this.draft,
    this.onConfirm,
    this.onCancel,
    this.onEditDetail,
  });

  TextStyle _ts(double sz, FontWeight fw, [Color c = NeoBrutalism.dark]) =>
      TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: sz, fontWeight: fw, color: c);

  @override
  Widget build(BuildContext context) {
    final isFinalized = draft.isConfirmed || draft.isCancelled;
    final isLocked = draft.isSubmitting || isFinalized || draft.items.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: NeoBrutalism.cardDecoration(borderRadius: NeoBrutalism.radiusLg, shadowOffset: 3.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.black),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                draft.items.length > 1 ? 'Draf Transaksi (${draft.items.length} item)' : 'Draf Transaksi',
                style: _ts(13.5, FontWeight.w900),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (draft.items.isEmpty)
            _box(NeoBrutalism.surfaceWarm, 1.5, Text('Belum ada item transaksi pada draf ini.', style: _ts(12, FontWeight.w600, const Color(0xFF4B5563))))
          else
            for (var i = 0; i < draft.items.length; i++)
              Padding(padding: EdgeInsets.only(bottom: i == draft.items.length - 1 ? 0 : 8), child: _buildItemRow(draft.items[i])),
          const SizedBox(height: 12),
          if (draft.isConfirmed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _banner(NeoBrutalism.mint, Icons.check_circle_rounded, draft.items.length > 1 ? 'Tercatat (${draft.items.length} transaksi)' : 'Tercatat'),
            )
          else if (draft.isCancelled)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _banner(NeoBrutalism.coral, Icons.cancel_rounded, 'Dibatalkan'),
            ),
          _tactileButton(
            key: const Key('tx_confirm_btn'), label: 'Konfirmasi & Catat', bgColor: NeoBrutalism.lime, textColor: Colors.black,
            minHeight: 44, isPrimary: true, enabled: !isLocked, isLoading: draft.isSubmitting, onTap: onConfirm,
          ),
          if (!isFinalized) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tactileButton(key: const Key('tx_cancel_btn'), label: 'Batal', bgColor: Colors.white, textColor: const Color(0xFF9F1239), minHeight: 44, enabled: !draft.isSubmitting, onTap: onCancel)),
              const SizedBox(width: 8),
              Expanded(child: _tactileButton(key: const Key('tx_edit_btn'), label: 'Edit Rinci', icon: Icons.edit_outlined, bgColor: Colors.white, textColor: Colors.black, minHeight: 44, enabled: !draft.isSubmitting, onTap: () => _handleEditDetail(context))),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _box(Color bg, double borderW, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm), border: NeoBrutalism.border(width: borderW)),
    child: child,
  );

  Widget _buildItemRow(AiTransactionDraftItem item) {
    final badge = _badgeForType(item.type);
    final baseWallet = item.walletName.isNotEmpty ? item.walletName : item.walletId;
    final walletLabel = item.type == 'transfer' && (item.targetWalletId ?? '').isNotEmpty ? '$baseWallet -> ${item.targetWalletId}' : baseWallet;
    return _box(
      NeoBrutalism.surfaceWarm,
      1.5,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: _ts(13.5, FontWeight.w800))),
            const SizedBox(width: 8),
            Text(CurrencyFormatter.format(item.amount), style: _ts(13.5, FontWeight.w900, Colors.black)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _pill(badge.$1, badge.$2, badge.$3),
            _pill(item.canonicalCategory, Colors.white, NeoBrutalism.dark),
            if (walletLabel.isNotEmpty) _pill(walletLabel, Colors.white, const Color(0xFF374151), icon: Icons.account_balance_wallet_outlined),
          ]),
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg, {IconData? icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill), border: NeoBrutalism.border(width: 1.2)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
      Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(11, FontWeight.w700, fg))),
    ]),
  );

  Widget _banner(Color bg, IconData icon, String label) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm), border: NeoBrutalism.border(width: 2.0)),
    child: Row(children: [Icon(icon, size: 18, color: Colors.black), const SizedBox(width: 8), Expanded(child: Text(label, style: _ts(12.5, FontWeight.w900, Colors.black)))]),
  );

  Widget _tactileButton({
    required Key key,
    required String label,
    required Color bgColor,
    required Color textColor,
    required double minHeight,
    required bool enabled,
    VoidCallback? onTap,
    IconData? icon,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    final fg = enabled ? textColor : const Color(0xFF4B5563);
    final borderCol = enabled ? Colors.black : (isPrimary ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF));
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? bgColor : (isPrimary ? const Color(0xFFE5E7EB) : Colors.white),
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
          border: NeoBrutalism.border(width: 2.0, color: borderCol),
          boxShadow: enabled ? NeoBrutalism.shadow(yOffset: 2.0) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(10),
            onTap: (enabled && onTap != null) ? onTap : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight, minWidth: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (isLoading) ...[const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black)), const SizedBox(width: 8)]
                  else if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 5)],
                  Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(isPrimary ? 13 : 12.5, isPrimary ? FontWeight.w900 : FontWeight.w800, fg))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleEditDetail(BuildContext context) {
    if (onEditDetail != null) return onEditDetail!();
    GoRouter.maybeOf(context)?.push('/draft/review', extra: {
      'prefillItems': draft.items.map((item) => {
        'title': item.title, 'amount': item.amount, 'isExpense': item.type == 'expense', 'type': item.type,
        'category': item.canonicalCategory, 'walletId': item.walletId, 'walletName': item.walletName,
        if (item.targetWalletId != null) 'targetWalletId': item.targetWalletId,
        'occurredAt': item.occurredAt.toIso8601String(),
      }).toList(),
      'clientMutationId': draft.clientMutationId,
    });
  }

  (String, Color, Color) _badgeForType(String type) => switch (type.trim().toLowerCase()) {
    'income' => ('Pemasukan', const Color(0xFFD1FAE5), const Color(0xFF065F46)),
    'transfer' => ('Transfer', const Color(0xFFE0F2FE), const Color(0xFF075985)),
    _ => ('Pengeluaran', const Color(0xFFFFE4E6), const Color(0xFF9F1239)),
  };
}
