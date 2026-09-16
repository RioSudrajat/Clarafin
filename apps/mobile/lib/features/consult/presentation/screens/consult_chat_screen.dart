import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/chat_message_model.dart';
import '../widgets/consult_chat_app_bar.dart';
import '../widgets/consult_chat_bubble.dart';
import '../widgets/consult_chat_input_bar.dart';
import '../widgets/consult_chat_typing_indicator.dart';

class ConsultChatScreen extends StatefulWidget {
  final String? consultantId;
  const ConsultChatScreen({super.key, this.consultantId});

  @override
  State<ConsultChatScreen> createState() => _ConsultChatScreenState();
}

class _ConsultChatScreenState extends State<ConsultChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  Timer? _typingTimer;
  int _cannedIndex = 0;

  static const String _avatarUrl =
      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=200&auto=format&fit=crop';

  final List<String> _quickReplies = [
    'Bagaimana cara lapor SPT 1770S?',
    'Alokasi dana darurat yang pas?',
    'Strategi investasi pemula',
  ];

  final List<String> _cannedResponses = [
    'Untuk SPT 1770S, kamu perlu menyiapkan bukti potong 1721-A1 dan rekap aset per 31 Desember. Saya siapkan panduannya ya! 📋',
    'Rekomendasi dana darurat untuk profil kamu adalah 3-6 bulan pengeluaran rutin, simpan di RDPU atau tabungan fleksibel 💡',
    'Untuk pemula, utamakan porsi 50-30-20 dan investasi berkala di index fund sebelum masuk instrumen high risk 📈',
  ];

  late final List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        id: 'msg_0',
        text: 'Sesi konsultasi resmi dimulai • Terverifikasi CFP® Halofin',
        type: ChatMessageType.system,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        id: 'msg_1',
        text: 'Halo Rio! 👋 Saya Maria dari Halofin. Dokumen pre-assessment kamu sudah saya review. Mari kita bahas rencanamu!',
        type: ChatMessageType.consultant,
        timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
      ChatMessage(
        id: 'msg_2',
        text: 'Halo Kak Maria! Terima kasih sudah bersedia membantu. Saya ingin memastikan cashflow bulanan dan strategi pajak investasi saya.',
        type: ChatMessageType.user,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      ChatMessage(
        id: 'msg_3',
        text: 'Tentu, portofolio reksa dana dan dividen sahammu sudah saya catat. Mau mulai dari breakdown pengeluaran atau optimalisasi pajak dulu?',
        type: ChatMessageType.consultant,
        timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
      ),
    ];
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          text: text.trim(),
          type: ChatMessageType.user,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            text: _cannedResponses[_cannedIndex % _cannedResponses.length],
            type: ChatMessageType.consultant,
            timestamp: DateTime.now(),
          ),
        );
        _cannedIndex++;
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: ConsultChatAppBar(
        onVideoCall: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menghubungkan ke Ruang Video Call terenkripsi...'),
              backgroundColor: Colors.black,
            ),
          );
        },
        onAudioCall: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menghubungkan ke Panggilan Suara Halofin...'),
              backgroundColor: Colors.black,
            ),
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const ConsultChatTypingIndicator(avatarUrl: _avatarUrl);
                }
                return ConsultChatBubble(
                  message: _messages[index],
                  consultantAvatar: _avatarUrl,
                );
              },
            ),
          ),
          ConsultChatInputBar(
            controller: _textController,
            focusNode: _focusNode,
            quickReplies: _quickReplies,
            onSend: _sendMessage,
            onAttach: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulasi lampiran dokumen (PDF/JPG) aktif.'),
                  backgroundColor: Colors.black,
                ),
              );
            },
            onQuickReplyTap: _sendMessage,
          ),
        ],
      ),
    );
  }
}
