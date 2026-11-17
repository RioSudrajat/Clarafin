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
    InstitutionModel(
      id: 'jago',
      name: 'Bank Jago',
      shortName: 'Jago',
      type: 'Bank',
      logoAsset: 'assets/icons/institutions/jago.png',
      brandColor: Color(0xFFFFB400),
      fallbackIcon: Icons.account_balance,
      isSvg: false,
    ),
    InstitutionModel(
      id: 'jenius',
      name: 'Jenius BTPN',
      shortName: 'Jenius',
      type: 'Bank',
      logoAsset: 'assets/icons/institutions/jenius.png',
      brandColor: Color(0xFF009CE0),
      fallbackIcon: Icons.account_balance,
      isSvg: false,
    ),
    InstitutionModel(
      id: 'seabank',
      name: 'SeaBank',
      shortName: 'SeaBank',
      type: 'Bank',
      logoAsset: 'assets/icons/institutions/seabank.png',
      brandColor: Color(0xFFFF6600),
      fallbackIcon: Icons.account_balance,
      isSvg: false,
    ),
    InstitutionModel(
      id: 'blu',
      name: 'blu by BCA Digital',
      shortName: 'blu',
      type: 'Bank',
      logoAsset: 'assets/icons/institutions/blu.png',
      brandColor: Color(0xFF00B4D8),
      fallbackIcon: Icons.account_balance,
      isSvg: false,
    ),
    InstitutionModel(
      id: 'cimb',
      name: 'CIMB Niaga',
      shortName: 'CIMB',
      type: 'Bank',
      logoAsset: 'assets/icons/institutions/cimb.png',
      brandColor: Color(0xFF7A0019),
      fallbackIcon: Icons.account_balance,
      isSvg: false,
    ),
    InstitutionModel(
      id: 'permata',
      name: 'Bank Permata',
      shortName: 'Permata',
      type: 'Bank',
      logoAsset: 'assets/icons/institutions/permata.png',
      brandColor: Color(0xFF1D6F42),
      fallbackIcon: Icons.account_balance,
      isSvg: false,
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

    // ── CEX (Centralized Exchange) ──
    InstitutionModel(
      id: 'binance',
      name: 'Binance',
      shortName: 'Binance',
      type: 'CEX',
      logoAsset: 'assets/icons/institutions/binance.png',
      brandColor: Color(0xFFF3BA2F),
      fallbackIcon: Icons.currency_exchange_rounded,
      isSvg: false,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'bitget',
      name: 'Bitget',
      shortName: 'Bitget',
      type: 'CEX',
      logoAsset: 'assets/icons/institutions/bitget.png',
      brandColor: Color(0xFF00F0FF),
      fallbackIcon: Icons.currency_exchange_rounded,
      isSvg: false,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'floq',
      name: 'Floq',
      shortName: 'Floq',
      type: 'CEX',
      logoAsset: 'assets/icons/institutions/floq.png',
      brandColor: Color(0xFF6C5CE7),
      fallbackIcon: Icons.currency_exchange_rounded,
      isSvg: false,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'indodax',
      name: 'Indodax',
      shortName: 'Indodax',
      type: 'CEX',
      logoAsset: 'assets/icons/institutions/indodax.png',
      brandColor: Color(0xFF1D71B8),
      fallbackIcon: Icons.currency_exchange_rounded,
      isSvg: false,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'pintu',
      name: 'Pintu',
      shortName: 'Pintu',
      type: 'CEX',
      logoAsset: 'assets/icons/institutions/pintu.png',
      brandColor: Color(0xFF0A1172),
      fallbackIcon: Icons.currency_exchange_rounded,
      isSvg: false,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'tokocrypto',
      name: 'Tokocrypto',
      shortName: 'Tokocrypto',
      type: 'CEX',
      logoAsset: 'assets/icons/institutions/tokocrypto.png',
      brandColor: Color(0xFF24A148),
      fallbackIcon: Icons.currency_exchange_rounded,
      isSvg: false,
      supportsAutoSync: false,
    ),

    // ── DEX & Web3 Wallet ──
    InstitutionModel(
      id: 'uniswap',
      name: 'Uniswap',
      shortName: 'Uniswap',
      type: 'DEX',
      logoAsset: 'assets/icons/institutions/uniswap.png',
      brandColor: Color(0xFFFF007A),
      fallbackIcon: Icons.swap_horiz_rounded,
      isSvg: false,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'phantom',
      name: 'Phantom Wallet',
      shortName: 'Phantom',
      type: 'Web3 Wallet',
      logoAsset: 'assets/icons/institutions/phantom.png',
      brandColor: Color(0xFFAB9FF2),
      fallbackIcon: Icons.account_balance_wallet_rounded,
      isSvg: false,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'metamask',
      name: 'MetaMask',
      shortName: 'MetaMask',
      type: 'Web3 Wallet',
      logoAsset: 'assets/icons/institutions/metamask.png',
      brandColor: Color(0xFFF6851B),
      fallbackIcon: Icons.shield_rounded,
      isSvg: false,
      supportsAutoSync: false,
    ),
    InstitutionModel(
      id: 'trustwallet',
      name: 'Trust Wallet',
      shortName: 'Trust Wallet',
      type: 'Web3 Wallet',
      logoAsset: 'assets/icons/institutions/trustwallet.png',
      brandColor: Color(0xFF0500FF),
      fallbackIcon: Icons.security_rounded,
      isSvg: false,
      supportsAutoSync: false,
    ),

    // ── Investments & Cash ──
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

  static final RegExp _danaNonWalletRegex = RegExp(
    r'\bdana\s+(darurat|pensiun|pendidikan|usaha|nikah|cadangan|sosial|investasi|rumah|liburan|menikah|tunai)\b',
  );

  /// Smart lookup: finds an institution by matching wallet name or type keywords
  static InstitutionModel findByWallet({String? institutionId, required String name, required String type}) {
    if (institutionId != null && institutionId.isNotEmpty) {
      final match = findById(institutionId);
      if (match != null) return match;
    }

    final lower = name.toLowerCase();

    // 1. Direct name and alias matches (check blu before bca so "blu bca" resolves to blu)
    if (RegExp(r'\bblu\b').hasMatch(lower) || lower.contains('bca digital')) {
      return findById('blu')!;
    }
    if (lower.contains('bca') || lower.contains('bank central asia')) {
      return findById('bca')!;
    }
    if (lower.contains('mandiri') || lower.contains('livin')) return findById('mandiri')!;
    if (lower.contains('bri') || lower.contains('brimo') || lower.contains('bank rakyat indonesia')) {
      return findById('bri')!;
    }
    if (lower.contains('bni') || lower.contains('wondr') || lower.contains('bank negara indonesia')) {
      return findById('bni')!;
    }
    if (lower.contains('bsi') || lower.contains('bank syariah indonesia') || lower.contains('syariah indonesia') || lower.contains('byond')) {
      return findById('bsi')!;
    }
    if (lower.contains('jago') || lower.contains('kantong jago')) return findById('jago')!;
    if (lower.contains('jenius') || lower.contains('btpn') || lower.contains('smbc')) {
      return findById('jenius')!;
    }
    if (lower.contains('seabank') || lower.contains('sea bank')) return findById('seabank')!;
    if (lower.contains('cimb') || lower.contains('octo')) return findById('cimb')!;
    if (lower.contains('permata')) return findById('permata')!;
    if (lower.contains('gopay') || lower.contains('go pay')) return findById('gopay')!;
    if (RegExp(r'\bdana\b').hasMatch(lower) && !_danaNonWalletRegex.hasMatch(lower)) {
      return findById('dana')!;
    }
    if (lower.contains('ovo')) return findById('ovo')!;
    if (lower.contains('shopee') || lower.contains('spay')) return findById('shopeepay')!;
    if (lower.contains('linkaja') || lower.contains('link aja')) return findById('linkaja')!;
    if (lower.contains('binance')) return findById('binance')!;
    if (lower.contains('bitget')) return findById('bitget')!;
    if (lower.contains('floq')) return findById('floq')!;
    if (lower.contains('indodax')) return findById('indodax')!;
    if (lower.contains('pintu')) return findById('pintu')!;
    if (lower.contains('tokocrypto')) return findById('tokocrypto')!;
    if (lower.contains('uniswap')) return findById('uniswap')!;
    if (lower.contains('phantom')) return findById('phantom')!;
    if (lower.contains('metamask')) return findById('metamask')!;
    if (lower.contains('trust')) return findById('trustwallet')!;
    if (lower.contains('bibit')) return findById('bibit')!;
    if (lower.contains('stockbit')) return findById('stockbit')!;
    if (lower.contains('tunai') || lower.contains('cash')) return findById('cash')!;

    // 2. Type based fallbacks
    if (type == 'Bank') return findById('bca')!;
    if (type == 'E-Wallet') return findById('gopay')!;
    if (['CEX', 'DEX', 'Web3 Wallet', 'Crypto'].contains(type)) return findById('binance')!;
    if (type == 'Mutual Fund') return findById('bibit')!;
    if (type == 'Stock') return findById('stockbit')!;
    return findById('cash')!;
  }

  static List<InstitutionModel> get popularBanks =>
      all.where((i) => i.type == 'Bank').toList();

  static List<InstitutionModel> get ewallets =>
      all.where((i) => i.type == 'E-Wallet').toList();

  static List<InstitutionModel> get cryptoWeb3 =>
      all.where((i) => ['CEX', 'DEX', 'Web3 Wallet'].contains(i.type)).toList();

  static List<InstitutionModel> get investments =>
      all.where((i) => ['Mutual Fund', 'Stock', 'Cash'].contains(i.type)).toList();
}
