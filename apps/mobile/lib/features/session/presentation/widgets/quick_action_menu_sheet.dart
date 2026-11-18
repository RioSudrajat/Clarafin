import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/ai_quota_provider.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../shared/widgets/saas_upgrade_bottom_sheet.dart';
import '../../../home/presentation/widgets/notion_doodle_icons.dart';
import '../screens/quick_action_sheets.dart';
import 'ai_action_card_primitives.dart';

/// 2x2 Quick Action hub sheet opened from the center bottom-nav FAB.
class QuickActionMenuSheet extends ConsumerWidget {
  const QuickActionMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiQuota = ref.watch(aiQuotaProvider);
    final isAiExhausted = !aiQuota.isUnlimited && aiQuota.quotaRemaining <= 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 18),
            Text(
              'Catat Transaksi Cepat',
              style: aiActionTextStyle(context, 18, FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih metode paling efisien untuk catat keuanganmu.',
              style: aiActionTextStyle(
                context,
                13,
                FontWeight.w500,
                const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.0,
              children: [
                _ActionGridItem(
                  svgString: NotionDoodleIcons.aiChat,
                  title: 'AI Chat Action',
                  subtitle: 'Ketik lewat asisten AI',
                  limitText: 'AI Kuota: ${aiQuota.displayQuotaBadge}',
                  isLimited: isAiExhausted,
                  onTap: () {
                    final hostContext = Navigator.of(context).context;
                    Navigator.of(context).pop();
                    if (isAiExhausted) {
                      SaasUpgradeBottomSheet.show(
                        hostContext,
                        reason:
                            'Kuota AI kamu sudah habis untuk AI Chat Quick Action. Upgrade paket untuk lanjut.',
                      );
                    } else {
                      showAiChatQuickSheet(hostContext, ref);
                    }
                  },
                ),
                _ActionGridItem(
                  svgString: NotionDoodleIcons.voiceAi,
                  title: 'Voice AI Action',
                  subtitle: 'Ucapkan ke asisten AI',
                  limitText: 'AI Kuota: ${aiQuota.displayQuotaBadge}',
                  isLimited: isAiExhausted,
                  onTap: () {
                    final hostContext = Navigator.of(context).context;
                    Navigator.of(context).pop();
                    showVoiceAiSheet(hostContext, ref);
                  },
                ),
                _ActionGridItem(
                  svgString: NotionDoodleIcons.ocrScan,
                  title: 'Scan Action (OCR)',
                  subtitle: 'Foto struk belanja untuk scan',
                  limitText: 'AI Kuota: ${aiQuota.displayQuotaBadge}',
                  isLimited: isAiExhausted,
                  onTap: () {
                    final hostContext = Navigator.of(context).context;
                    Navigator.of(context).pop();
                    showOcrScanSheet(hostContext, ref);
                  },
                ),
                _ActionGridItem(
                  svgString: NotionDoodleIcons.manualAdd,
                  title: 'Manual Add',
                  subtitle: 'Isi formulir manual lengkap',
                  limitText: 'Unlimited',
                  isLimited: false,
                  onTap: () {
                    final router = GoRouter.maybeOf(context);
                    Navigator.of(context).pop();
                    router?.push('/transaction/entry');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionGridItem extends StatelessWidget {
  final String svgString;
  final String title;
  final String subtitle;
  final String limitText;
  final bool isLimited;
  final VoidCallback onTap;

  const _ActionGridItem({
    required this.svgString,
    required this.title,
    required this.subtitle,
    required this.limitText,
    required this.isLimited,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: 16,
        shadowOffset: 3.5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLimited ? NeoBrutalism.coral : NeoBrutalism.lime,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 1.2),
                  ),
                  child: Text(
                    limitText,
                    style: aiActionTextStyle(context, 8.5, FontWeight.w800),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 26, 10, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NotionDoodleWidget(svgString: svgString, size: 42),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: aiActionTextStyle(context, 13, FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: aiActionTextStyle(
                          context,
                          10.5,
                          FontWeight.w500,
                          const Color(0xFF4B5563),
                        ).copyWith(height: 1.2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
