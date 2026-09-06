import 'package:flutter/material.dart';
import '../models/match_expert_models.dart';

class MatchExpertQuestionsData {
  static const List<MatchExpertQuestion> questions = [
    // Step 1 (Ref 2.jpg): Metode Konseling
    MatchExpertQuestion(
      id: 'method',
      stepIndex: 1,
      title: 'Setiap orang punya cara yang berbeda untuk merasa nyaman. Metode konsultasi seperti apa yang paling ingin kamu jalani?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: true,
      options: [
        MatchExpertOption(id: 'online', title: 'Online', icon: Icons.phone_in_talk_outlined),
        MatchExpertOption(id: 'offline', title: 'Tatap Muka', icon: Icons.groups_outlined),
        MatchExpertOption(id: 'both', title: 'Nyaman dengan keduanya', icon: Icons.handshake_outlined),
      ],
    ),

    // Step 2 (Ref 3.jpg): Target Konseling
    MatchExpertQuestion(
      id: 'target',
      stepIndex: 2,
      title: 'Agar kami bisa mendampingi dengan tepat, sesi konsultasi ini kamu butuhkan untuk siapa?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: true,
      options: [
        MatchExpertOption(id: 'self', title: 'Dirimu Sendiri', icon: Icons.person_outline),
        MatchExpertOption(id: 'couple', title: 'Bersama Pasangan', icon: Icons.favorite_outline),
        MatchExpertOption(id: 'family', title: 'Bersama Keluarga', icon: Icons.diversity_3_outlined),
        MatchExpertOption(id: 'business', title: 'Bisnis / UMKM', icon: Icons.storefront_outlined),
      ],
    ),

    // Step 3 (Ref 4.jpg): Bahasa
    MatchExpertQuestion(
      id: 'languages',
      stepIndex: 3,
      title: 'Bahasa apa yang paling nyaman kamu gunakan saat sesi konsultasi agar kamu bisa lebih leluasa berdiskusi?',
      subtitle: 'Dapat memilih lebih dari 1',
      selectionType: SelectionType.multi,
      isGrid: true,
      options: [
        MatchExpertOption(id: 'id', title: 'Indonesia', emoji: '🇮🇩'),
        MatchExpertOption(id: 'en', title: 'Inggris', emoji: '🇬🇧'),
        MatchExpertOption(id: 'zh', title: 'Mandarin', emoji: '🇨🇳'),
        MatchExpertOption(id: 'ar', title: 'Arab', emoji: '🇸🇦'),
        MatchExpertOption(id: 'fr', title: 'Prancis', emoji: '🇫🇷'),
        MatchExpertOption(id: 'es', title: 'Spanyol', emoji: '🇪🇸'),
      ],
    ),

    // Step 4 (Ref 5.jpg): Waktu Sesi
    MatchExpertQuestion(
      id: 'session_time',
      stepIndex: 4,
      title: 'Untuk mendapatkan sesi konsultasi yang tenang & fokus, kapan waktu yang paling nyaman untukmu menjalani sesi?',
      subtitle: 'Dapat memilih lebih dari 1',
      selectionType: SelectionType.multi,
      isGrid: true,
      options: [
        MatchExpertOption(id: 'morning', title: 'Pagi (06:00 - 11:59)', icon: Icons.wb_sunny_outlined),
        MatchExpertOption(id: 'afternoon', title: 'Siang (12:00 - 17:59)', icon: Icons.light_mode_outlined),
        MatchExpertOption(id: 'night', title: 'Malam (18:00 - 23:59)', icon: Icons.nights_stay_outlined),
        MatchExpertOption(id: 'flexible', title: 'Fleksibel, bisa menyesuaikan', icon: Icons.handshake_outlined),
      ],
    ),

    // Step 5 (Ref 6.jpg): Anggaran / Tarif
    MatchExpertQuestion(
      id: 'budget_tier',
      stepIndex: 5,
      title: 'Tipe konsultasi dan rentang tarif seperti apa yang paling sesuai dengan kebutuhanmu saat ini?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: true,
      options: [
        MatchExpertOption(id: 'low', title: 'Harga terendah', icon: Icons.monetization_on_outlined),
        MatchExpertOption(id: 'medium', title: 'Harga menengah', icon: Icons.savings_outlined),
        MatchExpertOption(id: 'high', title: 'Harga tertinggi', icon: Icons.workspace_premium_outlined),
        MatchExpertOption(id: 'flexible', title: 'Fleksibel', icon: Icons.handshake_outlined),
      ],
    ),

    // Step 6 (Ref 7.jpg): Topik Utama
    MatchExpertQuestion(
      id: 'main_topic',
      stepIndex: 6,
      title: 'Topik finansial apa yang paling mendesak dan ingin kamu bahas dalam konsultasi saat ini?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: false, // Vertical list
      options: [
        MatchExpertOption(id: 'debt_cashflow', title: 'Manajemen Hutang & Cashflow', icon: Icons.account_balance_wallet_outlined),
        MatchExpertOption(id: 'investment', title: 'Perencanaan Investasi & Portofolio', icon: Icons.trending_up),
        MatchExpertOption(id: 'emergency_insurance', title: 'Dana Darurat & Proteksi Asuransi', icon: Icons.shield_outlined),
        MatchExpertOption(id: 'house_wedding', title: 'Persiapan Pernikahan & Rumah Pertama', icon: Icons.home_work_outlined),
        MatchExpertOption(id: 'education', title: 'Perencanaan Dana Pendidikan Anak', icon: Icons.school_outlined),
        MatchExpertOption(id: 'sme', title: 'Keuangan Bisnis & UMKM', icon: Icons.store_outlined),
        MatchExpertOption(id: 'retirement', title: 'Persiapan Pensiun & Warisan', icon: Icons.chair_outlined),
      ],
    ),

    // Step 7 (Ref 8.jpg): Harapan / Goals
    MatchExpertQuestion(
      id: 'outcomes',
      stepIndex: 7,
      title: 'Setelah menjalani sesi konsultasi, hal apa yang kamu harapkan bisa kamu dapatkan?',
      subtitle: 'Dapat memilih lebih dari 1',
      selectionType: SelectionType.multi,
      isGrid: false,
      options: [
        MatchExpertOption(id: 'action_plan', title: 'Roadmap & Action Plan Finansial yang Jelas', icon: Icons.checklist_rtl_outlined),
        MatchExpertOption(id: 'debt_free', title: 'Bebas Hutang & Cashflow Lebih Sehat', icon: Icons.sentiment_very_satisfied_outlined),
        MatchExpertOption(id: 'low_risk_portfolio', title: 'Rekomendasi Portofolio yang Tepat & Minim Risiko', icon: Icons.pie_chart_outline),
        MatchExpertOption(id: 'peace_of_mind', title: 'Ketenangan Pikiran & Kepastian Finansial', icon: Icons.spa_outlined),
        MatchExpertOption(id: 'specific_goal', title: 'Strategi Konkret Mencapai Target Tertentu', icon: Icons.track_changes_outlined),
      ],
    ),

    // Step 8 (Ref 9.jpg): Preferensi Gender
    MatchExpertQuestion(
      id: 'gender',
      stepIndex: 8,
      title: 'Apakah kamu memiliki preferensi gender konsultan keuangan yang akan mendampingimu?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: true,
      options: [
        MatchExpertOption(id: 'male', title: 'Laki-laki', icon: Icons.male),
        MatchExpertOption(id: 'female', title: 'Perempuan', icon: Icons.female),
        MatchExpertOption(id: 'flexible', title: 'Fleksibel', icon: Icons.wc),
      ],
    ),

    // Step 9 (Ref 10.jpg): Gaya Pendekatan
    MatchExpertQuestion(
      id: 'approach_style',
      stepIndex: 9,
      title: 'Setiap konsultan keuangan punya gaya pendekatan yang berbeda. Pendekatan seperti apa yang paling sesuai denganmu?',
      subtitle: 'Dapat memilih lebih dari 1',
      selectionType: SelectionType.multi,
      isGrid: false,
      options: [
        MatchExpertOption(id: 'supportive', title: 'Hangat dan suportif', icon: Icons.favorite_border),
        MatchExpertOption(id: 'direct', title: 'To the point dan solutif (Data-Driven)', icon: Icons.crisis_alert_outlined),
        MatchExpertOption(id: 'balanced', title: 'Seimbang di antara keduanya', icon: Icons.balance_outlined),
        MatchExpertOption(id: 'flexible', title: 'Fleksibel', icon: Icons.handshake_outlined),
      ],
    ),

    // Step 10 (Ref 11.jpg): Preferensi Usia
    MatchExpertQuestion(
      id: 'age_preference',
      stepIndex: 10,
      title: 'Apakah kamu memiliki preferensi usia konsultan yang akan mendampingimu?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: true,
      options: [
        MatchExpertOption(id: 'young', title: '< 30 tahun', icon: Icons.face),
        MatchExpertOption(id: 'mid', title: '30 s.d. 40 tahun', icon: Icons.person),
        MatchExpertOption(id: 'senior', title: '> 40 tahun', icon: Icons.elderly),
        MatchExpertOption(id: 'flexible', title: 'Fleksibel', icon: Icons.diversity_1_outlined),
      ],
    ),

    // Step 11 (Ref 12.jpg): Pola Komunikasi
    MatchExpertQuestion(
      id: 'communication_style',
      stepIndex: 11,
      title: 'Pola komunikasi seperti apa yang kamu harapkan dari konsultan keuangan yang mendampingimu?',
      subtitle: 'Pilih salah satu',
      selectionType: SelectionType.single,
      isGrid: false,
      options: [
        MatchExpertOption(id: 'listen_first', title: 'Lebih banyak mendengarkan', icon: Icons.hearing_outlined),
        MatchExpertOption(id: 'proactive', title: 'Aktif memberikan arahan dan insight', icon: Icons.lightbulb_outline),
        MatchExpertOption(id: 'both', title: 'Gabungan keduanya', icon: Icons.swap_horiz_outlined),
      ],
    ),

    // Step 12 (Ref 13.jpg): Topik Spesifik
    MatchExpertQuestion(
      id: 'specific_tags',
      stepIndex: 12,
      title: 'Apakah ada topik spesifik yang ingin kamu fokuskan sebagai topik diskusi konsultasi?',
      subtitle: 'Dapat memilih lebih dari 1',
      selectionType: SelectionType.multi,
      isGrid: true,
      options: [
        MatchExpertOption(id: 'pinjol', title: 'Pinjol & Restrukturisasi', icon: Icons.warning_amber_outlined),
        MatchExpertOption(id: 'saham', title: 'Saham & Dividen', icon: Icons.show_chart),
        MatchExpertOption(id: 'reksadana', title: 'Reksadana & Obligasi', icon: Icons.pie_chart),
        MatchExpertOption(id: 'kpr', title: 'KPR & Rumah Pertama', icon: Icons.cottage_outlined),
        MatchExpertOption(id: 'pajak', title: 'Pajak Freelancer', icon: Icons.receipt_long_outlined),
        MatchExpertOption(id: 'asuransi', title: 'Asuransi Jiwa & Kesehatan', icon: Icons.health_and_safety_outlined),
        MatchExpertOption(id: 'crypto', title: 'Crypto & Aset Digital', icon: Icons.currency_bitcoin),
        MatchExpertOption(id: 'dana_darurat', title: 'Dana Darurat Ideal', icon: Icons.savings_outlined),
        MatchExpertOption(id: 'budget_nikah', title: 'Budgeting Pasangan Baru', icon: Icons.favorite_border),
        MatchExpertOption(id: 'kas_bisnis', title: 'Pembukuan Kas Bisnis', icon: Icons.storefront_outlined),
      ],
    ),
  ];
}
