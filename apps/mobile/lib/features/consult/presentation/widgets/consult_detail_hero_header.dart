import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/consultant.dart';

class ConsultDetailHeroHeader extends StatelessWidget {
  final Consultant consultant;

  const ConsultDetailHeroHeader({
    super.key,
    required this.consultant,
  });

  @override
  Widget build(BuildContext context) {
    final topSafeArea = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 300 + topSafeArea,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Consultant Avatar Background
          Image.network(
            consultant.avatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.person_rounded, size: 80, color: Colors.grey),
              ),
            ),
          ),

          // 2. Gradient Overlay for readability
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black54,
                  Colors.transparent,
                  Colors.black87,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // 3. Top Action Buttons (Back, Share, Bookmark)
          Positioned(
            top: topSafeArea + 8,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleAction(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => context.pop(),
                ),
                Row(
                  children: [
                    _buildCircleAction(
                      icon: Icons.share_rounded,
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),
                    _buildCircleAction(
                      icon: Icons.favorite_border_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Bottom Info Overlay (Name, Title, Verified Pill)
          Positioned(
            bottom: 34,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        consultant.name,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${consultant.title} • ${consultant.credentials}',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: NeoBrutalism.lime,
                    borderRadius: BorderRadius.circular(9999),
                    border: NeoBrutalism.border(width: 2.0),
                    boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 14, color: NeoBrutalism.dark),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: NeoBrutalism.border(width: 2.0),
          boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
        ),
        child: Center(
          child: Icon(icon, size: 20, color: NeoBrutalism.dark),
        ),
      ),
    );
  }
}
