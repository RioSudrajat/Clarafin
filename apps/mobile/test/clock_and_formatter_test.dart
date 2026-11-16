import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/thousand_separator_formatter.dart';
import 'package:mobile/features/consult/domain/models/consultant.dart';
import 'package:mobile/features/consult/presentation/widgets/booking_service_mock_data.dart';

void main() {
  group('ThousandSeparatorFormatter Tests', () {
    final formatter = ThousandSeparatorFormatter();

    test('Formats 250000 into 250.000', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: '250000');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('250.000'));
    });

    test('Formats 100000000 into 100.000.000', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: '100000000');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('100.000.000'));
    });

    test('Strips non-digits properly', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: 'abc 50000 xyz');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('50.000'));
    });
  });

  group('Interactive Clock Continuous Rollover Math Tests', () {
    test('Rollover from 23:45 to 00:00 when continuing clockwise', () {
      int accumulatedMinutes = 23 * 60 + 45; // 1425 minutes
      accumulatedMinutes += 15;
      int totalMinutes = accumulatedMinutes % 1440;
      if (totalMinutes < 0) totalMinutes += 1440;

      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;

      expect(hour, equals(0));
      expect(minute, equals(0));
    });

    test('Rollover from 00:00 to 01:15', () {
      int accumulatedMinutes = 0;
      accumulatedMinutes += 75; // 1 hr 15 mins
      int totalMinutes = accumulatedMinutes % 1440;
      if (totalMinutes < 0) totalMinutes += 1440;

      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;

      expect(hour, equals(1));
      expect(minute, equals(15));
    });

    test('Counter-clockwise rotation from 00:00 wraps backwards to 23:45', () {
      int accumulatedMinutes = 0;
      accumulatedMinutes -= 15;
      int totalMinutes = accumulatedMinutes % 1440;
      if (totalMinutes < 0) totalMinutes += 1440;

      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;

      expect(hour, equals(23));
      expect(minute, equals(45));
    });
  });

  group('Consultant Package Pricing Calculation Tests', () {
    test('Calculates Shopee-style min and max package pricing for consultant', () {
      final consultant = ConsultantRepository.initialConsultants.first;

      final services = BookingServiceMockData.getServicesForConsultant(consultant);
      expect(services.isNotEmpty, isTrue);

      double minPrice = services.first.basePricePerSession;
      double maxPrice = services.first.offlinePricePerSession;
      for (final s in services) {
        if (s.basePricePerSession < minPrice) minPrice = s.basePricePerSession;
        final highestTier = s.offlinePricePerSession > s.basePricePerSession
            ? s.offlinePricePerSession
            : s.basePricePerSession;
        if (highestTier > maxPrice) maxPrice = highestTier;
      }

      // Verifies that minimum price is indeed the minimum of base prices, and max price is higher (strikethrough)
      final expectedMin = services.map((s) => s.basePricePerSession).reduce((a, b) => a < b ? a : b);
      final expectedMax = services.map((s) => s.offlinePricePerSession > s.basePricePerSession ? s.offlinePricePerSession : s.basePricePerSession).reduce((a, b) => a > b ? a : b);
      expect(minPrice, equals(expectedMin));
      expect(maxPrice, equals(expectedMax));
      expect(maxPrice, greaterThan(minPrice));
    });
  });
}
