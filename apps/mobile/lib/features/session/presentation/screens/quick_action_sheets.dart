import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/providers/ai_quota_provider.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/utils/ai_category_normalizer.dart';
import '../../../../shared/widgets/saas_upgrade_bottom_sheet.dart';
import '../../../home/presentation/widgets/notion_doodle_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

class _ResolvedWallet {
  final String id;
  final String name;
  const _ResolvedWallet({required this.id, required this.name});
}

_ResolvedWallet _resolveWalletFromText(String text, List<WalletModel> wallets) {
  final lower = text.toLowerCase();
  for (final w in wallets) {
    if (lower.contains(w.name.toLowerCase())) {
      return _ResolvedWallet(id: w.id, name: w.name);
    }
    final instId = (w.institutionId ?? '').toLowerCase().trim();
    if (instId.isNotEmpty && RegExp('\\b${RegExp.escape(instId)}\\b').hasMatch(lower)) {
      return _ResolvedWallet(id: w.id, name: w.name);
    }
  }
  const keywords = <String, String>{
    'blu': 'blu by BCA Digital',
    'bni': 'BNI',
    'bca': 'BCA',
    'mandiri': 'Mandiri',
    'bri': 'BRI',
    'bsi': 'BSI',
    'jago': 'Bank Jago',
    'jenius': 'Jenius BTPN',
    'seabank': 'SeaBank',
    'cimb': 'CIMB Niaga',
    'permata': 'Bank Permata',
    'gopay': 'GoPay',
    'ovo': 'OVO',
    'dana': 'DANA',
    'shopeepay': 'ShopeePay',
    'linkaja': 'LinkAja',
    'tunai': 'Dompet Tunai',
    'cash': 'Dompet Tunai',
    'bibit': 'Bibit',
    'stockbit': 'Stockbit',
  };
  for (final entry in keywords.entries) {
    if (RegExp('\\b${RegExp.escape(entry.key)}\\b').hasMatch(lower) ||
        (entry.key.length > 3 && lower.contains(entry.key))) {
      for (final w in wallets) {
        final wNameLower = w.name.toLowerCase();
        final wTypeLower = w.type.toLowerCase();
        final wInstLower = (w.institutionId ?? '').toLowerCase();
        if (wInstLower == entry.key ||
            wNameLower.contains(entry.key) ||
            wTypeLower.contains(entry.key)) {
          return _ResolvedWallet(id: w.id, name: w.name);
        }
      }
      if (wallets.isNotEmpty) {
        return _ResolvedWallet(id: wallets.first.id, name: wallets.first.name);
      }
      return _ResolvedWallet(id: 'w_${entry.key}', name: entry.value);
    }
  }
  if (wallets.isNotEmpty) {
    return _ResolvedWallet(id: wallets.first.id, name: wallets.first.name);
  }
  return const _ResolvedWallet(id: 'w1', name: 'BCA Utama');
}

double _parseAmountFromText(String text) {
  final lower = text.toLowerCase();

  // 1. Check for number + million (jt, juta)
  final jutaRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:jt|juta)\b');
  final jutaMatch = jutaRegex.firstMatch(lower);
  if (jutaMatch != null) {
    final numStr = jutaMatch.group(1)!.replaceAll(',', '.');
    final val = double.tryParse(numStr);
    if (val != null) return val * 1000000.0;
  }

  // 2. Check for number + thousand (k, rb, ribu) with strict boundaries!
  // Note: Only words like "300k", "300 k", "300rb", "300 ribu", NOT "tiket" or "kreta"!
  final ribuRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:k|rb|ribu)\b');
  final ribuMatch = ribuRegex.firstMatch(lower);
  if (ribuMatch != null) {
    final numStr = ribuMatch.group(1)!.replaceAll(',', '.');
    final val = double.tryParse(numStr);
    if (val != null) {
      return val < 10000 ? val * 1000.0 : val;
    }
  }

  // 3. Plain or formatted number (e.g. 300000, 300.000, 300,000)
  final numberRegex = RegExp(r'\b\d{1,3}(?:[.,]\d{3})+\b|\b\d{4,}\b|\b\d+\b');
  final numberMatch = numberRegex.firstMatch(lower);
  if (numberMatch != null) {
    final raw = numberMatch.group(0)!;
    final clean = raw.replaceAll('.', '').replaceAll(',', '');
    final val = double.tryParse(clean);
    if (val != null) return val;
  }

  return 50000.0;
}

bool _isIncomeInput(String text) {
  final lower = text.toLowerCase();
  return RegExp(
    r'\b(gaji|gajian|salary|upah|honor|bonus|thr|dividen|cashback|bunga|cuan|profit|transfer masuk|pemasukan|terima|masuk|freelance)\b',
  ).hasMatch(lower);
}

CanonicalCategoryResult _resolveCategoryDetailFromText(String text) {
  final isIncome = _isIncomeInput(text);
  return AiCategoryNormalizer.normalizeDetailed(
    text,
    isIncome: isIncome,
    contextHint: text,
  );
}

String _resolveTitleFromText(String text, String category) {
  final lower = text.toLowerCase();
  if (lower.contains('tiket') && (lower.contains('kreta') || lower.contains('kereta'))) {
    return 'Tiket Kereta';
  }
  if (lower.contains('tiket') && lower.contains('pesawat')) {
    return 'Tiket Pesawat';
  }
  if (lower.contains('kopi') || lower.contains('starbucks')) {
    return 'Kopi Starbucks';
  }
  if (lower.contains('bensin') || lower.contains('pertalite') || lower.contains('pertamax')) {
    return 'Bensin Kendaraan';
  }
  if (lower.contains('listrik') || lower.contains('pln')) {
    return 'Tagihan Listrik';
  }
  if (lower.contains('wifi') || lower.contains('indihome')) {
    return 'Tagihan WiFi';
  }
  if (lower.contains('pulsa') || lower.contains('kuota')) {
    return 'Pulsa / Paket Data';
  }
  if (lower.contains('gaji')) {
    return 'Gaji Bulanan';
  }
  if (lower.contains('padang')) {
    return 'Nasi Padang';
  }
  if (lower.contains('pizza')) {
    return 'Pizza';
  }
  if (lower.contains('burger')) {
    return 'Burger';
  }
  if (lower.contains('mie')) {
    return 'Mie';
  }

  // Clean conversational filler words
  String cleaned = text
      .replaceAll(RegExp(r'\b(abis|udah|tadi|baru|beli|bayar|buat|transaksi|catat|pake|pakai|lewat|dari|ke|sebesar|rp|bca|bni|bri|mandiri|bsi|jago|jenius|seabank|blu|cimb|permata|gopay|ovo|dana|shopeepay|linkaja|cash|tunai)\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\b\d+(?:[.,]\d+)?\s*(?:k|rb|ribu|jt|juta)?\b', caseSensitive: false), '')
      .trim();
  if (cleaned.length >= 3) {
    return cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
  return category;
}

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

void showAiChatQuickSheet(BuildContext context, WidgetRef parentRef) {
  _showAiChatQuickSheet(context, parentRef);
}

void showOcrScanSheet(BuildContext context, WidgetRef parentRef) {
  _showOcrScanSheet(context, parentRef);
}

void showQuickActionMenuSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: Colors.black, width: 2.0),
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
    final aiQuota = ref.watch(aiQuotaProvider);
    final isAiExhausted = !aiQuota.isUnlimited && aiQuota.quotaRemaining <= 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
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
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih metode paling efisien untuk catat keuanganmu.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
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
              childAspectRatio: 1.02,
              children: [
                _buildActionGridItem(
                  context,
                  ref,
                  svgString: NotionDoodleIcons.aiChat,
                  title: 'AI Chat Action',
                  subtitle: 'Ketik lewat asisten AI',
                  limitText: 'AI Kuota: ${aiQuota.displayQuotaBadge}',
                  isLimited: isAiExhausted,
                  onTap: () {
                    Navigator.pop(context);
                    if (isAiExhausted) {
                      SaasUpgradeBottomSheet.show(
                        context,
                        reason: 'Kuota AI kamu sudah habis untuk AI Chat Quick Action. Upgrade paket untuk lanjut.',
                      );
                    } else {
                      _showAiChatQuickSheet(context, parentRef);
                    }
                  },
                ),
                _buildActionGridItem(
                  context,
                  ref,
                  svgString: NotionDoodleIcons.voiceAi,
                  title: 'Voice AI Action',
                  subtitle: 'Ucapkan ke asisten AI',
                  limitText: 'AI Kuota: ${aiQuota.displayQuotaBadge}',
                  isLimited: isAiExhausted,
                  onTap: () {
                    Navigator.pop(context);
                    if (isAiExhausted) {
                      SaasUpgradeBottomSheet.show(
                        context,
                        reason: 'Kuota AI kamu sudah habis untuk Voice AI Action. Upgrade paket untuk lanjut.',
                      );
                    } else {
                      _showVoiceAiSheet(context, parentRef);
                    }
                  },
                ),
                _buildActionGridItem(
                  context,
                  ref,
                  svgString: NotionDoodleIcons.ocrScan,
                  title: 'Scan Action (OCR)',
                  subtitle: 'Foto struk belanja untuk scan',
                  limitText: 'AI Kuota: ${aiQuota.displayQuotaBadge}',
                  isLimited: isAiExhausted,
                  onTap: () {
                    Navigator.pop(context);
                    if (isAiExhausted) {
                      SaasUpgradeBottomSheet.show(
                        context,
                        reason: 'Kuota AI kamu sudah habis untuk Scan Action (OCR). Upgrade paket untuk lanjut.',
                      );
                    } else {
                      _showOcrScanSheet(context, parentRef);
                    }
                  },
                ),
                _buildActionGridItem(
                  context,
                  ref,
                  svgString: NotionDoodleIcons.manualAdd,
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
    required String svgString,
    required String title,
    required String subtitle,
    required String limitText,
    required bool isLimited,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 0,
            offset: Offset(0, 3.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Stack(
            children: [
              // Quota Pill Badge at top-right
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLimited ? const Color(0xFFFFDAD6) : const Color(0xFFCCFF00),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 1.2),
                  ),
                  child: Text(
                    limitText,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              // Centered Icon (Unwrapped) + Titles
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Notion Doodle icon in center - strictly NO border wrapper!
                      NotionDoodleWidget(
                        svgString: svgString,
                        size: 46,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B5563),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            text: 'Pengeluaran kamu bulan ini adalah Rp 3.041.000, terbagi di kategori Food & Beverage, Shopping, dan Bills & Utilities.',
            isUser: false,
          ));
        });
      } else if (lowerText.contains('pemasukan vs')) {
        setState(() {
          _isProcessing = false;
          _messages.add(_QuickChatMessage(
            text: 'Pemasukan kamu bulan ini Rp 15.000.000 vs Pengeluaran Rp 3.041.000. Keuangan kamu dalam kondisi sehat.',
            isUser: false,
          ));
        });
      } else {
        // Intelligent Natural Language Transaction Parser
        final userWallets = widget.parentRef.read(walletsProvider);
        final resolved = _resolveWalletFromText(lowerText, userWallets);
        final isIncomeHint = _isIncomeInput(text);
        final detail = _resolveCategoryDetailFromText(text);
        final category = detail.canonicalCategory;
        final title = _resolveTitleFromText(text, category);
        final amount = _parseAmountFromText(text);
        final isIncome = detail.type == 'income' || isIncomeHint;
        final type = isIncome ? 'income' : 'expense';

        final draft = _DraftTransaction(
          title: title,
          amount: amount,
          category: category,
          walletId: resolved.id,
          walletName: resolved.name,
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
    widget.parentRef.read(aiQuotaProvider.notifier).useQuota();

    setState(() {
      msg.isConfirmed = true;
    });

    // AI confirmation feedback
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_QuickChatMessage(
          text: 'Transaksi "${draft.title}" sebesar ${CurrencyFormatter.format(draft.amount, currencyCode: widget.parentRef.read(userProfileProvider).currency)} berhasil disimpan ke ${draft.walletName}.',
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
        // CARD 1: Chat History & Suggestions Panel (Neo-Brutalist)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        
        const SizedBox(height: 12),
        
        // CARD 2: Input & Control Panel (Neo-Brutalist)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Full-width Input container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1.8),
                ),
                child: TextField(
                  controller: _controller,
                  cursorColor: Colors.black,
                  style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (t) => _processInput(t),
                ),
              ),
              const SizedBox(height: 12),
              
              // Row of shortcuts + Send button
              Row(
                children: [
                  // Scan Button Shortcut
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showOcrScanSheet(context, widget.parentRef);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.document_scanner_outlined, size: 16, color: Colors.black),
                          SizedBox(width: 6),
                          Text(
                            'Scan', 
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w800, 
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Bicara Button Shortcut
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showVoiceAiSheet(context, widget.parentRef);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.mic_none_rounded, size: 16, color: Colors.black),
                          SizedBox(width: 6),
                          Text(
                            'Bicara', 
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w800, 
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Neo-Brutalist Send Button (Lime with black border & hard shadow)
                  GestureDetector(
                    onTap: () => _processInput(_controller.text),
                    child: Container(
                      width: 44,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFF00),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_upward_rounded, size: 22, color: Colors.black),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black, width: 2.0)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Robot Avatar Icon in lime square with black border
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFCCFF00),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2.0),
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
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFF00),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.0),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Close X Button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 22),
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
        const Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.black),
            SizedBox(width: 6),
            Text(
              'TANYA DATA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.black,
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  p,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tanya data: tanya pakai bahasa biasa (saldo, pengeluaran, pemasukan, dll). Pakai tombol Scan untuk struk/nota, Bicara untuk input suara.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
            height: 1.4,
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
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFF00), // Lime green Neo-Brutalist
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  m.text,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
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
            decoration: BoxDecoration(
              color: const Color(0xFFCCFF00),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text bubble (Neo-Brutalist white card with black border & hard shadow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
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
                  child: Text(
                    m.text,
                    style: const TextStyle(
                      fontSize: 13, 
                      color: Colors.black, 
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
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
          color: const Color(0xFFE5F9E0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
              'Draf Disimpan Secara Riil',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ],
        ),
      );
    }

    if (msg.isCancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
              'Draf Transaksi Dibatalkan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: Colors.black, size: 18),
              SizedBox(width: 8),
              Text(
                'TINJAU DRAF TRANSAKSI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Details rows
          _buildDraftDetailRow('Transaksi', draft.title),
          _buildDraftDetailRow('Nominal', CurrencyFormatter.format(draft.amount, currencyCode: widget.parentRef.watch(userProfileProvider).currency)),
          _buildDraftDetailRow('Kategori', draft.category),
          _buildDraftDetailRow('Metode', draft.walletName),
          _buildDraftDetailRow('Tipe', draft.type == 'income' ? 'Pemasukan' : 'Pengeluaran'),
          
          const SizedBox(height: 14),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _cancelDraft(msg, draft),
                      child: const Center(
                        child: Text('Batal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C))),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFF00),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _confirmDraft(msg, draft),
                      child: const Center(
                        child: Text('Konfirmasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
                      ),
                    ),
                  ),
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
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w800),
            ),
          ),
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
            decoration: BoxDecoration(
              color: const Color(0xFFCCFF00),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz_rounded, size: 20, color: Colors.black),
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
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: Colors.black, width: 2.0),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: _VoiceAiModal(parentRef: parentRef),
      ),
    ),
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
        final userWallets = widget.parentRef.read(walletsProvider);
        final resolvedWallet = _resolveWalletFromText('Dompet Tunai Cash', userWallets);
        final canonicalCategory = AiCategoryNormalizer.normalize(
          'Makanan',
          contextHint: 'Makan Siang Padang',
        );

        setState(() {
          _isProcessing = false;
          _voiceDraft = _DraftTransaction(
            title: 'Makan Siang Padang',
            category: canonicalCategory,
            amount: 35000,
            walletId: resolvedWallet.id,
            walletName: resolvedWallet.name,
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
    widget.parentRef.read(aiQuotaProvider.notifier).useQuota();

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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Voice AI Action',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
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
                fontWeight: FontWeight.w800,
                color: _isListening ? Colors.black : const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            
            if (_isProcessing) ...[
              const SizedBox(height: 10),
              const CircularProgressIndicator(color: Colors.black),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
            
            // Record trigger button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFCCFF00),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black, width: 2.0),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(0, 3), blurRadius: 0),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _isListening || _isProcessing ? null : _startListening,
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic_rounded, color: Colors.black, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Mulai Perekaman',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
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
          color: const Color(0xFFE5F9E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 3), blurRadius: 0),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.black, size: 36),
            SizedBox(height: 10),
            Text(
              'Sukses Menyimpan Transaksi!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
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
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 3), blurRadius: 0),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.black, size: 36),
            SizedBox(height: 10),
            Text(
              'Draf Transaksi Dibatalkan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(0, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: Colors.black, size: 20),
              SizedBox(width: 8),
              Text(
                'REVIEW DRAF SUARA AI',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRow('Detail', _voiceDraft!.title),
          _buildRow('Nominal', CurrencyFormatter.format(_voiceDraft!.amount, currencyCode: widget.parentRef.watch(userProfileProvider).currency)),
          _buildRow('Kategori', _voiceDraft!.category),
          _buildRow('Metode', _voiceDraft!.walletName),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _cancelDraft,
                      child: const Center(
                        child: Text('Hapus', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB91C1C), fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFF00),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _confirmDraft,
                      child: const Center(
                        child: Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 13)),
                      ),
                    ),
                  ),
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
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
            ),
          ),
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
        final scale = 1.0 + (widget.isListening ? 0.25 * _ctrl.value : 0.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening)
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFCCFF00).withValues(alpha: 0.3),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                transform: Matrix4.diagonal3Values(scale, scale, 1.0),
              ),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFCCFF00),
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.black, size: 38),
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
    backgroundColor: Colors.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: Colors.black, width: 2.0),
    ),
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.94,
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

    // Simulate laser scanning for 2s
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanningOCR = true;
      });

      // OCR detection simulation for 1.5s
      Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        final userWallets = widget.parentRef.read(walletsProvider);
        final resolvedWallet = _resolveWalletFromText('GoPay', userWallets);
        final canonicalCategory = AiCategoryNormalizer.normalize(
          'Alfamart Belanja',
          contextHint: 'Alfamart Belanja',
        );

        setState(() {
          _scanningOCR = false;
          _ocrDraft = _DraftTransaction(
            title: 'Alfamart Belanja',
            category: canonicalCategory,
            amount: 124500,
            walletId: resolvedWallet.id,
            walletName: resolvedWallet.name,
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
    widget.parentRef.read(aiQuotaProvider.notifier).useQuota();

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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan Struk / Nota (OCR)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black,
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
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Viewfinder corner bracket accents
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.black, width: 3.5),
                              left: BorderSide(color: Colors.black, width: 3.5),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.black, width: 3.5),
                              right: BorderSide(color: Colors.black, width: 3.5),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.black, width: 3.5),
                              left: BorderSide(color: Colors.black, width: 3.5),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.black, width: 3.5),
                              right: BorderSide(color: Colors.black, width: 3.5),
                            ),
                          ),
                        ),
                      ),

                      // State contents
                      if (_scanningOCR) ...[
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.black),
                            SizedBox(height: 14),
                            Text(
                              'Menjalankan OCR & Pemindaian...',
                              style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ] else if (_isScanning) ...[
                        // Animated Scanning Laser line
                        const _ScannerAnimation(),
                        const Positioned(
                          bottom: 24,
                          child: Text(
                            'Menyelaraskan struktur struk...',
                            style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ] else ...[
                        // Idle instructions
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCCFF00),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2.0),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black, offset: Offset(0, 3), blurRadius: 0),
                                ],
                              ),
                              child: const Icon(Icons.qr_code_scanner_rounded, size: 40, color: Colors.black),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Posisikan struk di dalam bingkai',
                              style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pastikan nama toko & nominal terlihat jelas',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Control trigger button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFF00),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2.0),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(0, 3), blurRadius: 0),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isScanning || _scanningOCR ? null : _capturePhoto,
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Jepret Struk Belanjaan',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
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
          color: const Color(0xFFE5F9E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 3), blurRadius: 0),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.black, size: 36),
            SizedBox(height: 10),
            Text(
              'Sukses Menyimpan Transaksi!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
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
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 3), blurRadius: 0),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.black, size: 36),
            SizedBox(height: 10),
            Text(
              'Draf Transaksi Dibatalkan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(0, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: Colors.black, size: 20),
              SizedBox(width: 8),
              Text(
                'TINJAU HASIL SCAN OCR',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRow('Detail', _ocrDraft!.title),
          _buildRow('Nominal', CurrencyFormatter.format(_ocrDraft!.amount, currencyCode: widget.parentRef.watch(userProfileProvider).currency)),
          _buildRow('Kategori', _ocrDraft!.category),
          _buildRow('Metode', _ocrDraft!.walletName),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _cancelDraft,
                      child: const Center(
                        child: Text('Hapus', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB91C1C), fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFF00),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _confirmDraft,
                      child: const Center(
                        child: Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 13)),
                      ),
                    ),
                  ),
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
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
            ),
          ),
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
              top: _ctrl.value * 220.0,
              left: 20,
              right: 20,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFF00),
                  border: Border.all(color: Colors.black, width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(0, 2),
                      blurRadius: 0,
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
