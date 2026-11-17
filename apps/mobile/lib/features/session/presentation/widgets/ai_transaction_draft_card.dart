import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_action_card_primitives.dart';

/// Neo-Brutalist confirmation card for 1..N proposed transaction drafts.
class AiTransactionDraftCard extends StatelessWidget {
  final AiTransactionDraftGroup draft;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onEditDetail;
  final String Function(String walletId)? walletLabelResolver;

  const AiTransactionDraftCard({
    super.key,
    required this.draft,
    this.onConfirm,
    this.onCancel,
    this.onEditDetail,
    this.walletLabelResolver,
  });

  @override
  Widget build(BuildContext context) {
    final isFinalized = draft.isConfirmed || draft.isCancelled;
    final isLocked = draft.isSubmitting || isFinalized || draft.items.isEmpty;

    return AiActionCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.black),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  draft.items.length > 1 ? 'Draf Transaksi (${draft.items.length} item)' : 'Draf Transaksi',
                  style: aiActionTextStyle(context, 13.5, FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (draft.items.isEmpty)
            _box(Text('Belum ada item transaksi pada draf ini.', style: aiActionTextStyle(context, 12, FontWeight.w600, const Color(0xFF4B5563))))
          else
            for (var i = 0; i < draft.items.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == draft.items.length - 1 ? 0 : 8),
                child: _buildItemRow(context, draft.items[i]),
              ),
          const SizedBox(height: 12),
          if (draft.isConfirmed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AiActionStatusBanner.mint(
                message: draft.items.length > 1 ? 'Tercatat (${draft.items.length} transaksi)' : 'Tercatat',
              ),
            )
          else if (draft.isCancelled)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: AiActionStatusBanner.coral(message: 'Dibatalkan'),
            ),
          AiActionTactileButton(
            buttonKey: const Key('tx_confirm_btn'),
            label: 'Konfirmasi & Catat',
            backgroundColor: NeoBrutalism.lime,
            textColor: Colors.black,
            isPrimary: true,
            fullWidth: true,
            enabled: !isLocked,
            isLoading: draft.isSubmitting,
            onTap: onConfirm,
          ),
          if (!isFinalized) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AiActionTactileButton(
                    buttonKey: const Key('tx_cancel_btn'),
                    label: 'Batal',
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFF9F1239),
                    fullWidth: true,
                    enabled: !draft.isSubmitting,
                    onTap: onCancel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AiActionTactileButton(
                    buttonKey: const Key('tx_edit_btn'),
                    label: 'Edit Rinci',
                    icon: Icons.edit_outlined,
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                    fullWidth: true,
                    enabled: !draft.isSubmitting && draft.items.isNotEmpty,
                    onTap: () => _handleEditDetail(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _box(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: NeoBrutalism.surfaceWarm,
      borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
      border: NeoBrutalism.border(width: 1.5),
    ),
    child: child,
  );

  Widget _buildItemRow(BuildContext context, AiTransactionDraftItem item) {
    final normalizedType = item.type.trim().toLowerCase();
    final badge = _badgeForType(normalizedType);
    final sourceWallet = _resolveWallet(item.walletId, item.walletName);
    final targetId = (item.targetWalletId ?? '').trim();
    final walletLabel = normalizedType == 'transfer' && targetId.isNotEmpty
        ? '$sourceWallet -> ${_resolveWallet(targetId, '')}'
        : sourceWallet;

    return _box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: aiActionTextStyle(context, 13.5, FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  CurrencyFormatter.format(item.amount),
                  textAlign: TextAlign.right,
                  style: aiActionTextStyle(context, 13.5, FontWeight.w900, Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _pill(context, badge.$1, badge.$2, badge.$3),
              _pill(context, item.canonicalCategory, Colors.white, NeoBrutalism.dark),
              if (walletLabel.isNotEmpty)
                _pill(
                  context,
                  walletLabel,
                  Colors.white,
                  const Color(0xFF374151),
                  icon: Icons.account_balance_wallet_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String label, Color bg, Color fg, {IconData? icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
      border: NeoBrutalism.border(width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: aiActionTextStyle(context, 11, FontWeight.w700, fg),
          ),
        ),
      ],
    ),
  );

  String _resolveWallet(String walletId, String fallbackName) {
    final trimmedId = walletId.trim();
    if (trimmedId.isNotEmpty && walletLabelResolver != null) {
      final resolved = walletLabelResolver!(trimmedId).trim();
      if (resolved.isNotEmpty) return resolved;
    }
    return fallbackName.trim().isNotEmpty ? fallbackName.trim() : trimmedId;
  }

  void _handleEditDetail(BuildContext context) {
    if (draft.items.isEmpty) return;
    if (onEditDetail != null) return onEditDetail!();
    GoRouter.maybeOf(context)?.push(
      '/draft/review',
      extra: {
        'prefillItems': draft.items.map((item) => {
          'title': item.title,
          'amount': item.amount,
          'isExpense': item.type.trim().toLowerCase() == 'expense',
          'type': item.type.trim().toLowerCase(),
          'category': item.canonicalCategory,
          'walletId': item.walletId,
          'walletName': item.walletName,
          if (item.targetWalletId != null) 'targetWalletId': item.targetWalletId,
          'occurredAt': item.occurredAt.toIso8601String(),
        }).toList(),
        'clientMutationId': draft.clientMutationId,
      },
    );
  }

  (String, Color, Color) _badgeForType(String normalizedType) => switch (normalizedType) {
    'income' => ('Pemasukan', const Color(0xFFD1FAE5), const Color(0xFF065F46)),
    'transfer' => ('Transfer', const Color(0xFFE0F2FE), const Color(0xFF075985)),
    _ => ('Pengeluaran', const Color(0xFFFFE4E6), const Color(0xFF9F1239)),
  };
}
