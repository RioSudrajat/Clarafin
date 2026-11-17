import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/ai_category_normalizer.dart';
import '../widgets/ai_draft_review_chrome.dart';
import '../widgets/ai_draft_review_form_card.dart';

class AiDraftReviewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extra;
  final List<Map<String, dynamic>>? prefillItems;

  const AiDraftReviewScreen({
    super.key,
    this.extra,
    this.prefillItems,
  });

  @override
  ConsumerState<AiDraftReviewScreen> createState() => _AiDraftReviewScreenState();
}

class _AiDraftReviewScreenState extends ConsumerState<AiDraftReviewScreen> {
  final List<EditableDraftItem> _drafts = [];
  int _activeIndex = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _drafts.addAll(EditableDraftItem.fromPrefillList(_extractPrefillItems()));
  }

  List<Map<String, dynamic>> _extractPrefillItems() {
    if (widget.prefillItems != null && widget.prefillItems!.isNotEmpty) {
      return widget.prefillItems!;
    }
    final directExtra = widget.extra ?? _tryReadRouteExtra();
    final list = directExtra?['prefillItems'];
    if (list is List) {
      return list.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  Map<String, dynamic>? _tryReadRouteExtra() {
    try {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map<String, dynamic>) return extra;
    } catch (_) {
      // Screen can be mounted directly in tests without GoRouter.
    }
    return null;
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _confirmAndSave() {
    final wallets = ref.read(walletsProvider);
    final parsedAmounts = <double>[];
    for (var i = 0; i < _drafts.length; i++) {
      final digits = _drafts[i].amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.tryParse(digits) ?? 0.0;
      if (amount <= 0) {
        setState(() => _activeIndex = i);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nominal draf ${i + 1} tidak valid.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            backgroundColor: NeoBrutalism.dark,
          ),
        );
        return;
      }
      parsedAmounts.add(amount);
    }

    final baseTs = DateTime.now().millisecondsSinceEpoch;
    double totalSaved = 0;
    for (var i = 0; i < _drafts.length; i++) {
      final item = _drafts[i];
      final amount = parsedAmounts[i];
      totalSaved += amount;
      final note = item.noteController.text.trim();
      ref.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: 'tx_ai_${baseTs}_$i',
              title: note.isNotEmpty ? note : 'Transaksi Draf AI',
              category: AiCategoryNormalizer.normalize(
                item.category,
                isIncome: !item.isExpense,
                contextHint: note,
              ),
              amount: amount,
              date: DateTime.now(),
              type: item.isExpense ? 'expense' : 'income',
              walletId: item.resolveWalletId(wallets) ?? 'w_main',
              notes: 'Dikonfirmasi dari AI Draft Review',
            ),
          );
    }

    final label = _drafts.length > 1
        ? '${_drafts.length} transaksi (Rp ${totalSaved.toInt()}) berhasil disimpan!'
        : 'Transaksi Rp ${totalSaved.toInt()} berhasil disimpan!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.black),
              ),
            ),
          ],
        ),
        backgroundColor: NeoBrutalism.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (GoRouter.maybeOf(context) != null) {
      context.go('/transaction/history');
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _navigateBack() {
    if (GoRouter.maybeOf(context) != null && context.canPop()) {
      context.pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider);
    final activeDraft = _drafts[_activeIndex];
    activeDraft.walletId ??= activeDraft.resolveWalletId(wallets);

    return Scaffold(
      backgroundColor: const Color(0xFF0F758A),
      body: Container(
        decoration: const BoxDecoration(gradient: NeoBrutalism.brandGradient),
        child: Column(
          children: [
            DraftReviewTopBar(onBack: _navigateBack),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 2.0),
                    left: BorderSide(color: Colors.black, width: 2.0),
                    right: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DraftDetectionBanner(
                          count: _drafts.length,
                          activeTitle: activeDraft.noteController.text,
                        ),
                        if (_drafts.length > 1) ...[
                          const SizedBox(height: 14),
                          DraftIndexTabs(
                            count: _drafts.length,
                            activeIndex: _activeIndex,
                            onSelect: (i) => setState(() => _activeIndex = i),
                          ),
                        ],
                        const SizedBox(height: 16),
                        AiDraftReviewFormCard(
                          draft: activeDraft,
                          wallets: wallets,
                          onTypeChanged: (isExp) {
                            setState(() {
                              activeDraft.isExpense = isExp;
                              activeDraft.category = AiCategoryNormalizer.normalize(
                                activeDraft.category,
                                isIncome: !isExp,
                                contextHint: activeDraft.noteController.text,
                              );
                            });
                          },
                          onCategoryChanged: (cat) => setState(() => activeDraft.category = cat),
                          onWalletChanged: (id) => setState(() => activeDraft.walletId = id),
                        ),
                        const SizedBox(height: 20),
                        DraftReviewActionBar(
                          count: _drafts.length,
                          onCancel: _navigateBack,
                          onConfirm: _confirmAndSave,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
