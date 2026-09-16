import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class ConsultChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> quickReplies;
  final ValueChanged<String> onSend;
  final VoidCallback onAttach;
  final ValueChanged<String> onQuickReplyTap;

  const ConsultChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.quickReplies,
    required this.onSend,
    required this.onAttach,
    required this.onQuickReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quickReplies.isNotEmpty) _buildQuickRepliesBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  _buildAttachButton(),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInputField()),
                  const SizedBox(width: 8),
                  _buildSendButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRepliesBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: quickReplies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = quickReplies[index];
          return InkWell(
            onTap: () => onQuickReplyTap(reply),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Text(
                reply,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttachButton() {
    return InkWell(
      onTap: onAttach,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(0, 1.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Icon(Icons.attach_file_rounded, color: Colors.black, size: 20),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        maxLines: 3,
        minLines: 1,
        decoration: const InputDecoration(
          hintText: 'Tulis pesan konsultasi...',
          hintStyle: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: Color(0xFF9CA3AF),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return InkWell(
      onTap: () => onSend(controller.text),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: NeoBrutalism.lime,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(0, 1.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
      ),
    );
  }
}
