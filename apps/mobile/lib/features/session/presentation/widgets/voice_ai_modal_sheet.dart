import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/ai_quota_provider.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/ai_category_normalizer.dart';
import 'ai_action_card_primitives.dart';
import 'quick_action_draft_review.dart';

/// Voice AI quick transaction modal with timer lifecycle cleanup.
class VoiceAiModalSheet extends ConsumerStatefulWidget {
  const VoiceAiModalSheet({super.key});

  @override
  ConsumerState<VoiceAiModalSheet> createState() => _VoiceAiModalSheetState();
}

class _VoiceAiModalSheetState extends ConsumerState<VoiceAiModalSheet> {
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isConfirmed = false;
  bool _isCancelled = false;
  String _speechText = 'Tekan mic dan ucapkan transaksi kamu';
  QuickActionDraftData? _voiceDraft;

  Timer? _listenTimer;
  Timer? _processTimer;
  Timer? _closeTimer;

  @override
  void dispose() {
    _listenTimer?.cancel();
    _processTimer?.cancel();
    _closeTimer?.cancel();
    super.dispose();
  }

  void _startListening() {
    _listenTimer?.cancel();
    _processTimer?.cancel();
    setState(() {
      _isListening = true;
      _speechText = 'Mendengarkan... Ucapkan nominal dan kategori';
      _voiceDraft = null;
      _isConfirmed = false;
      _isCancelled = false;
    });

    _listenTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _isProcessing = true;
        _speechText = '"Makan siang Padang 35 ribu"';
      });

      _processTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        final wallets = ref.read(walletsProvider);
        final resolved = resolveQuickActionWallet('Dompet Tunai Cash', wallets);
        final category = AiCategoryNormalizer.normalize(
          'Makanan',
          contextHint: 'Makan Siang Padang',
        );
        setState(() {
          _isProcessing = false;
          _voiceDraft = QuickActionDraftData(
            title: 'Makan Siang Padang',
            category: category,
            amount: 35000,
            walletId: resolved.id,
            walletName: resolved.name,
            type: 'expense',
          );
        });
      });
    });
  }

  void _confirmDraft() {
    final draft = _voiceDraft;
    if (draft == null || _isConfirmed) return;
    final tx = TransactionModel(
      id: 'tx_voice_${DateTime.now().millisecondsSinceEpoch}',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Voice AI Action',
            style: aiActionTextStyle(context, 18, FontWeight.w900),
          ),
          const SizedBox(height: 18),
          if (_voiceDraft != null)
            QuickActionDraftReviewCard(
              headerIcon: Icons.graphic_eq_rounded,
              headerTitle: 'TINJAU DRAF SUARA AI',
              draft: _voiceDraft!,
              isConfirmed: _isConfirmed,
              isCancelled: _isCancelled,
              onCancel: _cancelDraft,
              onConfirm: _confirmDraft,
            )
          else ...[
            _PulsingWaveform(isListening: _isListening),
            const SizedBox(height: 20),
            Text(
              _speechText,
              textAlign: TextAlign.center,
              style: aiActionTextStyle(
                context,
                14,
                FontWeight.w800,
                _isListening ? NeoBrutalism.dark : const Color(0xFF374151),
              ),
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 12),
              const CircularProgressIndicator(color: Colors.black),
            ],
            const SizedBox(height: 20),
            AiActionTactileButton(
              label: 'Mulai Perekaman',
              icon: Icons.mic_rounded,
              backgroundColor: NeoBrutalism.lime,
              textColor: Colors.black,
              isPrimary: true,
              fullWidth: true,
              minHeight: 48,
              enabled: !_isListening && !_isProcessing,
              onTap: (_isListening || _isProcessing) ? null : _startListening,
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingWaveform extends StatefulWidget {
  final bool isListening;
  const _PulsingWaveform({required this.isListening});

  @override
  State<_PulsingWaveform> createState() => _PulsingWaveformState();
}

class _PulsingWaveformState extends State<_PulsingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _PulsingWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final disableAnim = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.isListening && !disableAnim) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final scale = 1.0 + (widget.isListening ? 0.25 * _ctrl.value : 0.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening)
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NeoBrutalism.lime.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                transform: Matrix4.diagonal3Values(scale, scale, 1.0),
              ),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NeoBrutalism.lime,
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.black, size: 38),
            ),
          ],
        );
      },
    );
  }
}
