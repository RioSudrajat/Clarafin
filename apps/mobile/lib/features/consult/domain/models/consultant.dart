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
        avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&fit=crop&crop=faces',
        rating: 4.95,
        reviewCount: 142,
        totalSessions: 181,
        experienceYears: '5+ Thn',
        location: 'Jakarta Selatan, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: ['Cashflow & Budgeting', 'Investasi Reksadana', 'Dana Darurat', 'Pasangan Baru'],
        feePerSession: 180000,
        bio: 'Fokus mendampingi individu dan keluarga muda dalam merapikan arus kas, menyiapkan dana darurat, dan memulai portofolio investasi terukur.',
        gender: 'Perempuan',
        languages: ['Indonesia', 'Inggris'],
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c2',
        name: 'Nurhuzaifah Amini, M.M., CFP®',
        title: 'Debt Relief & Tax Specialist',
        credentials: 'CFP®, Registered Financial Planner',
        avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&fit=crop&crop=faces',
        rating: 4.92,
        reviewCount: 198,
        totalSessions: 245,
        experienceYears: '6+ Thn',
        location: 'Tangerang Selatan, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: ['Restrukturisasi Pinjol & Hutang', 'Pajak & Bisnis', 'KPR & Properti', 'Asuransi'],
        feePerSession: 220000,
        bio: 'Spesialis dalam memulihkan kesehatan finansial dari jeratan hutang konsumtif dan merencanakan pembelian properti pertama secara aman.',
        gender: 'Perempuan',
        languages: ['Indonesia', 'Inggris'],
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c3',
        name: 'Upik Nuri Budi S., QWP®, RFC®',
        title: 'Senior Family & Business Strategist',
        credentials: 'RFC®, Qualified Wealth Planner',
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&fit=crop&crop=faces',
        rating: 4.88,
        reviewCount: 265,
        totalSessions: 320,
        experienceYears: '10+ Thn',
        location: 'Surabaya, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: ['Keuangan UMKM', 'Dana Pendidikan Anak', 'Keluarga & KPR', 'Pensiun & Warisan'],
        feePerSession: 300000,
        bio: 'Membantu pemilik bisnis UMKM memisahkan keuangan pribadi vs usaha, serta mengamankan dana pendidikan anak dan masa pensiun keluarga.',
        gender: 'Perempuan',
        languages: ['Indonesia', 'Inggris', 'Jawa'],
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c4',
        name: 'Dimas Pratama, S.E., CFP®',
        title: 'Investment & Portfolio Advisor',
        credentials: 'CFP®, Chartered Portfolio Manager',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&fit=crop&crop=faces',
        rating: 4.90,
        reviewCount: 167,
        totalSessions: 210,
        experienceYears: '5+ Thn',
        location: 'Jakarta Pusat, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: ['Investasi & Saham', 'Crypto & Asset Digital', 'FIRE (Financial Freedom)', 'Reksadana'],
        feePerSession: 200000,
        bio: 'Membantu profesional muda membangun portofolio investasi agresif terukur untuk mencapai kemerdekaan finansial di usia produktif.',
        gender: 'Laki-laki',
        languages: ['Indonesia', 'Inggris'],
        isFullyBooked: false,
      ),
      Consultant(
        id: 'c5',
        name: 'Reza Firmansyah, MBA, CFP®',
        title: 'Executive Wealth & SME Consultant',
        credentials: 'CFP®, MBA Financial Management',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&fit=crop&crop=faces',
        rating: 4.96,
        reviewCount: 340,
        totalSessions: 410,
        experienceYears: '12+ Thn',
        location: 'Bandung, Indonesia',
        methods: ['Online', 'Tatap Muka'],
        specializations: ['Pajak & Bisnis', 'Arus Kas Bisnis', 'Pensiun & Warisan', 'KPR Mewah'],
        feePerSession: 350000,
        bio: 'Konsultan senior untuk perencanaan bisnis keluarga dan preservasi kekayaan jangka panjang lintas generasi.',
        gender: 'Laki-laki',
        languages: ['Indonesia', 'Inggris', 'Mandarin'],
        isFullyBooked: true,
      ),
    ];
  }
}
