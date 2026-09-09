import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../home/presentation/widgets/notion_doodle_icons.dart';

/// Renders a Notion-Doodle styled vector icon for Match Expert options.
/// When [isSelected] is true, inlines, strokes, and dark fills dynamically turn
/// to the theme lime green (#9ADC09).
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
    // Q3: Languages (Real Country Flags)
    'id', 'en', 'zh', 'ar', 'flag_id', 'flag_en', 'flag_zh', 'flag_ar', 'lang_flexible',
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

  /// Adapt an existing NotionDoodleIcons SVG so its inlines, strokes, and dark fills
  /// dynamically turn to Clarafin theme lime (#9ADC09) when selected.
  static String _adapt(String svg, {required bool isSelected}) {
    if (!isSelected) {
      return svg;
    }
    return svg
        .replaceAll('stroke="black"', 'stroke="#9ADC09"')
        .replaceAll('stroke="#000000"', 'stroke="#9ADC09"')
        .replaceAll('stroke="#111827"', 'stroke="#9ADC09"')
        .replaceAll('stroke="#1E293B"', 'stroke="#9ADC09"')
        .replaceAll('fill="black"', 'fill="#9ADC09"')
        .replaceAll('fill="#000000"', 'fill="#9ADC09"')
        .replaceAll('fill="#111827"', 'fill="#9ADC09"')
        .replaceAll('fill="#1E293B"', 'fill="#9ADC09"');
  }

  static String getSvg(String key, {bool isSelected = false}) {
    final s = isSelected ? '#9ADC09' : '#111827';
    final f = isSelected ? '#9ADC09' : '#111827';

    switch (key) {
      // ── Q1: Metode Konseling ──
      case 'online':
        return _online(s, f);
      case 'offline':
        return _offline(s);
      case 'both':
        // Nyaman dengan keduanya -> Jabat Tangan dengan Badge Checklist
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

      // ── Q3: Bahasa (Real Country Flags) ──
      case 'id':
      case 'flag_id':
        return _flagIndonesia(s);
      case 'en':
      case 'flag_en':
        return _flagUK(s);
      case 'zh':
      case 'flag_zh':
        return _flagChina(s);
      case 'ar':
      case 'flag_ar':
        return _flagSaudi(s);
      case 'lang_flexible':
        return _handshake(s);

      // ── Q4: Waktu Sesi ──
      case 'morning':
        return _morning(s);
      case 'afternoon':
        return _afternoon(s, f);
      case 'night':
        return _night(s, f);
      case 'time_flexible':
        return _handshake(s);

      // ── Q5: Anggaran / Tarif ──
      case 'low':
        return _budgetLow(s, f);
      case 'medium':
        return _adapt(NotionDoodleIcons.goals, isSelected: isSelected);
      case 'high':
        return _budgetHigh(s, f);
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
        return _retirement(s, f);

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
        return _male(s, f);
      case 'female':
        return _female(s, f);
      case 'gender_flexible':
        return _handshake(s);

      // ── Q9: Gaya Pendekatan ──
      case 'supportive':
        return _supportive(s, f);
      case 'direct':
        return _direct(s, f);
      case 'balanced':
        return _balanced(s);
      case 'style_flexible':
        return _handshake(s);

      // ── Q10: Preferensi Usia ──
      case 'young':
        return _ageYoung(s, f);
      case 'mid':
        // 30-40 tahun -> Reuses NotionDoodleIcons.individu (professional with glasses!)
        return _adapt(NotionDoodleIcons.individu, isSelected: isSelected);
      case 'senior':
        return _ageSenior(s, f);
      case 'age_flexible':
        return _handshake(s);

      // ── Q11: Pola Komunikasi ──
      case 'listen_first':
        return _commListen(s);
      case 'proactive':
        return _commProactive(s);
      case 'comm_both':
        // Diskusi Interaktif Seimbang -> Balon dialog dua arah interaktif
        return _commBoth(s);
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

  /// 🤝 Jabat Tangan (Handshake) dengan Badge Approval di atasnya
  /// Sesuai referensi: 2 lengan bersudut diagonal, cuff kapsul, jabat tangan, dan badge checklist.
  static String _handshake(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Top badge: Circle with checkmark -->
  <circle cx="24" cy="11.5" r="6.5" stroke="$s" stroke-width="2.5" fill="white" />
  <path d="M21.2 11.5 L23.4 13.8 L26.8 9.8" stroke="$s" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" />
  
  <!-- Left sleeve cuff: rounded capsule tilted ~-40 deg -->
  <path d="M7.5 19.5 L13 14 C14.5 12.5 16.5 14 15.5 15.5 L10.5 21 C9.5 22 6.5 20.5 7.5 19.5 Z" stroke="$s" stroke-width="2.5" stroke-linejoin="round" fill="white" />
  
  <!-- Right sleeve cuff: rounded capsule tilted ~40 deg -->
  <path d="M40.5 19.5 L35 14 C33.5 12.5 31.5 14 32.5 15.5 L37.5 21 C38.5 22 41.5 20.5 40.5 19.5 Z" stroke="$s" stroke-width="2.5" stroke-linejoin="round" fill="white" />
  
  <!-- Left hand: thumb & upper palm reaching right -->
  <path d="M14.5 19.5 L19 23 C20.5 24 23.5 24.5 25.5 22.5 C27 21 29 21.5 29.5 23" stroke="$s" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
  
  <!-- Right hand: palm outline & fingers wrapping -->
  <path d="M33.5 19.5 C34.5 24 33 29.5 28.5 33.5 C26 35.8 22 36.5 19 33.5" stroke="$s" stroke-width="2.5" stroke-linecap="round" />
  
  <!-- 4 Fingers (dividing curves) -->
  <path d="M16 27 C17.5 25.5 20.5 25 23 26.5" stroke="$s" stroke-width="2.4" stroke-linecap="round" />
  <path d="M17 30 C18.5 28.5 21.5 28 24 29.5" stroke="$s" stroke-width="2.4" stroke-linecap="round" />
  <path d="M18.5 33 C20 31.5 23 31 25 32.5" stroke="$s" stroke-width="2.4" stroke-linecap="round" />
</svg>
''';

  /// 🇮🇩 Bendera Indonesia (Real Flag Badge)
  static String _flagIndonesia(String s) => '''
<svg viewBox="0 0 54 36" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <clipPath id="clip_flag_id">
      <rect width="54" height="36" rx="6" />
    </clipPath>
  </defs>
  <g clip-path="url(#clip_flag_id)">
    <rect x="0" y="0" width="54" height="18" fill="#E11D48" />
    <rect x="0" y="18" width="54" height="18" fill="#FFFFFF" />
  </g>
  <rect width="54" height="36" rx="6" stroke="$s" stroke-width="2" fill="none" />
</svg>
''';

  /// 🇬🇧 Bendera United Kingdom / English (Real Flag Badge)
  static String _flagUK(String s) => '''
<svg viewBox="0 0 54 36" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <clipPath id="clip_flag_en">
      <rect width="54" height="36" rx="6" />
    </clipPath>
  </defs>
  <g clip-path="url(#clip_flag_en)">
    <rect width="54" height="36" fill="#012169" />
    <!-- Diagonal white saltire -->
    <line x1="0" y1="0" x2="54" y2="36" stroke="#FFFFFF" stroke-width="7" />
    <line x1="0" y1="36" x2="54" y2="0" stroke="#FFFFFF" stroke-width="7" />
    <!-- Diagonal red saltire -->
    <line x1="0" y1="0" x2="54" y2="36" stroke="#C8102E" stroke-width="2.6" />
    <line x1="0" y1="36" x2="54" y2="0" stroke="#C8102E" stroke-width="2.6" />
    <!-- St George white cross -->
    <rect x="22" y="0" width="10" height="36" fill="#FFFFFF" />
    <rect x="0" y="13" width="54" height="10" fill="#FFFFFF" />
    <!-- St George red cross -->
    <rect x="24" y="0" width="6" height="36" fill="#C8102E" />
    <rect x="0" y="15" width="54" height="6" fill="#C8102E" />
  </g>
  <rect width="54" height="36" rx="6" stroke="$s" stroke-width="2" fill="none" />
</svg>
''';

  /// 🇨🇳 Bendera China / Mandarin (Real Flag Badge)
  static String _flagChina(String s) => '''
<svg viewBox="0 0 54 36" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <clipPath id="clip_flag_zh">
      <rect width="54" height="36" rx="6" />
    </clipPath>
  </defs>
  <g clip-path="url(#clip_flag_zh)">
    <rect width="54" height="36" fill="#DE2910" />
    <!-- Large Yellow Star -->
    <polygon points="10,5 11.8,10.5 17.5,10.5 13,13.8 14.7,19.2 10,15.8 5.3,19.2 7,13.8 2.5,10.5 8.2,10.5" fill="#FFDE00" />
    <!-- 4 Small Stars in Arc -->
    <polygon points="19,5 19.6,7 21.5,7 20,8.2 20.6,10 19,8.9 17.4,10 18,8.2 16.5,7 18.4,7" fill="#FFDE00" />
    <polygon points="22,9 22.6,11 24.5,11 23,12.2 23.6,14 22,12.9 20.4,14 21,12.2 19.5,11 21.4,11" fill="#FFDE00" />
    <polygon points="22,15 22.6,17 24.5,17 23,18.2 23.6,20 22,18.9 20.4,20 21,18.2 19.5,17 21.4,17" fill="#FFDE00" />
    <polygon points="19,19 19.6,21 21.5,21 20,22.2 20.6,24 19,22.9 17.4,24 18,22.2 16.5,21 18.4,21" fill="#FFDE00" />
  </g>
  <rect width="54" height="36" rx="6" stroke="$s" stroke-width="2" fill="none" />
</svg>
''';

  /// 🇸🇦 Bendera Arab Saudi (Real Flag Badge)
  static String _flagSaudi(String s) => '''
<svg viewBox="0 0 54 36" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <clipPath id="clip_flag_ar">
      <rect width="54" height="36" rx="6" />
    </clipPath>
  </defs>
  <g clip-path="url(#clip_flag_ar)">
    <rect width="54" height="36" fill="#006C35" />
    <!-- Arabic Calligraphy Inscription representation -->
    <path d="M12 13 Q16 10 20 13 T28 12 T36 14 T40 12" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round" fill="none" />
    <path d="M14 10 H18 M24 9 H27 M32 10 H35" stroke="#FFFFFF" stroke-width="1.8" stroke-linecap="round" />
    <!-- White Sword underneath -->
    <path d="M12 21 H36 Q39 21 41 19.5 Q39 22.5 36 22.5 H12 Z" fill="#FFFFFF" />
    <path d="M12 18.5 V23.5" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" />
  </g>
  <rect width="54" height="36" rx="6" stroke="$s" stroke-width="2" fill="none" />
</svg>
''';

  /// 💬 Diskusi Interaktif Seimbang (Question 11) - Balon Dialog Dua Arah
  static String _commBoth(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Left Speech Bubble -->
  <rect x="7" y="10" width="20" height="15" rx="5" stroke="$s" stroke-width="2.4" fill="white" />
  <path d="M12 25 L10 29 L16 25" stroke="$s" stroke-width="2.4" stroke-linejoin="round" fill="white" />
  <path d="M12 15 H21" stroke="$s" stroke-width="2" stroke-linecap="round" />
  <path d="M12 19 H17" stroke="$s" stroke-width="2" stroke-linecap="round" />
  
  <!-- Right Speech Bubble -->
  <rect x="21" y="20" width="20" height="15" rx="5" stroke="$s" stroke-width="2.4" fill="white" />
  <path d="M36 35 L38 39 L32 35" stroke="$s" stroke-width="2.4" stroke-linejoin="round" fill="white" />
  <path d="M26 25 H35" stroke="$s" stroke-width="2" stroke-linecap="round" />
  <path d="M30 29 H35" stroke="$s" stroke-width="2" stroke-linecap="round" />
  
  <!-- Exchange arrow / spark -->
  <path d="M19 6 L21 4 L23 6" stroke="$s" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
</svg>
''';

  /// 💻 Online (Question 1)
  static String _online(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="8" y="11" width="32" height="21" rx="4" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M4 33H44" stroke="$s" stroke-width="2.6" stroke-linecap="round"/>
  <circle cx="24" cy="19" r="3.5" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M18 28C18 25 20.5 23.5 24 23.5C27.5 23.5 30 25 30 28" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <circle cx="24" cy="13.5" r="1" fill="$f"/>
  <path d="M34 8L36 6M38 10L42 9" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  /// 👥 Tatap Muka (Question 1)
  static String _offline(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="18" cy="17" r="4.5" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M11 32C11 27.5 14.5 25 18 25C21.5 25 25 27.5 25 32" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <circle cx="30" cy="17" r="4.5" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M23 32C23 27.5 26.5 25 30 25C33.5 25 37 27.5 37 32" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M18 35H30" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  /// 👨 Laki-laki (Question 8)
  static String _male(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Hair: side part in dark/active color -->
  <path d="M14 20C13 13 17 9 24 9C31 9 35 13 34 20C33 16 31 12 24 12C17 12 15 16 14 20Z" fill="$f" stroke="$s" stroke-width="1.5" stroke-linejoin="round"/>
  <path d="M14 19C15 13 21 10 27 10C33 10 35 13 34 20C31 15 26 14 21 15C17 17 15 19 14 19Z" fill="$f"/>
  <!-- Face outline -->
  <path d="M16 20C16 27 19 32 24 32C29 32 32 27 32 20" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <!-- Ears -->
  <path d="M16 21C14.5 21 14 22.5 14.5 24C15 25.5 16 25.5 16 25" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M32 21C33.5 21 34 22.5 33.5 24C33 25.5 32 25.5 32 25" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <!-- Eyes -->
  <circle cx="20" cy="21" r="1.5" fill="$f"/>
  <circle cx="28" cy="21" r="1.5" fill="$f"/>
  <!-- Smile -->
  <path d="M21.5 27C22.5 28.5 25.5 28.5 26.5 27" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <!-- Neck & Collar -->
  <path d="M21 32V35M27 32V35" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <!-- Shoulders with Tie -->
  <path d="M12 41C13 36 17 35 21 35H27C31 35 35 36 36 41" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M21 35L24 39L27 35" stroke="$s" stroke-width="2" stroke-linejoin="round"/>
  <path d="M23 39H25L25.5 44L24 46L22.5 44L23 39Z" fill="$f"/>
</svg>
''';

  /// 👩 Perempuan (Question 8)
  static String _female(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Solid long hair in dark/active color matching Notion style -->
  <path d="M14 22C14 13 18 9 24 9C30 9 34 13 34 22C35 27 34 33 32 36C32 30 33 24 30 20C27 15 21 14 17 16C15 18 14 22 14 25C14 30 16 33 17 36C15 33 14 27 14 22Z" fill="$f"/>
  <path d="M15 19C17 13 22 10 27 11C31 12 33 15 33 19C30 15 25 13 21 14C17 15 15 18 15 19Z" fill="$f"/>
  <path d="M13 25C13 14 17 8 24 8C31 8 35 14 35 25C36 30 35 35 33 38" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M13 25C12 30 13 35 15 38" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <!-- Face outline -->
  <path d="M16 20C16 27 19 31 24 31C29 31 32 27 32 20" stroke="$s" stroke-width="2.2" stroke-linecap="round" fill="white"/>
  <!-- Eyes -->
  <circle cx="20" cy="21" r="1.5" fill="$f"/>
  <circle cx="28" cy="21" r="1.5" fill="$f"/>
  <!-- Smile -->
  <path d="M21.5 26.5C22.5 28 25.5 28 26.5 26.5" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <!-- Pearl earrings -->
  <circle cx="14.5" cy="23" r="1.5" fill="$f"/>
  <circle cx="33.5" cy="23" r="1.5" fill="$f"/>
  <!-- Shoulders & Blouse -->
  <path d="M11 41C12 36 16 34 20 34H28C32 34 36 36 37 41" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M20 34C20 38 28 38 28 34" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  /// 🧒 < 30 tahun (Question 10: Muda & Relate)
  static String _ageYoung(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Modern cap/snapback -->
  <path d="M15 18C15 12 18 9 24 9C30 9 33 12 33 18H15Z" fill="$f" stroke="$s" stroke-width="1.5"/>
  <path d="M13 18H37" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <!-- Face -->
  <path d="M16 19C16 27 19 31 24 31C29 31 32 27 32 19" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <!-- Eyes -->
  <circle cx="20" cy="22" r="1.5" fill="$f"/>
  <circle cx="28" cy="22" r="1.5" fill="$f"/>
  <!-- Big Smile -->
  <path d="M20.5 26.5C22 28.5 26 28.5 27.5 26.5" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <!-- Hoodie & Drawstrings -->
  <path d="M12 41C13 35 17 34 21 34H27C31 34 35 35 36 41" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M22 34V39M26 34V39" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <circle cx="22" cy="39" r="1" fill="$f"/>
  <circle cx="26" cy="39" r="1" fill="$f"/>
  <!-- Young energy sparkle -->
  <path d="M31 10L32 8L33 10L35 11L33 12L32 14L31 12L29 11L31 10Z" fill="$f"/>
</svg>
''';

  /// 👴 > 40 tahun (Question 10: Pengalaman & Jam Terbang)
  static String _ageSenior(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Distinguished hairline / temples -->
  <path d="M13 22C13 18 14 13 18 10C21 8 27 8 30 10C34 13 35 18 35 22C35 24 33 24 32 22C31 15 27 11 24 11C21 11 17 15 16 22C15 24 13 24 13 22Z" fill="$f"/>
  <!-- Face outline -->
  <path d="M15 21C15 28 18 32 24 32C30 32 33 28 33 21" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <!-- Normal dot eyes with subtle smile lines -->
  <circle cx="20" cy="21" r="1.5" fill="$f"/>
  <circle cx="28" cy="21" r="1.5" fill="$f"/>
  <path d="M17 21L18 22M31 21L30 22" stroke="$s" stroke-width="1.5" stroke-linecap="round"/>
  <!-- Distinguished mustache -->
  <path d="M20 27C21.5 26 23.5 26 24 27.5C24.5 26 26.5 26 28 27" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M22 29C23 29.8 25 29.8 26 29" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <!-- Suit with tie -->
  <path d="M11 41C12 36 16 34 21 34H27C32 34 36 36 37 41" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M21 34L24 38L27 34" stroke="$s" stroke-width="2" stroke-linejoin="round"/>
  <path d="M23 38H25L24.5 43H23.5L23 38Z" fill="$f"/>
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
  static String _afternoon(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="9.5" stroke="$s" stroke-width="2.4" fill="white"/>
  <circle cx="21" cy="22" r="1.4" fill="$f"/>
  <circle cx="27" cy="22" r="1.4" fill="$f"/>
  <path d="M22 26C23 27.5 25 27.5 26 26" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M24 7V11M24 37V41M7 24H11M37 24H41M12 12L15 15M33 33L36 36M36 12L33 15M12 36L15 33" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
</svg>
''';

  /// 🌙 Malam (Question 4)
  static String _night(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M27 10C19.5 10 14 15.5 14 23C14 30.5 19.5 36 27 36C24 33.5 22 28.5 22 23C22 17.5 24.5 12.5 27 10Z" stroke="$s" stroke-width="2.4" fill="white"/>
  <circle cx="18.5" cy="21" r="1.3" fill="$f"/>
  <path d="M34 13L35 11L36 13L38 14L36 15L35 17L34 15L32 14L34 13Z" fill="$f"/>
  <circle cx="36" cy="25" r="1.6" fill="$f"/>
  <circle cx="11" cy="17" r="1.3" fill="$f"/>
  <path d="M12 39H36" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  /// 🪙 Harga Terendah (Question 5)
  static String _budgetLow(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="13" stroke="$s" stroke-width="2.4" fill="white"/>
  <circle cx="24" cy="24" r="9" stroke="$s" stroke-width="1.6" stroke-dasharray="2 3"/>
  <path d="M24 17V31M21 21C21 19.5 22.5 19 24 19C25.5 19 27 19.5 27 21C27 23 21 23 21 25.5C21 27 22.5 28 24 28C26 28 27 27 27 25.5" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <circle cx="37" cy="11" r="1.8" fill="$f"/>
</svg>
''';

  /// 💎 Harga Tertinggi (Question 5)
  static String _budgetHigh(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M15 19L24 11L33 19L24 37L15 19Z" stroke="$s" stroke-width="2.4" stroke-linejoin="round" fill="white"/>
  <path d="M15 19H33M19 15L24 19L29 15M24 19V37" stroke="$s" stroke-width="1.8"/>
  <path d="M10 15L11 13L12 15L14 16L12 17L11 19L10 17L8 16L10 15Z" fill="$f"/>
  <path d="M38 13L39 11L40 13L42 14L40 15L39 17L38 15L36 14L38 13Z" fill="$f"/>
</svg>
''';

  /// 🛡️ Asuransi & Dana Darurat (Question 6)
  static String _insurance(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 8L13 13V23C13 30.5 18 36.5 24 40C30 36.5 35 30.5 35 23V13L24 8Z" stroke="$s" stroke-width="2.4" stroke-linejoin="round" fill="white"/>
  <path d="M24 17V30M17.5 23.5H30.5" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
</svg>
''';

  /// 🏡 Rumah & KPR (Question 6)
  static String _house(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M10 21L24 10L38 21" stroke="$s" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M14 18V36H34V18" stroke="$s" stroke-width="2.4" fill="white"/>
  <rect x="20" y="26" width="8" height="10" stroke="$s" stroke-width="2" fill="white"/>
  <circle cx="22" cy="31" r="0.8" fill="$s"/>
</svg>
''';

  /// 🎓 Pendidikan Anak (Question 6)
  static String _education(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M8 20L24 13L40 20L24 27L8 20Z" stroke="$s" stroke-width="2.4" stroke-linejoin="round" fill="white"/>
  <path d="M14 23V31C14 34.5 18.5 37 24 37C29.5 37 34 34.5 34 31V23" stroke="$s" stroke-width="2.4"/>
  <path d="M38 21V31" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  /// 🌴 Pensiun & Warisan (Question 6)
  static String _retirement(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 14C24 14 18 20 18 26C18 30 20 33 24 33C28 33 30 30 30 26C30 20 24 14 24 14Z" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M18 24C15 25 11 28 11 31C11 33 14 34 18 34" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M30 24C33 25 37 28 37 31C37 33 34 34 30 34" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="24" cy="10" r="1.6" fill="$f"/>
</svg>
''';

  /// 🕊️ Ketenangan Pikiran (Question 7)
  static String _peaceOfMind(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 14C24 14 18 20 18 26C18 30 20 33 24 33C28 33 30 30 30 26C30 20 24 14 24 14Z" stroke="$s" stroke-width="2.4" fill="white"/>
  <circle cx="24" cy="24" r="3.5" stroke="$s" stroke-width="2"/>
</svg>
''';

  /// ❤️ Hangat & Suportif (Question 9)
  static String _supportive(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 16C22.5 13.5 19 14.5 19 17C19 20 24 23.5 24 23.5C24 23.5 29 20 29 17C29 14.5 25.5 13.5 24 16Z" stroke="$s" stroke-width="2.4" fill="$f"/>
  <path d="M12 30C14 27 18 25 21 27L24 29L27 27C30 25 34 27 36 30" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M14 34C17 37 31 37 34 34" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
</svg>
''';

  /// 🎯 To The Point & Solutif (Question 9)
  static String _direct(String s, String f) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="13" stroke="$s" stroke-width="2.4" fill="white"/>
  <circle cx="24" cy="24" r="7" stroke="$s" stroke-width="2"/>
  <circle cx="24" cy="24" r="2" fill="$f"/>
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
