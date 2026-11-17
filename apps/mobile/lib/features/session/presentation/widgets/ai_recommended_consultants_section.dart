import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../consult/presentation/providers/booking_provider.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_catalog_package_banner.dart';
import 'ai_recommendation_primitives.dart';
import 'ai_recommended_consultant_card.dart';

/// Renders the AI-matched catalog package banner and 1-3 practitioner cards.
class AiRecommendedConsultantsSection extends ConsumerWidget {
  final AiPackageRecommendation? recommendedPackage;
  final List<AiConsultantRecommendation> consultants;
  final void Function(String consultantId)? onViewProfile;
  final void Function(AiConsultantRecommendation consultant)? onSchedule;
  final VoidCallback? onBrowseConsultants;

  const AiRecommendedConsultantsSection({
    super.key,
    this.recommendedPackage,
    required this.consultants,
    this.onViewProfile,
    this.onSchedule,
    this.onBrowseConsultants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleConsultants = consultants.take(3).toList();
    if (recommendedPackage == null && visibleConsultants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recommendedPackage != null) ...[
          AiCatalogPackageBanner(package: recommendedPackage!),
          const SizedBox(height: 12),
        ],
        if (visibleConsultants.isEmpty)
          _EmptyConsultantsCard(onBrowseConsultants: onBrowseConsultants)
        else
          for (var i = 0; i < visibleConsultants.length; i++) ...[
            AiRecommendedConsultantCard(
              consultant: visibleConsultants[i],
              onViewProfile: visibleConsultants[i].consultantId.trim().isNotEmpty
                  ? () => _handleViewProfile(
                      context,
                      visibleConsultants[i].consultantId,
                    )
                  : null,
              onSchedule: visibleConsultants[i].consultantId.trim().isNotEmpty
                  ? () => _handleSchedule(
                      context,
                      ref,
                      visibleConsultants[i],
                    )
                  : null,
            ),
            if (i < visibleConsultants.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }

  void _handleViewProfile(BuildContext context, String consultantId) {
    final trimmedId = consultantId.trim();
    if (trimmedId.isEmpty) return;
    if (onViewProfile != null) {
      onViewProfile!(trimmedId);
      return;
    }
    GoRouter.maybeOf(context)?.push('/consult/$trimmedId');
  }

  void _handleSchedule(
    BuildContext context,
    WidgetRef ref,
    AiConsultantRecommendation consultant,
  ) {
    final trimmedId = consultant.consultantId.trim();
    if (trimmedId.isEmpty) return;
    final pkg = recommendedPackage;
    final resolvedPackageCode = consultant.selectedPackageCode.trim().isNotEmpty
        ? consultant.selectedPackageCode.trim()
        : (pkg?.packageCode.trim() ?? '');
    final resolvedTierLabel = consultant.tierLabel.trim().isNotEmpty
        ? consultant.tierLabel.trim()
        : (pkg?.packageTitle.trim().isNotEmpty == true
            ? pkg!.packageTitle.trim()
            : (pkg?.categoryTag.trim() ?? ''));
    final resolvedUnitPrice = consultant.unitPrice > 0
        ? consultant.unitPrice
        : (pkg?.priceIdr ?? 0.0);

    ref.read(bookingProvider.notifier).prefillFromAi(
      packageCode: resolvedPackageCode,
      selectedTierLabel: resolvedTierLabel,
      unitPrice: resolvedUnitPrice,
      topics: consultant.recommendedTopics,
      description: consultant.prefilledDescription.trim(),
      expectations: consultant.prefilledExpectations.trim(),
    );

    if (onSchedule != null) {
      onSchedule!(consultant);
      return;
    }
    GoRouter.maybeOf(context)?.push('/booking/$trimmedId/service');
  }
}

class _EmptyConsultantsCard extends StatelessWidget {
  final VoidCallback? onBrowseConsultants;

  const _EmptyConsultantsCard({this.onBrowseConsultants});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: NeoBrutalism.surfaceWarm,
        borderRadius: NeoBrutalism.radiusLg,
        shadowOffset: 3.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Belum ada konsultan tersedia',
            style: aiCardTextStyle(
              context,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: NeoBrutalism.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jadwal praktisi untuk paket ini sedang penuh. Buka daftar konsultan untuk melihat jadwal lainnya.',
            style: aiCardTextStyle(
              context,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4B5563),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          AiNeoActionButton(
            label: 'Lihat Semua Konsultan',
            backgroundColor: NeoBrutalism.lime,
            onTap:
                onBrowseConsultants ??
                () => GoRouter.maybeOf(context)?.go('/consult'),
          ),
        ],
      ),
    );
  }
}
