import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/ai_quota_provider.dart';
import '../../core/theme/neo_brutalism_decorations.dart';
import 'saas_plan_tier_card.dart';

/// Shared Neo-Brutalist subscription sheet for Free -> Pro / Unlimited upgrades.
class SaasUpgradeBottomSheet extends ConsumerWidget {
  final String? reason;

  const SaasUpgradeBottomSheet({super.key, this.reason});

  static Future<void> show(BuildContext context, {String? reason}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SaasUpgradeBottomSheet(reason: reason),
    );
  }

  void _selectPlan(
    BuildContext context,
    WidgetRef ref,
    String planKey,
    String feedbackText,
  ) {
    ref.read(aiQuotaProvider.notifier).upgradePlan(planKey);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          feedbackText,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        backgroundColor: NeoBrutalism.lime,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quota = ref.watch(aiQuotaProvider);
    final currentPlan = quota.planType;
    final hasReason = reason != null && reason!.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(NeoBrutalism.radiusBoundary),
        ),
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.0),
          left: BorderSide(color: Colors.black, width: 2.0),
          right: BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Paket Clarafin',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kuota saat ini: ${quota.displayQuotaBadge}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: NeoBrutalism.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'Tutup lembar paket',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: NeoBrutalism.circleDecoration(shadowOffset: 1.5),
                        child: const Icon(Icons.close, size: 20, color: NeoBrutalism.dark),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hasReason
                    ? reason!.trim()
                    : 'Sesuaikan kapasitas catat transaksi lewat chat, suara, dan scan struk per bulan.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SaasPlanTierCard(
                title: 'Paket Pro',
                price: 'Rp 49.000 / bln',
                quotaSummary: '400 aksi catat per bulan',
                details: const [
                  'Chat, input suara, dan scan OCR struk',
                  'Cocok untuk pencatatan harian rutin',
                ],
                backgroundColor: NeoBrutalism.surfaceWarm,
                ctaColor: NeoBrutalism.lime,
                isActive: currentPlan == 'pro_monthly' || currentPlan == 'pro',
                ctaLabel: currentPlan == 'pro_monthly' || currentPlan == 'pro'
                    ? 'Paket Pro Aktif'
                    : 'Pilih Paket Pro',
                onTap: () => _selectPlan(
                  context,
                  ref,
                  'pro_monthly',
                  'Paket Pro aktif. Kuota sekarang 400 aksi per bulan.',
                ),
              ),
              const SizedBox(height: 12),
              SaasPlanTierCard(
                title: 'Paket Unlimited',
                price: 'Rp 99.000 / bln',
                quotaSummary: 'Kuota tanpa batas (Unlimited)',
                details: const [
                  'Akses penuh chat, suara, dan OCR kapan saja',
                  'Tanpa batas kuota bulanan',
                ],
                backgroundColor: NeoBrutalism.mint,
                ctaColor: NeoBrutalism.lime,
                isActive: currentPlan == 'unlimited',
                ctaLabel: currentPlan == 'unlimited'
                    ? 'Paket Unlimited Aktif'
                    : 'Pilih Paket Unlimited',
                onTap: () => _selectPlan(
                  context,
                  ref,
                  'unlimited',
                  'Paket Unlimited aktif. Kuota tanpa batas siap digunakan.',
                ),
              ),
              if (currentPlan != 'free') ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.black, width: 2.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                      ),
                    ),
                    onPressed: () => _selectPlan(
                      context,
                      ref,
                      'free',
                      'Paket dikembalikan ke Gratis (40 kuota per bulan).',
                    ),
                    child: Text(
                      'Kembali ke Paket Gratis (40 kuota/bln)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
