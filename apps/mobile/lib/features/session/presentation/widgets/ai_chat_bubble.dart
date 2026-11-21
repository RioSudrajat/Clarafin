import 'package:flutter/material.dart';

import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../home/presentation/widgets/notion_doodle_icons.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_action_card_primitives.dart';
import 'ai_chat_error_card.dart';
import 'ai_formatted_narrative_text.dart';
import 'ai_money_flow_card.dart';
import 'ai_planning_action_card.dart';
import 'ai_recommended_consultants_section.dart';
import 'ai_spending_breakdown_table_card.dart';
import 'ai_thinking_trace_widget.dart';
import 'ai_transaction_draft_card.dart';
import 'ai_wallet_creation_draft_card.dart';

typedef AiSelectConsultantCallback = void Function(
  AiConsultantRecommendation consultant,
  AiPackageRecommendation? fallbackPackage,
);

/// Renders a unified user or multimodal assistant chat turn with rich cards.
class AiChatBubble extends StatelessWidget {
  final UnifiedAiChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onUpgradePlan;
  final ValueChanged<double>? onCreateWallet;
  final ValueChanged<String>? onSelectExistingWallet;
  final VoidCallback? onConfirmTransaction;
  final VoidCallback? onCancelTransaction;
  final ValueChanged<int>? onConfirmTransactionGroup;
  final ValueChanged<int>? onCancelTransactionGroup;
  final VoidCallback? onConfirmGoal;
  final VoidCallback? onCancelGoal;
  final VoidCallback? onConfirmBudget;
  final VoidCallback? onCancelBudget;
  final VoidCallback? onViewBudget;
  final VoidCallback? onConfirmBill;
  final VoidCallback? onCancelBill;
  final AiSelectConsultantCallback? onSelectConsultant;
  final VoidCallback? onBrowseConsultants;
  final String Function(String walletId)? walletLabelResolver;
  final double? Function(String walletId)? walletBalanceResolver;
  final WalletModel? Function(String walletId)? walletResolver;

  const AiChatBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onUpgradePlan,
    this.onCreateWallet,
    this.onSelectExistingWallet,
    this.onConfirmTransaction,
    this.onCancelTransaction,
    this.onConfirmTransactionGroup,
    this.onCancelTransactionGroup,
    this.onConfirmGoal,
    this.onCancelGoal,
    this.onConfirmBudget,
    this.onCancelBudget,
    this.onViewBudget,
    this.onConfirmBill,
    this.onCancelBill,
    this.onSelectConsultant,
    this.onBrowseConsultants,
    this.walletLabelResolver,
    this.walletBalanceResolver,
    this.walletResolver,
  });

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserTurn(context);
    }
    return _buildAssistantTurn(context);
  }

  Widget _buildUserTurn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 36),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: NeoBrutalism.lime,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16), topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4),
                    ),
                    border: NeoBrutalism.border(width: 2.0),
                    boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                  ),
                  child: Text(
                    message.text,
                    textAlign: TextAlign.justify,
                    style: AppTypography.chatBody(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.48,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_formatTime(message.timestamp), style: aiActionTextStyle(context, 10.5, FontWeight.w600, const Color(0xFF4B5563))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantTurn(BuildContext context) {
    final hasPlanning = message.goalDraft != null || message.budgetDraft != null || message.billDraft != null;
    final hasAdvisory = message.recommendedPackage != null || message.recommendedConsultants.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: NeoBrutalism.lime, shape: BoxShape.circle,
              border: NeoBrutalism.border(width: 1.8), boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
            ),
            child: Center(child: NotionDoodleWidget(svgString: NotionDoodleIcons.aiChat, size: 19)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (message.errorCode != null)
                  AiChatErrorCard(message: message, onRetry: onRetry, onUpgradePlan: onUpgradePlan)
                else ...[
                  if (message.thinkingTrace != null) ...[
                    AiThinkingTraceWidget(trace: message.thinkingTrace!),
                    const SizedBox(height: 8),
                  ],
                  if (message.text.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4), topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
                        ),
                        border: NeoBrutalism.border(width: 1.8), boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                      ),
                      child: AiFormattedNarrativeText(text: message.text),
                    ),
                  if (message.moneyFlowCard != null) ...[const SizedBox(height: 10), AiMoneyFlowCard(data: message.moneyFlowCard!)],
                  if (message.spendingTableCard != null) ...[const SizedBox(height: 10), AiSpendingBreakdownTableCard(data: message.spendingTableCard!)],
                  if (message.walletCreationDraft != null) ...[
                    const SizedBox(height: 10),
                    AiWalletCreationDraftCard(
                      draft: message.walletCreationDraft!,
                      onCreateWallet: onCreateWallet, onUseExistingWallet: onSelectExistingWallet, walletLabelResolver: walletLabelResolver,
                    ),
                  ],
                  for (var i = 0; i < message.transactionDraftGroups.length; i++) ...[
                    const SizedBox(height: 10),
                    AiTransactionDraftCard(
                      key: ValueKey('tx_draft_card_${message.id}_$i'),
                      draft: message.transactionDraftGroups[i],
                      onConfirm: onConfirmTransactionGroup != null
                          ? () => onConfirmTransactionGroup!(i)
                          : (i == 0 ? onConfirmTransaction : null),
                      onCancel: onCancelTransactionGroup != null
                          ? () => onCancelTransactionGroup!(i)
                          : (i == 0 ? onCancelTransaction : null),
                      walletLabelResolver: walletLabelResolver,
                      walletBalanceResolver: walletBalanceResolver,
                      walletResolver: walletResolver,
                    ),
                  ],
                  if (hasPlanning) ...[
                    const SizedBox(height: 10),
                    AiPlanningActionCard(
                      goalDraft: message.goalDraft, budgetDraft: message.budgetDraft, billDraft: message.billDraft,
                      onConfirmGoal: onConfirmGoal, onCancelGoal: onCancelGoal,
                      onConfirmBudget: onConfirmBudget, onCancelBudget: onCancelBudget, onViewBudget: onViewBudget,
                      onConfirmBill: onConfirmBill, onCancelBill: onCancelBill, walletLabelResolver: walletLabelResolver,
                    ),
                  ],
                  if (hasAdvisory) ...[
                    const SizedBox(height: 10),
                    AiRecommendedConsultantsSection(
                      recommendedPackage: message.recommendedPackage, consultants: message.recommendedConsultants,
                      onSchedule: onSelectConsultant == null ? null : (c) => onSelectConsultant!(c, message.recommendedPackage),
                      onBrowseConsultants: onBrowseConsultants,
                    ),
                  ],
                ],
                const SizedBox(height: 4),
                Text(_formatTime(message.timestamp), style: aiActionTextStyle(context, 10.5, FontWeight.w600, const Color(0xFF4B5563))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
