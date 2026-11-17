import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/ai_quota_provider.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../shared/widgets/saas_upgrade_bottom_sheet.dart';

class ProfileSaasPlanCard extends ConsumerWidget {
  const ProfileSaasPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quota = ref.watch(aiQuotaProvider);

    final isPro = quota.planType == 'pro_monthly' || quota.planType == 'pro';
    final isUnlimited = quota.isUnlimited;

    final planTitle = isUnlimited
        ? 'Paket Unlimited'
        : isPro
            ? 'Paket Pro Bulanan'
            : 'Paket Gratis (Free)';

    final quotaText = isUnlimited
        ? 'Unlimited Kuota AI'
        : '${quota.quotaRemaining}/${quota.quotaTotal} Kuota AI Tersisa';

    final quotaFraction = isUnlimited || quota.quotaTotal <= 0
        ? 1.0
        : (quota.quotaRemaining / quota.quotaTotal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPro || isUnlimited ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: NeoBrutalism.lime,
                        borderRadius: BorderRadius.circular(8),
                        border: NeoBrutalism.border(width: 1.5),
                      ),
                      child: Icon(
                        isUnlimited
                            ? Icons.all_inclusive_rounded
                            : Icons.receipt_long_rounded,
                        size: 20,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: NeoBrutalism.dark,
                            ),
                          ),
                          Text(
                            quotaText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: NeoBrutalism.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPro || isUnlimited
                      ? NeoBrutalism.lime
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: NeoBrutalism.border(width: 1.0),
                ),
                child: Text(
                  isUnlimited ? 'UNLIMITED' : (isPro ? 'PRO' : 'FREE TIER'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: quotaFraction,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(NeoBrutalism.lime),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: isPro || isUnlimited ? Colors.white : NeoBrutalism.lime,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => SaasUpgradeBottomSheet.show(context),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: NeoBrutalism.border(width: 1.5),
                  boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPro || isUnlimited
                          ? Icons.tune_rounded
                          : Icons.upgrade_rounded,
                      size: 16,
                      color: NeoBrutalism.dark,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isPro || isUnlimited
                            ? 'Kelola Paket Langganan'
                            : 'Upgrade ke Pro (Rp 49.000 / bln)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
