import 'package:flutter/material.dart';
import 'institution_model.dart';

class InstitutionRegistry {
  static const List<InstitutionModel> all = [
    // ── Banks ──
    InstitutionModel(
      id: 'bca',
      name: 'Bank Central Asia',
      shortName: 'BCA',
      type: 'Bank',
      logoAsset: 'assets/icons/institutions/bca.svg',
      brandColor: Color(0xFF005EAA),
      fallbackIcon: Icons.account_balance,
      isSvg: true,
    ),
    InstitutionModel(
      id: 'mandiri',
      name: 'Bank Mandiri',
      shortName: 'Mandiri',
      type: 'Bank',
      logoAsset: 'assets/icons/institutions/mandiri.svg',
      brandColor: Color(0xFF00387A),
      fallbackIcon: Icons.account_balance,
      isSvg: true,
    ),
    InstitutionModel(
      id: 'bri',
      name: 'Bank Rakyat Indonesia',
      shortName: 'BRI',
      type: 'Bank',
      logoAsset: 'assets/icons/institutions/bri.svg',
      brandColor: Color(0xFF00529C),
      fallbackIcon: Icons.account_balance,
      isSvg: true,
    ),
    InstitutionModel(
      id: 'bni',
      name: 'Bank Negara Indonesia',
      shortName: 'BNI',
      type: 'Bank',
      logoAsset: 'assets/icons/institutions/bni.svg',
      brandColor: Color(0xFFF15A24),
      fallbackIcon: Icons.account_balance,
      isSvg: true,
    ),
    InstitutionModel(
      id: 'bsi',
      name: 'Bank Syariah Indonesia',
      shortName: 'BSI',
      type: 'Bank',
      logoAsset: 'assets/icons/institutions/bsi.svg',
      brandColor: Color(0xFF00A39D),
      fallbackIcon: Icons.account_balance,
      isSvg: true,
      supportsAutoSync: false,
    ),

    // ── E-Wallets ──
    InstitutionModel(
      id: 'gopay',
      name: 'GoPay',
      shortName: 'GoPay',
      type: 'E-Wallet',
      logoAsset: 'assets/icons/institutions/gopay.png',
      brandColor: Color(0xFF00AED6),
      fallbackIcon: Icons.account_balance_wallet,
      isSvg: false,
    ),
    InstitutionModel(
      id: 'dana',
      name: 'DANA',
      shortName: 'DANA',
      type: 'E-Wallet',
      logoAsset: 'assets/icons/institutions/dana.png',
      brandColor: Color(0xFF108EE9),
      fallbackIcon: Icons.account_balance_wallet,
      isSvg: false,
    ),
    InstitutionModel(
      id: 'ovo',
      name: 'OVO',
      shortName: 'OVO',
      type: 'E-Wallet',
      logoAsset: 'assets/icons/institutions/ovo.png',
      brandColor: Color(0xFF4C2A86),
      fallbackIcon: Icons.account_balance_wallet,
      isSvg: false,
    ),
    InstitutionModel(
      id: 'shopeepay',
      name: 'ShopeePay',
      shortName: 'ShopeePay',
      type: 'E-Wallet',
      logoAsset: 'assets/icons/institutions/shopeepay.png',
      brandColor: Color(0xFFEE4D2D),
      fallbackIcon: Icons.account_balance_wallet,
      isSvg: false,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'linkaja',
      name: 'LinkAja',
      shortName: 'LinkAja',
      type: 'E-Wallet',
      logoAsset: 'assets/icons/institutions/linkaja.png',
      brandColor: Color(0xFFED1C24),
      fallbackIcon: Icons.account_balance_wallet,
      isSvg: false,
    ),

    // ── Investments & Crypto & Cash ──
    InstitutionModel(
      id: 'bibit',
      name: 'Bibit Reksadana',
      shortName: 'Bibit',
      type: 'Mutual Fund',
      logoAsset: 'assets/icons/institutions/bibit.svg',
      brandColor: Color(0xFF22C55E),
      fallbackIcon: Icons.pie_chart_outline,
      isSvg: true,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'stockbit',
      name: 'Stockbit Saham',
      shortName: 'Stockbit',
      type: 'Stock',
      logoAsset: 'assets/icons/institutions/stockbit.svg',
      brandColor: Color(0xFF0F766E),
      fallbackIcon: Icons.show_chart,
      isSvg: true,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'bitcoin',
      name: 'Bitcoin Crypto',
      shortName: 'Bitcoin',
      type: 'Crypto',
      logoAsset: 'assets/icons/institutions/bitcoin.svg',
      brandColor: Color(0xFFF7931A),
      fallbackIcon: Icons.currency_bitcoin,
      isSvg: true,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'cash',
      name: 'Dompet Tunai',
      shortName: 'Cash',
      type: 'Cash',
      logoAsset: 'assets/icons/institutions/cash.svg',
      brandColor: Color(0xFF10B981),
      fallbackIcon: Icons.wallet,
      isSvg: true,
      supportsAutoSync: false,
    ),
  ];

  static InstitutionModel? findById(String id) {
    try {
      return all.firstWhere((i) => i.id.toLowerCase() == id.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  /// Smart lookup: finds an institution by matching wallet name or type keywords
  static InstitutionModel findByWallet({String? institutionId, required String name, required String type}) {
    if (institutionId != null && institutionId.isNotEmpty) {
      final match = findById(institutionId);
      if (match != null) return match;
    }

    final lower = name.toLowerCase();

    // 1. Direct name matches
    if (lower.contains('bca')) return findById('bca')!;
    if (lower.contains('mandiri') || lower.contains('livin')) return findById('mandiri')!;
    if (lower.contains('bri')) return findById('bri')!;
    if (lower.contains('bni')) return findById('bni')!;
    if (lower.contains('bsi') || lower.contains('syariah indonesia')) return findById('bsi')!;
    if (lower.contains('gopay')) return findById('gopay')!;
    if (lower.contains('dana')) return findById('dana')!;
    if (lower.contains('ovo')) return findById('ovo')!;
    if (lower.contains('shopee')) return findById('shopeepay')!;
    if (lower.contains('linkaja')) return findById('linkaja')!;
    if (lower.contains('bibit')) return findById('bibit')!;
    if (lower.contains('stockbit')) return findById('stockbit')!;
    if (lower.contains('bitcoin') || lower.contains('crypto')) return findById('bitcoin')!;
    if (lower.contains('tunai') || lower.contains('cash')) return findById('cash')!;

    // 2. Type based fallbacks
    if (type == 'Bank') return findById('bca')!;
    if (type == 'E-Wallet') return findById('gopay')!;
    if (type == 'Mutual Fund') return findById('bibit')!;
    if (type == 'Stock') return findById('stockbit')!;
    if (type == 'Crypto') return findById('bitcoin')!;
    return findById('cash')!;
  }

  static List<InstitutionModel> get popularBanks =>
      all.where((i) => i.type == 'Bank').toList();

  static List<InstitutionModel> get ewallets =>
      all.where((i) => i.type == 'E-Wallet').toList();

  static List<InstitutionModel> get investments =>
      all.where((i) => ['Mutual Fund', 'Stock', 'Crypto', 'Cash'].contains(i.type)).toList();
}
