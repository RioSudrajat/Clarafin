import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/models/consultant.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

class BookingClientConsultantCard extends ConsumerWidget {
  final String consultantId;

  const BookingClientConsultantCard({
    super.key,
    required this.consultantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultant = ConsultantRepository.getById(consultantId) ??
        ConsultantRepository.initialConsultants.first;
    final userProfile = ref.watch(userProfileProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: Column(
        children: [
          _buildPersonRow(
            avatarUrl: consultant.avatarUrl,
            badgeLabel: 'Konsultan',
            badgeBg: const Color(0xFF0F758A),
            badgeTextColor: Colors.white,
            name: consultant.name,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFF3F4F6), height: 1, thickness: 1),
          ),
          _buildPersonRow(
            avatarUrl: userProfile.avatarUrl,
            badgeLabel: 'Diri Sendiri',
            badgeBg: const Color(0xFFE0F2F6),
            badgeTextColor: const Color(0xFF0F758A),
            name: userProfile.name.isNotEmpty ? userProfile.name : 'Rio Sudrajat',
          ),
        ],
      ),
    );
  }

  Widget _buildPersonRow({
    required String avatarUrl,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeTextColor,
    required String name,
  }) {
    return Row(
      children: [
        UserAvatar(
          avatarUrl: avatarUrl,
          size: 46,
          borderWidth: 1.5,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: badgeTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
