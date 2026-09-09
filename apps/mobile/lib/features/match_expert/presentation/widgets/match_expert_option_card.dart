import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/match_expert_models.dart';
import 'match_expert_doodle_icons.dart';

class MatchExpertOptionCard extends StatelessWidget {
  final MatchExpertOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final SelectionType selectionType;
  final bool isGrid;

  const MatchExpertOptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.selectionType = SelectionType.single,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints(
          minHeight: isGrid ? 0 : 64,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black,
            width: isSelected ? 2.2 : 2.0,
          ),
          boxShadow: isSelected
              ? NeoBrutalism.shadow(yOffset: 3, xOffset: 2)
              : NeoBrutalism.shadow(yOffset: 2, xOffset: 1),
        ),
        child: isGrid ? _buildGridCard() : _buildListCard(),
      ),
    );
  }

  Widget _buildGridCard() {
    return Column(
      children: [
        // Upper section: Pure white background with centered large icon
        Expanded(
          child: Center(
            child: _buildIconWidget(size: 60),
          ),
        ),
        // Lower section: Soft tinted or lime banner with centered title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? NeoBrutalism.lime
                : const Color(0xFFEAF2F6),
            border: Border(
              top: BorderSide(
                color: isSelected
                    ? Colors.black.withValues(alpha: 0.15)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            option.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: NeoBrutalism.dark,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListCard() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left section: Pure white background with centered icon
          Container(
            width: 76,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: _buildIconWidget(size: 44),
          ),
          // Right section: Soft tinted or lime banner with left-aligned title
          Expanded(
            child: Container(
              color: isSelected
                  ? NeoBrutalism.lime
                  : const Color(0xFFEAF2F6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              alignment: Alignment.centerLeft,
              child: Text(
                option.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: NeoBrutalism.dark,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconWidget({required double size}) {
    final key = option.svgKey ?? option.id;
    if (MatchExpertDoodleIcons.hasSvg(key)) {
      return MatchExpertDoodleWidget(
        svgKey: key,
        isSelected: isSelected,
        size: size,
      );
    }
    if (option.icon != null) {
      return Icon(
        option.icon,
        size: size,
        color: isSelected ? NeoBrutalism.lime : NeoBrutalism.dark,
      );
    }
    if (option.emoji != null) {
      return Text(
        option.emoji!,
        style: TextStyle(fontSize: size * 0.9),
      );
    }
    if (option.flagCode != null) {
      return Container(
        width: 32,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? NeoBrutalism.lime : Colors.black,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          option.flagCode!,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? NeoBrutalism.lime : NeoBrutalism.dark,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
