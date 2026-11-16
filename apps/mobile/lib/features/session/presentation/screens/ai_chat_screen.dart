import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/ai_quota_provider.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/ai_chat_bubble.dart';
import '../widgets/ai_chat_input_bar.dart';
import '../widgets/ai_chat_welcome_widget.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<AiChatMessage> _messages = [];
  bool _isAiTyping = false;
  int _responseIndex = 0;

  final List<Map<String, dynamic>> _aiResponses = [
    {
      'text':
          'Berdasarkan tinjauan alokasi bulananmu, porsi pengeluaran pokok berada di angka 45% (sehat). Porsi hiburan dan keinginan sedikit melebihi pagu 20%. Kamu bisa membatasi pengeluaran gaya hidup di angka maksimal Rp 1.500.000 agar alokasi tabungan tetap terjaga.',
      'cta': null,
    },
    {
      'text':
          'Secara konsep umum, metode pelunasan pinjaman terdiri dari Debt Snowball (fokus ke nominal terkecil untuk motivasi psikologis) dan Debt Avalanche (fokus ke suku bunga tertinggi untuk efisiensi bunga).\n\n⚠️ Batas Kepatuhan AI Clarafin:\nPerencanaan skema restrukturisasi utang yang mengikat dan pemilihan instrumen konsolidasi pinjaman memerlukan konsultasi mendalam dengan Certified Financial Planner (CFP®) berlisensi.',
      'cta': 'Lihat Praktisi Rekomendasi',
      'route': '/consult',
    },
    {
      'text':
          'Untuk persiapan dana darurat, formula ideal bagi lajang adalah 3–6 kali pengeluaran bulanan rutin. Karakteristik wadah dana darurat yang baik adalah likuid, berisiko rendah, dan mudah dicairkan sewaktu-waktu.\n\n⚠️ Batas Kepatuhan AI Clarafin:\nClarafin AI tidak menjual atau memilihkan produk investasi spesifik (seperti reksa dana atau deposito perbankan tertentu). Penyesuaian profil risiko wajib diverifikasi oleh konsultan perencana keuangan berizin.',
      'cta': 'Lihat Praktisi Rekomendasi',
      'route': '/consult',
    },
    {
      'text':
          'Target tabunganmu untuk liburan atau dana pendidikan dapat dioptimalkan dengan pembagian rekening terpisah (envelope budgeting) dan auto-debit berkala setiap tanggal gajian.',
      'cta': null,
    },
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

    ref.read(aiQuotaProvider.notifier).useQuota();
    final userQuery = text.trim();
    setState(() {
      _messages.add(AiChatMessage(text: userQuery, isUser: true));
      _textController.clear();
      _isAiTyping = true;
    });

    _scrollToBottom();

    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

      final respData = _aiResponses[_responseIndex % _aiResponses.length];
      _responseIndex++;

      setState(() {
        _isAiTyping = false;
        _messages.add(
          AiChatMessage(
            text: respData['text'] as String,
            isUser: false,
            ctaLabel: respData['cta'] as String?,
            ctaRoute: respData['route'] as String?,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 140,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiQuota = ref.watch(aiQuotaProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0F758A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeoBrutalism.brandGradient,
        ),
        child: Column(
          children: [
            // Pinned Neo-Brutalist Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: NeoBrutalism.border(width: 2.0),
                          boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_rounded, size: 22, color: NeoBrutalism.dark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Robot Icon
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: NeoBrutalism.primary,
                        borderRadius: BorderRadius.circular(8),
                        border: NeoBrutalism.border(width: 1.5),
                      ),
                      child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Clarafin AI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),

                    // Free AI Quota Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: NeoBrutalism.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: NeoBrutalism.border(width: 1.5),
                        boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 13, color: Colors.black),
                          const SizedBox(width: 3),
                          Text(
                            aiQuota.displayQuotaBadge,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Reset button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _messages.clear();
                          _responseIndex = 0;
                          _isAiTyping = false;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: NeoBrutalism.border(width: 1.8),
                          boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.refresh_rounded, size: 18, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main White Container with Curvature
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 2.0),
                    left: BorderSide(color: Colors.black, width: 2.0),
                    right: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
              ),
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
              color: NeoBrutalism.surfaceWarm,
              borderRadius: BorderRadius.circular(10),
              border: NeoBrutalism.border(width: 1.5),
              boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                ),
                const SizedBox(width: 8),
                Text(
                  'Clarafin sedang menganalisa...',
                  style: GoogleFonts.plusJakartaSans(
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
