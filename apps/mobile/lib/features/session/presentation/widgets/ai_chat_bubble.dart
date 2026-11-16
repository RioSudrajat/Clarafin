import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? ctaLabel;
  final String? ctaRoute;

  AiChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.ctaLabel,
    this.ctaRoute,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiChatBubble extends StatelessWidget {
  final AiChatMessage message;

  const AiChatBubble({super.key, required this.message});

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: NeoBrutalism.primary,
                shape: BoxShape.circle,
                border: NeoBrutalism.border(width: 1.8),
                boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.smart_toy_rounded, size: 18, color: Colors.black),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? NeoBrutalism.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: isUser ? const Radius.circular(14) : const Radius.circular(3),
                      bottomRight: isUser ? const Radius.circular(3) : const Radius.circular(14),
                    ),
                    border: NeoBrutalism.border(width: 1.8),
                    boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isUser ? FontWeight.w700 : FontWeight.w500,
                          color: Colors.black,
                          height: 1.45,
                        ),
                      ),
                      if (message.ctaLabel != null) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            if (message.ctaRoute != null) {
                              context.push(message.ctaRoute!);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: NeoBrutalism.primary,
                              borderRadius: BorderRadius.circular(10),
                              border: NeoBrutalism.border(width: 1.5),
                              boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.ctaLabel!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: NeoBrutalism.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 24),
        ],
      ),
    );
  }
}
