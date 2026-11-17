import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_consultant_avatar.dart';
import 'ai_recommendation_primitives.dart';

export 'ai_recommendation_primitives.dart' show AiNeoActionButton, AiNeoBadge;

/// Displays a recommended practitioner card with safe avatar fallback and actions.
class AiRecommendedConsultantCard extends StatelessWidget {
  final AiConsultantRecommendation consultant;
  final VoidCallback onViewProfile;
  final VoidCallback onSchedule;

  const AiRecommendedConsultantCard({
    super.key,
    required this.consultant,
    required this.onViewProfile,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final hasCerts = consultant.certifications.isNotEmpty;
    final hasTier = consultant.tierLabel.trim().isNotEmpty;
    final hasReason = consultant.matchReason.trim().isNotEmpty;
    final hasStats =
        consultant.ratingAvg > 0 || consultant.totalSessionsCompleted > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: NeoBrutalism.radiusLg,
        shadowOffset: 3.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AiConsultantAvatar(
                name: consultant.name,
                avatarUrl: consultant.avatarUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultant.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: aiCardTextStyle(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: NeoBrutalism.dark,
                        height: 1.25,
                      ),
                    ),
                    if (hasCerts) ...[
                      const SizedBox(height: 2),
                      Text(
                        consultant.certifications.join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: aiCardTextStyle(
                          context,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: NeoBrutalism.teal,
                        ),
                      ),
                    ],
                    if (hasTier || consultant.isStaffPinned) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (hasTier)
                            AiNeoBadge(
                              label: consultant.tierLabel.trim(),
                              backgroundColor: _tierBgColor(consultant.tierLabel),
                            ),
                          if (consultant.isStaffPinned)
                            const AiNeoBadge(
                              label: 'Staff Curated',
                              backgroundColor: NeoBrutalism.teal,
                              textColor: Colors.white,
                              leadingIcon: Icons.verified_rounded,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hasStats) ...[const SizedBox(height: 10), _buildStatsRow(context)],
          if (hasReason) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: NeoBrutalism.surfaceWarm,
                borderRadius: BorderRadius.circular(10),
                border: NeoBrutalism.border(width: 1.5),
              ),
              child: Text(
                consultant.matchReason.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: aiCardTextStyle(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: NeoBrutalism.dark,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.schedule_rounded, size: 15, color: NeoBrutalism.teal),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Slot terdekat: ${aiResolveSlotLabel(consultant)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: aiCardTextStyle(
                    context,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: NeoBrutalism.dark,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final ratingText = consultant.ratingAvg.toStringAsFixed(2);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (consultant.ratingAvg > 0)
          Semantics(
            label: 'Rating $ratingText',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 3),
                Text(
                  ratingText,
                  style: aiCardTextStyle(
                    context,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: NeoBrutalism.dark,
                  ),
                ),
              ],
            ),
          ),
        if (consultant.totalSessionsCompleted > 0)
          Text(
            '${consultant.totalSessionsCompleted} sesi selesai',
            style: aiCardTextStyle(
              context,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B5563),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final textScale = aiEffectiveTextScale(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewBtn = AiNeoActionButton(
          label: 'Lihat Profil',
          backgroundColor: Colors.white,
          onTap: onViewProfile,
        );
        final scheduleBtn = AiNeoActionButton(
          label: 'Pilih & Jadwalkan',
          backgroundColor: NeoBrutalism.lime,
          onTap: onSchedule,
        );
        if (constraints.maxWidth < 260 || textScale >= 1.35) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [viewBtn, const SizedBox(height: 8), scheduleBtn],
          );
        }
        return Row(
          children: [
            Expanded(flex: 4, child: viewBtn),
            const SizedBox(width: 4),
            Expanded(flex: 6, child: scheduleBtn),
          ],
        );
      },
    );
  }

  static Color _tierBgColor(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.contains('premium')) return NeoBrutalism.lime;
    if (normalized.contains('medium')) return NeoBrutalism.mint;
    return NeoBrutalism.surfaceWarm;
  }
}
