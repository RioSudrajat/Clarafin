import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
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
  bool _hasAttended = false;
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
        text: 'Sesi konsultasi resmi dimulai • Terverifikasi CFP® Clarafin',
        type: ChatMessageType.system,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        id: 'msg_1',
        text: 'Halo Rio! 👋 Saya Maria dari Clarafin. Dokumen pre-assessment kamu sudah saya review. Mari kita bahas rencanamu!',
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

  void _showClosingNotesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.black, width: 2.0),
            left: BorderSide(color: Colors.black, width: 2.0),
            right: BorderSide(color: Colors.black, width: 2.0),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catatan Penutup Sesi Konsultasi',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: NeoBrutalism.lime, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black, width: 1.2)),
                    child: Text('3 BAGIAN RESMI', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bagian 1
              _buildNoteSection(
                number: '1',
                title: 'Temuan Masalah Finansial Utama',
                icon: Icons.search_rounded,
                content:
                    '• Rasio cicilan utang saat ini berada di angka 28% (mendekati batas aman 30%).\n• Terdeteksi pos pengeluaran gaya hidup & langganan tak terpakai sebesar Rp 1.450.000/bulan.\n• Dana darurat baru terisi 1,5 bulan pengeluaran rutin dari target ideal 6 bulan.',
              ),
              const SizedBox(height: 12),

              // Bagian 2
              _buildNoteSection(
                number: '2',
                title: 'Rekomendasi Rencana Aksi (30 Hari)',
                icon: Icons.checklist_rounded,
                content:
                    '• Setop cicilan PayLater baru dan gunakan metode Debt Avalanche untuk melunasi bunga tertinggi.\n• Pangkas langganan streaming tak aktif dan alihkan Rp 1.000.000 ke RDPU Dana Darurat.\n• Buka rekening terpisah khusus operasional bulanan vs tabungan.',
              ),
              const SizedBox(height: 12),

              // Bagian 3
              _buildNoteSection(
                number: '3',
                title: 'Catatan Alokasi Aset & Tindak Lanjut',
                icon: Icons.trending_up_rounded,
                content:
                    '• Evaluasi polis asuransi unit link ke proteksi murni tradisional dalam 60 hari.\n• Batas maksimal plafon cicilan KPR masa depan adalah Rp 4.800.000/bulan.\n• Jadwal sesi evaluasi progres direkomendasikan pada H+30.',
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeoBrutalism.lime,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Tutup Catatan', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteSection({required String number, required String title, required IconData icon, required String content}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: Color(0xFF0F758A), shape: BoxShape.circle),
                child: Center(
                  child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF374151), height: 1.4)),
        ],
      ),
    );
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
              content: Text('Menghubungkan ke Panggilan Suara Clarafin...'),
              backgroundColor: Colors.black,
            ),
          );
        },
      ),
      body: Column(
        children: [
          // Pinned Session Header: Attendance ("Hadir") & Closing Notes Trigger
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(bottom: BorderSide(color: Colors.black, width: 1.5)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  'Sesi Aktif: 12:45 / 60:00',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F758A)),
                ),
                const Spacer(),
                // "Hadir" Confirmation Button
                if (!_hasAttended)
                  GestureDetector(
                    onTap: () {
                      setState(() => _hasAttended = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kehadiran Anda berhasil dikonfirmasi tepat waktu!'),
                          backgroundColor: Color(0xFF0F758A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NeoBrutalism.lime,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 13, color: Colors.black),
                          const SizedBox(width: 4),
                          Text('Hadir', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_rounded, size: 13, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text('Hadir', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF065F46))),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),

                // 3-Part Closing Notes Button
                GestureDetector(
                  onTap: _showClosingNotesSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 13, color: Colors.black),
                        const SizedBox(width: 4),
                        Text('Catatan', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.black)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

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
