import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class ExpertHelpBannerCarousel extends StatefulWidget {
  const ExpertHelpBannerCarousel({super.key});

  @override
  State<ExpertHelpBannerCarousel> createState() => _ExpertHelpBannerCarouselState();
}

class _ExpertHelpBannerCarouselState extends State<ExpertHelpBannerCarousel> {
  int _bannerPage = 0;
  late final PageController _bannerController = PageController();

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          SizedBox(
            height: 162,
            child: PageView(
              controller: _bannerController,
              clipBehavior: Clip.none,
              physics: const PageScrollPhysics(),
              onPageChanged: (i) => setState(() => _bannerPage = i),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: _buildBannerCard(
                    tag: 'EXPERT HELP',
                    title: 'Bingung mencari konsultan?',
                    buttonText: 'MATCH',
                    onTap: () => context.go('/consult'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: _buildBannerCard(
                    tag: 'AI ADVISOR',
                    title: 'Analisis budgeting kamu dengan AI',
                    buttonText: 'TRY NOW',
                    onTap: () => context.push('/session'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Banner Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _bannerPage == i ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _bannerPage == i ? NeoBrutalism.dark : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard({
    required String tag,
    required String title,
    required String buttonText,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoBrutalism.mint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: NeoBrutalism.shadow(yOffset: 4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 13, color: NeoBrutalism.dark),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.dark,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: NeoBrutalism.lime,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: NeoBrutalism.shadow(yOffset: 2),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Large White Circle Badge on the right
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: NeoBrutalism.shadow(yOffset: 2),
            ),
            child: const Icon(Icons.groups_outlined, size: 30, color: NeoBrutalism.dark),
          ),
        ],
      ),
    );
  }
}
