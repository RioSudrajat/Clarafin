import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../data/local_ai_nlp_helpers.dart';
import 'ai_action_card_primitives.dart';

/// Draft data extracted by Voice AI or OCR Scan modals.
class QuickActionDraftData {
  final String title;
  final double amount;
  final String category;
  final String walletId;
  final String walletName;
  final String type;

  const QuickActionDraftData({
    required this.title,
    required this.amount,
    required this.category,
    required this.walletId,
    required this.walletName,
    required this.type,
  });
}

/// Resolves a wallet from [hint] without silently failing on empty lists.
({String id, String name}) resolveQuickActionWallet(
  String hint,
  List<WalletModel> wallets,
) {
  final matched = LocalAiNlpHelpers.matchWalletStrict(hint, wallets);
  if (matched != null) return (id: matched.id, name: matched.name);
  if (wallets.isNotEmpty) return (id: wallets.first.id, name: wallets.first.name);
  return const (id: 'w1', name: 'BCA Utama');
}

/// Shared Neo-Brutalist review card for Voice AI and OCR Scan quick drafts.
class QuickActionDraftReviewCard extends ConsumerWidget {
  final IconData headerIcon;
  final String headerTitle;
  final QuickActionDraftData draft;
  final bool isConfirmed;
  final bool isCancelled;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const QuickActionDraftReviewCard({
    super.key,
    required this.headerIcon,
    required this.headerTitle,
    required this.draft,
    required this.isConfirmed,
    required this.isCancelled,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isConfirmed) {
      return const AiActionStatusBanner.mint(
        message: 'Sukses menyimpan transaksi!',
      );
    }
    if (isCancelled) {
      return const AiActionStatusBanner.coral(
        message: 'Draf transaksi dibatalkan',
      );
    }

    final currency = ref.watch(userProfileProvider.select((p) => p.currency));
    return AiActionCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(headerIcon, color: NeoBrutalism.dark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headerTitle,
                  style: aiActionTextStyle(context, 12, FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Detail', value: draft.title),
          _DetailRow(
            label: 'Nominal',
            value: CurrencyFormatter.format(draft.amount, currencyCode: currency),
          ),
          _DetailRow(label: 'Kategori', value: draft.category),
          _DetailRow(label: 'Metode', value: draft.walletName),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AiActionTactileButton(
                  label: 'Hapus',
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFF9F1239),
                  fullWidth: true,
                  onTap: onCancel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AiActionTactileButton(
                  label: 'Konfirmasi',
                  backgroundColor: NeoBrutalism.lime,
                  textColor: Colors.black,
                  isPrimary: true,
                  fullWidth: true,
                  onTap: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: aiActionTextStyle(
              context,
              12,
              FontWeight.w600,
              const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: aiActionTextStyle(context, 12, FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
