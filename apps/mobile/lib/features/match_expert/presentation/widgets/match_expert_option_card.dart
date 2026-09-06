import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/match_expert_models.dart';

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isGrid ? 14 : 16,
          vertical: isGrid ? 16 : 14,
        ),
        decoration: BoxDecoration(
          color: isSelected ? NeoBrutalism.lime : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: isSelected
              ? NeoBrutalism.shadow(yOffset: 3, xOffset: 2)
              : NeoBrutalism.shadow(yOffset: 2, xOffset: 1),
        ),
        child: isGrid ? _buildGridLayout() : _buildListLayout(),
      ),
    );
  }

  Widget _buildListLayout() {
    return Row(
      children: [
        _buildLeadingWidget(),
        if (_hasLeading) const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                option.title,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: NeoBrutalism.dark,
                  height: 1.25,
                ),
              ),
              if (option.subtitle != null && option.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  option.subtitle!,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: NeoBrutalism.dark.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        _buildSelectorIndicator(),
      ],
    );
  }

  Widget _buildGridLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingWidget(),
            _buildSelectorIndicator(),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option.title,
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
            if (option.subtitle != null && option.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                option.subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: NeoBrutalism.dark.withValues(alpha: 0.7),
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  bool get _hasLeading =>
      option.emoji != null || option.icon != null || option.flagCode != null;

  Widget _buildLeadingWidget() {
    if (option.emoji != null) {
      return Text(
        option.emoji!,
        style: const TextStyle(fontSize: 24),
      );
    }
    if (option.flagCode != null) {
      return Container(
        width: 30,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          option.flagCode!,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: NeoBrutalism.dark,
          ),
        ),
      );
    }
    if (option.icon != null) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Icon(
          option.icon,
          size: 20,
          color: NeoBrutalism.dark,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSelectorIndicator() {
    final isMulti = selectionType == SelectionType.multi;
    const size = 22.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? NeoBrutalism.dark : Colors.white,
        shape: isMulti ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isMulti ? BorderRadius.circular(6) : null,
        border: Border.all(color: Colors.black, width: 1.8),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
