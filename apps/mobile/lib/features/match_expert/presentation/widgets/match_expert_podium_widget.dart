import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/match_expert_models.dart';

class MatchExpertPodiumWidget extends StatelessWidget {
  final List<MatchedConsultant> consultants;
  final String? selectedId;
  final void Function(String consultantId) onSelectConsultant;

  const MatchExpertPodiumWidget({
    super.key,
    required this.consultants,
    required this.selectedId,
    required this.onSelectConsultant,
  });

  @override
  Widget build(BuildContext context) {
    if (consultants.length < 3) return const SizedBox.shrink();

    // Order: Rank 2 (left), Rank 1 (center), Rank 3 (right)
    final rank1 = consultants[0];
    final rank2 = consultants[1];
    final rank3 = consultants[2];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Rank 2 (Left)
          Expanded(
            child: _buildPodiumColumn(
              consultant: rank2,
              rank: 2,
              podiumHeight: 90,
              pedestalColor: const Color(0xFFE2E8F0),
              badgeColor: const Color(0xFF94A3B8),
              isSelected: selectedId == rank2.id,
            ),
          ),
          const SizedBox(width: 8),

          // Rank 1 (Center - Tallest)
          Expanded(
            child: _buildPodiumColumn(
              consultant: rank1,
              rank: 1,
              podiumHeight: 120,
              pedestalColor: NeoBrutalism.lime,
              badgeColor: const Color(0xFFF59E0B), // Golden yellow
              isWinner: true,
              isSelected: selectedId == rank1.id,
            ),
          ),
          const SizedBox(width: 8),

          // Rank 3 (Right)
          Expanded(
            child: _buildPodiumColumn(
              consultant: rank3,
              rank: 3,
              podiumHeight: 70,
              pedestalColor: const Color(0xFFFFE4E6), // Soft coral/rose
              badgeColor: const Color(0xFFF97316), // Orange
              isSelected: selectedId == rank3.id,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required MatchedConsultant consultant,
    required int rank,
    required double podiumHeight,
    required Color pedestalColor,
    required Color badgeColor,
    required bool isSelected,
    bool isWinner = false,
  }) {
    return GestureDetector(
      onTap: () => onSelectConsultant(consultant.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Winner Crown if Rank 1
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.workspace_premium, color: Color(0xFFFBBF24), size: 28),
            )
          else
            const SizedBox(height: 32),

          // Avatar Stack
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Avatar Circle
              Container(
                width: isWinner ? 72 : 62,
                height: isWinner ? 72 : 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.black87,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: isSelected
                      ? NeoBrutalism.shadow(yOffset: 3, xOffset: 1)
                      : [],
                ),
                child: ClipOval(
                  child: Image.network(
                    consultant.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        consultant.name.isNotEmpty ? consultant.name[0] : 'C',
                        style: TextStyle(
                          fontSize: isWinner ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Match % Pill
              Positioned(
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isWinner ? NeoBrutalism.lime : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: NeoBrutalism.shadow(yOffset: 1, xOffset: 1),
                  ),
                  child: Text(
                    '${consultant.matchPercentage}%',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Consultant Name
          Text(
            consultant.name.split(',')[0],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // Pedestal Block
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: podiumHeight,
            decoration: BoxDecoration(
              color: pedestalColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border.all(
                color: Colors.black,
                width: isSelected ? 2.5 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, isSelected ? 4 : 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
