enum ChatMessageType {
  system,
  consultant,
  user,
}

class ChatMessage {
  final String id;
  final String text;
  final ChatMessageType type;
  final DateTime timestamp;
  final String? attachmentName;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    this.attachmentName,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    ChatMessageType? type,
    DateTime? timestamp,
    String? attachmentName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      attachmentName: attachmentName ?? this.attachmentName,
    );
  }
}
