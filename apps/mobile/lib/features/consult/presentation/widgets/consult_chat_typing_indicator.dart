import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class ConsultChatTypingIndicator extends StatefulWidget {
  final String avatarUrl;

  const ConsultChatTypingIndicator({
    super.key,
    required this.avatarUrl,
  });

  @override
  State<ConsultChatTypingIndicator> createState() => _ConsultChatTypingIndicatorState();
}

class _ConsultChatTypingIndicatorState extends State<ConsultChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = ((_controller.value + delay) % 1.0);
        final y = -4.0 * (1.0 - (2.0 * t - 1.0) * (2.0 * t - 1.0));
        return Transform.translate(
          offset: Offset(0, y),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2.0),
            ),
            child: ClipOval(
              child: Image.network(
                widget.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: NeoBrutalism.lime,
                  child: const Icon(Icons.person, size: 16, color: Colors.black),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
                bottomLeft: Radius.circular(2),
              ),
              border: Border.all(color: Colors.black, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0.0),
                const SizedBox(width: 4),
                _buildDot(0.2),
                const SizedBox(width: 4),
                _buildDot(0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
