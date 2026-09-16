import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/ai_chat_bubble.dart';
import '../widgets/ai_chat_input_bar.dart';
import '../widgets/ai_chat_welcome_widget.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<AiChatMessage> _messages = [];
  bool _isAiTyping = false;
  int _responseIndex = 0;

  final List<String> _aiResponses = [
    'Berdasarkan data keuanganmu, alokasi kebutuhan pokokmu sudah optimal (45%). Namun pos hiburan masih di atas batas 20%. Sebaiknya buat pagu maksimal Rp 1.500.000 untuk bulan depan.',
    'Untuk persiapan dana darurat, idealnya siapkan 3-6 kali pengeluaran bulanan. Simpan di instrumen likuid seperti Reksa Dana Pasar Uang atau Deposito Bank Digital terpercaya.',
    'Target tabunganmu bisa tercapai lebih cepat jika kamu mengaktifkan fitur auto-debit setiap awal gajian. Mau saya bantu simulasikan nominal tabungan per bulan?',
    'Metode pelunasan utang yang paling disarankan adalah Debt Avalanche (bunga tertinggi lebih dulu) atau Snowball (nominal terkecil lebih dulu untuk dorongan psikologis).',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(AiChatMessage(text: text.trim(), isUser: true));
      _textController.clear();
      _isAiTyping = true;
    });

    _scrollToBottom();

    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isAiTyping = false;
        _messages.add(AiChatMessage(
          text: _aiResponses[_responseIndex % _aiResponses.length],
          isUser: false,
        ));
        _responseIndex++;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: NeoBrutalism.lime,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.black),
            ),
            const SizedBox(width: 8),
            const Text(
              'Clarafin AI',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black, size: 22),
            tooltip: 'Mulai Ulang Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _responseIndex = 0;
                _isAiTyping = false;
              });
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: Colors.black, height: 2.0),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? AiChatWelcomeWidget(onSelectPrompt: _sendMessage)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _messages.length + (_isAiTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isAiTyping) {
                          return _buildTypingCard();
                        }
                        return AiChatBubble(message: _messages[index]);
                      },
                    ),
            ),
            AiChatInputBar(
              controller: _textController,
              focusNode: _focusNode,
              isAiTyping: _isAiTyping,
              onSendMessage: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                ),
                SizedBox(width: 8),
                Text(
                  'Clarafin sedang menganalisa...',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
