import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/consult/domain/models/consultant.dart';
import 'package:mobile/features/consult/presentation/widgets/booking_service_mock_data.dart';
import 'package:mobile/features/match_expert/domain/data/match_expert_consultants_data.dart';

void main() {
  group('Task 3.1: Canonical 6 Consultants Alignment Tests', () {
    test('ConsultantRepository and MatchExpertConsultantsData both have 6 canonical consultants', () {
      final initialConsultants = ConsultantRepository.initialConsultants;
      final matchExpertPool = MatchExpertConsultantsData.pool;

      expect(initialConsultants.length, equals(6));
      expect(matchExpertPool.length, equals(6));

      final expectedFees = {
        'c1': 299000,
        'c2': 399000,
        'c3': 199000,
        'c4': 399000,
        'c5': 349000,
        'c6': 299000,
      };

      final expectedNames = {
        'c1': 'Chrysan Gomargana, S.E., CFP®',
        'c2': 'Nurhuzaifah Amini, M.M., CFP®, BKP',
        'c3': 'Rian Pratama, S.Ak., QWP®, AWP®',
        'c4': 'Dr. Hendra Wijaya, MBA, CFA®, CFP®',
        'c5': 'Nadia Kusuma, S.Psi., CFP®, AEPP®',
        'c6': 'Budi Santoso, S.E., Ak., CPA, CFP®',
      };

      for (int i = 1; i <= 6; i++) {
        final id = 'c$i';
        final initial = initialConsultants.firstWhere((c) => c.id == id);
        final matched = matchExpertPool.firstWhere((c) => c.id == id);

        // Assert identical names across both pools
        expect(initial.name, equals(expectedNames[id]), reason: 'Initial consultant $id name mismatch');
        expect(matched.name, equals(expectedNames[id]), reason: 'Matched consultant $id name mismatch');
        expect(initial.name, equals(matched.name), reason: 'Pools have disparate names for $id');

        // Assert fees match canonical catalog
        expect(initial.feePerSession, equals(expectedFees[id]), reason: 'Initial consultant $id fee mismatch');
        expect(matched.feePerSession, equals(expectedFees[id]), reason: 'Matched consultant $id fee mismatch');
        expect(initial.feePerSession, equals(matched.feePerSession), reason: 'Pools have disparate fees for $id');

        // Assert credentials align across pools
        expect(initial.credentials, equals(matched.credentials), reason: 'Credentials disparity for $id');
      }

      // Assert specific credential tokens
      final c1 = initialConsultants.firstWhere((c) => c.id == 'c1');
      final c2 = initialConsultants.firstWhere((c) => c.id == 'c2');
      final c3 = initialConsultants.firstWhere((c) => c.id == 'c3');
      final c4 = initialConsultants.firstWhere((c) => c.id == 'c4');
      final c5 = initialConsultants.firstWhere((c) => c.id == 'c5');
      final c6 = initialConsultants.firstWhere((c) => c.id == 'c6');

      expect(c1.credentials.contains('CFP®'), isTrue);
      expect(c2.credentials.contains('BKP'), isTrue);
      expect(c3.credentials.contains('QWP®') && c3.credentials.contains('AWP®'), isTrue);
      expect(c4.credentials.contains('CFA®') && c4.credentials.contains('CFP®'), isTrue);
      expect(c5.credentials.contains('CFP®') && c5.credentials.contains('AEPP®'), isTrue);
      expect(c6.credentials.contains('CPA') && c6.credentials.contains('CFP®'), isTrue);
    });

    test('Consultant models carry canonical tier and clients handled properties', () {
      final initialConsultants = ConsultantRepository.initialConsultants;
      final tiers = {
        'c1': 'Medium',
        'c2': 'Premium',
        'c3': 'Basic',
        'c4': 'Premium',
        'c5': 'Premium',
        'c6': 'Medium',
      };
      final minClients = {
        'c1': 300,
        'c2': 500,
        'c3': 100,
        'c4': 500,
        'c5': 500,
        'c6': 300,
      };

      for (final c in initialConsultants) {
        expect(c.tier, equals(tiers[c.id]));
        expect(c.clientsHandled, greaterThanOrEqualTo(minClients[c.id]!));
      }
    });

    test('BookingServiceMockData.findPackageByCode resolves couple_pre_marriage and canonical packages', () {
      final pkg = BookingServiceMockData.findPackageByCode('couple_pre_marriage');
      expect(pkg, isNotNull);
      expect(pkg!.title, equals('Siap Menikah Tanpa Drama Finansial'));
      expect(pkg.basePricePerSession, equals(349000.0));
      expect(pkg.offlinePricePerSession, equals(529000.0));
      expect(pkg.packageCode, equals('couple_pre_marriage'));
    });

    test('BookingServiceMockData.getServicesForConsultant honors preferredPackageCode prioritization', () {
      final consultant = ConsultantRepository.initialConsultants.firstWhere((c) => c.id == 'c1');
      final servicesWithPref = BookingServiceMockData.getServicesForConsultant(
        consultant,
        preferredPackageCode: 'couple_pre_marriage',
      );

      expect(servicesWithPref.isNotEmpty, isTrue);
      expect(servicesWithPref.first.packageCode, equals('couple_pre_marriage'));
    });
  });
}
