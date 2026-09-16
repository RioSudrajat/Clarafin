import 'booking_service_tier_card.dart';

class BookingServiceMockData {
  static const List<ServiceModel> onlineServices = [
    ServiceModel(
      title: 'Quick Consult',
      subtitle: 'Premium',
      shortDesc: 'Konseling praktis via chat/call/video call perencana finansial.',
      fullDesc: 'Konseling keuangan praktis via chat/call/video call dengan perencana keuangan Clarafin. Cocok untuk pembahasan masalah keuangan jangka pendek atau review portofolio cepat.',
      basePricePerSession: 399000.0,
      features: [
        'Perencana keuangan berpengalaman >5 tahun',
        'Memiliki sertifikasi CFP® (Certified Financial Planner)',
        'Termasuk rangkuman hasil konsultasi & rekomendasi aksi',
      ],
    ),
    ServiceModel(
      title: 'Deep-Dive Planning',
      subtitle: 'Ultimate',
      shortDesc: 'Perencanaan keuangan komprehensif & pendampingan intensif.',
      fullDesc: 'Perencanaan keuangan komprehensif & pendampingan intensif untuk merapikan seluruh pos pengeluaran, utang, investasi, hingga waris secara mendalam.',
      basePricePerSession: 599000.0,
      features: [
        'Perencana keuangan senior berpengalaman >8 tahun',
        'Akses premium ke tools analisis cashflow Clarafin',
        'Dibuatkan blueprint perencanaan keuangan kustom (.pdf)',
        'Pendampingan intensif selama periode paket sesi',
      ],
    ),
  ];

  static const List<ServiceModel> offlineServices = [
    ServiceModel(
      title: 'Counseling Corner',
      subtitle: 'Premium',
      shortDesc: 'Konseling tatap muka private di kantor cabang Clarafin.',
      fullDesc: 'Konseling tatap muka langsung secara private di kantor cabang Clarafin dengan suasana aman dan nyaman bersama perencana keuangan profesional.',
      basePricePerSession: 499000.0,
      features: [
        'Konsultasi tatap muka langsung di private room eksklusif',
        'Perencana keuangan senior berlisensi CFP®',
        'Hardcopy blueprint keuangan dicetak eksklusif',
      ],
    ),
    ServiceModel(
      title: 'Deep-Dive Family',
      subtitle: 'Comprehensive',
      shortDesc: 'Konsultasi tatap muka keluarga & perencanaan aset.',
      fullDesc: 'Konsultasi komprehensif tatap muka untuk merancang aset keluarga, waris, dan proteksi jangka panjang secara tatap muka.',
      basePricePerSession: 799000.0,
      features: [
        'Sesi tatap muka hingga 2 anggota keluarga sekaligus',
        'Analisis komprehensif waris, pajak keluarga, & proteksi',
        'Pendampingan berkala selama 3 bulan pasca sesi',
      ],
    ),
  ];
}
