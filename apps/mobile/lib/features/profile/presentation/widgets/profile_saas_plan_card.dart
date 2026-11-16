import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/ai_quota_provider.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/user_profile_provider.dart';

class ProfileSaasPlanCard extends ConsumerWidget {
  const ProfileSaasPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final quota = ref.watch(aiQuotaProvider);

    final isPro = profile.subscriptionPlan == 'pro_monthly' || profile.subscriptionPlan == 'pro';
    final isUnlimited = profile.subscriptionPlan == 'unlimited';

    final planTitle = isUnlimited
        ? 'Paket Unlimited'
        : isPro
            ? 'Paket Pro Bulanan'
            : 'Paket Gratis (Free)';

    final quotaText = isUnlimited
        ? 'Unlimited Kuota AI'
        : '${quota.quotaRemaining} Kuota AI Tersisa';

    final maxQuota = isUnlimited ? 1 : (isPro ? 400 : 40);
    final quotaFraction = isUnlimited ? 1.0 : (quota.quotaRemaining / maxQuota).clamp(0.0, 1.0);

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
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: NeoBrutalism.lime,
                      borderRadius: BorderRadius.circular(8),
                      border: NeoBrutalism.border(width: 1.5),
                    ),
                    child: const Icon(Icons.bolt_rounded, size: 20, color: NeoBrutalism.dark),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                      Text(
                        quotaText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NeoBrutalism.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPro || isUnlimited ? NeoBrutalism.lime : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: NeoBrutalism.border(width: 1.0),
                ),
                child: Text(
                  isUnlimited ? 'ACTIVE' : (isPro ? 'PRO' : 'FREE TIER'),
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
          // Progress Bar
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
          GestureDetector(
            onTap: () {
              // Toggle or upgrade plan
              if (!isPro && !isUnlimited) {
                ref.read(aiQuotaProvider.notifier).upgradePlan('pro_monthly');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Berhasil upgrade ke Paket Pro! Kuota AI kini 400x/bulan.',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: NeoBrutalism.teal,
                  ),
                );
              } else {
                ref.read(aiQuotaProvider.notifier).upgradePlan('free');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Kembali ke Paket Free.',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: NeoBrutalism.dark,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isPro || isUnlimited ? Colors.white : NeoBrutalism.lime,
                borderRadius: BorderRadius.circular(10),
                border: NeoBrutalism.border(width: 1.5),
                boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPro || isUnlimited ? Icons.check_circle_outline_rounded : Icons.star_rounded,
                    size: 16,
                    color: NeoBrutalism.dark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPro || isUnlimited ? 'Kelola Paket Langganan' : 'Upgrade ke Pro (Rp 29.000 / bln)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
