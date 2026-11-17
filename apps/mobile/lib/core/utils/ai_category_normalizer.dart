import '../models/transaction_category_model.dart';

class CanonicalCategoryResult {
  final String canonicalCategory;
  final String mainCategory;
  final String? subcategory;
  final String type; // 'expense', 'income', 'transfer'
  final bool isFallback;

  const CanonicalCategoryResult({
    required this.canonicalCategory,
    required this.mainCategory,
    this.subcategory,
    required this.type,
    this.isFallback = false,
  });
}

class _CategoryDef {
  final String txType;
  final String mainName;
  final String? subName;
  final String canonicalName;
  final bool isParent;
  final List<String> aliases;

  const _CategoryDef({
    required this.txType,
    required this.mainName,
    this.subName,
    required this.canonicalName,
    required this.isParent,
    this.aliases = const [],
  });
}

class _CompiledAliasRule {
  final _CategoryDef def;
  final List<String> aliasTokens;

  const _CompiledAliasRule({
    required this.def,
    required this.aliasTokens,
  });
}

/// Client-side canonical category mapper mirroring backend Go `category_mapper.go`
/// and producing verbatim `TransactionCategories` strings for local NLP/OCR/UI flows.
class AiCategoryNormalizer {
  AiCategoryNormalizer._();

  static final List<_CategoryDef> _catalog = _buildCatalog();
  static final List<_CompiledAliasRule> _aliasRules = _compileAliasRules(_catalog);

  /// Normalizes a raw category string (or colloquial phrase) into a verbatim
  /// `TransactionCategories` string (`"Main • Sub"` or `"Main"`).
  static String normalize(
    String raw, {
    bool isIncome = false,
    String? contextHint,
  }) {
    return normalizeDetailed(
      raw,
      isIncome: isIncome,
      contextHint: contextHint,
    ).canonicalCategory;
  }

  /// Normalizes any category or merchant hint into a top-level expense category
  /// name (`Food & Beverage`, `Transportation`, `Shopping`, etc.) so
  /// `syncedBudgetsProvider` matches normalized transactions reliably.
  static String normalizeBudgetCategory(String raw) {
    final res = normalizeDetailed(raw, isIncome: false);
    if (res.type == 'expense' &&
        TransactionCategories.findCategory(res.mainCategory, isIncome: false) != null) {
      return res.mainCategory;
    }
    return 'Others';
  }

  static CanonicalCategoryResult normalizeDetailed(
    String raw, {
    bool isIncome = false,
    bool isTransfer = false,
    String? contextHint,
  }) {
    final rawTrimmed = raw.trim();
    final hintTrimmed = (contextHint ?? '').trim();

    if (isTransfer) {
      final incoming = _matchIncomingTransfer(rawTrimmed);
      if (incoming != null) return incoming;
      return const CanonicalCategoryResult(
        canonicalCategory: 'Transfer',
        mainCategory: 'Transfer',
        type: 'transfer',
      );
    }

    if (!isIncome && _isTransferPhrase(rawTrimmed)) {
      return const CanonicalCategoryResult(
        canonicalCategory: 'Transfer',
        mainCategory: 'Transfer',
        type: 'transfer',
      );
    }

    if (isIncome) {
      return _normalizeIncome(rawTrimmed, hintTrimmed);
    }
    return _normalizeExpenseWithExplicitIncomeSupport(rawTrimmed, hintTrimmed);
  }

  static CanonicalCategoryResult _normalizeIncome(
    String rawTrimmed,
    String hintTrimmed,
  ) {
    // Generic "Others" inputs under income bypass expense "Others" and stay strictly income.
    if (rawTrimmed.isNotEmpty && !_isGenericOthersInput(rawTrimmed)) {
      final def = _resolveTextToCategory(
        rawTrimmed,
        preferredType: 'income',
        allowCrossType: false,
      );
      if (def != null) {
        if (def.isParent && hintTrimmed.isNotEmpty) {
          final child = _refineMainNameWithHint(def.mainName, 'income', hintTrimmed);
          if (child != null) return _resultFromDef(child);
        }
        return _resultFromDef(def);
      }
    }

    if (hintTrimmed.isNotEmpty) {
      final hintDef = _resolveTextToCategory(
        hintTrimmed,
        preferredType: 'income',
        allowCrossType: false,
      );
      if (hintDef != null) return _resultFromDef(hintDef);
    }

    return const CanonicalCategoryResult(
      canonicalCategory: 'Income • Additional Income',
      mainCategory: 'Income',
      subcategory: 'Additional Income',
      type: 'income',
      isFallback: true,
    );
  }

  static CanonicalCategoryResult _normalizeExpenseWithExplicitIncomeSupport(
    String rawTrimmed,
    String hintTrimmed,
  ) {
    if (rawTrimmed.isNotEmpty) {
      final def = _resolveTextToCategory(
        rawTrimmed,
        preferredType: 'expense',
        allowCrossType: !_isGenericOthersInput(rawTrimmed),
      );
      if (def != null) {
        if (def.mainName == 'Others' && hintTrimmed.isNotEmpty) {
          final hintDef = _resolveTextToCategory(
            hintTrimmed,
            preferredType: 'expense',
            allowCrossType: false,
          );
          if (hintDef != null) return _resultFromDef(hintDef);
        }
        if (def.isParent && hintTrimmed.isNotEmpty && def.mainName != 'Others') {
          final child = _refineMainNameWithHint(def.mainName, def.txType, hintTrimmed);
          if (child != null) return _resultFromDef(child);
        } else if (def.canonicalName == 'Transportation • Ride Hailing / Taxi' &&
            _isTransportasiOnly(rawTrimmed) &&
            hintTrimmed.isNotEmpty) {
          final child = _refineMainNameWithHint('Transportation', 'expense', hintTrimmed);
          if (child != null) return _resultFromDef(child);
        }
        return _resultFromDef(def);
      }
    }

    if (hintTrimmed.isNotEmpty) {
      final hintDef = _resolveTextToCategory(
        hintTrimmed,
        preferredType: 'expense',
        allowCrossType: false,
      );
      if (hintDef != null) return _resultFromDef(hintDef);
    }

    return const CanonicalCategoryResult(
      canonicalCategory: 'Others • General Uncategorized',
      mainCategory: 'Others',
      subcategory: 'General Uncategorized',
      type: 'expense',
      isFallback: true,
    );
  }

  static CanonicalCategoryResult _resultFromDef(
    _CategoryDef def, {
    bool isFallback = false,
  }) {
    return CanonicalCategoryResult(
      canonicalCategory: def.canonicalName,
      mainCategory: def.mainName,
      subcategory: def.subName,
      type: def.txType,
      isFallback: isFallback,
    );
  }

  static CanonicalCategoryResult? _matchIncomingTransfer(String raw) {
    if (raw.isEmpty) return null;
    final parts = _splitCategoryParts(raw);
    if (parts.mainPart.toLowerCase() == 'incoming transfer') {
      if (parts.subPart.isEmpty) {
        return const CanonicalCategoryResult(
          canonicalCategory: 'Incoming Transfer',
          mainCategory: 'Incoming Transfer',
          type: 'transfer',
        );
      }
      for (final def in _catalog) {
        if (def.mainName == 'Incoming Transfer' &&
            !def.isParent &&
            (def.subName ?? '').toLowerCase() == parts.subPart.toLowerCase()) {
          return CanonicalCategoryResult(
            canonicalCategory: def.canonicalName,
            mainCategory: def.mainName,
            subcategory: def.subName,
            type: 'transfer',
          );
        }
      }
    }
    return null;
  }

  static _CategoryDef? _resolveTextToCategory(
    String text, {
    required String preferredType,
    required bool allowCrossType,
  }) {
    final verbatim = _matchVerbatimCategory(text, preferredType);
    if (verbatim != null) return verbatim;

    final alias = _matchAliasRules(text, preferredType);
    if (alias != null) return alias;

    if (allowCrossType) {
      final otherType = preferredType == 'income' ? 'expense' : 'income';
      final crossVerbatim = _matchVerbatimCategory(text, otherType);
      if (crossVerbatim != null) return crossVerbatim;
      final crossAlias = _matchAliasRules(text, otherType);
      if (crossAlias != null) return crossAlias;
    }
    return null;
  }

  static _CategoryDef? _matchVerbatimCategory(String raw, String typeFilter) {
    final parts = _splitCategoryParts(raw);
    if (parts.mainPart.isEmpty) return null;
    final mainLower = parts.mainPart.toLowerCase();
    final subLower = parts.subPart.toLowerCase();

    if (subLower.isNotEmpty) {
      for (final def in _catalog) {
        if (def.txType != typeFilter) continue;
        if (!def.isParent &&
            def.mainName.toLowerCase() == mainLower &&
            (def.subName ?? '').toLowerCase() == subLower) {
          return def;
        }
      }
    }

    if (subLower.isEmpty) {
      for (final def in _catalog) {
        if (def.txType != typeFilter) continue;
        if (def.isParent && def.mainName.toLowerCase() == mainLower) {
          return def;
        }
      }
      for (final def in _catalog) {
        if (def.txType != typeFilter) continue;
        if (!def.isParent && (def.subName ?? '').toLowerCase() == mainLower) {
          return def;
        }
      }
    }
    return null;
  }

  static _CategoryDef? _matchAliasRules(String text, String typeFilter) {
    final tokens = _tokenizeForMatch(text);
    if (tokens.isEmpty) return null;

    var bestScore = -1;
    _CategoryDef? bestDef;

    for (final rule in _aliasRules) {
      if (rule.def.txType != typeFilter) continue;
      if (!_matchTokenSequence(tokens, rule.aliasTokens)) continue;

      final score = rule.aliasTokens.length * 100 + (rule.def.isParent ? 0 : 20);
      if (bestDef == null || score > bestScore) {
        bestScore = score;
        bestDef = rule.def;
      }
    }
    return bestDef;
  }

  static _CategoryDef? _refineMainNameWithHint(
    String mainName,
    String txType,
    String hint,
  ) {
    final hintTokens = _tokenizeForMatch(hint);
    if (hintTokens.isEmpty) return null;

    var bestScore = -1;
    _CategoryDef? bestDef;

    for (final rule in _aliasRules) {
      if (rule.def.isParent ||
          rule.def.mainName != mainName ||
          rule.def.txType != txType) {
        continue;
      }
      if (_matchTokenSequence(hintTokens, rule.aliasTokens)) {
        final score = rule.aliasTokens.length * 10;
        if (bestDef == null || score > bestScore) {
          bestScore = score;
          bestDef = rule.def;
        }
      }
    }
    return bestDef;
  }

  static bool _isGenericOthersInput(String raw) {
    final parts = _splitCategoryParts(raw);
    if (parts.mainPart.toLowerCase() == 'others' &&
        (parts.subPart.isEmpty ||
            parts.subPart.toLowerCase() == 'general uncategorized')) {
      return true;
    }
    final tokens = _tokenizeForMatch(raw);
    if (tokens.length == 1) {
      const generic = {'other', 'others', 'uncategorized', 'lainnya', 'umum'};
      if (generic.contains(tokens.first)) return true;
    }
    final joined = tokens.join(' ');
    return joined == 'general uncategorized' || joined == 'lain lain';
  }

  static bool _isTransportasiOnly(String raw) {
    final tokens = _tokenizeForMatch(raw);
    return tokens.length == 1 && tokens.first == 'transportasi';
  }

  static bool _isTransferPhrase(String raw) {
    final tokens = _tokenizeForMatch(raw);
    return tokens.length == 1 && tokens.first == 'transfer';
  }

  static ({String mainPart, String subPart}) _splitCategoryParts(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return (mainPart: '', subPart: '');
    for (final sep in const ['•', ' - ', ':']) {
      final idx = clean.indexOf(sep);
      if (idx >= 0) {
        return (
          mainPart: clean.substring(0, idx).trim(),
          subPart: clean.substring(idx + sep.length).trim(),
        );
      }
    }
    return (mainPart: clean, subPart: '');
  }

  static List<String> _tokenizeForMatch(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) return const [];
    return lower
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  static bool _matchTokenSequence(List<String> haystack, List<String> needle) {
    if (needle.isEmpty || needle.length > haystack.length) return false;
    final limit = haystack.length - needle.length;
    for (var i = 0; i <= limit; i++) {
      var matched = true;
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          matched = false;
          break;
        }
      }
      if (matched) return true;
    }
    return false;
  }

  static List<_CompiledAliasRule> _compileAliasRules(List<_CategoryDef> defs) {
    final rules = <_CompiledAliasRule>[];
    for (final def in defs) {
      for (final alias in def.aliases) {
        final tokens = _tokenizeForMatch(alias);
        if (tokens.isNotEmpty) {
          rules.add(_CompiledAliasRule(def: def, aliasTokens: tokens));
        }
      }
    }
    return rules;
  }

  static _CategoryDef _parent(
    String txType,
    String mainName, [
    List<String> aliases = const [],
  ]) {
    assert(
      TransactionCategories.findCategory(
            mainName,
            isIncome: txType == 'income',
          ) !=
          null,
      'Non-canonical parent $mainName ($txType)',
    );
    return _CategoryDef(
      txType: txType,
      mainName: mainName,
      canonicalName: mainName,
      isParent: true,
      aliases: aliases,
    );
  }

  static _CategoryDef _sub(
    String txType,
    String mainName,
    String subName, [
    List<String> aliases = const [],
  ]) {
    final canonical = '$mainName • $subName';
    assert(
      TransactionCategories.isCanonical(
        canonical,
        isIncome: txType == 'income',
      ),
      'Non-canonical subcategory $canonical ($txType)',
    );
    return _CategoryDef(
      txType: txType,
      mainName: mainName,
      subName: subName,
      canonicalName: canonical,
      isParent: false,
      aliases: aliases,
    );
  }

  static List<_CategoryDef> _buildCatalog() {
    return [
      // Income categories
      _parent('income', 'Income', ['pemasukan', 'pendapatan', 'penghasilan']),
      _sub('income', 'Income', 'Salary', [
        'gaji',
        'gajian',
        'salary',
        'payroll',
        'upah',
        'thr',
        'tunjangan',
        'honor',
        'gaji bulanan',
      ]),
      _sub('income', 'Income', 'Bonus', [
        'bonus',
        'insentif',
        'incentive',
        'komisi',
        'commission',
      ]),
      _sub('income', 'Income', 'Pocket Money', [
        'uang saku',
        'uang jajan',
        'pocket money',
        'kiriman orang tua',
      ]),
      _sub('income', 'Income', 'Additional Income', [
        'penghasilan tambahan',
        'additional income',
        'other income',
        'income other income',
        'side income',
        'extra income',
        'income others',
        'pemasukan lain',
        'side hustle',
        'sampingan',
      ]),

      _parent('income', 'Business', [
        'pemasukan bisnis',
        'omset usaha',
        'pendapatan bisnis',
      ]),
      _sub('income', 'Business', 'Sales Revenue', [
        'penjualan',
        'omzet',
        'omset',
        'jualan',
        'sales',
        'sales revenue',
        'hasil jualan',
        'pendapatan toko',
      ]),
      _sub('income', 'Business', 'Freelance & Client', [
        'freelance',
        'klien',
        'client',
        'fee proyek',
        'honor proyek',
      ]),

      _parent('income', 'Investment', ['hasil investasi', 'return investasi']),
      _sub('income', 'Investment', 'Dividends', [
        'dividen',
        'dividend',
        'dividends',
        'bagi hasil',
      ]),
      _sub('income', 'Investment', 'Capital Gains', [
        'capital gain',
        'capital gains',
        'profit saham',
        'cuan',
        'profit investasi',
      ]),
      _sub('income', 'Investment', 'Bank Interest', [
        'bunga bank',
        'bank interest',
        'bunga deposito',
        'bunga tabungan',
        'kupon sbn',
        'kupon obligasi',
      ]),

      _parent('income', 'Gift', [
        'hadiah',
        'kado',
        'hadiah masuk',
        'pemberian',
        'income gift',
      ]),
      _sub('income', 'Gift', 'From Family', [
        'hadiah keluarga',
        'from family',
        'angpao',
        'thr keluarga',
      ]),
      _sub('income', 'Gift', 'Rewards / Cashback', [
        'cashback',
        'reward',
        'rewards',
        'promo cashback',
      ]),

      _parent('income', 'Loans', ['pencairan pinjaman']),
      _sub('income', 'Loans', 'Bank Loan', [
        'pinjaman bank',
        'bank loan',
        'pencairan kredit',
      ]),
      _sub('income', 'Loans', 'Personal Borrowing', [
        'personal borrowing',
        'pinjam uang',
      ]),

      _parent('income', 'Incoming Transfer', [
        'incoming transfer',
        'transfer masuk',
      ]),
      _sub('income', 'Incoming Transfer', 'Inter-Bank Transfer', [
        'inter-bank transfer',
        'terima transfer',
      ]),
      _sub('income', 'Incoming Transfer', 'E-Wallet Top-up', [
        'e-wallet top-up',
        'topup masuk',
        'top up masuk',
      ]),

      // Expense: Daily Needs
      _parent('expense', 'Food & Beverage', [
        'makanan',
        'makan',
        'minuman',
        'minum',
        'fnb',
        'f b',
        'food',
        'beverage',
        'kuliner',
        'jajan',
        'snack',
        'cemilan',
        'air mineral',
        'air putih',
      ]),
      _sub('expense', 'Food & Beverage', 'Restaurant', [
        'warteg',
        'street food',
        'hawker',
        'restoran',
        'resto',
        'restaurant',
        'rumah makan',
        'nasi padang',
        'padang',
        'warung',
        'bakso',
        'mie ayam',
        'mie',
        'gacoan',
        'sate',
        'soto',
        'ayam geprek',
        'geprek',
        'sushi',
        'ramen',
        'solaria',
        'makan siang',
        'makan malam',
        'sarapan',
        'lunch',
        'dinner',
        'breakfast',
      ]),
      _sub('expense', 'Food & Beverage', 'Food delivery', [
        'gofood',
        'go food',
        'grabfood',
        'grab food',
        'shopeefood',
        'shopee food',
        'food delivery',
        'pesan makan',
      ]),
      _sub('expense', 'Food & Beverage', 'Coffee Shop', [
        'kopi',
        'coffee',
        'coffee shop',
        'kopi kenangan',
        'kenangan',
        'starbucks',
        'sbux',
        'fore',
        'fore coffee',
        'janji jiwa',
        'janjijiwa',
        'kopi tuku',
        'tuku',
        'point coffee',
        'tomoro',
        'kulo',
        'flash coffee',
        'chatime',
        'mixue',
        'boba',
        'cafe',
        'kafe',
        'ngopi',
        'warkop',
        'espresso',
        'latte',
      ]),
      _sub('expense', 'Food & Beverage', 'Fast Food', [
        'fast food',
        'fastfood',
        'mcd',
        'mcdonalds',
        'kfc',
        'burger king',
        'hokben',
        'richeese',
        'pizza hut',
        'pizza',
        'dominos',
        'burger',
        'fried chicken',
      ]),
      _sub('expense', 'Food & Beverage', 'Alcoholic Beverages', [
        'alcoholic beverages',
        'alkohol',
        'alcohol',
        'bir',
        'beer',
        'bir bintang',
        'wine',
        'soju',
        'cocktail',
        'whisky',
      ]),
      _sub('expense', 'Food & Beverage', 'Bakery & Cake Shop', [
        'bakery',
        'cake',
        'bakery & cake shop',
        'roti',
        'kue',
        'breadtalk',
        'mako',
        'holland bakery',
        'jco',
        'dunkin',
        'donat',
        'donut',
        'croissant',
        'martabak',
      ]),

      _parent('expense', 'Transportation', [
        'transportation',
        'transport',
        'ongkos',
      ]),
      _sub('expense', 'Transportation', 'Public Transport', [
        'public transport',
        'krl',
        'commuter',
        'commuter line',
        'mrt',
        'lrt',
        'transjakarta',
        'busway',
        'bus',
        'angkot',
        'kereta',
        'kreta',
        'kai',
        'whoosh',
      ]),
      _sub('expense', 'Transportation', 'Ride Hailing / Taxi', [
        'transportasi',
        'ojol',
        'ojek',
        'gojek',
        'goride',
        'gocar',
        'grab',
        'grabbike',
        'grabcar',
        'maxim',
        'indrive',
        'bluebird',
        'taksi',
        'taxi',
        'ride hailing',
      ]),
      _sub('expense', 'Transportation', 'Fuel & Gas', [
        'bensin',
        'bbm',
        'pertamax',
        'pertalite',
        'solar',
        'dexlite',
        'spbu',
        'pom bensin',
        'isi bensin',
        'fuel',
        'fuel & gas',
      ]),
      _sub('expense', 'Transportation', 'Parking & Toll', [
        'parkir',
        'parking',
        'e-toll',
        'etoll',
        'toll',
        'tol',
        'karcis parkir',
        'valet',
      ]),
      _sub('expense', 'Transportation', 'Vehicle Maintenance', [
        'vehicle maintenance',
        'servis motor',
        'service motor',
        'servis mobil',
        'service mobil',
        'ganti oli',
        'oli',
        'bengkel',
        'cuci mobil',
        'cuci motor',
        'tambal ban',
        'sparepart',
      ]),

      // Expense: Household Needs
      _parent('expense', 'Household Needs', [
        'household',
        'household needs',
        'kebutuhan rumah',
        'rumah tangga',
      ]),
      _sub('expense', 'Household Needs', 'Groceries / Belanja Dapur', [
        'groceries',
        'belanja dapur',
        'belanja bulanan',
        'supermarket',
        'minimarket',
        'indomaret',
        'alfamart',
        'alfamidi',
        'superindo',
        'hypermart',
        'transmart',
        'sembako',
        'beras',
        'sayur',
        'minyak goreng',
        'gas lpg',
        'elpiji',
        'galon air',
      ]),
      _sub('expense', 'Household Needs', 'Cleaning Supplies', [
        'cleaning supplies',
        'sabun cuci',
        'detergen',
        'deterjen',
        'pewangi',
        'pembersih',
        'tisu',
        'tissue',
      ]),
      _sub('expense', 'Household Needs', 'Home Repair', [
        'home repair',
        'perbaikan rumah',
        'renovasi',
        'tukang',
        'cat rumah',
      ]),
      _sub('expense', 'Household Needs', 'Rent / Sewa', [
        'rent',
        'sewa',
        'sewa rumah',
        'sewa apartemen',
        'kos',
        'kost',
        'kontrakan',
        'ipl',
        'apartemen',
      ]),

      _parent('expense', 'Bills & Utilities', [
        'tagihan',
        'bill',
        'bills',
        'utilities',
        'bills & utilities',
      ]),
      _sub('expense', 'Bills & Utilities', 'Electricity / Listrik PLN', [
        'listrik',
        'pln',
        'token listrik',
        'token pln',
        'tagihan listrik',
        'electricity',
      ]),
      _sub('expense', 'Bills & Utilities', 'Water / Air PDAM', [
        'pdam',
        'air pdam',
        'tagihan air',
        'bayar air',
        'air bersih',
        'water',
      ]),
      _sub('expense', 'Bills & Utilities', 'Internet & Wi-Fi', [
        'internet',
        'wifi',
        'wi fi',
        'indihome',
        'biznet',
        'myrepublic',
        'firstmedia',
        'first media',
      ]),
      _sub('expense', 'Bills & Utilities', 'Phone & Mobile Data', [
        'pulsa',
        'kuota',
        'paket data',
        'telkomsel',
        'indosat',
        'xl',
        'axis',
        'smartfren',
        'byu',
        'mobile data',
      ]),
      _sub('expense', 'Bills & Utilities', 'Digital Subscriptions', [
        'netflix',
        'spotify',
        'youtube premium',
        'disney',
        'icloud',
        'google one',
        'chatgpt',
        'claude',
        'canva',
        'subscription',
        'subscriptions',
        'langganan',
      ]),

      _parent('expense', 'Pets', ['pets', 'pet', 'hewan peliharaan', 'anabul']),
      _sub('expense', 'Pets', 'Pet Food', [
        'pet food',
        'makanan kucing',
        'makanan anjing',
        'whiskas',
        'royal canin',
        'pasir kucing',
      ]),
      _sub('expense', 'Pets', 'Veterinary / Dokter', [
        'dokter hewan',
        'veterinary',
        'vaksin kucing',
        'vaksin anjing',
      ]),
      _sub('expense', 'Pets', 'Grooming & Toys', [
        'grooming',
        'pet shop',
        'petshop',
        'mainan kucing',
        'mainan anjing',
      ]),

      _parent('expense', 'Family', ['family', 'keluarga']),
      _sub('expense', 'Family', 'Childcare & Needs', [
        'childcare',
        'popok',
        'diapers',
        'pampers',
        'susu anak',
        'susu bayi',
        'daycare',
        'kebutuhan anak',
      ]),
      _sub('expense', 'Family', 'Allowance to Parents', [
        'orang tua',
        'ortu',
        'kiriman ortu',
        'uang bulanan ortu',
        'allowance to parents',
      ]),
      _sub('expense', 'Family', 'Family Events', [
        'family events',
        'acara keluarga',
        'arisan',
        'reuni',
      ]),

      // Expense: Personal Needs
      _parent('expense', 'Shopping', [
        'belanja',
        'shopping',
        'tokopedia',
        'shopee',
        'lazada',
        'blibli',
        'tiktok shop',
      ]),
      _sub('expense', 'Shopping', 'Clothing & Fashion', [
        'baju',
        'celana',
        'kaos',
        'kemeja',
        'jaket',
        'hoodie',
        'dress',
        'uniqlo',
        'zara',
        'pakaian',
        'fashion',
        'clothing',
      ]),
      _sub('expense', 'Shopping', 'Electronics & Gadgets', [
        'elektronik',
        'gadget',
        'gadgets',
        'smartphone',
        'iphone',
        'samsung',
        'laptop',
        'macbook',
        'ipad',
        'headphone',
        'tws',
        'earphone',
        'charger',
        'keyboard',
        'mouse',
        'erafone',
        'ibox',
        'electronics',
      ]),
      _sub('expense', 'Shopping', 'Beauty & Skincare', [
        'skincare',
        'makeup',
        'kosmetik',
        'beauty',
        'sociolla',
        'serum',
        'sunscreen',
        'lipstik',
        'parfum',
      ]),
      _sub('expense', 'Shopping', 'Shoes & Accessories', [
        'sepatu',
        'tas',
        'jam tangan',
        'kacamata',
        'shoes',
        'accessories',
        'sneakers',
        'nike',
        'adidas',
      ]),

      _parent('expense', 'Health & Sports', [
        'kesehatan',
        'health',
        'olahraga',
        'sports',
        'health & sports',
        'medis',
      ]),
      _sub('expense', 'Health & Sports', 'Doctor & Hospital', [
        'dokter',
        'rumah sakit',
        'klinik',
        'puskesmas',
        'halodoc',
        'alodokter',
        'konsultasi dokter',
        'dokter gigi',
        'dental',
        'hospital',
        'doctor',
        'bpjs kesehatan',
      ]),
      _sub('expense', 'Health & Sports', 'Medicine & Pharmacy', [
        'obat',
        'apotek',
        'apotik',
        'kimia farma',
        'century',
        'k24',
        'guardian',
        'watsons',
        'vitamin',
        'suplemen',
        'medicine',
        'pharmacy',
      ]),
      _sub('expense', 'Health & Sports', 'Gym & Fitness Membership', [
        'gym',
        'fitness',
        'pilates',
        'yoga',
        'fithub',
        'celebrity fitness',
        'fitness first',
        'padel',
        'badminton',
        'futsal',
        'renang',
      ]),
      _sub('expense', 'Health & Sports', 'Sports Equipment', [
        'alat olahraga',
        'sports equipment',
        'raket',
        'barbel',
        'matras yoga',
      ]),

      _parent('expense', 'Donations & Gifts', [
        'donations',
        'donations & gifts',
        'sumbangan',
      ]),
      _sub('expense', 'Donations & Gifts', 'Charity & Infaq', [
        'sedekah',
        'infaq',
        'infak',
        'donasi',
        'charity',
        'amal',
        'kitabisa',
        'baznas',
      ]),
      _sub('expense', 'Donations & Gifts', 'Gifts & Presents', [
        'kado',
        'hadiah',
        'kondangan',
        'bingkisan',
        'hampers',
        'gifts',
        'presents',
      ]),
      _sub('expense', 'Donations & Gifts', 'Zakat', [
        'zakat',
        'zakat fitrah',
        'zakat mal',
        'zakat penghasilan',
      ]),

      _parent('expense', 'Travel', [
        'travel',
        'liburan',
        'vacation',
        'trip',
        'mudik',
      ]),
      _sub('expense', 'Travel', 'Flight & Train Tickets', [
        'tiket pesawat',
        'pesawat',
        'garuda',
        'citilink',
        'lion air',
        'airasia',
        'batik air',
        'tiket kereta',
        'tiket kreta',
        'kereta api',
        'traveloka',
        'tiket com',
        'flight',
        'airport',
        'bandara',
      ]),
      _sub('expense', 'Travel', 'Hotel & Lodging', [
        'hotel',
        'staycation',
        'penginapan',
        'villa',
        'resort',
        'airbnb',
        'reddoorz',
        'oyo',
        'lodging',
      ]),
      _sub('expense', 'Travel', 'Attractions & Tours', [
        'wisata',
        'tiket masuk',
        'tour',
        'dufan',
        'taman safari',
        'museum',
        'attractions',
      ]),

      _parent('expense', 'Entertainment', [
        'hiburan',
        'entertainment',
        'karaoke',
        'rekreasi',
      ]),
      _sub('expense', 'Entertainment', 'Cinema & Movies', [
        'bioskop',
        'nonton',
        'xxi',
        'cinema',
        'cgv',
        'cinepolis',
        'film',
        'movie',
        'movies',
        'tiket bioskop',
      ]),
      _sub('expense', 'Entertainment', 'Games & Top-up', [
        'game',
        'games',
        'topup game',
        'top up game',
        'steam',
        'playstation',
        'ps5',
        'nintendo',
        'mlbb',
        'mobile legends',
        'valorant',
        'genshin',
        'robux',
        'voucher game',
      ]),
      _sub('expense', 'Entertainment', 'Concerts & Events', [
        'konser',
        'concert',
        'concerts',
        'tiket konser',
        'festival',
        'pameran',
      ]),
      _sub('expense', 'Entertainment', 'Hobbies & Crafts', [
        'hobi',
        'hobby',
        'hobbies',
        'komik',
        'manga',
        'lego',
        'gundam',
        'crafts',
      ]),

      _parent('expense', 'Education', [
        'pendidikan',
        'education',
        'kuliah',
        'sekolah',
      ]),
      _sub('expense', 'Education', 'Courses & Certification', [
        'kursus',
        'course',
        'courses',
        'bootcamp',
        'udemy',
        'coursera',
        'sertifikasi',
        'bimbel',
        'ruangguru',
        'webinar',
        'seminar',
        'pelatihan',
      ]),
      _sub('expense', 'Education', 'Books & Stationery', [
        'buku',
        'gramedia',
        'alat tulis',
        'atk',
        'stationery',
        'books',
        'novel',
      ]),
      _sub('expense', 'Education', 'Tuition / SPP', [
        'spp',
        'ukt',
        'uang kuliah',
        'uang sekolah',
        'tuition',
        'uang gedung',
      ]),

      // Expense: Finance
      _parent('expense', 'Loans', ['utang', 'hutang', 'pinjaman', 'loans', 'loan']),
      _sub('expense', 'Loans', 'Mortgage / KPR', [
        'kpr',
        'cicilan rumah',
        'angsuran rumah',
        'mortgage',
      ]),
      _sub('expense', 'Loans', 'Vehicle Installment', [
        'cicilan motor',
        'cicilan mobil',
        'leasing',
        'adira',
        'fif',
        'angsuran kendaraan',
        'vehicle installment',
      ]),
      _sub('expense', 'Loans', 'Personal Loan', [
        'cicilan',
        'angsuran',
        'paylater',
        'kredivo',
        'akulaku',
        'spaylater',
        'gopaylater',
        'pinjol',
        'kta',
        'personal loan',
      ]),
      _sub('expense', 'Loans', 'Credit Card Bill', [
        'kartu kredit',
        'tagihan kartu kredit',
        'credit card',
      ]),

      _parent('expense', 'Investment', ['investasi', 'investment']),
      _sub('expense', 'Investment', 'Stocks / Saham', [
        'saham',
        'stocks',
        'stockbit',
        'ajaib',
        'bbca',
        'ipot',
        'beli saham',
      ]),
      _sub('expense', 'Investment', 'Mutual Funds / Reksadana', [
        'reksadana',
        'reksa dana',
        'mutual fund',
        'mutual funds',
        'bibit',
        'bareksa',
      ]),
      _sub('expense', 'Investment', 'Crypto Assets', [
        'crypto',
        'kripto',
        'bitcoin',
        'btc',
        'eth',
        'solana',
        'usdt',
        'pintu',
        'indodax',
        'tokocrypto',
        'binance',
      ]),
      _sub('expense', 'Investment', 'Gold / Emas', [
        'emas',
        'gold',
        'antam',
        'logam mulia',
        'pegadaian emas',
      ]),

      _parent('expense', 'Business', ['bisnis', 'usaha', 'modal usaha', 'business']),
      _sub('expense', 'Business', 'Operations & Utilities', [
        'operasional bisnis',
        'operasional toko',
        'sewa kantor',
        'gaji karyawan',
        'operations',
      ]),
      _sub('expense', 'Business', 'Inventory & Supplies', [
        'stok barang',
        'kulakan',
        'supplier',
        'inventory',
        'bahan baku',
      ]),
      _sub('expense', 'Business', 'Marketing & Ads', [
        'iklan',
        'ads',
        'meta ads',
        'facebook ads',
        'google ads',
        'tiktok ads',
        'endorse',
        'marketing',
      ]),

      _parent('expense', 'Other Financial Expenses', [
        'biaya keuangan',
        'other financial expenses',
        'keuangan lain',
      ]),
      _sub('expense', 'Other Financial Expenses', 'Bank Admin Fees', [
        'biaya admin',
        'admin bank',
        'biaya transfer',
        'biaya bulanan bank',
        'bank admin',
        'admin fee',
        'materai',
      ]),
      _sub('expense', 'Other Financial Expenses', 'Taxes / Pajak', [
        'pajak',
        'tax',
        'taxes',
        'pph',
        'ppn',
        'pbb',
        'pajak kendaraan',
        'stnk',
        'samsat',
      ]),
      _sub('expense', 'Other Financial Expenses', 'Insurance Premium', [
        'asuransi',
        'premi asuransi',
        'insurance',
        'allianz',
        'prudential',
        'aia',
        'manulife',
        'bpjs ketenagakerjaan',
      ]),

      // Expense: Services
      _parent('expense', 'Other Services', [
        'jasa',
        'layanan',
        'other services',
        'services',
      ]),
      _sub('expense', 'Other Services', 'Laundry', [
        'laundry',
        'londri',
        'cuci baju',
        'cuci sepatu',
        'dry clean',
      ]),
      _sub('expense', 'Other Services', 'Salon & Barbershop', [
        'salon',
        'barbershop',
        'potong rambut',
        'cukur',
        'pangkas rambut',
        'creambath',
        'manicure',
      ]),
      _sub('expense', 'Other Services', 'Repair & Tech Services', [
        'service hp',
        'servis hp',
        'service laptop',
        'servis laptop',
        'service ac',
        'cuci ac',
        'tukang kunci',
        'reparasi',
        'repair',
      ]),
      _sub('expense', 'Other Services', 'Courier & Postage', [
        'jne',
        'jnt',
        'j t',
        'sicepat',
        'anteraja',
        'pos indonesia',
        'gosend',
        'grabexpress',
        'paxel',
        'lalamove',
        'ongkir',
        'kurir',
        'courier',
        'postage',
      ]),

      // Expense: Others
      _parent('expense', 'Others'),
      _sub('expense', 'Others', 'General Uncategorized', [
        'general uncategorized',
        'uncategorized',
        'lainnya',
        'lain lain',
        'umum',
      ]),
    ];
  }
}
