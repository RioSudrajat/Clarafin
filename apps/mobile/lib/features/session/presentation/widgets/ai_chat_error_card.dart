import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../shared/widgets/saas_upgrade_bottom_sheet.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_action_card_primitives.dart';

/// Accessible Neo-Brutalist error bubble with Retry or Upgrade Plan CTA.
class AiChatErrorCard extends StatelessWidget {
  final UnifiedAiChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onUpgradePlan;

  const AiChatErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.onUpgradePlan,
  });

  bool get _isQuotaExceeded {
    final code = (message.errorCode ?? '').trim().toUpperCase();
    return code == 'QUOTA_EXCEEDED' || code == '402';
  }

  @override
  Widget build(BuildContext context) {
    final isQuota = _isQuotaExceeded;
    final canRetry = !isQuota && (message.failedPrompt ?? '').trim().isNotEmpty;
    final headline = isQuota ? 'Kuota AI Habis' : 'Permintaan Belum Berhasil';
    final detail = message.text.trim().isNotEmpty
        ? message.text.trim()
        : (isQuota
            ? 'Kuota AI bulanan kamu sudah habis. Upgrade paket untuk lanjut.'
            : 'Terjadi kendala saat memproses permintaanmu. Silakan coba lagi.');

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const Key('ai_chat_error_card'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: NeoBrutalism.cardDecoration(
          backgroundColor: NeoBrutalism.coral,
          borderRadius: 16,
          shadowOffset: 2.5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isQuota ? Icons.lock_clock_rounded : Icons.error_outline_rounded,
                  size: 18,
                  color: const Color(0xFF9F1239),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headline,
                    style: aiActionTextStyle(
                      context,
                      13,
                      FontWeight.w900,
                      const Color(0xFF9F1239),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: aiActionTextStyle(
                context,
                12.5,
                FontWeight.w600,
                NeoBrutalism.dark,
              ).copyWith(height: 1.4),
            ),
            if (isQuota) ...[
              const SizedBox(height: 12),
              AiActionTactileButton(
                buttonKey: const Key('ai_error_upgrade_btn'),
                label: 'Upgrade Plan',
                icon: Icons.upgrade_rounded,
                backgroundColor: NeoBrutalism.lime,
                textColor: Colors.black,
                isPrimary: true,
                fullWidth: true,
                onTap: onUpgradePlan ??
                    () => SaasUpgradeBottomSheet.show(context, reason: detail),
              ),
            ] else if (canRetry && onRetry != null) ...[
              const SizedBox(height: 12),
              AiActionTactileButton(
                buttonKey: const Key('ai_error_retry_btn'),
                label: 'Coba Lagi',
                icon: Icons.refresh_rounded,
                backgroundColor: Colors.white,
                textColor: NeoBrutalism.dark,
                fullWidth: true,
                onTap: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
