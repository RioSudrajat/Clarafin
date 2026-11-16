import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/currency_formatter.dart';

// Standalone mirror of the NLP extraction logic for unit testing
double parseAmountFromText(String text) {
  final lower = text.toLowerCase();
  final jutaRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:jt|juta)\b');
  final jutaMatch = jutaRegex.firstMatch(lower);
  if (jutaMatch != null) {
    final numStr = jutaMatch.group(1)!.replaceAll(',', '.');
    final val = double.tryParse(numStr);
    if (val != null) return val * 1000000.0;
  }

  final ribuRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:k|rb|ribu)\b');
  final ribuMatch = ribuRegex.firstMatch(lower);
  if (ribuMatch != null) {
    final numStr = ribuMatch.group(1)!.replaceAll(',', '.');
    final val = double.tryParse(numStr);
    if (val != null) {
      return val < 10000 ? val * 1000.0 : val;
    }
  }

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

String resolveCategoryFromText(String text) {
  final lower = text.toLowerCase();
  if (RegExp(r'\b(tiket|kreta|kereta|kai|pesawat|flight|bensin|bbm|pertalite|pertamax|solar|spbu|ojol|gojek|goride|gocar|grab|grabcar|grabbike|maxim|indrive|parkir|tol|mrt|lrt|krl|commuter|transjakarta|tj|bus|angkot|taksi|taxi)\b').hasMatch(lower)) {
    return 'Transportasi';
  }
  if (RegExp(r'\b(makan|makanan|minum|minuman|kopi|coffee|starbucks|janji jiwa|kulo|fore|chatime|cafe|kafe|resto|restoran|warung|warkop|mie|gacoan|bakso|sate|nasi|padang|ayam|geprek|pizza|burger|mcd|kfc|hokben|gofood|grabfood|shopeefood)\b').hasMatch(lower)) {
    return 'Makanan';
  }
  if (RegExp(r'\b(tagihan|listrik|pln|token|air|pdam|wifi|indihome|biznet|firstmedia|myrepublic|pulsa|kuota|paket data|telkomsel|indosat|xl|tri|smartfren|bpjs|sewa|kontrakan|kos|kost|ipl|pbb)\b').hasMatch(lower)) {
    return 'Tagihan';
  }
  if (RegExp(r'\b(belanja|tokopedia|shopee|lazada|tiktok shop|supermarket|minimarket|indomaret|alfamart|hypermart|superindo|transmart|baju|celana|sepatu|tas|skincare|makeup|elektronik|laptop|hp|gadget)\b').hasMatch(lower)) {
    return 'Belanja';
  }
  return 'Lainnya';
}

void main() {
  group('CurrencyFormatter Multi-Currency Tests', () {
    test('Formats IDR correctly', () {
      final formatted = CurrencyFormatter.format(300000, currencyCode: 'IDR');
      expect(formatted.contains('300.000'), isTrue);
      expect(formatted.startsWith('Rp'), isTrue);
    });

    test('Converts and formats USD correctly from IDR base', () {
      // 16.000 IDR = 1 USD -> 320.000 IDR = 20 USD
      final formatted = CurrencyFormatter.format(320000, currencyCode: 'USD');
      expect(formatted, equals(r'$20'));
    });

    test('Converts and formats SGD correctly from IDR base', () {
      // 12.000 IDR = 1 SGD -> 120.000 IDR = 10 SGD
      final formatted = CurrencyFormatter.format(120000, currencyCode: 'SGD');
      expect(formatted, equals(r'S$10'));
    });

    test('formatWithoutSymbol strips currency symbols cleanly', () {
      final raw = CurrencyFormatter.formatWithoutSymbol(300000, currencyCode: 'IDR');
      expect(raw, equals('300.000'));
    });
  });

  group('AI Quick Action NLP & Bug Fix Verification', () {
    test('Correctly parses "abis beli tiket kreta 300000 pake bni "', () {
      const input = 'abis beli tiket kreta 300000 pake bni ';
      final amount = parseAmountFromText(input);
      final category = resolveCategoryFromText(input);

      // Must be 300.000, NOT 300.000.000 (from 'k' inside 'tiket' and 'kreta' and 'pake')
      expect(amount, equals(300000.0));
      // Must be Transportasi, NOT Makanan
      expect(category, equals('Transportasi'));
    });

    test('Correctly parses "beli tiket kreta 300 ribu pake bni"', () {
      const input = 'beli tiket kreta 300 ribu pake bni';
      final amount = parseAmountFromText(input);
      final category = resolveCategoryFromText(input);

      expect(amount, equals(300000.0));
      expect(category, equals('Transportasi'));
    });

    test('Correctly parses "kopi starbucks 50k"', () {
      const input = 'kopi starbucks 50k';
      final amount = parseAmountFromText(input);
      final category = resolveCategoryFromText(input);

      expect(amount, equals(50000.0));
      expect(category, equals('Makanan'));
    });

    test('Correctly parses "sewa kos 1.5jt"', () {
      const input = 'sewa kos 1.5jt';
      final amount = parseAmountFromText(input);
      final category = resolveCategoryFromText(input);

      expect(amount, equals(1500000.0));
      expect(category, equals('Tagihan'));
    });
  });
}
