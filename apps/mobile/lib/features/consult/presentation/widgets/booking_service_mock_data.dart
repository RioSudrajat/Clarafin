import 'booking_service_tier_card.dart';
import '../../domain/models/consultant.dart';

export 'booking_service_tier_card.dart' show BookingServiceItem, ServiceModel;

class BookingServiceMockData {
  // 1. Personal Advisory (Individu)
  static const ServiceModel personalBasic = ServiceModel(
    packageCode: 'personal_basic',
    title: 'Fondasi Arus Kas & Utang',
    subtitle: 'Basic',
    categoryTag: 'Personal Advisory • Basic',
    shortDesc: 'Rapikan cashflow bulanan, utang PayLater, dan dana darurat pertama.',
    fullDesc: 'Konseling finansial 1-on-1 (60 menit) untuk menghentikan siklus gaji selalu habis, restrukturisasi cicilan, serta menyusun dana darurat pertama yang realistis.',
    basePricePerSession: 199000.0,
    offlinePricePerSession: 349000.0,
    features: [
      'Praktisi berlisensi resmi QWP® / AWP® / RFP® (< 300 klien)',
      'Review riwayat pengeluaran 30 hari & bedah pos bocor halus',
      'Rekomendasi strategi pelunasan utang/PayLater prioritas',
      'Action plan 30 hari & template cashflow Clarafin',
    ],
  );

  static const ServiceModel personalMedium = ServiceModel(
    packageCode: 'personal_medium',
    title: 'Optimalisasi Aset & Proteksi',
    subtitle: 'Medium',
    categoryTag: 'Personal Advisory • Medium',
    shortDesc: 'Investasi reksa dana/saham, evaluasi asuransi, & persiapan KPR.',
    fullDesc: 'Perencanaan keuangan komprehensif bersama Senior CFP® untuk menyusun portofolio investasi seimbang, audit polis asuransi, dan kalkulasi aman pengajuan KPR.',
    basePricePerSession: 299000.0,
    offlinePricePerSession: 449000.0,
    features: [
      'Perencana Keuangan tersertifikasi resmi CFP® / BKP (301-500 klien)',
      'Audit alokasi investasi reksa dana, obligasi SBN, & saham',
      'Evaluasi kecukupan polis asuransi jiwa & kesehatan',
      'Simulasi kelayakan KPR & rasio DSR terhadap penghasilan',
    ],
  );

  static const ServiceModel personalPremium = ServiceModel(
    packageCode: 'personal_premium',
    title: 'Menuju Kebebasan Finansial',
    subtitle: 'Premium',
    categoryTag: 'Personal Advisory • Premium',
    shortDesc: 'Peta jalan Financial Freedom (FIRE), passive income, & pensiun.',
    fullDesc: 'Perencanaan kekayaan tingkat lanjut bersama Principal CFP®/CFA® untuk membangun passive income dividen/properti, efisiensi pajak pribadi, dan percepatan FIRE.',
    basePricePerSession: 399000.0,
    offlinePricePerSession: 599000.0,
    features: [
      'Praktisi Senior CFP® Senior / CFA® / AEPP® (> 500 klien)',
      'Peta jalan Financial Freedom (FIRE) & strategi passive income',
      'Perencanaan waris, proteksi kekayaan, & efisiensi pajak SPT',
      'Blueprint Master Financial Plan (.pdf) & pendampingan prioritas',
    ],
  );

  // 2. Couple Advisory (Pasangan & Keluarga)
  static const ServiceModel couplePreMarriage = ServiceModel(
    packageCode: 'couple_pre_marriage',
    title: 'Siap Menikah Tanpa Drama Finansial',
    subtitle: 'Pre-Marriage',
    categoryTag: 'Couple Advisory • Pre-Marriage',
    shortDesc: 'Buka-bukaan finansial sebelum akad, budget nikah, & rekening bersama.',
    fullDesc: 'Sesi privat 60 menit bersama perencana keuangan spesialis pranikah untuk menyepakati manajemen uang suami-istri tanpa rasa canggung sebelum melangkah ke pelaminan.',
    basePricePerSession: 349000.0,
    offlinePricePerSession: 529000.0,
    features: [
      'Praktisi CFP® spesialis keuangan pasangan (301-500 klien)',
      'Diskusi terbuka profil utang, aset bawaan, & transparansi gaji',
      'Penyusunan anggaran pernikahan tanpa jerat utang baru',
      'Kesepakatan model rekening keluarga (1 pintu / 2 pintu)',
    ],
  );

  static const ServiceModel coupleMarriage = ServiceModel(
    packageCode: 'couple_marriage',
    title: 'Satu Visi Bangun Aset Keluarga',
    subtitle: 'Marriage',
    categoryTag: 'Couple Advisory • Marriage',
    shortDesc: 'Lepas dari generasi sandwich, dana anak, & percepat lunas KPR.',
    fullDesc: 'Pendampingan finansial rumah tangga untuk menyelaraskan prioritas hidup bersama, mengamankan dana pendidikan anak hingga kuliah, dan menuntaskan KPR lebih cepat.',
    basePricePerSession: 399000.0,
    offlinePricePerSession: 599000.0,
    features: [
      'Praktisi Senior CFP® spesialis keluarga (> 400 klien)',
      'Strategi mengelola beban generasi sandwich tanpa konflik',
      'Proyeksi biaya sekolah & inflasi dana pendidikan anak',
      'Simulasi percepatan pelunasan KPR keluarga',
    ],
  );

  static const ServiceModel couplePremium = ServiceModel(
    packageCode: 'couple_premium',
    title: 'Mapan Finansial Lintas Generasi',
    subtitle: 'Premium',
    categoryTag: 'Couple Advisory • Premium',
    shortDesc: 'Proteksi pencari nafkah, studi luar negeri, hibah & waris keluarga.',
    fullDesc: 'Perencanaan kekayaan keluarga besar dan perlindungan aset lintas generasi bersama Master Planner untuk memastikan kemakmuran keluarga terus berlanjut tanpa sengketa.',
    basePricePerSession: 549000.0,
    offlinePricePerSession: 799000.0,
    features: [
      'Praktisi Utama CFP® Senior / AEPP® (> 500 klien)',
      'Proteksi komprehensif penghasilan kepala keluarga',
      'Persiapan dana studi internasional & mata uang asing',
      'Penataan hibah dan waris keluarga bebas konflik hukum',
    ],
  );

  // 3. UMKM Advisory
  static const ServiceModel umkmBasic = ServiceModel(
    packageCode: 'umkm_basic',
    title: 'Omzet Ramai, Untung Nyata di Rekening',
    subtitle: 'Basic',
    categoryTag: 'UMKM Advisory • Basic',
    shortDesc: 'Hentikan kebocoran uang toko tercampur uang dapur & hitung HPP tepat.',
    fullDesc: 'Bedah keuangan usaha mikro-kecil bersama Akuntan/QWP® untuk memisahkan rekening pribadi vs bisnis, menentukan gaji pemilik, dan menetapkan HPP yang menguntungkan.',
    basePricePerSession: 349000.0,
    offlinePricePerSession: 549000.0,
    features: [
      'Konsultan Keuangan Bisnis / Akuntan (QWP® / Brevet AB)',
      'Pemisahan kas operasional usaha dari pengeluaran rumah tangga',
      'Penetapan formula HPP (COGS) & margin harga jual yang sehat',
      'Template pencatatan arus kas harian toko/warung sederhana',
    ],
  );

  static const ServiceModel umkmMedium = ServiceModel(
    packageCode: 'umkm_medium',
    title: 'Ekspansi Cabang & Aman Pajak Bisnis',
    subtitle: 'Medium',
    categoryTag: 'UMKM Advisory • Medium',
    shortDesc: 'Kelayakan buka cabang, kredit modal kerja bank, & kepatuhan pajak.',
    fullDesc: 'Konsultasi pertumbuhan usaha bersama Senior CFP®/BKP untuk menguji kelayakan ekspansi cabang baru, persiapan pengajuan kredit bank, serta strategi pajak UMKM aman denda.',
    basePricePerSession: 549000.0,
    offlinePricePerSession: 799000.0,
    features: [
      'Konsultan Pajak & Bisnis Senior (CFP® / BKP / CPA)',
      'Analisis kelayakan investasi cabang baru tanpa ganggu kas',
      'Strategi restrukturisasi kredit modal usaha perbankan',
      'Audit kepatuhan pajak UMKM (PPh Final 0,5% vs PKP)',
    ],
  );

  static const ServiceModel umkmPremium = ServiceModel(
    packageCode: 'umkm_premium',
    title: 'Perpanjang Runway & Siap Pendanaan Investor',
    subtitle: 'Premium',
    categoryTag: 'UMKM Advisory • Premium',
    shortDesc: 'Kendalikan burn rate, optimasi CAC/LTV, & model proyeksi investor.',
    fullDesc: 'Sesi Fractional CFO bersama Principal Advisor/CFA® untuk memperpanjang cash runway startup, perbaikan unit economics, dan kesiapan dokumen due diligence investor.',
    basePricePerSession: 849000.0,
    offlinePricePerSession: 1199000.0,
    features: [
      'CFA® / Fractional CFO / Principal Advisor (> 500 klien)',
      'Pengendalian burn rate & perpanjangan cash runway bisnis',
      'Perbaikan unit economics (CAC, LTV, Gross Margin)',
      'Financial projection model & due diligence checklist',
    ],
  );

  // 4. Corporate Wellness & Advisory
  static const ServiceModel corporateBasic = ServiceModel(
    packageCode: 'corporate_basic',
    title: 'Karyawan Produktif Bebas Jerat Pinjol',
    subtitle: 'Basic',
    categoryTag: 'Corporate Wellness • Basic',
    shortDesc: 'Townhall 90 menit edukasi gaji, putus kasbon & pinjol karyawan.',
    fullDesc: 'Workshop edukasi interaktif 90 menit bersama CFP® untuk meningkatkan literasi finansial karyawan, memutus siklus gali lubang tutup lubang, dan memulihkan fokus kerja.',
    basePricePerSession: 2500000.0,
    offlinePricePerSession: 4500000.0,
    features: [
      'Dipandu langsung CFP® trainer korporasi berpengalaman',
      'Workshop interaktif pengelolaan gaji & simulasi dana darurat',
      'Strategi keluar dari jeratan pinjol ilegal & kasbon kantor',
      'E-Handout materi & toolkit kalkulator anggaran karyawan',
    ],
  );

  static const ServiceModel corporateMedium = ServiceModel(
    packageCode: 'corporate_medium',
    title: 'Klinik Finansial Privat & Retensi Talenta',
    subtitle: 'Medium',
    categoryTag: 'Corporate Wellness • Medium',
    shortDesc: 'Paket 5 slot konsultasi rahasia 1-on-1 bagi karyawan kunci HR.',
    fullDesc: 'Program benefit karyawan berupa 5 sesi konsultasi privat (masing-masing 60 menit) bersama tim CFP® terverifikasi untuk membantu menyelesaikan beban finansial individu.',
    basePricePerSession: 1490000.0,
    offlinePricePerSession: 2250000.0,
    features: [
      'Paket 5 slot sesi konsultasi 1-on-1 bersama tim CFP®/QWP®',
      '100% Kerahasiaan data karyawan terlindungi standar etik',
      'Penyelesaian masalah utang, KPR, dan persiapan dana anak',
      'Laporan agregat anonim kesehatan finansial tim untuk HRD',
    ],
  );

  static const ServiceModel corporatePremium = ServiceModel(
    packageCode: 'corporate_premium',
    title: 'Optimalisasi Kas Korporasi & Pajak Eksekutif',
    subtitle: 'Premium',
    categoryTag: 'Corporate Advisory • Premium',
    shortDesc: 'Corporate treasury kas menganggur, pajak badan, & pensiun direksi.',
    fullDesc: 'Konsultasi tingkat tinggi bersama CFA®/CPA/Konsultan Pajak Terdaftar untuk penempatan likuiditas kas perusahaan menganggur dan perencanaan pajak eksekutif.',
    basePricePerSession: 1490000.0,
    offlinePricePerSession: 2190000.0,
    features: [
      'CFA® / CPA / Konsultan Pajak Terdaftar (> 500 klien)',
      'Penempatan dana kas menganggur (Corporate Treasury)',
      'Optimalisasi efisiensi pajak penghasilan badan usaha',
      'Skema golden parachute & kompensasi pensiun jajaran direksi',
    ],
  );

  // 5. Financial Check-Up
  static const ServiceModel checkUpBasic = ServiceModel(
    packageCode: 'checkup_basic',
    title: 'Bongkar Bocor Halus & Skor Keuanganmu',
    subtitle: 'Basic',
    categoryTag: 'Financial Check-Up • Basic',
    shortDesc: 'Rapor skor 4 rasio keuangan utama & resep perbaikan 30 hari.',
    fullDesc: 'Sesi bedah kilat 45 menit bersama AWP®/QWP® untuk mendeteksi sumber kebocoran uang bulanan dan mendapatkan skor kesehatan finansial yang jelas beserta panduan aksi.',
    basePricePerSession: 149000.0,
    offlinePricePerSession: 279000.0,
    features: [
      'Praktisi AWP® / QWP® (< 300 klien) + sesi bedah 45 menit',
      'Rapor skor 4 rasio keuangan: Tabungan, Utang, Darurat, & Gaya Hidup',
      'Identifikasi titik kebocoran pengeluaran yang tidak disadari',
      'Resep perbaikan finansial 30 hari dalam format ringkas',
    ],
  );

  static const ServiceModel checkUpMedium = ServiceModel(
    packageCode: 'checkup_medium',
    title: 'Bedah Tuntas Portofolio & Polis Asuransi',
    subtitle: 'Medium',
    categoryTag: 'Financial Check-Up • Medium',
    shortDesc: 'Audit seluruh polis asuransi & evaluasi kinerja portofolio investasi.',
    fullDesc: 'Sesi review mendalam 60 menit bersama CFP® independen untuk memastikan premi asuransi tidak kemahalan dan racikan investasi sudah optimal sesuai tujuan jangka panjang.',
    basePricePerSession: 279000.0,
    offlinePricePerSession: 429000.0,
    features: [
      'Praktisi CFP® independen (301-500 klien) + sesi 60 menit',
      'Audit independen polis asuransi (premi vs manfaat perlindungan)',
      'Evaluasi portofolio reksa dana, saham, crypto, & emas',
      'Rekomendasi rebalancing aset tanpa bias penjualan produk',
    ],
  );

  static const ServiceModel checkUpPremium = ServiceModel(
    packageCode: 'checkup_premium',
    title: 'Peta Jalan Kekayaan & Pensiun Dini (360°)',
    subtitle: 'Premium',
    categoryTag: 'Financial Check-Up • Premium',
    shortDesc: 'Master Financial Blueprint PDF 10 tahun, target FIRE, & alokasi aset.',
    fullDesc: 'Pemeriksaan kesehatan keuangan holistik 90 menit bersama Principal CFP®/CFA® menghasilkan cetak biru kekayaan 10 tahun untuk mencapai pensiun dini dengan rasa aman.',
    basePricePerSession: 499000.0,
    offlinePricePerSession: 699000.0,
    features: [
      'Praktisi Senior CFP® / CFA® (> 500 klien) + sesi 90 menit',
      'Dokumen Master Financial Blueprint PDF 10 tahun',
      'Kalkulasi angka pasti dana pensiun dini (FIRE) & inflasi riil',
      'Matriks alokasi aset multi-instrumen & roadmap eksekusi bulanan',
    ],
  );

  // All 15 canonical catalog packages
  static const List<ServiceModel> allPackages = [
    personalBasic,
    personalMedium,
    personalPremium,
    couplePreMarriage,
    coupleMarriage,
    couplePremium,
    umkmBasic,
    umkmMedium,
    umkmPremium,
    corporateBasic,
    corporateMedium,
    corporatePremium,
    checkUpBasic,
    checkUpMedium,
    checkUpPremium,
  ];

  // Default Online & Offline fallback lists
  static const List<ServiceModel> onlineServices = [
    personalBasic,
    personalMedium,
    personalPremium,
  ];

  static const List<ServiceModel> offlineServices = [
    personalBasic,
    personalMedium,
    personalPremium,
  ];

  /// Resolves the specific package by its canonical code or accepted alias
  static ServiceModel? findPackageByCode(String code) {
    final normalized = code.toLowerCase().trim();
    for (final pkg in allPackages) {
      if (pkg.packageCode.toLowerCase() == normalized) {
        return pkg;
      }
    }
    // Canonical aliases support
    switch (normalized) {
      case 'corporate_workshop':
        return corporateBasic;
      case 'corporate_employee_benefit':
        return corporateMedium;
      case 'corporate_consultation':
      case 'corporate_financial_audit':
        return corporatePremium;
      default:
        return null;
    }
  }

  /// Resolves the specific package list tailored to the consultant's category and tier
  static List<ServiceModel> getServicesForConsultant(
    Consultant consultant, {
    bool isOnline = true,
    String? preferredPackageCode,
  }) {
    final certs = consultant.credentials.toLowerCase();
    final specs = consultant.specializations.map((s) => s.toLowerCase()).join(' ');

    List<ServiceModel> list;
    switch (consultant.id) {
      case 'c1':
        list = [personalMedium, couplePreMarriage, coupleMarriage, checkUpMedium];
        break;
      case 'c2':
        list = [personalPremium, umkmMedium, umkmPremium, checkUpPremium];
        break;
      case 'c3':
        list = [personalBasic, umkmBasic, checkUpBasic];
        break;
      case 'c4':
        list = [personalPremium, umkmPremium, corporatePremium, checkUpPremium];
        break;
      case 'c5':
        list = [
          couplePreMarriage,
          coupleMarriage,
          couplePremium,
          personalPremium,
          checkUpMedium,
          checkUpPremium,
        ];
        break;
      case 'c6':
        list = [umkmBasic, umkmMedium, corporateBasic, corporateMedium, personalMedium];
        break;
      default:
        if (specs.contains('pasangan') || specs.contains('keluarga') || specs.contains('nikah')) {
          list = [couplePreMarriage, coupleMarriage, couplePremium];
        } else if (specs.contains('umkm') || specs.contains('bisnis') || specs.contains('usaha')) {
          list = [umkmBasic, umkmMedium, umkmPremium];
        } else if (specs.contains('pajak') || certs.contains('bkp') || certs.contains('cpa')) {
          list = [personalMedium, umkmMedium, personalPremium];
        } else if (certs.contains('cfa') || specs.contains('pensiun') || specs.contains('wealth')) {
          list = [personalMedium, personalPremium, checkUpPremium];
        } else {
          list = [personalBasic, personalMedium, personalPremium];
        }
    }

    if (preferredPackageCode != null && preferredPackageCode.isNotEmpty) {
      final preferred = findPackageByCode(preferredPackageCode);
      if (preferred != null) {
        final result = List<ServiceModel>.from(list);
        result.removeWhere((s) => s.packageCode == preferred.packageCode);
        result.insert(0, preferred);
        return result;
      }
    }
    return list;
  }
}
