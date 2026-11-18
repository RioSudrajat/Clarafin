import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_action_card_primitives.dart';

/// Dashed horizontal separator (`- - - - - -`) for Neo-Brutalist paper receipts.
class ReceiptDashedDivider extends StatelessWidget {
  const ReceiptDashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 1,
      child: CustomPaint(painter: _ReceiptDashedLinePainter()),
    );
  }
}

class _ReceiptDashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 1.2;
    const dash = 5.0;
    const gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, 0.5),
        Offset((x + dash).clamp(0.0, size.width), 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact pill badge used inside receipt headers and itemized rows.
class ReceiptPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  const ReceiptPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
        border: NeoBrutalism.border(width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: aiActionTextStyle(
                context,
                11,
                FontWeight.w700,
                foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Itemized receipt line with title + category chips on left & tabular Rp on right.
class ReceiptItemRow extends StatelessWidget {
  final AiTransactionDraftItem item;
  final String Function(String walletId, String fallbackName) resolveWallet;

  const ReceiptItemRow({
    super.key,
    required this.item,
    required this.resolveWallet,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedType = item.type.trim().toLowerCase();
    final badge = _badgeForType(normalizedType);
    final sourceWallet = resolveWallet(item.walletId, item.walletName);
    final targetId = (item.targetWalletId ?? '').trim();
    final transferLabel = normalizedType == 'transfer' && targetId.isNotEmpty
        ? '$sourceWallet -> ${resolveWallet(targetId, '')}'
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: aiActionTextStyle(context, 13, FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ReceiptPill(
                    label: badge.$1,
                    backgroundColor: badge.$2,
                    foregroundColor: badge.$3,
                  ),
                  ReceiptPill(
                    label: item.canonicalCategory,
                    backgroundColor: Colors.white,
                    foregroundColor: NeoBrutalism.dark,
                  ),
                  if (transferLabel.isNotEmpty)
                    ReceiptPill(
                      label: transferLabel,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF374151),
                      icon: Icons.swap_horiz_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(
            CurrencyFormatter.format(item.amount),
            textAlign: TextAlign.right,
            style: aiActionTextStyle(
              context,
              13,
              FontWeight.w900,
              Colors.black,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ],
    );
  }

  (String, Color, Color) _badgeForType(String normalizedType) =>
      switch (normalizedType) {
        'income' => (
          'Pemasukan',
          const Color(0xFFD1FAE5),
          const Color(0xFF065F46),
        ),
        'transfer' => (
          'Transfer',
          const Color(0xFFE0F2FE),
          const Color(0xFF075985),
        ),
        _ => (
          'Pengeluaran',
          const Color(0xFFFFE4E6),
          const Color(0xFF9F1239),
        ),
      };
}

/// Inline warning banner rendered when a wallet's balance is below total outgoing.
class ReceiptBalanceWarningBanner extends StatelessWidget {
  final String walletLabel;
  final double balance;
  final double outgoing;

  const ReceiptBalanceWarningBanner({
    super.key,
    required this.walletLabel,
    required this.balance,
    required this.outgoing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('tx_insufficient_balance_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
        border: NeoBrutalism.border(width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 17,
            color: Color(0xFF9F1239),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Saldo $walletLabel (${CurrencyFormatter.format(balance)}) kurang untuk ${CurrencyFormatter.format(outgoing)}. Ubah saldo atau pilih dompet lain via Edit Rinci.',
              style: aiActionTextStyle(
                context,
                11.5,
                FontWeight.w700,
                const Color(0xFF9F1239),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
