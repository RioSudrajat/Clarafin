import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/wallet_model.dart';
import '../../../../core/network/tracker_remote_sync_service.dart';
import '../../../../core/providers/ai_quota_provider.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../shared/widgets/saas_upgrade_bottom_sheet.dart';
import '../../domain/models/ai_chat_models.dart';
import '../providers/unified_ai_chat_provider.dart';
import 'ai_chat_input_bar.dart';
import 'ai_chat_welcome_widget.dart';
import 'unified_ai_chat_header.dart';
import 'unified_ai_chat_panel_chrome.dart';

/// Unified 2-Card Neo-Brutalist chat shell shared by Quick Sheet and `/ai-chat`.
class UnifiedAiChatPanel extends ConsumerStatefulWidget {
  final bool isFullScreen;
  final VoidCallback? onOpenScan;
  final VoidCallback? onOpenVoice;
  final VoidCallback? onExpandToFullScreen;
  final VoidCallback? onClose;

  const UnifiedAiChatPanel({
    super.key,
    required this.isFullScreen,
    this.onOpenScan,
    this.onOpenVoice,
    this.onExpandToFullScreen,
    this.onClose,
  });

  @override
  ConsumerState<UnifiedAiChatPanel> createState() => _UnifiedAiChatPanelState();
}

class _UnifiedAiChatPanelState extends ConsumerState<UnifiedAiChatPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  AiSurfaceMode get _surfaceMode =>
      widget.isFullScreen ? AiSurfaceMode.fullScreen : AiSurfaceMode.quickSheet;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) unawaited(ref.read(unifiedAiChatProvider.notifier).refreshQuota());
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _sendMessage(String rawText) {
    final trimmed = rawText.trim();
    final state = ref.read(unifiedAiChatProvider);
    if (trimmed.isEmpty || state.isStreaming || state.isMutating) return;
    _textController.clear();
    unawaited(
      ref.read(unifiedAiChatProvider.notifier).sendMessage(trimmed, surfaceMode: _surfaceMode),
    );
    _scrollToBottom();
  }

  void _handleSelectConsultant(
    BuildContext context,
    AiConsultantRecommendation consultant,
    AiPackageRecommendation? pkg,
  ) {
    final id = consultant.consultantId.trim();
    if (id.isEmpty) return;
    ref.read(unifiedAiChatProvider.notifier).prepareConsultantBooking(
          consultant,
          fallbackPackage: pkg,
        );
    final router = GoRouter.maybeOf(context);
    if (!widget.isFullScreen) widget.onClose?.call();
    router?.push('/booking/$id/service');
  }

  void _navigateShellBranch(BuildContext context, String route) {
    final router = GoRouter.maybeOf(context);
    if (!widget.isFullScreen) widget.onClose?.call();
    router?.go(route);
  }

  Widget _buildMessageList(
    BuildContext context,
    UnifiedAiChatState chatState,
    List<WalletModel> wallets, {
    required bool showLiveTrace,
    required bool showExpandPill,
  }) {
    final padding = EdgeInsets.fromLTRB(12, 14, 12, showExpandPill ? 68 : 14);
    final itemCount = chatState.messages.length + (showLiveTrace ? 1 : 0);
    final notifier = ref.read(unifiedAiChatProvider.notifier);
    final syncService = ref.watch(trackerRemoteSyncServiceProvider);

    Widget renderBubble(UnifiedAiChatMessage msg) => buildUnifiedChatBubble(
          context: context,
          msg: msg,
          wallets: wallets,
          notifier: notifier,
          surfaceMode: _surfaceMode,
          onSelectConsultant: (c, pkg) => _handleSelectConsultant(context, c, pkg),
          onNavigateShellBranch: (route) => _navigateShellBranch(context, route),
          localWalletIdResolver: syncService.resolveLocalWalletId,
        );

    // Quick Sheet keeps short threads non-virtualized so adjacent draft cards stay onstage.
    if (!widget.isFullScreen && itemCount <= 12) {
      return SingleChildScrollView(
        controller: _scrollController,
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final msg in chatState.messages) renderBubble(msg),
            if (showLiveTrace) LiveThinkingTraceRow(trace: chatState.activeThinkingTrace!),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      scrollCacheExtent: const ScrollCacheExtent.pixels(1200),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (showLiveTrace && index == chatState.messages.length) {
          return LiveThinkingTraceRow(trace: chatState.activeThinkingTrace!);
        }
        return renderBubble(chatState.messages[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UnifiedAiChatState>(unifiedAiChatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isStreaming != next.isStreaming ||
          prev?.activeThinkingTrace?.steps.length != next.activeThinkingTrace?.steps.length) {
        _scrollToBottom();
      }
    });

    final chatState = ref.watch(unifiedAiChatProvider);
    final aiQuota = ref.watch(aiQuotaProvider);
    final wallets = ref.watch(walletsProvider);
    final notifier = ref.read(unifiedAiChatProvider.notifier);

    final isQuotaExhausted = !aiQuota.isUnlimited && aiQuota.quotaRemaining <= 0;
    final showLiveTrace = chatState.isStreaming && chatState.activeThinkingTrace != null;
    final showExpandPill = !widget.isFullScreen &&
        chatState.hasRichCardsOrMultiReplies &&
        widget.onExpandToFullScreen != null;
    final hasMutationBanner = (chatState.errorMessage ?? '').trim().isNotEmpty &&
        (chatState.messages.isEmpty || chatState.messages.last.errorCode == null);

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Container(
            decoration: NeoBrutalism.cardDecoration(
              backgroundColor: Colors.white,
              borderRadius: 20,
              shadowOffset: 4.0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                children: [
                  UnifiedAiChatHeader(
                    isFullScreen: widget.isFullScreen,
                    quotaBadgeText: aiQuota.displayQuotaBadge,
                    isQuotaExhausted: isQuotaExhausted,
                    onTapQuota: () => SaasUpgradeBottomSheet.show(context),
                    onNewChat: notifier.startNewChat,
                    onExpandToFullScreen: widget.onExpandToFullScreen,
                    onClose: widget.onClose,
                  ),
                  if (hasMutationBanner)
                    MutationErrorBanner(message: chatState.errorMessage!, onDismiss: notifier.clearError),
                  Expanded(
                    child: Stack(
                      children: [
                        if (chatState.messages.isEmpty && !showLiveTrace)
                          AiChatWelcomeWidget(isCompact: !widget.isFullScreen, onSelectPrompt: _sendMessage)
                        else
                          _buildMessageList(context, chatState, wallets, showLiveTrace: showLiveTrace, showExpandPill: showExpandPill),
                        if (showExpandPill)
                          Positioned(
                            bottom: 10, left: 16, right: 16,
                            child: Center(child: ExpandFullScreenPill(onTap: widget.onExpandToFullScreen!)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: widget.isFullScreen ? 12 : 10),
        AiChatInputBar(
          controller: _textController,
          focusNode: _inputFocusNode,
          isAiTyping: chatState.isStreaming || chatState.isMutating,
          onSendMessage: _sendMessage,
          onOpenScan: widget.onOpenScan,
          onOpenVoice: widget.onOpenVoice,
        ),
      ],
    );
  }
}
