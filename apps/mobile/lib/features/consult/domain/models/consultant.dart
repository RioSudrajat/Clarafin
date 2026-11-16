class Consultant {
  final String id;
  final String name;
  final String title;
  final String credentials;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final int totalSessions;
  final String experienceYears;
  final String location;
  final List<String> methods; // 'Online', 'Tatap Muka'
  final List<String> specializations;
  final int feePerSession;
  final String bio;
  final bool isFullyBooked;
  final String gender;
  final List<String> languages;

  const Consultant({
    required this.id,
    required this.name,
    required this.title,
    required this.credentials,
    required this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.totalSessions,
    required this.experienceYears,
    required this.location,
    required this.methods,
    required this.specializations,
    required this.feePerSession,
    required this.bio,
    this.isFullyBooked = false,
    required this.gender,
    required this.languages,
  });
}

class ConsultantRepository {
  static List<Consultant> get initialConsultants {
    return const [
      Consultant(
        id: 'c1',
        name: 'Chrysan Gomargana, S.E., CFP®',
        title: 'Financial Planner & Wealth Consultant',
        credentials: 'CFP® Certified Financial Planner',
        avatarUrl:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&fit=crop&crop=faces',
        rating: 4.95,
        reviewCount: 142,
        totalSessions: 181,
        experienceYears: '5+ Thn',
        location: 'Jakarta Selatan, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: [
          'Cashflow & Budgeting',
          'Investasi Reksadana',
          'Dana Darurat',
          'Pasangan & Pranikah',
          'Asuransi Jiwa & Kesehatan',
          'Perencanaan Individu',
          'Keuangan Keluarga',
        ],
        feePerSession: 180000,
        bio:
            'Fokus mendampingi individu dan pasangan muda dalam merapikan arus kas, menyiapkan dana darurat, dan memulai portofolio investasi terukur.',
        gender: 'Perempuan',
        languages: ['Indonesia', 'Inggris'],
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c2',
        name: 'Nurhuzaifah Amini, M.M., CFP®',
        title: 'Debt Relief & Tax Specialist',
        credentials: 'CFP®, Registered Financial Planner',
        avatarUrl:
            'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&fit=crop&crop=faces',
        rating: 4.92,
        reviewCount: 198,
        totalSessions: 245,
        experienceYears: '6+ Thn',
        location: 'Tangerang Selatan, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: [
          'Restrukturisasi Utang',
          'Bebas Hutang & Pinjol',
          'Pajak & Bisnis UMKM',
          'KPR & Properti',
          'Asuransi Jiwa & Kesehatan',
          'Cashflow & Budgeting',
        ],
        feePerSession: 220000,
        bio:
            'Spesialis dalam pemulihan kesehatan finansial dari jeratan hutang konsumtif, optimasi pajak pribadi & UMKM, serta negosiasi restrukturisasi utang.',
        gender: 'Perempuan',
        languages: ['Indonesia', 'Inggris'],
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c3',
        name: 'Upik Nuri Budi S., QWP®, RFC®',
        title: 'Senior Family & Business Strategist',
        credentials: 'RFC®, Qualified Wealth Planner',
        avatarUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&fit=crop&crop=faces',
        rating: 4.88,
        reviewCount: 265,
        totalSessions: 320,
        experienceYears: '10+ Thn',
        location: 'Surabaya, Indonesia',
        methods: ['Online'],
        specializations: [
          'Keuangan UMKM & Bisnis',
          'Dana Pendidikan Anak',
          'Keuangan Keluarga',
          'Dana Pensiun',
          'Pajak & Bisnis',
          'Pasangan & Pranikah',
        ],
        feePerSession: 300000,
        bio:
            'Membantu pemilik bisnis UMKM memisahkan keuangan pribadi vs usaha, serta mengamankan dana pendidikan anak dan masa pensiun keluarga.',
        gender: 'Perempuan',
        languages: ['Indonesia', 'Inggris', 'Jawa'],
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c4',
        name: 'Dimas Pratama, S.E., CFP®',
        title: 'Investment & Portfolio Advisor',
        credentials: 'CFP®, Chartered Portfolio Manager',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&fit=crop&crop=faces',
        rating: 4.90,
        reviewCount: 167,
        totalSessions: 210,
        experienceYears: '5+ Thn',
        location: 'Jakarta Pusat, Indonesia',
        methods: ['Online'],
        specializations: [
          'Investasi & Saham',
          'Investasi Reksadana',
          'Crypto & Asset Digital',
          'FIRE (Financial Freedom)',
          'Dana Darurat & Pensiun',
          'Perencanaan Individu',
          'Manajemen Utang',
        ],
        feePerSession: 200000,
        bio:
            'Membantu profesional muda membangun portofolio investasi agresif terukur untuk mencapai kemerdekaan finansial di usia produktif.',
        gender: 'Laki-laki',
        languages: ['Indonesia', 'Inggris'],
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c5',
        name: 'Reza Firmansyah, MBA, CFP®',
        title: 'Executive Wealth & SME Consultant',
        credentials: 'CFP®, MBA Financial Management',
        avatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&fit=crop&crop=faces',
        rating: 4.96,
        reviewCount: 340,
        totalSessions: 410,
        experienceYears: '12+ Thn',
        location: 'Bandung, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: [
          'Pajak & Bisnis UMKM',
          'Arus Kas Bisnis & Korporat',
          'Dana Pensiun & Waris',
          'Keuangan Keluarga',
          'Investasi Reksadana & Saham',
        ],
        feePerSession: 350000,
        bio:
            'Konsultan senior untuk perencanaan bisnis keluarga, optimasi pajak korporat, dan preservasi kekayaan jangka panjang lintas generasi.',
        gender: 'Laki-laki',
        languages: ['Indonesia', 'Inggris', 'Mandarin'],
        isFullyBooked: true,
      ),
      Consultant(
        id: 'c6',
        name: 'Budi Santoso, S.E., CFP®, QWP®',
        title: 'Personal Finance & Debt Recovery Specialist',
        credentials: 'CFP®, Qualified Wealth Planner',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&fit=crop&crop=faces',
        rating: 4.93,
        reviewCount: 175,
        totalSessions: 220,
        experienceYears: '7+ Thn',
        location: 'Yogyakarta, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: [
          'Perencanaan Individu',
          'Restrukturisasi Utang',
          'Bebas Hutang & KPR',
          'Audit Polis Asuransi',
          'Dana Darurat & Cashflow',
        ],
        feePerSession: 190000,
        bio:
            'Membimbing individu mandiri dan pekerja lepas mengatasi masalah utang, audit polis proteksi asuransi, dan merancang fondasi finansial sehat.',
        gender: 'Laki-laki',
        languages: ['Indonesia', 'Jawa', 'Inggris'],
        isFullyBooked: false,
      ),
    ];
  }

  static Consultant? getById(String id) {
    try {
      return initialConsultants.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
