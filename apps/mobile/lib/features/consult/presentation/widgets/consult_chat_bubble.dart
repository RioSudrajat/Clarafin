import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/chat_message_model.dart';

class ConsultChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String consultantAvatar;

  const ConsultChatBubble({
    super.key,
    required this.message,
    required this.consultantAvatar,
  });

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (message.type == ChatMessageType.system) {
      return _buildSystemBubble();
    }
    final isUser = message.type == ChatMessageType.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ] else
            const SizedBox(width: 48),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildBubbleContent(isUser),
                const SizedBox(height: 4),
                _buildTimestampRow(isUser),
              ],
            ),
          ),
          if (!isUser) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSystemBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: ClipOval(
        child: Image.network(
          consultantAvatar,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: NeoBrutalism.lime,
            child: const Icon(Icons.person, size: 16, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleContent(bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isUser ? NeoBrutalism.lime : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isUser ? 14 : 2),
          bottomRight: Radius.circular(isUser ? 2 : 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: isUser ? FontWeight.w700 : FontWeight.w600,
              color: Colors.black,
              height: 1.4,
            ),
          ),
          if (message.attachmentName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_rounded, size: 16, color: Colors.black),
                  const SizedBox(width: 6),
                  Text(
                    message.attachmentName!,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimestampRow(bool isUser) {
    return Padding(
      padding: EdgeInsets.only(left: isUser ? 0 : 4, right: isUser ? 4 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(message.timestamp),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 4),
            const Icon(Icons.done_all_rounded, size: 14, color: Colors.black),
          ],
        ],
      ),
    );
  }
}
