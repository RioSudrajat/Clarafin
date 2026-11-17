import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/institutions/institution_logo_widget.dart';
import '../../../../core/institutions/institution_registry.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../domain/models/ai_chat_models.dart';

/// Interactive draft card shown when a requested wallet does not exist yet.
class AiWalletCreationDraftCard extends StatefulWidget {
  final AiWalletCreationDraft draft;
  final ValueChanged<double>? onCreateWallet;
  final ValueChanged<String>? onUseExistingWallet;
  final String Function(String walletId)? walletLabelResolver;

  const AiWalletCreationDraftCard({
    super.key,
    required this.draft,
    this.onCreateWallet,
    this.onUseExistingWallet,
    this.walletLabelResolver,
  });

  @override
  State<AiWalletCreationDraftCard> createState() =>
      _AiWalletCreationDraftCardState();
}

class _AiWalletCreationDraftCardState extends State<AiWalletCreationDraftCard> {
  late final TextEditingController _balanceController;
  final _formatter = ThousandSeparatorFormatter();

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(text: _formatInitial(widget.draft.initialBalance));
  }

  @override
  void didUpdateWidget(covariant AiWalletCreationDraftCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final switched = oldWidget.draft.institutionId != widget.draft.institutionId ||
        oldWidget.draft.institutionName != widget.draft.institutionName;
    if (switched || (widget.draft.isCreated && oldWidget.draft.initialBalance != widget.draft.initialBalance)) {
      _balanceController.text = _formatInitial(widget.draft.initialBalance);
    }
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  String _formatInitial(double amount) {
    if (amount <= 0) return '';
    return _formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: amount.round().toString()),
    ).text;
  }

  double _parseBalance() {
    final digits = _balanceController.text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? 0.0 : (double.tryParse(digits) ?? 0.0);
  }

  TextStyle _ts(double sz, FontWeight fw, [Color c = NeoBrutalism.dark]) =>
      TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: sz, fontWeight: fw, color: c);

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final isCreated = draft.isCreated;
    final typeLabel = _normalizeType(draft.walletType);
    final balNote = draft.initialBalance > 0 ? ' (Saldo ${CurrencyFormatter.format(draft.initialBalance)})' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: NeoBrutalism.cardDecoration(borderRadius: NeoBrutalism.radiusLg, shadowOffset: 3.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            InstitutionLogoWidget(institutionId: draft.institutionId, walletName: draft.institutionName, walletType: typeLabel, size: 42, borderWidth: 2.0),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(draft.institutionName, style: _ts(15, FontWeight.w800)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill), border: NeoBrutalism.border(width: 1.5)),
                    child: Text(typeLabel, style: _ts(10.5, FontWeight.w800, Colors.black)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  isCreated ? 'Dompet aktif dan siap mencatat transaksi.' : 'Dompet ini belum terdaftar di akunmu.',
                  style: _ts(12, FontWeight.w600, const Color(0xFF4B5563)),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          if (isCreated)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: NeoBrutalism.mint, borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm), border: NeoBrutalism.border(width: 2.0)),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(child: Text('Dompet ${draft.institutionName} dibuat$balNote', style: _ts(12.5, FontWeight.w800, Colors.black))),
              ]),
            )
          else ...[
            Text('Saldo Awal (Opsional)', style: _ts(11.5, FontWeight.w800)),
            const SizedBox(height: 6),
            _buildBalanceField(),
            const SizedBox(height: 12),
          ],
          _tactileBtn(
            key: const Key('wallet_create_button'),
            label: '+ Buat Dompet ${draft.institutionName}',
            bg: isCreated ? const Color(0xFFE5E7EB) : NeoBrutalism.lime,
            fg: isCreated ? const Color(0xFF4B5563) : Colors.black,
            borderCol: isCreated ? const Color(0xFF6B7280) : Colors.black,
            borderW: 2.0, shadowY: isCreated ? 0.0 : 2.0, fullW: true, enabled: !isCreated,
            icon: isCreated ? Icons.check_rounded : null, fontSize: 13, weight: FontWeight.w900,
            onTap: (!isCreated && widget.onCreateWallet != null) ? () => widget.onCreateWallet!(_parseBalance()) : null,
          ),
          if (!isCreated && draft.existingWalletIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Atau pakai dompet yang ada:', style: _ts(11.5, FontWeight.w700, const Color(0xFF4B5563))),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: draft.existingWalletIds.map((id) {
              final label = widget.walletLabelResolver?.call(id) ?? _fallbackWalletLabel(id);
              return _tactileBtn(
                key: Key('wallet_existing_chip_$id'),
                label: label,
                bg: NeoBrutalism.surfaceWarm,
                fg: Colors.black,
                borderCol: Colors.black,
                borderW: 1.5,
                shadowY: 1.5,
                fullW: false,
                enabled: widget.onUseExistingWallet != null,
                fontSize: 12.5,
                weight: FontWeight.w800,
                onTap: widget.onUseExistingWallet == null ? null : () => widget.onUseExistingWallet!(id),
              );
            }).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceField() => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm), border: NeoBrutalism.border(width: 2.0), boxShadow: NeoBrutalism.shadow(yOffset: 2.0)),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.horizontal(left: Radius.circular(10)), border: Border(right: BorderSide(color: Colors.black, width: 2.0))),
        child: Text('Rp', style: _ts(13.5, FontWeight.w900, Colors.black)),
      ),
      Expanded(
        child: TextField(
          controller: _balanceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, _formatter],
          style: _ts(14, FontWeight.w800),
          decoration: InputDecoration(
            hintText: '0', hintStyle: _ts(14, FontWeight.w700, const Color(0xFF6B7280)),
            border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    ]),
  );

  Widget _tactileBtn({
    required Key key, required String label, required Color bg, required Color fg, required Color borderCol,
    required double borderW, required double shadowY, required bool fullW, required bool enabled,
    required double fontSize, required FontWeight weight, VoidCallback? onTap, IconData? icon,
  }) => Semantics(
    button: true, enabled: enabled, label: label,
    child: Container(
      width: fullW ? double.infinity : null,
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
        border: NeoBrutalism.border(width: borderW, color: borderCol),
        boxShadow: shadowY > 0 ? NeoBrutalism.shadow(yOffset: shadowY) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key, borderRadius: BorderRadius.circular(10), onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(mainAxisSize: fullW ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
                Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(fontSize, weight, fg))),
              ]),
            ),
          ),
        ),
      ),
    ),
  );

  String _normalizeType(String raw) => switch (raw.trim().toLowerCase()) {
    'bank' => 'Bank', 'e-wallet' || 'ewallet' || 'e_wallet' => 'E-Wallet', 'cash' || 'tunai' => 'Cash',
    'mutual_fund' || 'mutual fund' => 'Mutual Fund', 'stock' => 'Stock', 'crypto' || 'cex' || 'dex' => 'Crypto',
    _ => raw.trim().isEmpty ? 'Dompet' : raw.trim(),
  };

  String _fallbackWalletLabel(String walletId) {
    final clean = walletId.replaceFirst(RegExp(r'^(wallet[-_]|w[-_])', caseSensitive: false), '').trim();
    if (clean.isEmpty) return walletId;
    final inst = InstitutionRegistry.findById(clean);
    if (inst != null) return inst.shortName;
    return clean.length <= 4 ? clean.toUpperCase() : '${clean[0].toUpperCase()}${clean.substring(1)}';
  }
}
