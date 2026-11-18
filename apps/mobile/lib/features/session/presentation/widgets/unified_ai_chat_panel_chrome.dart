import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/institutions/institution_registry.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../shared/widgets/saas_upgrade_bottom_sheet.dart';
import '../../../home/presentation/widgets/notion_doodle_icons.dart';
import '../../domain/models/ai_chat_models.dart';
import '../providers/unified_ai_chat_provider.dart';
import 'ai_action_card_primitives.dart';
import 'ai_chat_bubble.dart';
import 'ai_thinking_trace_widget.dart';

/// Matches a local [WalletModel] by ID, remote `existingWalletNames`, name, or institution.
WalletModel? matchChatLocalWallet(
  List<WalletModel> wallets,
  String walletId, {
  Map<String, String> existingWalletNames = const {},
}) {
  final trimmed = walletId.trim();
  if (trimmed.isEmpty) return null;
  final byId = wallets.where((w) => w.id == trimmed).firstOrNull;
  if (byId != null) return byId;

  final namedHint = existingWalletNames[trimmed]?.trim() ?? '';
  if (namedHint.isNotEmpty) {
    final lowerHint = namedHint.toLowerCase();
    final byNamedHint = wallets.where((w) => w.name.trim().toLowerCase() == lowerHint).firstOrNull;
    if (byNamedHint != null) return byNamedHint;
    final byInst = wallets.where((w) {
      return InstitutionRegistry.findByWallet(name: w.name, type: w.type).id ==
          InstitutionRegistry.findByWallet(name: namedHint, type: w.type).id;
    }).firstOrNull;
    if (byInst != null) return byInst;
  }

  final lowerId = trimmed.toLowerCase();
  return wallets.where((w) => w.name.trim().toLowerCase() == lowerId).firstOrNull;
}

/// Resolves a human-readable wallet label from user wallets or [InstitutionRegistry].
String resolveChatWalletLabel(
  List<WalletModel> wallets,
  String walletId, {
  Map<String, String> existingWalletNames = const {},
}) {
  final trimmed = walletId.trim();
  if (trimmed.isEmpty) return '';
  final hit = matchChatLocalWallet(wallets, trimmed, existingWalletNames: existingWalletNames);
  if (hit != null && hit.name.trim().isNotEmpty) return hit.name;
  final namedHint = existingWalletNames[trimmed]?.trim() ?? '';
  if (namedHint.isNotEmpty) return namedHint;
  final clean = trimmed.replaceFirst(RegExp(r'^(wallet[-_]|w[-_])', caseSensitive: false), '').trim();
  return (clean.isEmpty ? null : InstitutionRegistry.findById(clean))?.shortName ??
      (clean.isEmpty ? trimmed : clean);
}

/// Builds a fully wired [AiChatBubble] for [UnifiedAiChatPanel].
Widget buildUnifiedChatBubble({
  required BuildContext context,
  required UnifiedAiChatMessage msg,
  required List<WalletModel> wallets,
  required UnifiedAiChatNotifier notifier,
  required AiSurfaceMode surfaceMode,
  required void Function(AiConsultantRecommendation, AiPackageRecommendation?) onSelectConsultant,
  required void Function(String route) onNavigateShellBranch,
}) {
  final walletNames = msg.walletCreationDraft?.existingWalletNames ?? const {};
  return AiChatBubble(
    message: msg,
    onRetry: () => unawaited(notifier.retryFailedMessage(msg.id, surfaceMode: surfaceMode)),
    onUpgradePlan: () => SaasUpgradeBottomSheet.show(context, reason: msg.text),
    onCreateWallet: (bal) => unawaited(notifier.confirmWalletCreation(msg.id, initialBalance: bal)),
    onSelectExistingWallet: (walletId) {
      final w = matchChatLocalWallet(wallets, walletId, existingWalletNames: walletNames);
      if (w != null) notifier.selectExistingWalletForPendingTx(msg.id, w);
    },
    onConfirmTransaction: () => unawaited(notifier.confirmTransactionDraft(msg.id)),
    onCancelTransaction: () => notifier.cancelTransactionDraft(msg.id),
    onConfirmTransactionGroup: (groupIndex) => unawaited(notifier.confirmTransactionDraft(msg.id, groupIndex: groupIndex)),
    onCancelTransactionGroup: (groupIndex) => notifier.cancelTransactionDraft(msg.id, groupIndex: groupIndex),
    onConfirmGoal: () => unawaited(notifier.confirmGoalDraft(msg.id)),
    onCancelGoal: () => notifier.cancelGoalDraft(msg.id),
    onConfirmBudget: () => unawaited(notifier.confirmBudgetDraft(msg.id)),
    onCancelBudget: () => notifier.cancelBudgetDraft(msg.id),
    onViewBudget: () => onNavigateShellBranch('/budget?tab=1'),
    onConfirmBill: () => unawaited(notifier.confirmBillDraft(msg.id)),
    onCancelBill: () => notifier.cancelBillDraft(msg.id),
    onSelectConsultant: onSelectConsultant,
    onBrowseConsultants: () => onNavigateShellBranch('/consult'),
    walletLabelResolver: (id) => resolveChatWalletLabel(wallets, id, existingWalletNames: walletNames),
    walletBalanceResolver: (id) => matchChatLocalWallet(wallets, id, existingWalletNames: walletNames)?.balance,
  );
}

/// Live thinking trace row rendered at the bottom of the chat while streaming.
class LiveThinkingTraceRow extends StatelessWidget {
  final AiThinkingTrace trace;
  const LiveThinkingTraceRow({super.key, required this.trace});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: NeoBrutalism.lime,
              shape: BoxShape.circle,
              border: NeoBrutalism.border(width: 1.8),
              boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
            ),
            child: Center(
              child: NotionDoodleWidget(svgString: NotionDoodleIcons.aiChat, size: 19),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AiThinkingTraceWidget(trace: trace, initiallyExpanded: true),
          ),
        ],
      ),
    );
  }
}

/// Dismissible Neo-Brutalist banner for non-SSE mutation/sync failures.
class MutationErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const MutationErrorBanner({super.key, required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NeoBrutalism.coral,
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: aiActionTextStyle(context, 11.5, FontWeight.w700, const Color(0xFF9F1239)),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.close, size: 18, color: NeoBrutalism.dark),
            tooltip: 'Tutup pesan error',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// Contextual floating CTA escalating Quick Sheet threads into `/ai-chat`.
class ExpandFullScreenPill extends StatefulWidget {
  final VoidCallback onTap;
  const ExpandFullScreenPill({super.key, required this.onTap});

  @override
  State<ExpandFullScreenPill> createState() => _ExpandFullScreenPillState();
}

class _ExpandFullScreenPillState extends State<ExpandFullScreenPill> {
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: 'Lanjutkan di Layar Penuh',
        child: Transform.translate(
          offset: Offset(0, _isPressed ? 2.0 : 0.0),
          child: Container(
            decoration: BoxDecoration(
              color: NeoBrutalism.lime,
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
              border: NeoBrutalism.border(width: 2.0),
              boxShadow: _isPressed ? null : NeoBrutalism.shadow(yOffset: 2.5),
            ),
            foregroundDecoration: _isFocused
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                    border: Border.all(color: NeoBrutalism.darkTeal, width: 2.5),
                  )
                : null,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('ai_chat_expand_pill'),
                borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                onTap: widget.onTap,
                onFocusChange: (f) {
                  if (_isFocused != f) setState(() => _isFocused = f);
                },
                onHighlightChanged: (p) {
                  if (_isPressed != p) setState(() => _isPressed = p);
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_full_rounded, size: 15, color: NeoBrutalism.dark),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Lanjutkan di Layar Penuh',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: aiActionTextStyle(context, 12, FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
