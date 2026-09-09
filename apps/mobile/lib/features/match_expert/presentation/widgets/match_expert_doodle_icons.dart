import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../home/presentation/widgets/notion_doodle_icons.dart';

class MatchExpertDoodleWidget extends StatelessWidget {
  final String svgKey;
  final bool isSelected;
  final double size;

  const MatchExpertDoodleWidget({
    super.key,
    required this.svgKey,
    required this.isSelected,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final svgString = MatchExpertDoodleIcons.getSvg(svgKey, isSelected: isSelected);
    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class MatchExpertDoodleIcons {
  static const Set<String> _knownKeys = {
    // Q1: Method
    'online', 'offline', 'both',
    // Q2: Target (Reuses NotionDoodleIcons: individu, pasangan, keluarga, umkm)
    'self', 'couple', 'family', 'business',
    // Q3: Languages
    'id', 'en', 'zh', 'ar', 'lang_flexible',
    // Q4: Session Time
    'morning', 'afternoon', 'night', 'time_flexible',
    // Q5: Budget
    'low', 'medium', 'high', 'budget_flexible',
    // Q6: Main Topic
    'debt_cashflow', 'investment', 'emergency_insurance', 'house_wedding', 'education', 'sme', 'retirement',
    // Q7: Outcomes / Goals
    'action_plan', 'debt_free', 'low_risk_portfolio', 'peace_of_mind', 'specific_goal',
    // Q8: Gender
    'male', 'female', 'gender_flexible',
    // Q9: Approach Style
    'supportive', 'direct', 'balanced', 'style_flexible',
    // Q10: Age Preference
    'young', 'mid', 'senior', 'age_flexible',
    // Q11: Communication Style
    'listen_first', 'proactive', 'comm_both', 'comm_flexible',
    // General
    'flexible', 'handshake', 'referral',
  };

  static bool hasSvg(String key) {
    return _knownKeys.contains(key);
  }

  /// Adapt an existing NotionDoodleIcons SVG so its inlines/strokes dynamically turn
  /// to Clarafin theme lime (#9ADC09) when selected, while keeping hair and accents
  /// crisp and high-contrast.
  static String _adapt(String svg, {required bool isSelected}) {
    if (!isSelected) {
      return svg;
    }
    return svg
        .replaceAll('stroke="black"', 'stroke="#9ADC09"')
        .replaceAll('stroke="#000000"', 'stroke="#9ADC09"')
        .replaceAll('stroke="#111827"', 'stroke="#9ADC09"');
  }

  static String getSvg(String key, {bool isSelected = false}) {
    final s = isSelected ? '#9ADC09' : '#111827';

    switch (key) {
      // ── Q1: Metode Konseling ──
      case 'online':
        return _online(s);
      case 'offline':
        return _offline(s);
      case 'both':
      case 'comm_both':
        // Nyaman dengan keduanya -> Jabat Tangan (Handshake)
        return _handshake(s);

      // ── Q2: Target Konseling (REUSED directly from NotionDoodleIcons) ──
      case 'self':
        return _adapt(NotionDoodleIcons.individu, isSelected: isSelected);
      case 'couple':
        return _adapt(NotionDoodleIcons.pasangan, isSelected: isSelected);
      case 'family':
        return _adapt(NotionDoodleIcons.keluarga, isSelected: isSelected);
      case 'business':
      case 'sme':
        return _adapt(NotionDoodleIcons.umkm, isSelected: isSelected);

      // ── Q3: Bahasa ──
      case 'id':
        return _langId(s);
      case 'en':
        return _langEn(s);
      case 'zh':
        return _langZh(s);
      case 'ar':
        return _langAr(s);
      case 'lang_flexible':
        return _handshake(s);

      // ── Q4: Waktu Sesi ──
      case 'morning':
        return _morning(s);
      case 'afternoon':
        return _afternoon(s);
      case 'night':
        return _night(s);
      case 'time_flexible':
        return _handshake(s);

      // ── Q5: Anggaran / Tarif ──
      case 'low':
        return _budgetLow(s);
      case 'medium':
        return _adapt(NotionDoodleIcons.goals, isSelected: isSelected);
      case 'high':
        return _budgetHigh(s);
      case 'budget_flexible':
        return _handshake(s);

      // ── Q6: Topik Utama ──
      case 'debt_cashflow':
        return _adapt(NotionDoodleIcons.bebasHutang, isSelected: isSelected);
      case 'investment':
        return _adapt(NotionDoodleIcons.auditPortofolio, isSelected: isSelected);
      case 'emergency_insurance':
        return _insurance(s);
      case 'house_wedding':
        return _house(s);
      case 'education':
        return _education(s);
      case 'retirement':
        return _retirement(s);

      // ── Q7: Harapan / Goals ──
      case 'action_plan':
        return _adapt(NotionDoodleIcons.tesFinansial, isSelected: isSelected);
      case 'debt_free':
        return _adapt(NotionDoodleIcons.bebasHutang, isSelected: isSelected);
      case 'low_risk_portfolio':
        return _adapt(NotionDoodleIcons.auditPortofolio, isSelected: isSelected);
      case 'peace_of_mind':
        return _peaceOfMind(s);
      case 'specific_goal':
        return _adapt(NotionDoodleIcons.goals, isSelected: isSelected);

      // ── Q8: Preferensi Gender ──
      case 'male':
        return _male(s);
      case 'female':
        return _female(s);
      case 'gender_flexible':
        return _handshake(s);

      // ── Q9: Gaya Pendekatan ──
      case 'supportive':
        return _supportive(s);
      case 'direct':
        return _direct(s);
      case 'balanced':
        return _balanced(s);
      case 'style_flexible':
        return _handshake(s);

      // ── Q10: Preferensi Usia ──
      case 'young':
        return _ageYoung(s);
      case 'mid':
        // 30-40 tahun -> Reuses NotionDoodleIcons.individu (professional with glasses!)
        return _adapt(NotionDoodleIcons.individu, isSelected: isSelected);
      case 'senior':
        return _ageSenior(s);
      case 'age_flexible':
        return _handshake(s);

      // ── Q11: Pola Komunikasi ──
      case 'listen_first':
        return _commListen(s);
      case 'proactive':
        return _commProactive(s);
      case 'comm_flexible':
        return _handshake(s);

      // ── General / Referral / Handshake ──
      case 'referral':
      case 'handshake':
      case 'flexible':
      default:
        return _handshake(s);
    }
  }

  // ══════════════════════════════════════════════════════
  // SVG TEMPLATES
  // ══════════════════════════════════════════════════════

  /// 🤝 Jabat Tangan (Handshake) - untuk "Nyaman dengan keduanya", "Fleksibel", & "Ajak Teman"
  static String _handshake(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Left sleeve & cuff -->
  <path d="M4 23L12 21V33L4 31" stroke="$s" stroke-width="2.2" stroke-linejoin="round"/>
  <line x1="12" y1="21" x2="12" y2="33" stroke="$s" stroke-width="2"/>
  
  <!-- Right sleeve & cuff -->
  <path d="M44 23L36 21V33L44 31" stroke="$s" stroke-width="2.2" stroke-linejoin="round"/>
  <line x1="36" y1="21" x2="36" y2="33" stroke="$s" stroke-width="2"/>
  
  <!-- Left hand / thumb -->
  <path d="M12 23L18 19C20 18 22 18.5 22.5 20.5L20 25" stroke="$s" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  
  <!-- Right hand / thumb -->
  <path d="M36 23L30 19C28 18 26 18.5 25.5 20.5L28 25" stroke="$s" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  
  <!-- Clasping fingers (interlocked fingers) -->
  <path d="M18 24C21 23 27 23 30 24" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M17 27C20.5 26 27.5 26 31 27" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M17 30C20.5 29 27.5 29 31 30" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M19 33C21.5 32.5 26.5 32.5 29 33" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  
  <!-- Agreement sparkle on top -->
  <path d="M24 7V11" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M17 10L19 13" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M31 10L29 13" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="24" cy="14" r="1.5" fill="$s"/>
</svg>
''';

  /// 💻 Online (Question 1)
  static String _online(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="8" y="11" width="32" height="21" rx="4" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M4 33H44" stroke="$s" stroke-width="2.6" stroke-linecap="round"/>
  <circle cx="24" cy="19" r="3.5" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M18 28C18 25 20.5 23.5 24 23.5C27.5 23.5 30 25 30 28" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <circle cx="24" cy="13.5" r="1" fill="$s"/>
  <path d="M34 8L36 6M38 10L42 9" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  /// 👥 Tatap Muka (Question 1)
  static String _offline(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="15" cy="17" r="4" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M9 29C9 25 12 23.5 15 23.5C18 23.5 21 25 21 29" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="33" cy="17" r="4" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M39 29C39 25 36 23.5 33 23.5C30 23.5 27 25 27 29" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M6 34H42" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <rect x="21" y="27" width="6" height="7" stroke="$s" stroke-width="2" fill="white"/>
  <circle cx="24" cy="24" r="1.5" fill="$s"/>
</svg>
''';

  /// 👨 Laki-laki (Question 8)
  static String _male(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Solid black side-part hair -->
  <path d="M14 20C13 13 17 9 24 9C31 9 35 13 34 20C33 16 31 12 24 12C17 12 15 16 14 20Z" fill="#111827" stroke="$s" stroke-width="1.5" stroke-linejoin="round"/>
  <path d="M14 19C15 13 21 10 27 10C33 10 35 13 34 20C31 15 26 14 21 15C17 17 15 19 14 19Z" fill="#111827"/>
  <!-- Face outline -->
  <path d="M16 20C16 27 19 32 24 32C29 32 32 27 32 20" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <!-- Ears -->
  <path d="M16 21C14.5 21 14 22.5 14.5 24C15 25.5 16 25.5 16 25" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M32 21C33.5 21 34 22.5 33.5 24C33 25.5 32 25.5 32 25" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <!-- Eyes -->
  <circle cx="20" cy="21" r="1.5" fill="#111827"/>
  <circle cx="28" cy="21" r="1.5" fill="#111827"/>
  <!-- Smile -->
  <path d="M21.5 27C22.5 28.5 25.5 28.5 26.5 27" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <!-- Neck & Collar -->
  <path d="M21 32V35M27 32V35" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <!-- Shoulders with Tie -->
  <path d="M12 41C13 36 17 35 21 35H27C31 35 35 36 36 41" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M21 35L24 39L27 35" stroke="$s" stroke-width="2" stroke-linejoin="round"/>
  <path d="M23 39H25L25.5 44L24 46L22.5 44L23 39Z" fill="$s"/>
</svg>
''';

  /// 👩 Perempuan (Question 8)
  static String _female(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Solid long hair in black matching Notion style -->
  <path d="M14 22C14 13 18 9 24 9C30 9 34 13 34 22C35 27 34 33 32 36C32 30 33 24 30 20C27 15 21 14 17 16C15 18 14 22 14 25C14 30 16 33 17 36C15 33 14 27 14 22Z" fill="#111827"/>
  <path d="M15 19C17 13 22 10 27 11C31 12 33 15 33 19C30 15 25 13 21 14C17 15 15 18 15 19Z" fill="#111827"/>
  <path d="M13 25C13 14 17 8 24 8C31 8 35 14 35 25C36 30 35 35 33 38" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M13 25C12 30 13 35 15 38" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <!-- Face outline -->
  <path d="M16 20C16 27 19 31 24 31C29 31 32 27 32 20" stroke="$s" stroke-width="2.2" stroke-linecap="round" fill="white"/>
  <!-- Eyes -->
  <circle cx="20" cy="21" r="1.5" fill="#111827"/>
  <circle cx="28" cy="21" r="1.5" fill="#111827"/>
  <!-- Smile -->
  <path d="M21.5 26.5C22.5 28 25.5 28 26.5 26.5" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <!-- Pearl earrings -->
  <circle cx="14.5" cy="23" r="1.5" fill="$s"/>
  <circle cx="33.5" cy="23" r="1.5" fill="$s"/>
  <!-- Shoulders & Blouse -->
  <path d="M11 41C12 36 16 34 20 34H28C32 34 36 36 37 41" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M20 34C20 38 28 38 28 34" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  /// 🧒 < 30 tahun (Question 10: Muda & Relate)
  static String _ageYoung(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Modern cap/snapback -->
  <path d="M15 18C15 12 18 9 24 9C30 9 33 12 33 18H15Z" fill="#111827" stroke="$s" stroke-width="1.5"/>
  <path d="M13 18H37" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <!-- Face -->
  <path d="M16 19C16 27 19 31 24 31C29 31 32 27 32 19" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <!-- Eyes -->
  <circle cx="20" cy="21" r="1.5" fill="#111827"/>
  <circle cx="28" cy="21" r="1.5" fill="#111827"/>
  <!-- Big youthful smile -->
  <path d="M21 26C22.5 28 25.5 28 27 26" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <!-- Shoulders with Hoodie -->
  <path d="M11 41C12 36 16 34 21 34H27C32 34 36 36 37 41" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M19 34C20 37 28 37 29 34" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M22 36V40M26 36V40" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <!-- Youth sparkle -->
  <path d="M37 10L38 7L39 10L42 11L39 12L38 15L37 12L34 11L37 10Z" fill="$s"/>
</svg>
''';

  /// 👴 > 40 tahun (Question 10: Senior & Berpengalaman)
  static String _ageSenior(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Distinguished hairline (high forehead + temple hair) -->
  <path d="M16 18C15 13 18 9 24 9C30 9 33 13 32 18" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M14 18V24M34 18V24" stroke="$s" stroke-width="2.5" stroke-linecap="round"/>
  <!-- Face -->
  <path d="M16 19C16 27 19 31 24 31C29 31 32 27 32 19" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <!-- Normal dot eyes with subtle experience lines -->
  <circle cx="20" cy="20.5" r="1.5" fill="#111827"/>
  <circle cx="28" cy="20.5" r="1.5" fill="#111827"/>
  <path d="M17 19.5L18.5 20.5M31 19.5L29.5 20.5" stroke="$s" stroke-width="1.4" stroke-linecap="round"/>
  <!-- Neat distinguished mustache -->
  <path d="M20.5 24.5C22 23.5 24 24 24 24.5C24 24 26 23.5 27.5 24.5C28 25.5 26.5 26.5 24 26.5C21.5 26.5 20 25.5 20.5 24.5Z" fill="#111827"/>
  <!-- Smile below mustache -->
  <path d="M22 28C22.8 28.8 25.2 28.8 26 28" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <!-- Suit with tie -->
  <path d="M11 41C12 36 16 34 21 34H27C32 34 36 36 37 41" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M21 34L24 38L27 34" stroke="$s" stroke-width="2" stroke-linejoin="round"/>
  <path d="M23 38H25L24.5 43H23.5L23 38Z" fill="$s"/>
</svg>
''';

  /// 🇮🇩 Indonesia (Question 3)
  static String _langId(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M13 10V38" stroke="$s" stroke-width="2.5" stroke-linecap="round"/>
  <path d="M13 12H35C35 12 37 15 35 18H13" stroke="$s" stroke-width="2" fill="$s"/>
  <path d="M13 18H35C35 18 37 21 35 24H13" stroke="$s" stroke-width="2" fill="white"/>
  <circle cx="13" cy="9" r="2.2" fill="$s"/>
</svg>
''';

  /// 🇬🇧 English (Question 3)
  static String _langEn(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="9" y="12" width="30" height="22" rx="4" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M24 12V34M9 23H39" stroke="$s" stroke-width="2.4"/>
  <path d="M9 12L39 34M39 12L9 34" stroke="$s" stroke-width="1.6"/>
  <circle cx="38" cy="9" r="1.5" fill="$s"/>
</svg>
''';

  /// 🇨🇳 Mandarin (Question 3)
  static String _langZh(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="9" y="10" width="30" height="25" rx="5" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M15 35L13 40L21 35" stroke="$s" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="17" y="16" width="14" height="11" stroke="$s" stroke-width="2.2" fill="none"/>
  <path d="M24 12V32" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  /// 🇸🇦 Arab (Question 3)
  static String _langAr(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="9" y="10" width="30" height="25" rx="5" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M33 35L35 40L27 35" stroke="$s" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M27 16C23.5 16 20 18.5 20 22.5C20 26.5 23.5 29 27 29C25 28 24 25.5 24 22.5C24 19.5 25 17 27 16Z" stroke="$s" stroke-width="2" fill="$s"/>
  <circle cx="29" cy="18" r="1.5" fill="$s"/>
</svg>
''';

  /// 🌅 Pagi (Question 4)
  static String _morning(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M15 28C15 23 19 19 24 19C29 19 33 23 33 28" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M24 11V15M14 16L17 18M34 16L31 18M9 28H13M35 28H39" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M8 35C8 33 11 31 14 31C16 30 19 30 21 32C23 31 27 30 30 32C32 31 36 32 37 34C39 34 40 36 40 37H8V35Z" stroke="$s" stroke-width="2.2" fill="white"/>
</svg>
''';

  /// ☀️ Siang (Question 4)
  static String _afternoon(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="9.5" stroke="$s" stroke-width="2.4" fill="white"/>
  <circle cx="21" cy="22" r="1.4" fill="$s"/>
  <circle cx="27" cy="22" r="1.4" fill="$s"/>
  <path d="M22 26C23 27.5 25 27.5 26 26" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M24 7V11M24 37V41M7 24H11M37 24H41M12 12L15 15M33 33L36 36M36 12L33 15M12 36L15 33" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
</svg>
''';

  /// 🌙 Malam (Question 4)
  static String _night(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M27 10C19.5 10 14 15.5 14 23C14 30.5 19.5 36 27 36C24 33.5 22 28.5 22 23C22 17.5 24.5 12.5 27 10Z" stroke="$s" stroke-width="2.4" fill="white"/>
  <circle cx="18.5" cy="21" r="1.3" fill="$s"/>
  <path d="M34 13L35 11L36 13L38 14L36 15L35 17L34 15L32 14L34 13Z" fill="$s"/>
  <circle cx="36" cy="25" r="1.6" fill="$s"/>
  <circle cx="11" cy="17" r="1.3" fill="$s"/>
  <path d="M12 39H36" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  /// 🪙 Harga Terendah (Question 5)
  static String _budgetLow(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="13" stroke="$s" stroke-width="2.4" fill="white"/>
  <circle cx="24" cy="24" r="9" stroke="$s" stroke-width="1.6" stroke-dasharray="2 3"/>
  <path d="M24 17V31M21 21C21 19.5 22.5 19 24 19C25.5 19 27 19.5 27 21C27 23 21 23 21 25.5C21 27 22.5 28 24 28C26 28 27 27 27 25.5" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <circle cx="37" cy="11" r="1.8" fill="$s"/>
</svg>
''';

  /// 💎 Harga Tertinggi (Question 5)
  static String _budgetHigh(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M15 19L24 11L33 19L24 37L15 19Z" stroke="$s" stroke-width="2.4" stroke-linejoin="round" fill="white"/>
  <path d="M15 19H33M19 15L24 19L29 15M24 19V37" stroke="$s" stroke-width="1.8"/>
  <path d="M10 15L11 13L12 15L14 16L12 17L11 19L10 17L8 16L10 15Z" fill="$s"/>
  <path d="M38 13L39 11L40 13L42 14L40 15L39 17L38 15L36 14L38 13Z" fill="$s"/>
</svg>
''';

  /// 🛡️ Asuransi & Dana Darurat (Question 6)
  static String _insurance(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 10C15 10 9 15 9 21H39C39 15 33 10 24 10Z" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M24 10V28C24 30 22 31.5 20.5 31.5" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M15 25V30C15 35 24 39 24 39C24 39 33 35 33 30V25" stroke="$s" stroke-width="2.2" fill="white"/>
</svg>
''';

  /// 🏠 Beli Rumah & KPR (Question 6)
  static String _house(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M11 21L24 10L37 21V37H11V21Z" stroke="$s" stroke-width="2.4" stroke-linejoin="round" fill="white"/>
  <rect x="20" y="27" width="8" height="10" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M30 15V11H34V18" stroke="$s" stroke-width="2"/>
  <circle cx="26" cy="32" r="1.2" fill="$s"/>
</svg>
''';

  /// 🎓 Pendidikan (Question 6)
  static String _education(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 12L9 19L24 26L39 19L24 12Z" stroke="$s" stroke-width="2.4" stroke-linejoin="round" fill="white"/>
  <path d="M16 22V29C16 33 24 35 24 35C24 35 32 33 32 29V22" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M36 20V28" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <circle cx="36" cy="29" r="1.5" fill="$s"/>
</svg>
''';

  /// 🏖️ Pensiun (Question 6)
  static String _retirement(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M18 14V27H30V22" stroke="$s" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M18 27L14 36M28 27L32 36" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M9 37C15 40 33 40 39 37" stroke="$s" stroke-width="2.6" stroke-linecap="round"/>
  <path d="M22 17H28M22 21H28" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  /// 🧘 Ketenangan Pikiran (Question 7)
  static String _peaceOfMind(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 14C24 14 18 20 18 26C18 30 20 33 24 33C28 33 30 30 30 26C30 20 24 14 24 14Z" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M18 24C15 25 11 28 11 31C11 33 14 34 18 34" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M30 24C33 25 37 28 37 31C37 33 34 34 30 34" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="24" cy="10" r="1.6" fill="$s"/>
</svg>
''';

  /// ❤️ Hangat & Suportif (Question 9)
  static String _supportive(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 16C22.5 13.5 19 14.5 19 17C19 20 24 23.5 24 23.5C24 23.5 29 20 29 17C29 14.5 25.5 13.5 24 16Z" stroke="$s" stroke-width="2.4" fill="$s"/>
  <path d="M12 30C14 27 18 25 21 27L24 29L27 27C30 25 34 27 36 30" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M14 34C17 37 31 37 34 34" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
</svg>
''';

  /// 🎯 To The Point & Solutif (Question 9)
  static String _direct(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="13" stroke="$s" stroke-width="2.4" fill="white"/>
  <circle cx="24" cy="24" r="7" stroke="$s" stroke-width="2"/>
  <circle cx="24" cy="24" r="2" fill="$s"/>
  <path d="M35 13L24 24M35 13H29M35 13V19" stroke="$s" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  /// ⚖️ Seimbang (Question 9)
  static String _balanced(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 11V37M16 37H32" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M13 17L24 14L35 17" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M10 25C10 28.5 16 28.5 16 25L13 17L10 25Z" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M32 25C32 28.5 38 28.5 38 25L35 17L32 25Z" stroke="$s" stroke-width="2" fill="white"/>
</svg>
''';

  /// 👂 Lebih Banyak Mendengar (Question 11)
  static String _commListen(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M22 13C16 13 13 17 13 24C13 31 17 35 21 35C24 35 25 33 24 31C22 31 20 30 20 27C20 23 25 23 25 18C25 15 24 13 22 13Z" stroke="$s" stroke-width="2.6" stroke-linecap="round" fill="white"/>
  <path d="M28 17C31 19 32 23 31 27" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M33 13C37 17 38 24 36 31" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
</svg>
''';

  /// 💡 Aktif Memberi Arahan (Question 11)
  static String _commProactive(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M17 19C17 15 20 12 24 12C28 12 31 15 31 19C31 22 29 24 28 26V29H20V26C19 24 17 22 17 19Z" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M21 32H27M22 35H26" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M24 6V9M12 12L14 14M36 12L34 14M9 21H12M36 21H39" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
</svg>
''';
}
