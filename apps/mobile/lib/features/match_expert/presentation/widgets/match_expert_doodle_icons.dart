import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MatchExpertDoodleWidget extends StatelessWidget {
  final String svgKey;
  final bool isSelected;
  final double size;

  const MatchExpertDoodleWidget({
    super.key,
    required this.svgKey,
    required this.isSelected,
    this.size = 38,
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
    // Q2: Target
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
    'flexible',
  };

  static bool hasSvg(String key) {
    return _knownKeys.contains(key);
  }

  static String getSvg(String key, {bool isSelected = false}) {
    // Inlines turn to theme lime (#9ADC09) when active, dark (#111827) when inactive
    final s = isSelected ? '#9ADC09' : '#111827';

    switch (key) {
      // Q1: Method
      case 'online':
        return _online(s);
      case 'offline':
        return _offline(s);
      case 'both':
      case 'comm_both':
        return _both(s);

      // Q2: Target
      case 'self':
        return _self(s);
      case 'couple':
        return _couple(s);
      case 'family':
        return _family(s);
      case 'business':
      case 'sme':
        return _business(s);

      // Q3: Languages
      case 'id':
        return _langId(s);
      case 'en':
        return _langEn(s);
      case 'zh':
        return _langZh(s);
      case 'ar':
        return _langAr(s);
      case 'lang_flexible':
        return _langFlexible(s);

      // Q4: Time
      case 'morning':
        return _morning(s);
      case 'afternoon':
        return _afternoon(s);
      case 'night':
        return _night(s);
      case 'time_flexible':
        return _timeFlexible(s);

      // Q5: Budget
      case 'low':
        return _budgetLow(s);
      case 'medium':
        return _budgetMed(s);
      case 'high':
        return _budgetHigh(s);
      case 'budget_flexible':
        return _budgetFlex(s);

      // Q6: Topics
      case 'debt_cashflow':
        return _debtCashflow(s);
      case 'investment':
        return _investment(s);
      case 'emergency_insurance':
        return _insurance(s);
      case 'house_wedding':
        return _house(s);
      case 'education':
        return _education(s);
      case 'retirement':
        return _retirement(s);

      // Q7: Goals
      case 'action_plan':
        return _actionPlan(s);
      case 'debt_free':
        return _debtFree(s);
      case 'low_risk_portfolio':
        return _portfolio(s);
      case 'peace_of_mind':
        return _peaceOfMind(s);
      case 'specific_goal':
        return _specificGoal(s);

      // Q8: Gender
      case 'male':
        return _male(s);
      case 'female':
        return _female(s);
      case 'gender_flexible':
        return _genderFlex(s);

      // Q9: Approach Style
      case 'supportive':
        return _supportive(s);
      case 'direct':
        return _direct(s);
      case 'balanced':
        return _balanced(s);
      case 'style_flexible':
        return _styleFlex(s);

      // Q10: Age Preference
      case 'young':
        return _ageYoung(s);
      case 'mid':
        return _ageMid(s);
      case 'senior':
        return _ageSenior(s);
      case 'age_flexible':
        return _ageFlex(s);

      // Q11: Comm
      case 'listen_first':
        return _commListen(s);
      case 'proactive':
        return _commProactive(s);
      case 'comm_flexible':
        return _commFlex(s);

      case 'flexible':
      default:
        return _both(s);
    }
  }

  // --- SVG Templates ---
  static String _online(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="9" y="11" width="30" height="21" rx="4" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M5 33H43" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <circle cx="24" cy="19" r="3.2" stroke="$s" stroke-width="1.8" fill="white"/>
  <path d="M18 28C18 25.2 20.5 24 24 24C27.5 24 30 25.2 30 28" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M33 9L36 6M37 10L41 9" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  static String _offline(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="16" cy="18" r="3.2" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M11 28C11 25 13.5 23.5 16 23.5C18.5 23.5 20.5 24.5 21 26" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <circle cx="32" cy="18" r="3.2" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M37 28C37 25 34.5 23.5 32 23.5C29.5 23.5 27.5 24.5 27 26" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M8 32H40" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M22 32V27H26V32" stroke="$s" stroke-width="1.8" fill="white"/>
  <path d="M24 24.5V23" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  static String _both(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M10 24L17 18L24 23L18 29L10 24Z" stroke="$s" stroke-width="2.2" fill="white" stroke-linejoin="round"/>
  <path d="M38 24L31 18L24 23L30 29L38 24Z" stroke="$s" stroke-width="2.2" fill="white" stroke-linejoin="round"/>
  <path d="M21 21L24 24L27 21" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M22 25L24 27L26 25" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <circle cx="24" cy="10" r="2" fill="$s"/>
  <circle cx="12" cy="14" r="1.3" fill="$s"/>
  <circle cx="36" cy="14" r="1.3" fill="$s"/>
</svg>
''';

  static String _self(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M16 20C16 14 19 10 24 10C29 10 32 14 32 20" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M16 20C16 27 19 32 24 32C29 32 32 27 32 20" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="20" cy="21" r="1.5" fill="$s"/>
  <circle cx="28" cy="21" r="1.5" fill="$s"/>
  <path d="M18.5 18.5C19.5 18 21 18 21.5 18.5" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M26.5 18.5C27 18 28.5 18 29.5 18.5" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M21.5 27C22.5 28.5 25.5 28.5 26.5 27" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M12 40C13 36 17 35 21 35H27C31 35 35 36 36 40" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M21 35L24 39L27 35" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  static String _couple(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 7C22.5 4.5 19 5.5 19 8C19 11 24 13.5 24 13.5C24 13.5 29 11 29 8C29 5.5 25.5 4.5 24 7Z" fill="$s" stroke="$s" stroke-width="1.5"/>
  <path d="M12 21C12 26 14 29 18 29C21 29 23 26 23 21" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <circle cx="15.5" cy="21" r="1.3" fill="$s"/>
  <circle cx="20.5" cy="21" r="1.3" fill="$s"/>
  <path d="M17 25C18 26 19.5 26 20.5 25" stroke="$s" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M7 39C8 34 12 33 16 33C18 33 20 34 21 36" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M27 21C27 26 29 29 33 29C37 29 39 26 39 21" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <circle cx="30.5" cy="21" r="1.3" fill="$s"/>
  <circle cx="35.5" cy="21" r="1.3" fill="$s"/>
  <path d="M32 25C33 26 34.5 26 35.5 25" stroke="$s" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M27 36C28 34 30 33 33 33C37 33 40 34 41 39" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  static String _family(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M11 18C11 23 13 25 16 25C19 25 20 23 20 18" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <circle cx="14" cy="18" r="1.2" fill="$s"/>
  <circle cx="18" cy="18" r="1.2" fill="$s"/>
  <path d="M15 22C16 23 17 23 18 22" stroke="$s" stroke-width="1.3" stroke-linecap="round"/>
  <path d="M6 38C7 32 10 30 14 30" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M28 18C28 23 30 25 33 25C36 25 38 23 38 18" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <circle cx="31" cy="18" r="1.2" fill="$s"/>
  <circle cx="35" cy="18" r="1.2" fill="$s"/>
  <path d="M32 22C33 23 34 23 35 22" stroke="$s" stroke-width="1.3" stroke-linecap="round"/>
  <path d="M34 30C38 30 41 32 42 38" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M21 27C21 31 22.5 33 24.5 33C26.5 33 28 31 28 27" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <circle cx="23" cy="28" r="1" fill="$s"/>
  <circle cx="26" cy="28" r="1" fill="$s"/>
  <path d="M23.5 30.5C24.2 31.5 25.2 31.5 25.8 30.5" stroke="$s" stroke-width="1.3" stroke-linecap="round"/>
  <path d="M17 40C18 35 21 34 24.5 34C28 34 30 35 31 40" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  static String _business(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M10 19L13 11H35L38 19H10Z" stroke="$s" stroke-width="2.2" stroke-linejoin="round" fill="white"/>
  <path d="M10 19C10 21 12 22 14 21C16 22 18 22 19 21C20 22 22 22 24 21C26 22 28 22 29 21C30 22 32 22 34 21C36 22 38 21 38 19" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M12 21V38H36V21" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <rect x="21" y="26" width="8" height="12" rx="1" stroke="$s" stroke-width="1.8" fill="white"/>
  <circle cx="27" cy="32" r="1" fill="$s"/>
  <rect x="14" y="25" width="5" height="6" rx="1" stroke="$s" stroke-width="1.5" fill="white"/>
  <path d="M8 38H40" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  static String _langId(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M13 10V38" stroke="$s" stroke-width="2.5" stroke-linecap="round"/>
  <path d="M13 12H35C35 12 37 15 35 18H13" stroke="$s" stroke-width="2" fill="$s"/>
  <path d="M13 18H35C35 18 37 21 35 24H13" stroke="$s" stroke-width="2" fill="white"/>
  <circle cx="13" cy="9" r="2.2" fill="$s"/>
</svg>
''';

  static String _langEn(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="12" width="28" height="22" rx="4" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M24 12V34M10 23H38" stroke="$s" stroke-width="2.2"/>
  <path d="M10 12L38 34M38 12L10 34" stroke="$s" stroke-width="1.4"/>
  <circle cx="37" cy="9" r="1.5" fill="$s"/>
</svg>
''';

  static String _langZh(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="10" width="28" height="24" rx="5" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M16 34L14 39L21 34" stroke="$s" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="18" y="16" width="12" height="10" stroke="$s" stroke-width="2" fill="none"/>
  <path d="M24 12V31" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  static String _langAr(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="10" width="28" height="24" rx="5" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M32 34L34 39L27 34" stroke="$s" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M26 16C23 16 20 18.5 20 22C20 25.5 23 28 26 28C24.5 27 23.5 25 23.5 22C23.5 19 24.5 17 26 16Z" stroke="$s" stroke-width="2" fill="$s"/>
  <circle cx="28" cy="18" r="1.3" fill="$s"/>
</svg>
''';

  static String _langFlexible(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="14" stroke="$s" stroke-width="2.2" fill="white"/>
  <ellipse cx="24" cy="24" rx="6" ry="14" stroke="$s" stroke-width="1.8"/>
  <path d="M10 24H38" stroke="$s" stroke-width="1.8"/>
  <circle cx="21" cy="21" r="1.3" fill="$s"/>
  <circle cx="27" cy="21" r="1.3" fill="$s"/>
  <path d="M22 25C23 26 25 26 26 25" stroke="$s" stroke-width="1.5" stroke-linecap="round"/>
</svg>
''';

  static String _morning(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M15 28C15 23 19 19 24 19C29 19 33 23 33 28" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M24 11V15M14 16L17 18M34 16L31 18M9 28H13M35 28H39" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M8 35C8 33 11 31 14 31C16 30 19 30 21 32C23 31 27 30 30 32C32 31 36 32 37 34C39 34 40 36 40 37H8V35Z" stroke="$s" stroke-width="2.2" fill="white"/>
</svg>
''';

  static String _afternoon(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="9" stroke="$s" stroke-width="2.4" fill="white"/>
  <circle cx="21" cy="22" r="1.3" fill="$s"/>
  <circle cx="27" cy="22" r="1.3" fill="$s"/>
  <path d="M22 26C23 27.5 25 27.5 26 26" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M24 8V11M24 37V40M8 24H11M37 24H40M13 13L15 15M33 33L35 35M35 13L33 15M13 35L15 33" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  static String _night(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M27 11C20 11 15 16 15 23C15 30 20 35 27 35C24 33 22 28 22 23C22 18 24.5 13 27 11Z" stroke="$s" stroke-width="2.2" fill="white"/>
  <circle cx="19" cy="21" r="1.2" fill="$s"/>
  <path d="M34 13L35 11L36 13L38 14L36 15L35 17L34 15L32 14L34 13Z" fill="$s"/>
  <circle cx="36" cy="25" r="1.5" fill="$s"/>
  <circle cx="11" cy="18" r="1.2" fill="$s"/>
  <path d="M12 38H36" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  static String _timeFlexible(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="11" y="13" width="26" height="24" rx="4" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M11 20H37" stroke="$s" stroke-width="2"/>
  <path d="M18 10V14M30 10V14" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <circle cx="24" cy="27" r="5" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M24 24V27L26.5 28.5" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  static String _budgetLow(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="13" stroke="$s" stroke-width="2.4" fill="white"/>
  <circle cx="24" cy="24" r="9" stroke="$s" stroke-width="1.6" stroke-dasharray="2 3"/>
  <path d="M24 17V31M21 21C21 19.5 22.5 19 24 19C25.5 19 27 19.5 27 21C27 23 21 23 21 25.5C21 27 22.5 28 24 28C26 28 27 27 27 25.5" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="37" cy="11" r="1.8" fill="$s"/>
</svg>
''';

  static String _budgetMed(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M13 25C13 18 19 14 26 14C33 14 38 18 38 25C38 31 33 34 26 34C24 34 22 33.5 20 33L16 35V31C14 29 13 27 13 25Z" stroke="$s" stroke-width="2.2" fill="white"/>
  <circle cx="32" cy="21" r="1.3" fill="$s"/>
  <ellipse cx="38" cy="24" rx="2" ry="3" stroke="$s" stroke-width="1.8" fill="white"/>
  <path d="M23 14H28" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="25.5" cy="9" r="3" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M19 34V38M31 34V38" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  static String _budgetHigh(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M16 19L24 11L32 19L24 37L16 19Z" stroke="$s" stroke-width="2.4" stroke-linejoin="round" fill="white"/>
  <path d="M16 19H32M20 15L24 19L28 15M24 19V37" stroke="$s" stroke-width="1.8"/>
  <path d="M11 15L12 13L13 15L15 16L13 17L12 19L11 17L9 16L11 15Z" fill="$s"/>
  <path d="M37 13L38 11L39 13L41 14L39 15L38 17L37 15L35 14L37 13Z" fill="$s"/>
</svg>
''';

  static String _budgetFlex(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 11V37M16 37H32" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M14 17L24 14L34 17" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M11 25C11 28 17 28 17 25L14 17L11 25Z" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M31 25C31 28 37 28 37 25L34 17L31 25Z" stroke="$s" stroke-width="2" fill="white"/>
</svg>
''';

  static String _debtCashflow(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="14" width="28" height="18" rx="3" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M10 19H38" stroke="$s" stroke-width="1.8"/>
  <circle cx="17" cy="33" r="3" stroke="$s" stroke-width="2"/>
  <circle cx="26" cy="35" r="3" stroke="$s" stroke-width="2"/>
  <path d="M19 31L33 13" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M24 33L16 23" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  static String _investment(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="27" width="5" height="12" stroke="$s" stroke-width="2" fill="$s"/>
  <rect x="18" y="21" width="5" height="18" stroke="$s" stroke-width="2" fill="white"/>
  <rect x="26" y="15" width="5" height="24" stroke="$s" stroke-width="2" fill="$s"/>
  <path d="M8 39H36" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M12 22L20 16L28 11L36 15" stroke="$s" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M36 10L36 15L31 15" stroke="$s" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  static String _insurance(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 10C16 10 10 15 10 20H38C38 15 32 10 24 10Z" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M24 10V28C24 29.5 22.5 31 21 31" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M15 24V30C15 35 24 39 24 39C24 39 33 35 33 30V24" stroke="$s" stroke-width="2" fill="white"/>
</svg>
''';

  static String _house(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 21L24 11L36 21V37H12V21Z" stroke="$s" stroke-width="2.2" stroke-linejoin="round" fill="white"/>
  <rect x="20" y="27" width="8" height="10" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M30 16V12H34V19" stroke="$s" stroke-width="2"/>
  <circle cx="26" cy="32" r="1" fill="$s"/>
</svg>
''';

  static String _education(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 12L10 19L24 26L38 19L24 12Z" stroke="$s" stroke-width="2.2" stroke-linejoin="round" fill="white"/>
  <path d="M16 22V29C16 33 24 35 24 35C24 35 32 33 32 29V22" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M35 20V28" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <circle cx="35" cy="29" r="1.5" fill="$s"/>
</svg>
''';

  static String _retirement(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M18 14V27H30V22" stroke="$s" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M18 27L14 36M28 27L32 36" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M10 37C16 40 32 40 38 37" stroke="$s" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M22 17H28M22 21H28" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  static String _actionPlan(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="13" y="11" width="22" height="29" rx="3" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M19 11V9C19 8 20 7 21 7H27C28 7 29 8 29 9V11H19Z" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M17 19L19 21L23 17" stroke="$s" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M25 19H31" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M17 26L19 28L23 24" stroke="$s" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M25 26H31" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M17 33L19 35L23 31" stroke="$s" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M25 33H31" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  static String _debtFree(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="14" r="4.5" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M24 18V28M15 20L24 23L33 20M24 28L18 38M24 28L30 38" stroke="$s" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M10 16L12 18M38 16L36 18" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  static String _portfolio(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="13" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M24 11V24H37" stroke="$s" stroke-width="2.2" stroke-linejoin="round"/>
  <path d="M24 24L15 33" stroke="$s" stroke-width="2"/>
  <circle cx="34" cy="14" r="1.5" fill="$s"/>
</svg>
''';

  static String _peaceOfMind(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 14C24 14 18 20 18 26C18 30 20 33 24 33C28 33 30 30 30 26C30 20 24 14 24 14Z" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M18 24C15 25 11 28 11 31C11 33 14 34 18 34" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M30 24C33 25 37 28 37 31C37 33 34 34 30 34" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <circle cx="24" cy="10" r="1.5" fill="$s"/>
</svg>
''';

  static String _specificGoal(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="21" cy="21" r="10" stroke="$s" stroke-width="2.4" fill="white"/>
  <path d="M28 28L38 38" stroke="$s" stroke-width="3" stroke-linecap="round"/>
  <circle cx="21" cy="21" r="4" stroke="$s" stroke-width="1.8"/>
  <path d="M21 19V23" stroke="$s" stroke-width="1.6" stroke-linecap="round"/>
</svg>
''';

  static String _male(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M18 17C17 11 22 9 24 9C26 9 31 11 30 17C28 13 24 12 20 14" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M17 18C17 25 20 29 24 29C28 29 31 25 31 18" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="21" cy="19" r="1.3" fill="$s"/>
  <circle cx="27" cy="19" r="1.3" fill="$s"/>
  <path d="M22 24C23 25.5 25 25.5 26 24" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M12 40C13 35 17 33 21 33H27C31 33 35 35 36 40" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M23 33L24 37L25 33" stroke="$s" stroke-width="2" stroke-linejoin="round"/>
</svg>
''';

  static String _female(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M17 19C15 12 21 9 24 9C27 9 33 12 31 19" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M17 19C17 26 20 30 24 30C28 30 31 26 31 19" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="21" cy="20" r="1.3" fill="$s"/>
  <circle cx="27" cy="20" r="1.3" fill="$s"/>
  <path d="M22 25C23 26.5 25 26.5 26 25" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <circle cx="15.5" cy="23" r="1.2" fill="$s"/>
  <circle cx="32.5" cy="23" r="1.2" fill="$s"/>
  <path d="M13 40C14 35 18 34 24 34C30 34 34 35 35 40" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  static String _genderFlex(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="18" cy="21" r="7" stroke="$s" stroke-width="2" fill="white"/>
  <circle cx="16" cy="20" r="1.2" fill="$s"/>
  <circle cx="20" cy="20" r="1.2" fill="$s"/>
  <path d="M17 23C17.5 24 18.5 24 19 23" stroke="$s" stroke-width="1.4" stroke-linecap="round"/>
  <circle cx="30" cy="21" r="7" stroke="$s" stroke-width="2" fill="white"/>
  <circle cx="28" cy="20" r="1.2" fill="$s"/>
  <circle cx="32" cy="20" r="1.2" fill="$s"/>
  <path d="M29 23C29.5 24 30.5 24 31 23" stroke="$s" stroke-width="1.4" stroke-linecap="round"/>
  <path d="M11 37C12 33 15 31 18 31C21 31 23 32 24 34C25 32 27 31 30 31C33 31 36 33 37 37" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  static String _supportive(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 16C22.5 13.5 19 14.5 19 17C19 20 24 23.5 24 23.5C24 23.5 29 20 29 17C29 14.5 25.5 13.5 24 16Z" stroke="$s" stroke-width="2.2" fill="$s"/>
  <path d="M12 30C14 27 18 25 21 27L24 29L27 27C30 25 34 27 36 30" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M14 34C17 37 31 37 34 34" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  static String _direct(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="13" stroke="$s" stroke-width="2.2" fill="white"/>
  <circle cx="24" cy="24" r="7" stroke="$s" stroke-width="2"/>
  <circle cx="24" cy="24" r="2" fill="$s"/>
  <path d="M35 13L24 24M35 13H29M35 13V19" stroke="$s" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  static String _balanced(String s) => _budgetFlex(s);

  static String _styleFlex(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M14 18H20C20 16 22 16 22 18H28V24C26 24 26 26 28 26V32H22C22 30 20 30 20 32H14V26C16 26 16 24 14 24V18Z" stroke="$s" stroke-width="2.2" stroke-linejoin="round" fill="white"/>
  <circle cx="34" cy="16" r="1.8" fill="$s"/>
  <circle cx="36" cy="30" r="1.3" fill="$s"/>
</svg>
''';

  static String _ageYoung(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M16 17C16 13 19 11 24 11C29 11 32 13 32 17" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M14 17H34M32 17L37 15" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M17 18C17 25 20 29 24 29C28 29 31 25 31 18" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="21" cy="20" r="1.3" fill="$s"/>
  <circle cx="27" cy="20" r="1.3" fill="$s"/>
  <path d="M22 25C23 26.5 25 26.5 26 25" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M12 40C14 36 18 34 24 34C30 34 34 36 36 40" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  static String _ageMid(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M16 19C16 14 20 10 24 10C28 10 32 14 32 19" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M17 18C17 25 20 29 24 29C28 29 31 25 31 18" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <rect x="18" y="17" width="5" height="4" rx="1" stroke="$s" stroke-width="1.6" fill="white"/>
  <rect x="25" y="17" width="5" height="4" rx="1" stroke="$s" stroke-width="1.6" fill="white"/>
  <path d="M23 19H25" stroke="$s" stroke-width="1.6"/>
  <path d="M22 24C23 25.5 25 25.5 26 24" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M12 40C14 35 18 34 24 34C30 34 34 35 36 40" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  static String _ageSenior(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M16 16C15 12 18 9 24 9C30 9 33 12 32 16" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M17 18C17 25 20 29 24 29C28 29 31 25 31 18" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="21" cy="19" r="1.3" fill="$s"/>
  <circle cx="27" cy="19" r="1.3" fill="$s"/>
  <path d="M19 23C21 24.5 27 24.5 29 23" stroke="$s" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M22 26C23 27 25 27 26 26" stroke="$s" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M12 40C14 35 18 34 24 34C30 34 34 35 36 40" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M22 35L26 37L22 39V35ZM26 35L22 37L26 39V35Z" stroke="$s" stroke-width="1.5" fill="$s"/>
</svg>
''';

  static String _ageFlex(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="16" r="5" stroke="$s" stroke-width="2" fill="white"/>
  <circle cx="15" cy="22" r="4.5" stroke="$s" stroke-width="2" fill="white"/>
  <circle cx="33" cy="22" r="4.5" stroke="$s" stroke-width="2" fill="white"/>
  <path d="M9 37C10 32 13 30 16 30C19 30 21 31 22 33M39 37C38 32 35 30 32 30C29 30 27 31 26 33" stroke="$s" stroke-width="2" stroke-linecap="round"/>
  <path d="M19 37C20 31 22 28 24 28C26 28 28 31 29 37" stroke="$s" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  static String _commListen(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M22 13C16 13 13 17 13 24C13 31 17 35 21 35C24 35 25 33 24 31C22 31 20 30 20 27C20 23 25 23 25 18C25 15 24 13 22 13Z" stroke="$s" stroke-width="2.4" stroke-linecap="round" fill="white"/>
  <path d="M28 17C31 19 32 23 31 27" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M33 13C37 17 38 24 36 31" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  static String _commProactive(String s) => '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M17 19C17 15 20 12 24 12C28 12 31 15 31 19C31 22 29 24 28 26V29H20V26C19 24 17 22 17 19Z" stroke="$s" stroke-width="2.2" fill="white"/>
  <path d="M21 32H27M22 35H26" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M24 6V9M12 12L14 14M36 12L34 14M10 21H13M35 21H38" stroke="$s" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  static String _commFlex(String s) => _both(s);
}
