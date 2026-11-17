import '../../../core/institutions/institution_model.dart';
import '../../../core/institutions/institution_registry.dart';
import '../../../core/models/wallet_model.dart';
import '../../../core/network/tracker_remote_sync_service.dart';

/// Pure-Dart Indonesian NLP and prefilter helpers mirroring Go AI tools.
class LocalAiNlpHelpers {
  LocalAiNlpHelpers._();

  static final RegExp _danaNonWalletRegex = RegExp(
    r'\bdana\s+(darurat|pensiun|pendidikan|usaha|nikah|cadangan|sosial|investasi|rumah|liburan|menikah|tunai)\b',
  );

  static const Set<String> _blockedGreetingTokens = {
    'saldo', 'uang', 'duit', 'kopi', 'makan', 'belanja', 'cicilan',
    'paylater', 'paylaterku', 'kpr', 'budget', 'goal', 'goals', 'tagihan',
    'dompet', 'wallet', 'transaksi', 'pengeluaran', 'pemasukan', 'gaji',
    'gajian', 'catat', 'hitung', 'rekomendasi', 'konsultan', 'advisor',
    'praktisi', 'investasi', 'beli', 'bayar', 'transfer', 'pinjol', 'utang',
    'hutang', 'pajak', 'tabungan', 'nabung', 'rupiah', 'rp', 'idr', 'goceng',
    'gocap', 'cepek', 'seceng', 'ribu', 'juta', 'berapa', 'gimana',
    'bagaimana', 'kenapa', 'mengapa', 'apa', 'siapa', 'kapan', 'tolong',
    'bantu', 'cek', 'lihat', 'buat', 'buatin', 'hapus', 'edit',
  };

  static const Map<String, String> _coreGreetingReplies = {
    'assalamualaikum':
        'Waalaikumsalam! Ada yang bisa Clarafin AI bantu hari ini? Kamu bisa catat transaksi, cek saldo dompet, atau tanya seputar rencana keuanganmu.',
    'waalaikumsalam':
        'Waalaikumsalam! Ada yang bisa Clarafin AI bantu hari ini? Kamu bisa catat transaksi, cek saldo dompet, atau tanya seputar rencana keuanganmu.',
    'pagi':
        'Selamat pagi! Ada yang bisa Clarafin AI bantu hari ini? Kamu bisa catat pengeluaran, cek ringkasan kas, atau buat target keuangan.',
    'siang':
        'Selamat siang! Ada yang bisa Clarafin AI bantu? Ketik transaksi yang ingin dicatat atau tanyakan kondisi keuanganmu.',
    'sore':
        'Selamat sore! Ada yang bisa Clarafin AI bantu? Kamu bisa catat transaksi harian atau cek progres anggaranmu di sini.',
    'malam':
        'Selamat malam! Ada yang bisa Clarafin AI bantu hari ini? Kamu bisa catat pengeluaran hari ini atau tanyakan rincian keuanganmu.',
    'malem':
        'Selamat malam! Ada yang bisa Clarafin AI bantu hari ini? Kamu bisa catat pengeluaran hari ini atau tanyakan rincian keuanganmu.',
    'makasih':
        'Sama-sama! Kabari saja kalau ada transaksi yang mau dicatat atau hal keuangan lain yang ingin kamu cek.',
    'makasi':
        'Sama-sama! Kabari saja kalau ada transaksi yang mau dicatat atau hal keuangan lain yang ingin kamu cek.',
    'terimakasih':
        'Sama-sama! Kabari saja kalau ada transaksi yang mau dicatat atau hal keuangan lain yang ingin kamu cek.',
    'thanks':
        'Sama-sama! Kabari saja kalau ada transaksi yang mau dicatat atau hal keuangan lain yang ingin kamu cek.',
    'thx':
        'Sama-sama! Kabari saja kalau ada transaksi yang mau dicatat atau hal keuangan lain yang ingin kamu cek.',
    'tq':
        'Sama-sama! Kabari saja kalau ada transaksi yang mau dicatat atau hal keuangan lain yang ingin kamu cek.',
    'ok': 'Siap! Kalau ada transaksi atau pertanyaan keuangan lain, langsung tulis di sini ya.',
    'oke': 'Siap! Kalau ada transaksi atau pertanyaan keuangan lain, langsung tulis di sini ya.',
    'okee': 'Siap! Kalau ada transaksi atau pertanyaan keuangan lain, langsung tulis di sini ya.',
    'okay': 'Siap! Kalau ada transaksi atau pertanyaan keuangan lain, langsung tulis di sini ya.',
    'sip': 'Siap! Kalau ada transaksi atau pertanyaan keuangan lain, langsung tulis di sini ya.',
    'siap': 'Siap! Kalau ada transaksi atau pertanyaan keuangan lain, langsung tulis di sini ya.',
    'mantap': 'Siap! Kalau ada transaksi atau pertanyaan keuangan lain, langsung tulis di sini ya.',
    'baik': 'Siap! Kalau ada transaksi atau pertanyaan keuangan lain, langsung tulis di sini ya.',
    'bye': 'Siap! Kalau ada transaksi atau pertanyaan keuangan lain, langsung tulis di sini ya.',
  };

  static const Set<String> _generalGreetingTokens = {
    'halo', 'hallo', 'helo', 'hello', 'hai', 'hi', 'hey', 'hei', 'haloo',
  };

  static const Set<String> _greetingFillers = {
    'ya', 'yah', 'yaa', 'dong', 'deh', 'nih', 'kak', 'min', 'clarafin',
    'clara', 'ai', 'bang', 'mas', 'mba', 'mbak', 'bro', 'sis', 'banyak',
    'banget', 'bgt', 'sekali', 'juga', 'semua', 'selamat', 'terima', 'kasih',
    'thank', 'you', 'sama', 'sampai', 'jumpa', 'assalamu', 'alaikum',
  };

  static String formatIdr(num amount) {
    final rounded = amount.round();
    final sign = rounded < 0 ? '-' : '';
    final digits = rounded.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return '${sign}Rp $buf';
  }

  /// Mirrors backend `MatchPureGreeting` so zero-quota greetings return immediately.
  static String? matchPureGreeting(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty || trimmed.runes.length > 80) return null;
    if (RegExp(r'[0-9%$=<>/]').hasMatch(trimmed)) return null;

    final normalized = trimmed
        .toLowerCase()
        .replaceAll("'", '')
        .replaceAll('\u2019', '');
    final tokens = normalized
        .split(RegExp(r'[^a-z]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty || tokens.length > 6) return null;

    for (final tok in tokens) {
      if (_blockedGreetingTokens.contains(tok)) return null;
    }

    String? matchedReply;
    var hasCore = false;
    for (var i = 0; i < tokens.length; i++) {
      final tok = tokens[i];
      if (i + 1 < tokens.length) {
        final pair = '$tok ${tokens[i + 1]}';
        if (pair == 'terima kasih' || pair == 'thank you') {
          hasCore = true;
          matchedReply = _coreGreetingReplies['makasih'];
          i++;
          continue;
        }
        if (pair == 'assalamu alaikum') {
          hasCore = true;
          matchedReply = _coreGreetingReplies['assalamualaikum'];
          i++;
          continue;
        }
      }
      if (_coreGreetingReplies.containsKey(tok)) {
        hasCore = true;
        matchedReply = _coreGreetingReplies[tok];
      } else if (_generalGreetingTokens.contains(tok)) {
        hasCore = true;
        matchedReply ??=
            'Halo! Aku Clarafin AI. Kamu bisa langsung ketik transaksi untuk dicatat, cek saldo dan anggaran, atau tanya topik keuangan.';
      } else if (!_greetingFillers.contains(tok)) {
        return null;
      }
    }
    return hasCore ? matchedReply : null;
  }

  static double? parseAmount(String text) {
    final lower = text.toLowerCase();

    final jtMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:jt|juta)\b').firstMatch(lower);
    if (jtMatch != null) {
      final val = double.tryParse(jtMatch.group(1)!.replaceAll(',', '.'));
      if (val != null && val > 0) return val * 1000000.0;
    }

    final rbMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:k|rb|ribu)\b').firstMatch(lower);
    if (rbMatch != null) {
      final val = double.tryParse(rbMatch.group(1)!.replaceAll(',', '.'));
      if (val != null && val > 0) return val < 10000 ? val * 1000.0 : val;
    }

    const slangMap = <String, double>{
      'seceng': 1000.0,
      'goceng': 5000.0,
      'ceban': 10000.0,
      'gocap': 50000.0,
      'goban': 50000.0,
      'cepek': 100000.0,
      'seribu': 1000.0,
      'dua ribu': 2000.0,
      'lima ribu': 5000.0,
      'sepuluh ribu': 10000.0,
      'dua puluh ribu': 20000.0,
      'lima puluh ribu': 50000.0,
      'seratus ribu': 100000.0,
    };
    for (final entry in slangMap.entries) {
      if (RegExp('\\b${RegExp.escape(entry.key)}\\b').hasMatch(lower)) {
        return entry.value;
      }
    }

    final numMatch =
        RegExp(r'\b\d{1,3}(?:[.,]\d{3})+\b|\b\d{3,}\b').firstMatch(lower);
    if (numMatch != null) {
      final clean = numMatch.group(0)!.replaceAll('.', '').replaceAll(',', '');
      final val = double.tryParse(clean);
      if (val != null && val > 0) return val;
    }
    return null;
  }

  /// Resolves an institution mention (ordered so `blu` matches before `bca`).
  static InstitutionModel? detectInstitutionMention(String text) {
    final lower = text.toLowerCase();
    const aliasOrder = <({String id, List<String> aliases})>[
      (id: 'blu', aliases: ['blu bca', 'bca digital', 'blu']),
      (id: 'jago', aliases: ['bank jago', 'kantong jago', 'jago']),
      (id: 'jenius', aliases: ['btpn jenius', 'smbc jenius', 'jenius']),
      (id: 'seabank', aliases: ['sea bank', 'seabank']),
      (id: 'mandiri', aliases: ['livin mandiri', 'bank mandiri', 'mandiri', 'livin']),
      (id: 'bri', aliases: ['bank rakyat indonesia', 'bank bri', 'brimo', 'bri']),
      (id: 'bni', aliases: ['bank negara indonesia', 'bank bni', 'wondr', 'bni']),
      (id: 'bsi', aliases: ['bank syariah indonesia', 'bank bsi', 'byond', 'bsi']),
      (id: 'cimb', aliases: ['cimb niaga', 'cimb', 'octo']),
      (id: 'permata', aliases: ['bank permata', 'permata']),
      (id: 'bca', aliases: ['bank central asia', 'bank bca', 'bca']),
      (id: 'gopay', aliases: ['go pay', 'gopay']),
      (id: 'shopeepay', aliases: ['shopee pay', 'shopeepay', 'spay']),
      (id: 'linkaja', aliases: ['link aja', 'linkaja']),
      (id: 'ovo', aliases: ['ovo']),
      (id: 'dana', aliases: ['dompet dana', 'dana']),
      (id: 'bibit', aliases: ['bibit']),
      (id: 'stockbit', aliases: ['stockbit']),
      (id: 'cash', aliases: ['dompet tunai', 'uang tunai', 'tunai', 'cash']),
    ];

    for (final entry in aliasOrder) {
      for (final alias in entry.aliases) {
        if (entry.id == 'dana' && _danaNonWalletRegex.hasMatch(lower)) {
          continue;
        }
        if (RegExp('\\b${RegExp.escape(alias)}\\b').hasMatch(lower)) {
          return InstitutionRegistry.findById(entry.id);
        }
      }
    }
    return null;
  }

  /// Strictly matches [hint] against active [wallets] without silently substituting.
  static WalletModel? matchWalletStrict(
    String hint,
    List<WalletModel> wallets,
  ) {
    final trimmed = hint.trim();
    if (trimmed.isEmpty || wallets.isEmpty) return null;
    final lowerHint = trimmed.toLowerCase();

    for (final w in wallets) {
      if (w.name.trim().toLowerCase() == lowerHint) return w;
    }

    final spec = detectInstitutionMention(trimmed);
    if (spec != null) {
      for (final w in wallets) {
        if ((w.institutionId ?? '').trim().toLowerCase() == spec.id) return w;
      }
      for (final w in wallets) {
        if ((w.institutionId ?? '').trim().isNotEmpty) continue;
        final resolved = InstitutionRegistry.findByWallet(
          name: w.name,
          type: w.type,
        );
        if (resolved.id == spec.id) return w;
      }
      if (spec.id == 'cash') {
        for (final w in wallets) {
          if (TrackerRemoteSyncService.normalizeWalletTypeForApi(w.type) ==
              'cash') {
            return w;
          }
        }
      }
      return null;
    }

    for (final w in wallets) {
      if (w.name.toLowerCase().contains(lowerHint)) return w;
    }
    return null;
  }

  static String? extractWalletPhrase(String text) {
    final match = RegExp(
      r'\b(?:pake|pakai|via|lewat|masuk|ke|dari)\s+([a-zA-Z0-9\s]{2,24})$',
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (match != null) {
      final candidate = match.group(1)?.trim() ?? '';
      if (candidate.isNotEmpty) return candidate;
    }
    final inst = detectInstitutionMention(text);
    return inst?.name;
  }

  static String stripTrailingWalletPhrase(String text) {
    return text
        .replaceAll(
          RegExp(
            r'\b(?:pake|pakai|via|lewat|masuk|dari)\s+(?:bank\s+)?(?:bca|mandiri|bri|bni|bsi|jago|jenius|seabank|blu|cimb|permata|gopay|ovo|dana|shopeepay|linkaja|bibit|stockbit|cash|tunai)\b',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  static List<String> splitItemClauses(String text) {
    final cleaned = stripTrailingWalletPhrase(text);
    final parts = cleaned
        .split(RegExp(r'\s*\+\s*|\s+sama\s+|\s*,\s*(?=[a-zA-Z])'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.isEmpty ? [cleaned] : parts;
  }

  static String extractItemTitle(String clause, String fallbackCategory) {
    var title = stripTrailingWalletPhrase(clause)
        .replaceAll(
          RegExp(
            r'\b(abis|udah|tadi|baru|beli|bayar|buat|transaksi|catat|topup|top up|transfer|sebesar|rp|idr)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\b\d+(?:[.,]\d+)?\s*(?:jt|juta|rb|ribu|k)?\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\b(seceng|goceng|ceban|gocap|goban|cepek|seribu|dua ribu|lima ribu|sepuluh ribu|dua puluh ribu|lima puluh ribu|seratus ribu)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (title.isEmpty) return fallbackCategory.split('•').last.trim();
    return title
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static bool isIncomePrompt(String text) {
    return RegExp(
      r'\b(gaji|gajian|salary|upah|honor|bonus|thr|dividen|cashback|bunga|cuan|profit|omset|omzet|pemasukan|terima|freelance|dpt|dapat transfer)\b',
      caseSensitive: false,
    ).hasMatch(text);
  }
}
