import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/ai_quota_provider.dart';
import '../../../../shared/widgets/saas_upgrade_bottom_sheet.dart';
import '../providers/unified_ai_chat_provider.dart';
import '../widgets/clarafin_ai_quick_sheet.dart';
import '../widgets/ocr_scan_modal_sheet.dart';
import '../widgets/quick_action_menu_sheet.dart';
import '../widgets/voice_ai_modal_sheet.dart';

/// Opens the unified Clarafin AI Quick Sheet with a fresh capture session.
void showAiChatQuickSheet(
  BuildContext context,
  WidgetRef parentRef, {
  bool resetSession = true,
}) {
  if (resetSession) {
    parentRef.read(unifiedAiChatProvider.notifier).startNewChat();
  }
  final parentRouter = GoRouter.maybeOf(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetCtx) => ClarafinAiQuickSheet(
      parentRouter: parentRouter,
      onOpenScan: () {
        final hostContext = Navigator.of(sheetCtx).context;
        Navigator.of(sheetCtx).pop();
        showOcrScanSheet(hostContext, parentRef);
      },
      onOpenVoice: () {
        final hostContext = Navigator.of(sheetCtx).context;
        Navigator.of(sheetCtx).pop();
        showVoiceAiSheet(hostContext, parentRef);
      },
    ),
  );
}

/// Opens the OCR receipt scan sheet after enforcing remaining AI quota.
void showOcrScanSheet(BuildContext context, WidgetRef parentRef) {
  final quota = parentRef.read(aiQuotaProvider);
  if (!quota.isUnlimited && quota.quotaRemaining <= 0) {
    SaasUpgradeBottomSheet.show(
      context,
      reason:
          'Kuota AI kamu sudah habis untuk Scan Action (OCR). Upgrade paket untuk lanjut.',
    );
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: Colors.black, width: 2.0),
    ),
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.94,
      child: OcrScanModalSheet(),
    ),
  );
}

/// Opens the Voice AI recording sheet after enforcing remaining AI quota.
void showVoiceAiSheet(BuildContext context, WidgetRef parentRef) {
  final quota = parentRef.read(aiQuotaProvider);
  if (!quota.isUnlimited && quota.quotaRemaining <= 0) {
    SaasUpgradeBottomSheet.show(
      context,
      reason:
          'Kuota AI kamu sudah habis untuk Voice AI Action. Upgrade paket untuk lanjut.',
    );
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: Colors.black, width: 2.0),
    ),
    builder: (_) => const SafeArea(
      child: SingleChildScrollView(child: VoiceAiModalSheet()),
    ),
  );
}

/// Opens the 2x2 Quick Action hub sheet from the center bottom-nav FAB.
void showQuickActionMenuSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: Colors.black, width: 2.0),
    ),
    builder: (_) => const QuickActionMenuSheet(),
  );
}
