import 'package:flutter/material.dart';
import '../models/match_expert_models.dart';

class MatchExpertQuestionsData {
  static const List<MatchExpertQuestion> questions = [
    // Step 1 (Ref 2.jpg): Metode Konseling - 2-Column Grid
    MatchExpertQuestion(
      id: 'method',
      stepIndex: 1,
      title: 'Setiap orang punya cara yang berbeda untuk merasa nyaman. Metode konsultasi seperti apa yang paling ingin kamu jalani?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: true,
      options: [
        MatchExpertOption(
          id: 'online',
          title: 'Online',
          icon: Icons.perm_phone_msg_outlined,
        ),
        MatchExpertOption(
          id: 'offline',
          title: 'Tatap Muka',
          icon: Icons.groups_outlined,
        ),
        MatchExpertOption(
          id: 'both',
          title: 'Nyaman dengan keduanya',
          icon: Icons.handshake_outlined,
        ),
      ],
    ),

    // Step 2 (Ref 3.jpg): Target Konseling - 2x2 Grid
    MatchExpertQuestion(
      id: 'target',
      stepIndex: 2,
      title: 'Untuk siapa sesi konsultasi ini kamu butuhkan?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: true,
      options: [
        MatchExpertOption(
          id: 'self',
          title: 'Dirimu Sendiri',
          subtitle: 'Perencanaan personal & karir',
          emoji: '👤',
        ),
        MatchExpertOption(
          id: 'couple',
          title: 'Bersama Pasangan',
          subtitle: 'Finansial berdua & pranikah',
          emoji: '👩‍❤️‍👨',
        ),
        MatchExpertOption(
          id: 'family',
          title: 'Bersama Keluarga',
          subtitle: 'Budget rumah tangga & anak',
          emoji: '👨‍👩‍👧‍👦',
        ),
        MatchExpertOption(
          id: 'business',
          title: 'Bisnis / UMKM',
          subtitle: 'Pemisahan kas usaha & pribadi',
          emoji: '🏪',
        ),
      ],
    ),

    // Step 3 (Ref 4.jpg): Bahasa - Vertical List
    MatchExpertQuestion(
      id: 'languages',
      stepIndex: 3,
      title: 'Bahasa apa yang kamu inginkan selama sesi konsultasi?',
      subtitle: 'Dapat memilih lebih dari 1',
      selectionType: SelectionType.multi,
      isGrid: false,
      options: [
        MatchExpertOption(
          id: 'id',
          title: 'Bahasa Indonesia',
          subtitle: 'Percakapan utama bahasa ibu',
          emoji: '🇮🇩',
        ),
        MatchExpertOption(
          id: 'en',
          title: 'English',
          subtitle: 'International standard fluency',
          emoji: '🇬🇧',
        ),
        MatchExpertOption(
          id: 'zh',
          title: 'Mandarin (中文)',
          subtitle: 'Penutur aktif bahasa Mandarin',
          emoji: '🇨🇳',
        ),
        MatchExpertOption(
          id: 'ar',
          title: 'Arab (العربية)',
          subtitle: 'Penutur aktif bahasa Arab',
          emoji: '🇸🇦',
        ),
        MatchExpertOption(
          id: 'flexible',
          title: 'Bahasa Lainnya / Fleksibel',
          subtitle: 'Terbuka untuk opsi bahasa lain',
          emoji: '🌐',
        ),
      ],
    ),

    // Step 4 (Ref 5.jpg): Waktu Sesi - 2x2 Grid
    MatchExpertQuestion(
      id: 'session_time',
      stepIndex: 4,
      title: 'Kapan waktu yang paling ideal bagimu untuk berkonsultasi?',
      subtitle: 'Dapat memilih lebih dari 1',
      selectionType: SelectionType.multi,
      isGrid: true,
      options: [
        MatchExpertOption(
          id: 'morning',
          title: 'Pagi',
          subtitle: '08:00 - 12:00 WIB',
          icon: Icons.wb_sunny_outlined,
        ),
        MatchExpertOption(
          id: 'afternoon',
          title: 'Siang',
          subtitle: '12:00 - 17:00 WIB',
          icon: Icons.light_mode_outlined,
        ),
        MatchExpertOption(
          id: 'night',
          title: 'Malam',
          subtitle: '17:00 - 21:00 WIB',
          icon: Icons.nights_stay_outlined,
        ),
        MatchExpertOption(
          id: 'flexible',
          title: 'Fleksibel',
          subtitle: 'Kapan saja sesuai jadwal',
          icon: Icons.calendar_month_outlined,
        ),
      ],
    ),

    // Step 5 (Ref 6.jpg): Anggaran / Tarif - Vertical List
    MatchExpertQuestion(
      id: 'budget_tier',
      stepIndex: 5,
      title: 'Tipe konsultasi dan rentang tarif seperti apa yang kamu inginkan?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: false,
      options: [
        MatchExpertOption(
          id: 'low',
          title: 'Harga Terendah',
          subtitle: '< Rp 150.000 / sesi (Pemula & first jobber)',
          icon: Icons.monetization_on_outlined,
        ),
        MatchExpertOption(
          id: 'medium',
          title: 'Harga Menengah',
          subtitle: 'Rp 150.000 - Rp 350.000 / sesi (Paling diminati)',
          icon: Icons.savings_outlined,
        ),
        MatchExpertOption(
          id: 'high',
          title: 'Harga Tertinggi',
          subtitle: '> Rp 350.000 / sesi (CFP® Senior berpengalaman)',
          icon: Icons.workspace_premium_outlined,
        ),
        MatchExpertOption(
          id: 'flexible',
          title: 'Fleksibel',
          subtitle: 'Fokus pada keahlian tanpa batasan tarif',
          icon: Icons.handshake_outlined,
        ),
      ],
    ),

    // Step 6 (Ref 7.jpg): Topik Utama - Vertical List
    MatchExpertQuestion(
      id: 'main_topic',
      stepIndex: 6,
      title: 'Apa tantangan atau tujuan finansial utama yang ingin kamu bahas?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: false,
      options: [
        MatchExpertOption(
          id: 'debt_cashflow',
          title: 'Hutang & Cashflow',
          subtitle: 'Bebas pinjol & pemulihan cashflow sehat',
          icon: Icons.account_balance_wallet_outlined,
        ),
        MatchExpertOption(
          id: 'investment',
          title: 'Investasi & Portofolio',
          subtitle: 'Saham, reksadana, dan diversifikasi aset',
          icon: Icons.trending_up,
        ),
        MatchExpertOption(
          id: 'emergency_insurance',
          title: 'Dana Darurat & Asuransi',
          subtitle: 'Mitigasi risiko dan proteksi keluarga',
          icon: Icons.shield_outlined,
        ),
        MatchExpertOption(
          id: 'house_wedding',
          title: 'Beli Rumah & KPR',
          subtitle: 'Rencana DP, cicilan aman, & pernikahan',
          icon: Icons.cottage_outlined,
        ),
        MatchExpertOption(
          id: 'education',
          title: 'Dana Pendidikan Anak',
          subtitle: 'Investasi jenjang sekolah & kuliah anak',
          icon: Icons.school_outlined,
        ),
        MatchExpertOption(
          id: 'sme',
          title: 'Keuangan Bisnis & UMKM',
          subtitle: 'Pemisahan kas operasional usaha vs pribadi',
          icon: Icons.store_outlined,
        ),
        MatchExpertOption(
          id: 'retirement',
          title: 'Persiapan Pensiun & Warisan',
          subtitle: 'Dana hari tua dan distribusi waris',
          icon: Icons.chair_outlined,
        ),
      ],
    ),

    // Step 7 (Ref 8.jpg): Harapan / Goals - Vertical List
    MatchExpertQuestion(
      id: 'outcomes',
      stepIndex: 7,
      title: 'Apa ekspektasi utama yang ingin kamu capai setelah sesi konsultasi?',
      subtitle: 'Dapat memilih lebih dari 1',
      selectionType: SelectionType.multi,
      isGrid: false,
      options: [
        MatchExpertOption(
          id: 'action_plan',
          title: 'Action Plan Konkret',
          subtitle: 'Langkah taktis yang siap langsung dieksekusi',
          icon: Icons.checklist_rtl_outlined,
        ),
        MatchExpertOption(
          id: 'debt_free',
          title: 'Strategi Bebas Hutang',
          subtitle: 'Solusi terukur cicilan dan restrukturisasi',
          icon: Icons.sentiment_very_satisfied_outlined,
        ),
        MatchExpertOption(
          id: 'low_risk_portfolio',
          title: 'Portofolio Tumbuh Optimal',
          subtitle: 'Alokasi instrumen terarah minim risiko',
          icon: Icons.pie_chart_outline,
        ),
        MatchExpertOption(
          id: 'peace_of_mind',
          title: 'Ketenangan Pikiran',
          subtitle: 'Kepastian dan rasa aman terhadap masa depan',
          icon: Icons.spa_outlined,
        ),
        MatchExpertOption(
          id: 'specific_goal',
          title: 'Evaluasi Kebocoran Dana',
          subtitle: 'Mengetahui pos boros dan cara menambalnya',
          icon: Icons.track_changes_outlined,
        ),
      ],
    ),

    // Step 8 (Ref 9.jpg): Preferensi Gender - Vertical List
    MatchExpertQuestion(
      id: 'gender',
      stepIndex: 8,
      title: 'Apakah kamu memiliki preferensi gender untuk konsultanmu?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: false,
      options: [
        MatchExpertOption(
          id: 'male',
          title: 'Laki-laki',
          subtitle: 'Konsultan pria tersertifikasi',
          icon: Icons.male,
        ),
        MatchExpertOption(
          id: 'female',
          title: 'Perempuan',
          subtitle: 'Konsultan wanita tersertifikasi',
          icon: Icons.female,
        ),
        MatchExpertOption(
          id: 'flexible',
          title: 'Fleksibel / Bebas',
          subtitle: 'Yang terpenting keahlian dan kecocokan komunikasi',
          icon: Icons.wc,
        ),
      ],
    ),

    // Step 9 (Ref 10.jpg): Gaya Pendekatan - Vertical List
    MatchExpertQuestion(
      id: 'approach_style',
      stepIndex: 9,
      title: 'Pendekatan seperti apa yang paling sesuai dengan kenyamananmu?',
      subtitle: 'Dapat memilih lebih dari 1',
      selectionType: SelectionType.multi,
      isGrid: false,
      options: [
        MatchExpertOption(
          id: 'supportive',
          title: 'Hangat & Suportif',
          subtitle: 'Mendengarkan dengan empati tanpa menghakimi',
          icon: Icons.favorite_border,
        ),
        MatchExpertOption(
          id: 'direct',
          title: 'To the point & Solutif',
          subtitle: 'Fokus pada data kalkulasi dan action plan konkret',
          icon: Icons.crisis_alert_outlined,
        ),
        MatchExpertOption(
          id: 'balanced',
          title: 'Seimbang di antara keduanya',
          subtitle: 'Kombinasi kenyamanan bercerita dan analisa angka',
          icon: Icons.balance_outlined,
        ),
        MatchExpertOption(
          id: 'flexible',
          title: 'Fleksibel',
          subtitle: 'Bisa beradaptasi sesuai alur kebutuhanmu',
          icon: Icons.handshake_outlined,
        ),
      ],
    ),

    // Step 10 (Ref 11.jpg): Preferensi Usia - Vertical List
    MatchExpertQuestion(
      id: 'age_preference',
      stepIndex: 10,
      title: 'Berapa rentang usia konsultan yang membuatmu merasa paling nyaman?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: false,
      options: [
        MatchExpertOption(
          id: 'young',
          title: '< 30 tahun',
          subtitle: 'Muda & relate dengan tantangan generasi sekarang',
          icon: Icons.face,
        ),
        MatchExpertOption(
          id: 'mid',
          title: '30 - 40 tahun',
          subtitle: 'Matang dalam perencanaan fase keluarga & karir',
          icon: Icons.person,
        ),
        MatchExpertOption(
          id: 'senior',
          title: '> 40 tahun',
          subtitle: 'Jam terbang tinggi dan pengalaman lintas siklus ekonomi',
          icon: Icons.elderly,
        ),
        MatchExpertOption(
          id: 'flexible',
          title: 'Fleksibel',
          subtitle: 'Semua rentang usia asalkan kompeten dan cocok',
          icon: Icons.diversity_1_outlined,
        ),
      ],
    ),

    // Step 11 (Ref 12.jpg): Pola Komunikasi - Vertical List
    MatchExpertQuestion(
      id: 'communication_style',
      stepIndex: 11,
      title: 'Bagaimana pola komunikasi yang kamu harapkan selama sesi?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: false,
      options: [
        MatchExpertOption(
          id: 'listen_first',
          title: 'Lebih banyak mendengar',
          subtitle: 'Saya butuh wadah bercerita dan didengarkan dengan baik',
          icon: Icons.hearing_outlined,
        ),
        MatchExpertOption(
          id: 'proactive',
          title: 'Aktif memberi arahan',
          subtitle: 'Saya ingin konsultan yang dominan memberi saran praktis',
          icon: Icons.lightbulb_outline,
        ),
        MatchExpertOption(
          id: 'both',
          title: 'Diskusi interaktif seimbang',
          subtitle: 'Tanya jawab dua arah dan saling bertukar perspektif',
          icon: Icons.swap_horiz_outlined,
        ),
        MatchExpertOption(
          id: 'flexible',
          title: 'Fleksibel',
          subtitle: 'Mengikuti dinamika sesi dan topik yang dibahas',
          icon: Icons.handshake_outlined,
        ),
      ],
    ),

    // Step 12 (Ref 13.jpg): Topik Spesifik / Instrumen - Grid Compact
    MatchExpertQuestion(
      id: 'specific_tags',
      stepIndex: 12,
      title: 'Ada instrumen atau topik khusus yang ingin kamu bahas secara mendalam?',
      subtitle: 'Dapat memilih lebih dari 1 (opsional)',
      selectionType: SelectionType.multi,
      isGrid: true,
      isOptional: true,
      options: [
        MatchExpertOption(id: 'pinjol', title: '#Pinjol & Paylater', icon: Icons.warning_amber_outlined),
        MatchExpertOption(id: 'saham', title: '#Saham & Dividen', icon: Icons.show_chart),
        MatchExpertOption(id: 'reksadana', title: '#Reksadana', icon: Icons.pie_chart),
        MatchExpertOption(id: 'kpr', title: '#KPR & Properti', icon: Icons.cottage_outlined),
        MatchExpertOption(id: 'pajak', title: '#Pajak Pribadi & SPT', icon: Icons.receipt_long_outlined),
        MatchExpertOption(id: 'asuransi', title: '#Asuransi Unitlink', icon: Icons.health_and_safety_outlined),
        MatchExpertOption(id: 'crypto', title: '#Crypto & Web3', icon: Icons.currency_bitcoin),
        MatchExpertOption(id: 'dana_darurat', title: '#Dana Darurat', icon: Icons.savings_outlined),
        MatchExpertOption(id: 'budget_nikah', title: '#Budgeting Pasutri', icon: Icons.favorite_border),
        MatchExpertOption(id: 'kas_bisnis', title: '#Pembukuan Bisnis', icon: Icons.storefront_outlined),
      ],
    ),
  ];
}
