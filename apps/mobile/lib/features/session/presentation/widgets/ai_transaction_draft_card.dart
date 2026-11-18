import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_action_card_primitives.dart';
import 'ai_transaction_draft_receipt_parts.dart';

/// Neo-Brutalist paper receipt (`Struk Transaksi`) card for 1..N proposed drafts.
class AiTransactionDraftCard extends StatelessWidget {
  final AiTransactionDraftGroup draft;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onEditDetail;
  final String Function(String walletId)? walletLabelResolver;
  final double? Function(String walletId)? walletBalanceResolver;

  const AiTransactionDraftCard({
    super.key,
    required this.draft,
    this.onConfirm,
    this.onCancel,
    this.onEditDetail,
    this.walletLabelResolver,
    this.walletBalanceResolver,
  });

  @override
  Widget build(BuildContext context) {
    final isFinalized = draft.isConfirmed || draft.isCancelled;
    final isLocked = draft.isSubmitting || isFinalized || draft.items.isEmpty;
    final headerWallet = draft.items.isEmpty
        ? ''
        : _resolveWallet(draft.items.first.walletId, draft.items.first.walletName);
    final totalAmount = draft.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.amount.isFinite && item.amount > 0 ? item.amount : 0.0),
    );
    final balanceWarn = isFinalized ? null : _findInsufficientBalance();

    return AiActionCardShell(
      backgroundColor: const Color(0xFFFFFDF7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, headerWallet),
          const SizedBox(height: 10),
          const ReceiptDashedDivider(),
          const SizedBox(height: 10),
          if (draft.items.isEmpty)
            _emptyBox(context)
          else ...[
            for (var i = 0; i < draft.items.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == draft.items.length - 1 ? 0 : 10),
                child: ReceiptItemRow(item: draft.items[i], resolveWallet: _resolveWallet),
              ),
            const SizedBox(height: 10),
            const ReceiptDashedDivider(),
            const SizedBox(height: 10),
            _buildTotalRow(context, totalAmount),
          ],
          if (balanceWarn != null) ...[
            const SizedBox(height: 10),
            ReceiptBalanceWarningBanner(
              walletLabel: balanceWarn.label,
              balance: balanceWarn.balance,
              outgoing: balanceWarn.outgoing,
            ),
          ],
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

  Widget _buildHeader(BuildContext context, String headerWallet) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.black),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'STRUK TRANSAKSI',
                  style: aiActionTextStyle(context, 12.5, FontWeight.w900),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (headerWallet.isNotEmpty)
                ReceiptPill(
                  label: headerWallet.toUpperCase(),
                  backgroundColor: NeoBrutalism.lime,
                  foregroundColor: Colors.black,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              if (draft.items.isNotEmpty)
                ReceiptPill(
                  label: '${draft.items.length} item',
                  backgroundColor: NeoBrutalism.surfaceWarm,
                  foregroundColor: NeoBrutalism.dark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: NeoBrutalism.surfaceWarm,
      borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
      border: NeoBrutalism.border(width: 1.5),
    ),
    child: Text('Belum ada item transaksi pada draf ini.', style: aiActionTextStyle(context, 12, FontWeight.w600, const Color(0xFF4B5563))),
  );

  Widget _buildTotalRow(BuildContext context, double totalAmount) => SizedBox(
    width: double.infinity,
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text('TOTAL', style: aiActionTextStyle(context, 13, FontWeight.w900, Colors.black)),
        Text(
          CurrencyFormatter.format(totalAmount),
          style: aiActionTextStyle(context, 15, FontWeight.w900, Colors.black).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    ),
  );

  ({String label, double balance, double outgoing})? _findInsufficientBalance() {
    final resolver = walletBalanceResolver;
    if (resolver == null) return null;
    final outgoingByKey = <String, ({double total, String label})>{};
    for (final item in draft.items) {
      final type = item.type.trim().toLowerCase();
      if (type != 'expense' && type != 'transfer') continue;
      final key = item.walletId.trim().isNotEmpty ? item.walletId.trim() : item.walletName.trim();
      if (key.isEmpty) continue;
      final prev = outgoingByKey[key];
      outgoingByKey[key] = (total: (prev?.total ?? 0.0) + item.amount, label: _resolveWallet(item.walletId, item.walletName));
    }
    for (final entry in outgoingByKey.entries) {
      final balance = resolver(entry.key);
      if (balance != null && balance < entry.value.total) {
        return (label: entry.value.label, balance: balance, outgoing: entry.value.total);
      }
    }
    return null;
  }

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
    GoRouter.maybeOf(context)?.push('/draft/review', extra: {
      'prefillItems': draft.items.map((item) => {
        'title': item.title, 'amount': item.amount, 'isExpense': item.type.trim().toLowerCase() == 'expense',
        'type': item.type.trim().toLowerCase(), 'category': item.canonicalCategory, 'walletId': item.walletId,
        'walletName': item.walletName, if (item.targetWalletId != null) 'targetWalletId': item.targetWalletId,
        'occurredAt': item.occurredAt.toIso8601String(),
      }).toList(),
      'clientMutationId': draft.clientMutationId,
    });
  }
}
