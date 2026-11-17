import '../../consult/domain/models/consultant.dart';
import '../../consult/presentation/widgets/booking_service_mock_data.dart';
import '../domain/models/ai_chat_models.dart';
import 'ai_chat_repository.dart';
import 'local_ai_nlp_helpers.dart';

class AdvisoryMatchResult {
  final String narrative;
  final AiPackageRecommendation recommendedPackage;
  final List<AiConsultantRecommendation> recommendedConsultants;

  const AdvisoryMatchResult({
    required this.narrative,
    required this.recommendedPackage,
    required this.recommendedConsultants,
  });
}

/// Deterministic offline mirror of Go `tools_matching.go` and Module C rules.
class LocalAiConsultantMatcher {
  LocalAiConsultantMatcher._();

  static bool isDeepAdvisoryPrompt(String prompt) {
    final lower = prompt.toLowerCase();
    final hasAdvisoryCue = RegExp(
      r'\b(paylater|pinjol|galbay|restrukturisasi|kpr|suku bunga|bi rate|bi-rate|nikah|pranikah|pre-marriage|pasutri|rekening bersama|generasi sandwich|pajak|pph|umkm|hpp|runway|burn rate|fire|pensiun|asuransi|unitlink|portofolio|investasi|checkup|check-up|konsultan|praktisi|advisor)\b',
    ).hasMatch(lower);
    if (!hasAdvisoryCue) return false;

    final isExplicitGoalOrBill = RegExp(
      r'\b(buatin goal|buat goal|aturin budget|buat budget|ingetin tagihan|catat|bayar)\b',
    ).hasMatch(lower);
    if (isExplicitGoalOrBill && !lower.contains('?')) return false;
    return true;
  }

  static AdvisoryMatchResult match(
    String prompt,
    AiChatContextSnapshot snapshot,
  ) {
    final lower = prompt.toLowerCase();

    if (lower.contains('nikah') ||
        lower.contains('pranikah') ||
        lower.contains('pasutri') ||
        lower.contains('rekening bersama')) {
      return _buildResult(
        narrative:
            'Sebelum menikah, pasangan umumnya mempertimbangkan tiga pola rekening: satu rekening gabungan penuh, pemisahan rekening dengan patungan pos rutin, atau pola hybrid (satu rekening bersama untuk kebutuhan rumah tangga plus rekening pribadi masing-masing). Setiap pilihan punya konsekuensi berbeda pada transparansi utang dan fleksibilitas pribadi. Untuk menyusun kesepakatan rekening dan anggaran pernikahan sesuai kondisi kalian berdua, kamu bisa berkonsultasi dengan spesialis keuangan pasangan berizin di bawah.',
        pkg: BookingServiceMockData.couplePreMarriage,
        consultantIds: const ['c1', 'c5'],
        topics: const ['Keuangan Pranikah', 'Budget Nikah', 'Rekening Pasutri'],
        description:
            'Ingin merancang pembagian rekening pasangan dan anggaran pernikahan yang realistis.',
        expectations:
            'Mendapat skema rekening bersama dan batas anggaran acara tanpa utang konsumtif.',
        reasonFor: (c) => c.id == 'c1'
            ? 'Spesialis perencanaan individu dan pasangan pranikah dengan ${c.totalSessions} sesi selesai.'
            : 'Berpengalaman mendampingi keuangan keluarga dan pasangan lintas kebutuhan.',
      );
    }

    if (lower.contains('umkm') ||
        lower.contains('pajak') ||
        lower.contains('pph') ||
        lower.contains('hpp') ||
        lower.contains('runway')) {
      return _buildResult(
        narrative:
            'Prinsip dasar pemisahan kas usaha adalah memisahkan rekening operasional toko dari rekening pribadi, menetapkan gaji pemilik secara rutin, serta menghitung HPP sebelum menentukan margin jual. Untuk skema PPh Final UMKM 0,5%, besaran kewajiban bergantung pada omzet bruto dan status wajib pajak sesuai ketentuan berlaku. Untuk memastikan pembukuan dan kepatuhan pajak usahamu akurat, kamu bisa berdiskusi dengan praktisi UMKM dan pajak berizin di bawah.',
        pkg: lower.contains('pajak')
            ? BookingServiceMockData.umkmMedium
            : BookingServiceMockData.umkmBasic,
        consultantIds: const ['c6', 'c2'],
        topics: const ['Pemisahan Kas UMKM', 'Pajak Usaha', 'Margin & HPP'],
        description:
            'Butuh pendampingan memisahkan kas usaha dan pribadi serta mengecek kewajiban pajak UMKM.',
        expectations:
            'Memiliki struktur rekening usaha yang rapi dan kepatuhan pajak yang aman.',
        reasonFor: (c) => c.id == 'c6'
            ? 'Akuntan publik bersertifikasi CPA dan CFP spesialis pembukuan serta pajak UMKM.'
            : 'Spesialis pajak BKP dan restrukturisasi keuangan bisnis.',
      );
    }

    if (lower.contains('kpr') || lower.contains('suku bunga') || lower.contains('bi rate')) {
      return _buildResult(
        narrative:
            'Perubahan suku bunga acuan BI-Rate memengaruhi biaya dana perbankan sehingga menjadi pertimbangan penyesuaian bunga KPR floating setelah masa fixed selesai, meski waktu dan besaran penyesuaiannya mengikuti klausul kontrak masing-masing bank. Secara umum, porsi cicilan rumah yang aman berada di bawah 30% penghasilan bulanan. Untuk simulasi hitungan KPR sesuai kontrak kreditmu, silakan diskusikan bersama perencana keuangan berlisensi di bawah.',
        pkg: BookingServiceMockData.personalMedium,
        consultantIds: const ['c2', 'c1'],
        topics: const ['Simulasi KPR', 'Rasio Cicilan', 'Refinancing'],
        description:
            'Ingin mengevaluasi dampak bunga KPR floating terhadap rasio cicilan bulanan.',
        expectations:
            'Mendapat simulasi arus kas cicilan KPR dan opsi pelunasan yang terukur.',
        reasonFor: (c) => c.id == 'c2'
            ? 'Berpengalaman menangani simulasi KPR, properti, dan rasio utang rumah tangga.'
            : 'Membantu penataan arus kas dan alokasi aset untuk kebutuhan KPR.',
      );
    }

    if (lower.contains('fire') ||
        lower.contains('pensiun') ||
        lower.contains('saham') ||
        lower.contains('investasi')) {
      return _buildResult(
        narrative:
            'Dalam menyusun portofolio investasi dan target dana pensiun, prinsip utamanya adalah menyeimbangkan instrumen likuid berisiko rendah untuk dana darurat dengan aset pertumbuhan jangka panjang sesuai horizon waktu dan toleransi risiko. Clarafin AI tidak merekomendasikan produk, manajer investasi, atau saham spesifik. Untuk merancang alokasi aset personal yang sesuai profil risikomu, kamu bisa berdiskusi dengan perencana keuangan berizin di bawah.',
        pkg: BookingServiceMockData.personalPremium,
        consultantIds: const ['c4', 'c1'],
        topics: const ['Alokasi Portofolio', 'Peta Jalan FIRE', 'Dana Pensiun'],
        description:
            'Ingin menyusun alokasi portofolio jangka panjang dan target pensiun.',
        expectations:
            'Memperoleh kerangka alokasi aset yang terukur sesuai tujuan jangka panjang.',
        reasonFor: (c) => c.id == 'c4'
            ? 'Principal advisor bersertifikasi CFA dan CFP spesialis portofolio dan FIRE.'
            : 'Pendampingan bertahap menyusun investasi reksa dana dan proteksi dasar.',
      );
    }

    // Default deep advisory: PayLater / Pinjol / Cicilan / Debt & Cashflow
    final hasRatio = prompt.contains('%');
    final ratioHint = hasRatio
        ? 'Beban cicilan di kisaran porsi tersebut sudah melampaui batas aman ideal 30% dari penghasilan bulanan, sehingga ruang kas harian cenderung ketat. '
        : '';
    final cashHint = snapshot.transactions.isNotEmpty
        ? 'Total pengeluaran tercatat saat ini ${LocalAiNlpHelpers.formatIdr(_sumExpense(snapshot))}. '
        : '';

    return _buildResult(
      narrative:
          '$ratioHint${cashHint}Secara umum terdapat dua kerangka pelunasan utang konsumtif: metode Snowball (mendahulukan saldo terkecil agar arus kas cepat terasa lega) dan metode Avalanche (mendahulukan tagihan berbunga tertinggi untuk menekan total biaya bunga), masing-masing dengan trade-off terhadap likuiditas bulanan. Untuk menentukan urutan pelunasan atau restrukturisasi PayLater yang sesuai kontrak bungamu, kamu bisa berkonsultasi dengan perencana keuangan berlisensi di bawah.',
      pkg: BookingServiceMockData.personalBasic,
      consultantIds: const ['c3', 'c2', 'c1'],
      topics: const ['Pelunasan PayLater', 'Arus Kas Bulanan', 'Rasio Utang'],
      description:
          'Ingin menyusun prioritas pelunasan cicilan PayLater dan menstabilkan arus kas bulanan.',
      expectations:
          'Mendapat urutan pelunasan utang yang realistis tanpa mengganggu kebutuhan pokok.',
      reasonFor: (c) => switch (c.id) {
        'c3' =>
          'Spesialis fondasi arus kas dan bebas utang PayLater pada tier Basic.',
        'c2' =>
          'Berpengalaman menyusun restrukturisasi utang dan negosiasi cicilan.',
        _ => 'Mendampingi penataan ulang arus kas harian dan dana darurat awal.',
      },
    );
  }

  static AdvisoryMatchResult _buildResult({
    required String narrative,
    required ServiceModel pkg,
    required List<String> consultantIds,
    required List<String> topics,
    required String description,
    required String expectations,
    required String Function(Consultant) reasonFor,
  }) {
    final pkgRec = AiPackageRecommendation(
      packageCode: pkg.packageCode,
      categoryTag: pkg.categoryTag,
      packageTitle: pkg.title,
      priceIdr: pkg.basePricePerSession,
      durationMinutes: 60,
      sessionCount: 1,
    );

    final consultants = <AiConsultantRecommendation>[];
    for (var i = 0; i < consultantIds.length; i++) {
      final c = ConsultantRepository.getById(consultantIds[i]);
      if (c == null) continue;
      final services = BookingServiceMockData.getServicesForConsultant(
        c,
        preferredPackageCode: pkg.packageCode,
      );
      final selectedService = services.isNotEmpty ? services.first : pkg;
      consultants.add(
        AiConsultantRecommendation(
          consultantId: c.id,
          name: c.name,
          certifications: c.credentials
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          avatarUrl: c.avatarUrl,
          tierLabel: c.tier,
          ratingAvg: c.rating,
          totalSessionsCompleted: c.totalSessions,
          matchReason: reasonFor(c),
          nextAvailableSlotLabel: i == 0 ? 'Besok, 19:00 WIB' : 'Lusa, 10:00 WIB',
          isStaffPinned: i == 0,
          selectedPackageCode: selectedService.packageCode,
          unitPrice: selectedService.basePricePerSession,
          recommendedTopics: topics,
          prefilledDescription: description,
          prefilledExpectations: expectations,
        ),
      );
    }

    return AdvisoryMatchResult(
      narrative: narrative,
      recommendedPackage: pkgRec,
      recommendedConsultants: consultants,
    );
  }

  static double _sumExpense(AiChatContextSnapshot snapshot) {
    return snapshot.transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }
}
