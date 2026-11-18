import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/unified_ai_chat_panel.dart';
import 'quick_action_sheets.dart';

/// Full-screen Clarafin AI workspace sharing [UnifiedAiChatPanel] with Quick Sheet.
class AiChatScreen extends ConsumerWidget {
  const AiChatScreen({super.key});

  void _handleBack(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    router?.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F758A),
      body: Container(
        decoration: const BoxDecoration(gradient: NeoBrutalism.brandGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: UnifiedAiChatPanel(
              isFullScreen: true,
              onOpenScan: () => showOcrScanSheet(context, ref),
              onOpenVoice: () => showVoiceAiSheet(context, ref),
              onClose: () => _handleBack(context),
            ),
          ),
        ),
      ),
    );
  }
}
