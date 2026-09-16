import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class AiChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAiTyping;
  final ValueChanged<String> onSendMessage;

  const AiChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isAiTyping,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                decoration: const InputDecoration(
                  hintText: 'Tanya saran finansial...',
                  hintStyle: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Color(0xFF9CA3AF),
                    fontSize: 12.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (text) {
                  if (!isAiTyping && text.trim().isNotEmpty) {
                    onSendMessage(text);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, val, _) {
              final hasText = val.text.trim().isNotEmpty;
              final canSend = hasText && !isAiTyping;

              return InkWell(
                onTap: canSend ? () => onSendMessage(controller.text) : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: canSend ? NeoBrutalism.lime : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: canSend
                        ? const [
                            BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
                          ]
                        : null,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 22,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
