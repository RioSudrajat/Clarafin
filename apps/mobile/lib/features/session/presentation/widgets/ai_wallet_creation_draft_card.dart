import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/institutions/institution_logo_widget.dart';
import '../../../../core/institutions/institution_registry.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_action_card_primitives.dart';

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
  State<AiWalletCreationDraftCard> createState() => _AiWalletCreationDraftCardState();
}

class _AiWalletCreationDraftCardState extends State<AiWalletCreationDraftCard> {
  late final TextEditingController _balanceController;
  late final FocusNode _balanceFocusNode;
  final _formatter = ThousandSeparatorFormatter();
  bool _isBalanceFocused = false;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(text: _formatInitial(widget.draft.initialBalance));
    _balanceFocusNode = FocusNode()..addListener(_handleBalanceFocus);
  }

  void _handleBalanceFocus() {
    if (!mounted || _isBalanceFocused == _balanceFocusNode.hasFocus) return;
    setState(() => _isBalanceFocused = _balanceFocusNode.hasFocus);
  }

  @override
  void didUpdateWidget(covariant AiWalletCreationDraftCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final switched = oldWidget.draft.institutionId != widget.draft.institutionId ||
        oldWidget.draft.institutionName != widget.draft.institutionName;
    final resetCreated = oldWidget.draft.isCreated && !widget.draft.isCreated;
    final updatedOnCreate = widget.draft.isCreated && oldWidget.draft.initialBalance != widget.draft.initialBalance;
    if (switched || resetCreated || updatedOnCreate) {
      _balanceController.text = _formatInitial(widget.draft.initialBalance);
    }
  }

  @override
  void dispose() {
    _balanceFocusNode
      ..removeListener(_handleBalanceFocus)
      ..dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String _formatInitial(double amount) => amount <= 0
      ? ''
      : _formatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: amount.round().toString())).text;

  double _parseBalance() {
    final digits = _balanceController.text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? 0.0 : (double.tryParse(digits) ?? 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final isCreated = draft.isCreated;
    final typeLabel = _normalizeType(draft.walletType);
    final balNote = draft.initialBalance > 0 ? ' (Saldo ${CurrencyFormatter.format(draft.initialBalance)})' : '';

    return AiActionCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            InstitutionLogoWidget(
              institutionId: draft.institutionId,
              walletName: draft.institutionName,
              walletType: typeLabel,
              size: 42,
              borderWidth: 2.0,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(draft.institutionName, style: aiActionTextStyle(context, 15, FontWeight.w800)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                          border: NeoBrutalism.border(width: 1.5),
                        ),
                        child: Text(typeLabel, style: aiActionTextStyle(context, 10.5, FontWeight.w800, Colors.black)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCreated ? 'Dompet aktif dan siap mencatat transaksi.' : 'Dompet ini belum terdaftar di akunmu.',
                    style: aiActionTextStyle(context, 12, FontWeight.w600, const Color(0xFF4B5563)),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          if (isCreated) ...[
            AiActionStatusBanner.mint(message: 'Dompet ${draft.institutionName} dibuat$balNote'),
            const SizedBox(height: 12),
          ] else ...[
            Text('Saldo Awal (Opsional)', style: aiActionTextStyle(context, 11.5, FontWeight.w800)),
            const SizedBox(height: 6),
            _buildBalanceField(context),
            const SizedBox(height: 12),
          ],
          AiActionTactileButton(
            buttonKey: const Key('wallet_create_button'),
            label: '+ Buat Dompet ${draft.institutionName}',
            backgroundColor: NeoBrutalism.lime, textColor: Colors.black,
            isPrimary: true, fullWidth: true, enabled: !isCreated,
            icon: isCreated ? Icons.check_rounded : null,
            onTap: widget.onCreateWallet == null ? null : () => widget.onCreateWallet!(_parseBalance()),
          ),
          if (!isCreated && draft.existingWalletIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Atau pakai dompet yang ada:', style: aiActionTextStyle(context, 11.5, FontWeight.w700, const Color(0xFF4B5563))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: draft.existingWalletIds.map((id) {
                final label = widget.walletLabelResolver?.call(id) ?? _fallbackWalletLabel(id);
                return AiActionTactileButton(
                  buttonKey: Key('wallet_existing_chip_$id'),
                  label: label, backgroundColor: NeoBrutalism.surfaceWarm, textColor: Colors.black,
                  borderWidth: 1.5, shadowOffset: 1.5, enabled: widget.onUseExistingWallet != null,
                  onTap: widget.onUseExistingWallet == null ? null : () => widget.onUseExistingWallet!(id),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceField(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
      ),
      foregroundDecoration: _isBalanceFocused
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
              border: Border.all(color: NeoBrutalism.teal, width: 2.5),
            )
          : null,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                border: Border(right: BorderSide(color: Colors.black, width: 2.0)),
              ),
              child: Text('Rp', style: aiActionTextStyle(context, 13.5, FontWeight.w900, Colors.black)),
            ),
            Expanded(
              child: Semantics(
                textField: true,
                label: 'Saldo Awal (Opsional)',
                child: TextField(
                  controller: _balanceController,
                  focusNode: _balanceFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, _formatter],
                  style: aiActionTextStyle(context, 14, FontWeight.w800),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: aiActionTextStyle(context, 14, FontWeight.w700, const Color(0xFF6B7280)),
                    filled: false,
                    border: InputBorder.none, enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none, errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none, isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeType(String raw) => switch (raw.trim().toLowerCase()) {
    'bank' => 'Bank',
    'e-wallet' || 'ewallet' || 'e_wallet' => 'E-Wallet',
    'cash' || 'tunai' => 'Cash',
    'mutual_fund' || 'mutual fund' => 'Mutual Fund',
    'stock' => 'Stock',
    'crypto' || 'cex' || 'dex' => 'Crypto',
    'web3_wallet' || 'web3 wallet' || 'web3' => 'Web3 Wallet',
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
