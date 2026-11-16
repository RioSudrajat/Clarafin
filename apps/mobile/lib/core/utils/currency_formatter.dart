import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Exchange rates relative to IDR (1 unit of foreign currency = X IDR).
  static const Map<String, double> ratesToIdr = {
    'IDR': 1.0,
    'USD': 16000.0,
    'SGD': 12000.0,
    'MYR': 3600.0,
    'EUR': 17500.0,
    'JPY': 105.0,
  };

  /// Converts an amount stored in base IDR into the target currency.
  static double convertFromIdr(double amountInIdr, String targetCurrency) {
    final rate = ratesToIdr[targetCurrency.toUpperCase()] ?? 1.0;
    if (rate <= 0) return amountInIdr;
    return amountInIdr / rate;
  }

  /// Formats an amount with its currency symbol.
  /// If [isIdrBase] is true, converts from base IDR to [currencyCode] first.
  static String format(
    double amount, {
    String currencyCode = 'IDR',
    bool isIdrBase = true,
  }) {
    final code = currencyCode.toUpperCase();
    final converted = isIdrBase ? convertFromIdr(amount, code) : amount;

    switch (code) {
      case 'USD':
        final format = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);
        return converted % 1 == 0 ? format.format(converted).replaceAll('.00', '') : format.format(converted);
      case 'SGD':
        final format = NumberFormat.currency(locale: 'en_SG', symbol: r'S$', decimalDigits: 2);
        return converted % 1 == 0 ? format.format(converted).replaceAll('.00', '') : format.format(converted);
      case 'MYR':
        final format = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 2);
        return converted % 1 == 0 ? format.format(converted).replaceAll('.00', '') : format.format(converted);
      case 'EUR':
        final format = NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 2);
        return converted % 1 == 0 ? format.format(converted).replaceAll(',00', '') : format.format(converted);
      case 'JPY':
        final format = NumberFormat.currency(locale: 'ja_JP', symbol: '¥', decimalDigits: 0);
        return format.format(converted);
      case 'IDR':
      default:
        final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        return format.format(converted);
    }
  }

  /// Formats an amount WITHOUT the currency symbol (for custom styled nominals).
  /// If [isIdrBase] is true, converts from base IDR to [currencyCode] first.
  static String formatWithoutSymbol(
    double amount, {
    String currencyCode = 'IDR',
    bool isIdrBase = true,
  }) {
    final code = currencyCode.toUpperCase();
    final converted = isIdrBase ? convertFromIdr(amount, code) : amount;

    switch (code) {
      case 'USD':
        final format = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 2);
        final res = converted % 1 == 0 ? format.format(converted).replaceAll('.00', '') : format.format(converted);
        return res.trim();
      case 'SGD':
        final format = NumberFormat.currency(locale: 'en_SG', symbol: '', decimalDigits: 2);
        final res = converted % 1 == 0 ? format.format(converted).replaceAll('.00', '') : format.format(converted);
        return res.trim();
      case 'MYR':
        final format = NumberFormat.currency(locale: 'ms_MY', symbol: '', decimalDigits: 2);
        final res = converted % 1 == 0 ? format.format(converted).replaceAll('.00', '') : format.format(converted);
        return res.trim();
      case 'EUR':
        final format = NumberFormat.currency(locale: 'de_DE', symbol: '', decimalDigits: 2);
        final res = converted % 1 == 0 ? format.format(converted).replaceAll(',00', '') : format.format(converted);
        return res.trim();
      case 'JPY':
        final format = NumberFormat.currency(locale: 'ja_JP', symbol: '', decimalDigits: 0);
        return format.format(converted).trim();
      case 'IDR':
      default:
        final format = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
        return format.format(converted).trim();
    }
  }

  /// Returns the currency symbol for the given code.
  static String getSymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'SGD':
        return r'S$';
      case 'MYR':
        return 'RM ';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'IDR':
      default:
        return 'Rp ';
    }
  }
}
