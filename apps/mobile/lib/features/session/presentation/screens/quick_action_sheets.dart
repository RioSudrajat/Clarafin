import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/models/transaction_model.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

class _DraftTransaction {
  String title;
  double amount;
  String category;
  String walletId;
  String walletName;
  String type;

  _DraftTransaction({
    required this.title,
    required this.amount,
    required this.category,
    required this.walletId,
    required this.walletName,
    required this.type,
  });
}

class _QuickChatMessage {
  final String text;
  final bool isUser;
  final _DraftTransaction? draft;
  bool isConfirmed = false;
  bool isCancelled = false;

  _QuickChatMessage({
    required this.text,
    required this.isUser,
    this.draft,
  });
}

// ─── Entry Point function ───────────────────────────────────────────────────

void showQuickActionMenuSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _QuickActionMenuSheet(parentRef: ref),
  );
}

// ─── Quick Action Menu Sheet Widget ──────────────────────────────────────────

class _QuickActionMenuSheet extends ConsumerWidget {
  final WidgetRef parentRef;
  const _QuickActionMenuSheet({required this.parentRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limits = ref.watch(quickActionLimitProvider);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Catat Transaksi Cepat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih metode paling efisien untuk catat keuanganmu.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),

            // Grid list of quick actions (2x2 grid)
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.15,
              children: [
                _buildActionGridItem(
                  context,
                  ref,
                  emoji: '💬',
                  title: 'AI Chat Action',
                  subtitle: 'Ketik lewat asisten AI',
                  limitText: 'Quota: ${limits.aiChatCount}/10',
                  isLimited: limits.aiChatCount >= 10,
                  onTap: () {
                    Navigator.pop(context);
                    if (limits.aiChatCount >= 10) {
                      _showPremiumUpgradeSheet(context, 'AI Chat Quick Action');
                    } else {
                      _showAiChatQuickSheet(context, parentRef);
                    }
                  },
                ),
                _buildActionGridItem(
                  context,
                  ref,
                  emoji: '🎙️',
                  title: 'Voice AI Action',
                  subtitle: 'Ucapkan ke asisten AI',
                  limitText: 'Quota: ${limits.voiceAiCount}/5',
                  isLimited: limits.voiceAiCount >= 5,
                  onTap: () {
                    Navigator.pop(context);
                    if (limits.voiceAiCount >= 5) {
                      _showPremiumUpgradeSheet(context, 'Voice AI Action');
                    } else {
                      _showVoiceAiSheet(context, parentRef);
                    }
                  },
                ),
                _buildActionGridItem(
                  context,
                  ref,
                  emoji: '📸',
                  title: 'Scan Action (OCR)',
                  subtitle: 'Foto struk belanja untuk scan',
                  limitText: 'Quota: ${limits.scanCount}/8',
                  isLimited: limits.scanCount >= 8,
                  onTap: () {
                    Navigator.pop(context);
                    if (limits.scanCount >= 8) {
                      _showPremiumUpgradeSheet(context, 'Scan Action (OCR)');
                    } else {
                      _showOcrScanSheet(context, parentRef);
                    }
                  },
                ),
                _buildActionGridItem(
                  context,
                  ref,
                  emoji: '📝',
                  title: 'Manual Add',
                  subtitle: 'Isi formulir manual lengkap',
                  limitText: 'Unlimited',
                  isLimited: false,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/transaction/entry');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGridItem(
    BuildContext context,
    WidgetRef ref, {
    required String emoji,
    required String title,
    required String subtitle,
    required String limitText,
    required bool isLimited,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        limitText,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Premium Upgrade Sheet ───────────────────────────────────────────────────

void _showPremiumUpgradeSheet(BuildContext context, String featureName) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            // Premium icon with glow
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            const Text(
              'Oops, Kuota Lo Habis! 🔒',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lo sudah mencapai limit gratis untuk $featureName minggu ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            
            // Gold card listing advantages
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7).withValues(alpha: 0.5)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              ),
              child: Column(
                children: [
                  _buildBenefitRow(Icons.all_inclusive_rounded, 'Akses Fitur Cepat Tanpa Batas'),
                  const SizedBox(height: 10),
                  _buildBenefitRow(Icons.sync_rounded, 'Sinkronisasi Otomatis Bank & E-Wallet'),
                  const SizedBox(height: 10),
                  _buildBenefitRow(Icons.analytics_rounded, 'Laporan Keuangan AI Mendalam'),
                ],
              ),
            ),
            
            const SizedBox(height: 28),
            
            // Upgrade button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B), // Premium Dark
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Terima kasih! Kamu sekarang terdaftar di Clarafin Premium 🚀'),
                      backgroundColor: Color(0xFFD97706),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text(
                  'Upgrade ke Premium — Rp 49.000 / bln',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Tunggu 1 Minggu (Reset Otomatis)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildBenefitRow(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xFFD97706)),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF78350F),
          ),
        ),
      ),
    ],
  );
}

// ─── Redesigned AI Chat Quick Action Modal (Fundy-style Photo) ───────────────

void _showAiChatQuickSheet(BuildContext context, WidgetRef parentRef) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(ctx).size.height * 0.72, // Shorter and more compact top card
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: _AiQuickChatModal(parentRef: parentRef),
      );
    },
  );
}

class _AiQuickChatModal extends StatefulWidget {
  final WidgetRef parentRef;
  const _AiQuickChatModal({required this.parentRef});

  @override
  State<_AiQuickChatModal> createState() => _AiQuickChatModalState();
}

class _AiQuickChatModalState extends State<_AiQuickChatModal> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isProcessing = false;
  final List<_QuickChatMessage> _messages = [];

  final List<String> _samplePrompts = [
    'Berapa saldo saya?',
    'Pengeluaran bulan ini berapa?',
    'Pemasukan vs pengeluaran bulan ini?',
  ];

  @override
  void initState() {
    super.initState();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _processInput(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(_QuickChatMessage(text: text.trim(), isUser: true));
      _isProcessing = true;
    });
    
    _controller.clear();
    _scrollToBottom();

    // Simulate AI response delay
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      final lowerText = text.toLowerCase();
      
      // Check for prompt replies or extraction
      if (lowerText.contains('saldo')) {
        final wallets = widget.parentRef.read(walletsProvider);
        final total = wallets.fold<double>(0, (sum, w) => sum + w.balance);
        setState(() {
          _isProcessing = false;
          _messages.add(_QuickChatMessage(
            text: 'Saldo kamu saat ini adalah Rp ${total.toInt()} di semua dompet terhubung.',
            isUser: false,
          ));
        });
      } else if (lowerText.contains('pengeluaran')) {
        setState(() {
          _isProcessing = false;
          _messages.add(_QuickChatMessage(
            text: 'Pengeluaran kamu bulan ini adalah Rp 3.041.000, terbagi di kategori Makanan, Belanja, dan Tagihan.',
            isUser: false,
          ));
        });
      } else if (lowerText.contains('pemasukan vs')) {
        setState(() {
          _isProcessing = false;
          _messages.add(_QuickChatMessage(
            text: 'Pemasukan kamu bulan ini Rp 15.000.000 vs Pengeluaran Rp 3.041.000. Keuangan kamu sehat! 📈',
            isUser: false,
          ));
        });
      } else {
        // Assume extraction request
        String title = 'Makan Pizza';
        String category = 'Makanan';
        double amount = 200000;
        String type = 'expense';
        String walletId = 'w1'; // BCA
        String walletName = 'BCA Utama';

        if (lowerText.contains('kopi') || lowerText.contains('starbucks')) {
          title = 'Kopi Starbucks';
          category = 'Makanan';
          amount = 50000;
          walletId = 'w4';
          walletName = 'Dompet Tunai';
        } else if (lowerText.contains('gaji')) {
          title = 'Gaji Bulanan';
          category = 'Gaji';
          amount = 15000000;
          type = 'income';
          walletId = 'w1';
          walletName = 'BCA Utama';
        } else if (lowerText.contains('listrik')) {
          title = 'Tagihan Listrik';
          category = 'Tagihan';
          amount = 300000;
          walletId = 'w1';
          walletName = 'BCA Utama';
        } else {
          // generic fallback numbers
          final numberMatch = RegExp(r'\d+').firstMatch(lowerText);
          if (numberMatch != null) {
            final digits = numberMatch.group(0)!;
            double multiplier = 1.0;
            if (lowerText.contains('k') || lowerText.contains('rb') || lowerText.contains('ribu')) {
              multiplier = 1000.0;
            } else if (lowerText.contains('mas mas') || lowerText.contains('jt') || lowerText.contains('juta')) {
              multiplier = 1000000.0;
            }
            amount = double.tryParse(digits)! * multiplier;
          }
          title = text.length > 20 ? '${text.substring(0, 20)}...' : text;
          if (lowerText.contains('masuk') || lowerText.contains('gaji')) {
            type = 'income';
          }
        }

        final draft = _DraftTransaction(
          title: title,
          amount: amount,
          category: category,
          walletId: walletId,
          walletName: walletName,
          type: type,
        );

        setState(() {
          _isProcessing = false;
          _messages.add(_QuickChatMessage(
            text: 'Gue buatin draf transaksi ${type == 'income' ? 'Pemasukan' : 'Pengeluaran'} ya. Silakan konfirmasi di bawah:',
            isUser: false,
            draft: draft,
          ));
        });
      }
      _scrollToBottom();
    });
  }

  void _confirmDraft(_QuickChatMessage msg, _DraftTransaction draft) {
    // Add real transaction to mock providers!
    final tx = TransactionModel(
      id: 'tx_ai_quick_${DateTime.now().millisecondsSinceEpoch}',
      title: draft.title,
      category: draft.category,
      amount: draft.amount,
      date: DateTime.now(),
      type: draft.type,
      walletId: draft.walletId,
    );

    widget.parentRef.read(transactionsProvider.notifier).addTransaction(tx);
    widget.parentRef.read(quickActionLimitProvider.notifier).incrementAiChat();

    setState(() {
      msg.isConfirmed = true;
    });

    // AI confirmation feedback
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_QuickChatMessage(
          text: 'Transaksi "${draft.title}" sebesar Rp ${draft.amount.toInt()} berhasil disimpan secara riil ke ${draft.walletName}! 🎉',
          isUser: false,
        ));
      });
      _scrollToBottom();
    });
  }

  void _cancelDraft(_QuickChatMessage msg, _DraftTransaction draft) {
    setState(() {
      msg.isCancelled = true;
    });
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_QuickChatMessage(
          text: 'Draf transaksi dibatalkan.',
          isUser: false,
        ));
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CARD 1: Chat History & Suggestions Panel (Persis SS)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_messages.isEmpty) _buildSuggestionPanel(),
                          ..._messages.map((m) => _buildMessageBubble(m)),
                          if (_isProcessing) _buildTypingIndicator(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12), // GAP FISIK DI ANTARA KEDUA CARD (PERSIS SS!)
        
        // CARD 2: Input & Control Panel (Persis SS - Redesigned by Senior UI/UX Designer)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Full-width Input container (Sleek minimalist style)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200, width: 1.0),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isProcessing,
                  decoration: InputDecoration(
                    hintText: _isProcessing 
                        ? 'Sedang memproses request sebelumnya...' 
                        : 'Tanya Clara AI...',
                    hintStyle: const TextStyle(
                      fontSize: 13, 
                      color: Color(0xFF9CA3AF),
                      fontStyle: FontStyle.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (t) => _processInput(t),
                ),
              ),
              const SizedBox(height: 12),
              
              // Row of shortcuts + App primary colored action button (Senior UI/UX layout)
              Row(
                children: [
                  // Scan Button Shortcut (Elegant Pill)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showOcrScanSheet(context, widget.parentRef);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.01),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.document_scanner_outlined, size: 16, color: Color(0xFF4B5563)),
                          SizedBox(width: 6),
                          Text(
                            'Scan', 
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w600, 
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Bicara Button Shortcut (Elegant Pill with accessible Contrast)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showVoiceAiSheet(context, widget.parentRef);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.01),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.mic_none_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Bicara', 
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w600, 
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Primary Send button matching the brand's primary color with custom high-contrast square
                  GestureDetector(
                    onTap: () => _processInput(_controller.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Header Panel ──────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Robot Avatar Icon in rounded square matching photo using app's primary color
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_outlined, size: 22, color: Colors.black),
            ),
            const SizedBox(width: 12),
            // Name & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clara AI',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Close X Button
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Suggestions Panel ─────────────────────────────────────────────────────

  Widget _buildSuggestionPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            const Text(
              'TANYA DATA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _samplePrompts.map((p) {
            return InkWell(
              onTap: () => _processInput(p),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Text(
                  p,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Text(
          'Tanya data: tanya pakai bahasa biasa (saldo, pengeluaran, pemasukan, dll). - Pakai tombol Scan untuk struk/nota, Bicara untuk input suara.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── Bubble & Card Builder ─────────────────────────────────────────────────

  Widget _buildMessageBubble(_QuickChatMessage m) {
    if (m.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(width: 48),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF4C9A00), // Grass Green bubble matching photo perfectly
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Text(
                  m.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI message with possible draft review card
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    m.text,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),

                // Draft card if present
                if (m.draft != null) ...[
                  const SizedBox(height: 10),
                  _buildDraftCard(m, m.draft!),
                ],
              ],
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildDraftCard(_QuickChatMessage msg, _DraftTransaction draft) {
    if (msg.isConfirmed) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.shade200, width: 1.2),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text(
              'Draf Disimpan Secara Riil',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      );
    }

    if (msg.isCancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.shade200, width: 1.2),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Draf Transaksi Dibatalkan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'TINJAU DRAF TRANSAKSI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Details rows
          _buildDraftDetailRow('Transaksi', draft.title),
          _buildDraftDetailRow('Nominal', 'Rp ${draft.amount.toInt()}'),
          _buildDraftDetailRow('Kategori', draft.category),
          _buildDraftDetailRow('Metode', draft.walletName),
          _buildDraftDetailRow('Tipe', draft.type == 'income' ? 'Pemasukan' : 'Pengeluaran'),
          
          const SizedBox(height: 16),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _cancelDraft(msg, draft),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Batal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmDraft(msg, draft),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Konfirmasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraftDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }


}

// ─── Voice AI Action Sheet (with Review Panel workflow) ─────────────────────

void _showVoiceAiSheet(BuildContext context, WidgetRef parentRef) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _VoiceAiModal(parentRef: parentRef),
  );
}

class _VoiceAiModal extends StatefulWidget {
  final WidgetRef parentRef;
  const _VoiceAiModal({required this.parentRef});

  @override
  State<_VoiceAiModal> createState() => _VoiceAiModalState();
}

class _VoiceAiModalState extends State<_VoiceAiModal> {
  bool _isListening = false;
  String _speechText = 'Tekan mic dan ucapkan transaksi lo';
  bool _isProcessing = false;
  
  _DraftTransaction? _voiceDraft;
  bool _isConfirmed = false;
  bool _isCancelled = false;

  void _startListening() {
    setState(() {
      _isListening = true;
      _speechText = 'Mendengarkan... Ucapkan nominal & kategori';
      _voiceDraft = null;
      _isConfirmed = false;
      _isCancelled = false;
    });

    // Simulate listening done in 3s
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _isProcessing = true;
        _speechText = '"Makan siang Padang 35 ribu"';
      });

      // Process voice recognition mock
      Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;

        setState(() {
          _isProcessing = false;
          _voiceDraft = _DraftTransaction(
            title: 'Makan Siang Padang',
            category: 'Makanan',
            amount: 35000,
            walletId: 'w4', // Dompet Tunai Cash
            walletName: 'Dompet Tunai',
            type: 'expense',
          );
        });
      });
    });
  }

  void _confirmDraft() {
    if (_voiceDraft == null) return;
    
    // Add real transaction to mock providers!
    final tx = TransactionModel(
      id: 'tx_voice_${DateTime.now().millisecondsSinceEpoch}',
      title: _voiceDraft!.title,
      category: _voiceDraft!.category,
      amount: _voiceDraft!.amount,
      date: DateTime.now(),
      type: _voiceDraft!.type,
      walletId: _voiceDraft!.walletId,
    );

    widget.parentRef.read(transactionsProvider.notifier).addTransaction(tx);
    widget.parentRef.read(quickActionLimitProvider.notifier).incrementVoiceAi();

    setState(() {
      _isConfirmed = true;
    });

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _cancelDraft() {
    setState(() {
      _isCancelled = true;
    });
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Voice AI Action',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          if (_voiceDraft != null) ...[
            // Render High Fidelity Interactive Review Panel
            _buildReviewPanel(),
          ] else ...[
            // Pulse animation waveform wrapper
            _PulsingWaveform(isListening: _isListening),

            const SizedBox(height: 24),
            Text(
              _speechText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _isListening ? AppColors.primaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            
            if (_isProcessing) ...[
              const SizedBox(height: 10),
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
            
            // Record trigger button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isListening || _isProcessing ? null : _startListening,
                child: const Text(
                  'Mulai Perekaman',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewPanel() {
    if (_isConfirmed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200, width: 1.5),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
            SizedBox(height: 10),
            Text(
              'Sukses Menyimpan Transaksi! 🎉',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      );
    }

    if (_isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200, width: 1.5),
        ),
        child: const Column(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.red, size: 40),
            SizedBox(height: 10),
            Text(
              'Draf Transaksi Dibatalkan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'REVIEW DRAF SUARA AI',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRow('Detail', _voiceDraft!.title),
          _buildRow('Nominal', 'Rp ${_voiceDraft!.amount.toInt()}'),
          _buildRow('Kategori', _voiceDraft!.category),
          _buildRow('Metode', _voiceDraft!.walletName),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelDraft,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirmDraft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ─── Pulsing mic waveform component ──────────────────────────────────────────

class _PulsingWaveform extends StatefulWidget {
  final bool isListening;
  const _PulsingWaveform({required this.isListening});

  @override
  State<_PulsingWaveform> createState() => _PulsingWaveformState();
}

class _PulsingWaveformState extends State<_PulsingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isListening) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final scale = 1.0 + (widget.isListening ? 0.3 * _ctrl.value : 0.0);
        final opacity = 0.4 - (widget.isListening ? 0.3 * _ctrl.value : 0.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: opacity.clamp(0.0, 1.0)),
              ),
              transform: Matrix4.diagonal3Values(scale, scale, 1.0),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary,
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.black, size: 36),
            ),
          ],
        );
      },
    );
  }
}

// ─── Scan Action (OCR Scanner Simulator Sheet with Review workflow) ──────────

void _showOcrScanSheet(BuildContext context, WidgetRef parentRef) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 1.0,
      child: _OcrScanModal(parentRef: parentRef),
    ),
  );
}

class _OcrScanModal extends StatefulWidget {
  final WidgetRef parentRef;
  const _OcrScanModal({required this.parentRef});

  @override
  State<_OcrScanModal> createState() => _OcrScanModalState();
}

class _OcrScanModalState extends State<_OcrScanModal> {
  bool _isScanning = false;
  bool _scanningOCR = false;
  
  _DraftTransaction? _ocrDraft;
  bool _isConfirmed = false;
  bool _isCancelled = false;

  void _capturePhoto() {
    setState(() {
      _isScanning = true;
      _ocrDraft = null;
      _isConfirmed = false;
      _isCancelled = false;
    });

    // Simulate laser scanning for 2.5s
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanningOCR = true;
      });

      // OCR detection simulation for 1.5s
      Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;

        setState(() {
          _scanningOCR = false;
          _ocrDraft = _DraftTransaction(
            title: 'Alfamart Belanja',
            category: 'Belanja',
            amount: 124500,
            walletId: 'w2', // GoPay E-Wallet
            walletName: 'GoPay',
            type: 'expense',
          );
        });
      });
    });
  }

  void _confirmDraft() {
    if (_ocrDraft == null) return;
    
    // Add real transaction to mock providers!
    final tx = TransactionModel(
      id: 'tx_scan_${DateTime.now().millisecondsSinceEpoch}',
      title: _ocrDraft!.title,
      category: _ocrDraft!.category,
      amount: _ocrDraft!.amount,
      date: DateTime.now(),
      type: _ocrDraft!.type,
      walletId: _ocrDraft!.walletId,
    );

    widget.parentRef.read(transactionsProvider.notifier).addTransaction(tx);
    widget.parentRef.read(quickActionLimitProvider.notifier).incrementScan();

    setState(() {
      _isConfirmed = true;
    });

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _cancelDraft() {
    setState(() {
      _isCancelled = true;
    });
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan Struk / Nota (OCR)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            if (_ocrDraft != null) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: _buildReviewPanel(),
                ),
              ),
            ] else ...[
              // Camera Viewfinder Simulator Box expanded
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_scanningOCR) ...[
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 14),
                            Text(
                              'Menjalankan OCR & Pemindaian...',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ] else if (_isScanning) ...[
                        // Animated Scanning Laser line
                        const _ScannerAnimation(),
                        const Positioned(
                          bottom: 20,
                          child: Text(
                            'Menyelaraskan struktur struk...',
                            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ] else ...[
                        // Viewfinder corners outline overlay
                        Opacity(
                          opacity: 0.5,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_scanner_rounded, size: 48, color: Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                'Posisikan struk di dalam bingkai',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Control trigger button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isScanning || _scanningOCR ? null : _capturePhoto,
                  label: const Text(
                    'Jepret Struk Belanjaan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewPanel() {
    if (_isConfirmed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.shade900.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 40),
            SizedBox(height: 10),
            Text(
              'Sukses Menyimpan Transaksi! 🎉',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
      );
    }

    if (_isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red, width: 1.5),
        ),
        child: const Column(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.red, size: 40),
            SizedBox(height: 10),
            Text(
              'Draf Transaksi Dibatalkan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'TINJAU HASIL SCAN OCR',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRow('Detail', _ocrDraft!.title),
          _buildRow('Nominal', 'Rp ${_ocrDraft!.amount.toInt()}'),
          _buildRow('Kategori', _ocrDraft!.category),
          _buildRow('Metode', _ocrDraft!.walletName),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelDraft,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirmDraft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

// ─── Laser Scanning Line component ──────────────────────────────────────────

class _ScannerAnimation extends StatefulWidget {
  const _ScannerAnimation();

  @override
  State<_ScannerAnimation> createState() => _ScannerAnimationState();
}

class _ScannerAnimationState extends State<_ScannerAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: _ctrl.value * 200.0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary,
                      blurRadius: 10,
                      spreadRadius: 3,
                ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
