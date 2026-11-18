import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/ai_quota_provider.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/ai_category_normalizer.dart';
import 'ai_action_card_primitives.dart';
import 'ocr_viewfinder_box.dart';
import 'quick_action_draft_review.dart';

/// OCR receipt scan quick transaction modal with timer cleanup.
class OcrScanModalSheet extends ConsumerStatefulWidget {
  const OcrScanModalSheet({super.key});

  @override
  ConsumerState<OcrScanModalSheet> createState() => _OcrScanModalSheetState();
}

class _OcrScanModalSheetState extends ConsumerState<OcrScanModalSheet> {
  bool _isScanning = false;
  bool _scanningOcr = false;
  bool _isConfirmed = false;
  bool _isCancelled = false;
  QuickActionDraftData? _ocrDraft;

  Timer? _laserTimer;
  Timer? _ocrTimer;
  Timer? _closeTimer;

  @override
  void dispose() {
    _laserTimer?.cancel();
    _ocrTimer?.cancel();
    _closeTimer?.cancel();
    super.dispose();
  }

  void _capturePhoto() {
    _laserTimer?.cancel();
    _ocrTimer?.cancel();
    setState(() {
      _isScanning = true;
      _ocrDraft = null;
      _isConfirmed = false;
      _isCancelled = false;
    });

    _laserTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanningOcr = true;
      });

      _ocrTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        final wallets = ref.read(walletsProvider);
        final resolved = resolveQuickActionWallet('GoPay', wallets);
        final category = AiCategoryNormalizer.normalize(
          'Alfamart Belanja',
          contextHint: 'Alfamart Belanja',
        );
        setState(() {
          _scanningOcr = false;
          _ocrDraft = QuickActionDraftData(
            title: 'Alfamart Belanja',
            category: category,
            amount: 124500,
            walletId: resolved.id,
            walletName: resolved.name,
            type: 'expense',
          );
        });
      });
    });
  }

  void _confirmDraft() {
    final draft = _ocrDraft;
    if (draft == null || _isConfirmed) return;
    final tx = TransactionModel(
      id: 'tx_scan_${DateTime.now().millisecondsSinceEpoch}',
      title: draft.title,
      category: draft.category,
      amount: draft.amount,
      date: DateTime.now(),
      type: draft.type,
      walletId: draft.walletId,
    );
    ref.read(transactionsProvider.notifier).addTransaction(tx);
    ref.read(aiQuotaProvider.notifier).useQuota();
    setState(() => _isConfirmed = true);
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _cancelDraft() {
    setState(() => _isCancelled = true);
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan Struk / Nota (OCR)',
              style: aiActionTextStyle(context, 18, FontWeight.w900),
            ),
            const SizedBox(height: 16),
            if (_ocrDraft != null)
              Expanded(
                child: SingleChildScrollView(
                  child: QuickActionDraftReviewCard(
                    headerIcon: Icons.receipt_long_rounded,
                    headerTitle: 'TINJAU HASIL SCAN OCR',
                    draft: _ocrDraft!,
                    isConfirmed: _isConfirmed,
                    isCancelled: _isCancelled,
                    onCancel: _cancelDraft,
                    onConfirm: _confirmDraft,
                  ),
                ),
              )
            else ...[
              Expanded(
                child: OcrViewfinderBox(
                  isScanning: _isScanning,
                  scanningOcr: _scanningOcr,
                ),
              ),
              const SizedBox(height: 18),
              AiActionTactileButton(
                label: 'Jepret Struk Belanjaan',
                icon: Icons.camera_alt_rounded,
                backgroundColor: NeoBrutalism.lime,
                textColor: Colors.black,
                isPrimary: true,
                fullWidth: true,
                minHeight: 48,
                enabled: !_isScanning && !_scanningOcr,
                onTap: (_isScanning || _scanningOcr) ? null : _capturePhoto,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
