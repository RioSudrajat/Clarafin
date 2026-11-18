import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'unified_ai_chat_panel.dart';

/// Keyboard-safe Quick Sheet shell wrapping [UnifiedAiChatPanel] in `quick_sheet` mode.
class ClarafinAiQuickSheet extends ConsumerWidget {
  final VoidCallback onOpenScan;
  final VoidCallback onOpenVoice;
  final GoRouter? parentRouter;

  const ClarafinAiQuickSheet({
    super.key,
    required this.onOpenScan,
    required this.onOpenVoice,
    this.parentRouter,
  });

  void _expandToFullScreen(BuildContext context) {
    final router = GoRouter.maybeOf(context) ?? parentRouter;
    Navigator.of(context).pop();
    router?.push('/ai-chat');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.viewInsets.bottom - media.padding.top;
    final targetHeight = math.min(
      media.size.height * 0.78,
      math.max(260.0, availableHeight - 20.0),
    );

    return AnimatedPadding(
      duration: MediaQuery.maybeDisableAnimationsOf(context) == true
          ? Duration.zero
          : const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: media.viewInsets.bottom + 12,
        left: 12,
        right: 12,
        top: 12,
      ),
      child: SizedBox(
        height: targetHeight,
        child: UnifiedAiChatPanel(
          isFullScreen: false,
          onOpenScan: onOpenScan,
          onOpenVoice: onOpenVoice,
          onExpandToFullScreen: () => _expandToFullScreen(context),
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
