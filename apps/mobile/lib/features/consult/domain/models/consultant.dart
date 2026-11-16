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
  final String tier; // 'Basic', 'Medium', 'Premium'
  final int clientsHandled;

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
    this.tier = 'Medium',
    this.clientsHandled = 0,
  });
}

class ConsultantRepository {
  static List<Consultant> get initialConsultants {
    return const [
      Consultant(
        id: 'c1',
        name: 'Chrysan Gomargana, S.E., CFP®',
        title: 'Financial Planner & Wealth Consultant',
        credentials: 'CFP®',
        avatarUrl:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&fit=crop&crop=faces',
        rating: 4.95,
        reviewCount: 142,
        totalSessions: 380,
        experienceYears: '5 Thn',
        location: 'Jakarta Selatan, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: [
          'Perencanaan Individu',
          'Pasangan & Pranikah',
          'Keuangan Keluarga',
          'Cashflow & Budgeting',
          'Investasi Reksadana',
          'Financial Check-Up',
        ],
        feePerSession: 299000,
        bio:
            'Fokus mendampingi individu dan pasangan muda dalam merapikan arus kas, menyiapkan dana darurat, dan memulai portofolio investasi terukur.',
        gender: 'Perempuan',
        languages: ['Indonesia', 'Inggris'],
        tier: 'Medium',
        clientsHandled: 380,
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c2',
        name: 'Nurhuzaifah Amini, M.M., CFP®, BKP',
        title: 'Debt Relief & Tax Specialist',
        credentials: 'CFP®, BKP',
        avatarUrl:
            'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&fit=crop&crop=faces',
        rating: 4.92,
        reviewCount: 198,
        totalSessions: 520,
        experienceYears: '6 Thn',
        location: 'Tangerang Selatan, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: [
          'Restrukturisasi Utang',
          'Pajak & Bisnis UMKM',
          'Perencanaan Individu',
          'KPR & Properti',
          'Financial Check-Up',
          'Bebas Hutang & Pinjol',
        ],
        feePerSession: 399000,
        bio:
            'Spesialis dalam pemulihan kesehatan finansial dari jeratan hutang konsumtif, optimasi pajak pribadi & UMKM, serta negosiasi restrukturisasi utang.',
        gender: 'Perempuan',
        languages: ['Indonesia', 'Inggris'],
        tier: 'Premium',
        clientsHandled: 520,
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c3',
        name: 'Rian Pratama, S.Ak., QWP®, AWP®',
        title: 'Junior Financial Planner & Cashflow Specialist',
        credentials: 'QWP®, AWP®',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&fit=crop&crop=faces',
        rating: 4.88,
        reviewCount: 95,
        totalSessions: 190,
        experienceYears: '2 Thn',
        location: 'Surabaya, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: [
          'Fondasi Arus Kas',
          'Bebas Utang PayLater',
          'Dana Darurat Pertama',
          'UMKM Pemula',
          'Financial Check-Up',
        ],
        feePerSession: 199000,
        bio:
            'Membimbing profesional muda dan perintis usaha dalam membenahi arus kas harian, menghentikan kebocoran uang, dan membangun dana darurat pertama.',
        gender: 'Laki-laki',
        languages: ['Indonesia', 'Inggris'],
        tier: 'Basic',
        clientsHandled: 190,
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c4',
        name: 'Dr. Hendra Wijaya, MBA, CFA®, CFP®',
        title: 'Principal Wealth & Corporate Advisor',
        credentials: 'CFA®, CFP®',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&fit=crop&crop=faces',
        rating: 4.98,
        reviewCount: 310,
        totalSessions: 850,
        experienceYears: '10 Thn',
        location: 'Jakarta Pusat, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: [
          'FIRE (Financial Freedom)',
          'Corporate Treasury',
          'Startup Runway & Valuasi',
          'Investasi Saham & Portofolio',
          'Financial Check-Up 360°',
        ],
        feePerSession: 399000,
        bio:
            'Membantu eksekutif, investor, dan pemilik startup mengoptimalkan portofolio kekayaan, memperpanjang runway bisnis, serta menyusun peta jalan Financial Freedom.',
        gender: 'Laki-laki',
        languages: ['Indonesia', 'Inggris'],
        tier: 'Premium',
        clientsHandled: 850,
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c5',
        name: 'Nadia Kusuma, S.Psi., CFP®, AEPP®',
        title: 'Senior Family Wealth & Estate Planner',
        credentials: 'CFP®, AEPP®',
        avatarUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&fit=crop&crop=faces',
        rating: 4.96,
        reviewCount: 280,
        totalSessions: 610,
        experienceYears: '7 Thn',
        location: 'Bandung, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: [
          'Pasangan & Pranikah',
          'Keuangan Keluarga',
          'Generasi Sandwich',
          'Proteksi & Waris Lintas Generasi',
          'Dana Pendidikan Anak',
        ],
        feePerSession: 349000,
        bio:
            'Membantu pasangan dan keluarga merancang kemapanan finansial lintas generasi, proteksi aset keluarga, serta mengakhiri beban generasi sandwich secara bijak.',
        gender: 'Perempuan',
        languages: ['Indonesia', 'Inggris'],
        tier: 'Premium',
        clientsHandled: 610,
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c6',
        name: 'Budi Santoso, S.E., Ak., CPA, CFP®',
        title: 'SME & Business Tax Strategist',
        credentials: 'CPA, CFP®',
        avatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&fit=crop&crop=faces',
        rating: 4.93,
        reviewCount: 175,
        totalSessions: 340,
        experienceYears: '4 Thn',
        location: 'Yogyakarta, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: [
          'Keuangan UMKM & Bisnis',
          'Audit & Pembukuan Kas',
          'Pajak Bisnis & UKM',
          'Corporate Wellness',
          'Pemisahan Kas Usaha',
        ],
        feePerSession: 299000,
        bio:
            'Membantu pelaku UMKM dan manajemen korporasi menyehatkan arus kas, merapikan pembukuan usaha, dan memastikan kepatuhan pajak bebas denda.',
        gender: 'Laki-laki',
        languages: ['Indonesia', 'Jawa', 'Inggris'],
        tier: 'Medium',
        clientsHandled: 340,
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
