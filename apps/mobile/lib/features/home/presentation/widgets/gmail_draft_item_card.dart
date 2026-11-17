import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/ai_category_normalizer.dart';

class GmailDraftItemCard extends StatelessWidget {
  final Map<String, dynamic> draft;

  const GmailDraftItemCard({super.key, required this.draft});

  static WalletModel? matchWallet(List<WalletModel> wallets, String hint) {
    if (wallets.isEmpty) return null;
    final lower = hint.toLowerCase().trim();
    if (lower.isEmpty) return wallets.first;

    // 1. Exact wallet name match first.
    for (final w in wallets) {
      if (w.name.toLowerCase().trim() == lower) return w;
    }

    // 2. Institution priority match (blu / bca digital checked before bca).
    const priorityInstitutions = <String>[
      'blu',
      'bca',
      'gopay',
      'mandiri',
      'bri',
      'bni',
      'bsi',
      'jago',
      'jenius',
      'seabank',
      'cimb',
      'permata',
      'ovo',
      'dana',
      'shopeepay',
      'linkaja',
    ];
    for (final instKey in priorityInstitutions) {
      final matchesHint = switch (instKey) {
        'blu' => RegExp(r'\bblu\b').hasMatch(lower) || lower.contains('bca digital'),
        'dana' => RegExp(r'\bdana\b').hasMatch(lower) &&
            !RegExp(
              r'\bdana\s+(darurat|pensiun|pendidikan|usaha|nikah|cadangan|sosial|investasi|rumah|liburan|menikah|tunai)\b',
            ).hasMatch(lower),
        _ => RegExp('\\b${RegExp.escape(instKey)}\\b').hasMatch(lower) ||
            lower.contains(instKey),
      };
      if (!matchesHint) continue;
      for (final w in wallets) {
        final wInst = (w.institutionId ?? '').toLowerCase().trim();
        if (wInst == instKey || w.name.toLowerCase().contains(instKey)) {
          return w;
        }
      }
    }

    // 3. Fallback substring match against non-empty wallet names / institutionIds.
    for (final w in wallets) {
      final wName = w.name.toLowerCase().trim();
      final wInst = (w.institutionId ?? '').toLowerCase().trim();
      if ((wName.isNotEmpty && (lower.contains(wName) || wName.contains(lower))) ||
          (wInst.isNotEmpty && RegExp('\\b${RegExp.escape(wInst)}\\b').hasMatch(lower))) {
        return w;
      }
    }
    return wallets.first;
  }

  static List<Map<String, dynamic>> buildPrefillItems(
    List<Map<String, dynamic>> drafts,
    List<WalletModel> wallets,
  ) {
    return drafts.map((d) {
      final walletHint = d['wallet'] as String;
      final matched = matchWallet(wallets, walletHint);
      return <String, dynamic>{
        'title': d['title'] as String,
        'amount': d['amount'] as double,
        'isExpense': true,
        'category': AiCategoryNormalizer.normalize(d['category'] as String),
        'walletId': matched?.id,
        'walletName': matched?.name ?? walletHint,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: NeoBrutalism.border(width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: NeoBrutalism.mint,
              borderRadius: BorderRadius.circular(8),
              border: NeoBrutalism.border(width: 1.5),
            ),
            child: Icon(draft['icon'] as IconData, size: 18, color: NeoBrutalism.dark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: NeoBrutalism.dark,
                  ),
                ),
                Text(
                  '${draft['wallet']} • ${draft['date']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Rp ${(draft['amount'] as double).toInt()}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: NeoBrutalism.dark,
            ),
          ),
        ],
      ),
    );
  }
}
