import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotionDoodleWidget extends StatelessWidget {
  final String svgString;
  final double size;

  const NotionDoodleWidget({
    super.key,
    required this.svgString,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class NotionDoodleIcons {
  // ── 1. Individu ──
  static const String individu = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M14 20C13 13 17 9 24 9C31 9 35 13 34 20C33 16 31 12 24 12C17 12 15 16 14 20Z" fill="black" stroke="black" stroke-width="1.5" stroke-linejoin="round"/>
  <path d="M14 19C15 13 21 10 27 10C33 10 35 13 34 20C31 15 26 14 21 15C17 17 15 19 14 19Z" fill="black"/>
  <path d="M16 20C16 27 19 32 24 32C29 32 32 27 32 20" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M16 21C14.5 21 14 22.5 14.5 24C15 25.5 16 25.5 16 25" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M32 21C33.5 21 34 22.5 33.5 24C33 25.5 32 25.5 32 25" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <circle cx="20" cy="21" r="1.5" fill="black"/>
  <circle cx="28" cy="21" r="1.5" fill="black"/>
  <path d="M18.5 18.5C19.5 18 21 18 21.5 18.5" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M26.5 18.5C27 18 28.5 18 29.5 18.5" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M24 21.5V24.5H25.5" stroke="black" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M21.5 27C22.5 28.5 25.5 28.5 26.5 27" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M21 32V36M27 32V36" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M12 41C13 37 17 36 21 36H27C31 36 35 37 36 41" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M21 36L24 40L27 36" stroke="black" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  // ── 2. Pasangan ──
  static const String pasangan = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 7C22.5 4.5 19 5.5 19 8C19 11 24 13.5 24 13.5C24 13.5 29 11 29 8C29 5.5 25.5 4.5 24 7Z" fill="#DC2626" stroke="black" stroke-width="1.5"/>
  <path d="M8 25C8 18 11 14 16 14C20 14 22 16 22 21C21 17 18 15 14 16C10 17 9 22 9 26C9 29 11 30 12 31" fill="black"/>
  <path d="M12 21C12 26 14 29 18 29C21 29 23 26 23 21" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <circle cx="15.5" cy="21" r="1.3" fill="black"/>
  <circle cx="20.5" cy="21" r="1.3" fill="black"/>
  <path d="M17 25C18 26 19.5 26 20.5 25" stroke="black" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M7 40C8 35 12 33 16 33C18 33 20 34 21 36" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M26 18C27 14 31 13 36 14C38 14.5 40 17 39 21C37 16 33 15 29 16C27 16.5 26 17.5 26 18Z" fill="black"/>
  <path d="M27 21C27 26 29 29 33 29C37 29 39 26 39 21" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <circle cx="30.5" cy="21" r="1.3" fill="black"/>
  <circle cx="35.5" cy="21" r="1.3" fill="black"/>
  <path d="M32 25C33 26 34.5 26 35.5 25" stroke="black" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M27 36C28 34 30 33 33 33C37 33 40 35 41 40" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  // ── 3. Keluarga ──
  static const String keluarga = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M10 18C11 13 15 12 19 13C17 14 14 16 13 19" fill="black" stroke="black" stroke-width="1.5"/>
  <path d="M11 18C11 23 13 25 16 25C19 25 20 23 20 18" stroke="black" stroke-width="1.6" stroke-linecap="round"/>
  <circle cx="14" cy="18" r="1.2" fill="black"/>
  <circle cx="18" cy="18" r="1.2" fill="black"/>
  <path d="M15 22C16 23 17 23 18 22" stroke="black" stroke-width="1.3" stroke-linecap="round"/>
  <path d="M6 38C7 32 10 30 14 30" stroke="black" stroke-width="1.6" stroke-linecap="round"/>
  <path d="M28 17C29 12 34 11 38 14C35 15 32 16 30 19" fill="black" stroke="black" stroke-width="1.5"/>
  <path d="M28 18C28 23 30 25 33 25C36 25 38 23 38 18" stroke="black" stroke-width="1.6" stroke-linecap="round"/>
  <circle cx="31" cy="18" r="1.2" fill="black"/>
  <circle cx="35" cy="18" r="1.2" fill="black"/>
  <path d="M32 22C33 23 34 23 35 22" stroke="black" stroke-width="1.3" stroke-linecap="round"/>
  <path d="M34 30C38 30 41 32 42 38" stroke="black" stroke-width="1.6" stroke-linecap="round"/>
  <path d="M20 27C21 24 24 23 27 24C26 25 24 26 23 27" fill="black" stroke="black" stroke-width="1.2"/>
  <path d="M21 27C21 31 22.5 33 24.5 33C26.5 33 28 31 28 27" stroke="black" stroke-width="1.6" stroke-linecap="round"/>
  <circle cx="23" cy="28" r="1" fill="black"/>
  <circle cx="26" cy="28" r="1" fill="black"/>
  <path d="M23.5 30.5C24.2 31.5 25.2 31.5 25.8 30.5" stroke="black" stroke-width="1.3" stroke-linecap="round"/>
  <path d="M17 41C18 36 21 35 24.5 35C28 35 30 36 31 41" stroke="black" stroke-width="1.6" stroke-linecap="round"/>
</svg>
''';

  // ── 4. AI Clarafin ──
  static const String aiClarafin = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 13V8" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <circle cx="24" cy="7" r="2.5" fill="black" stroke="black" stroke-width="1"/>
  <path d="M38 12L39 9L40 12L43 13L40 14L39 17L38 14L35 13L38 12Z" fill="black"/>
  <path d="M9 22L9.5 20.5L10 22L11.5 22.5L10 23L9.5 24.5L9 23L7.5 22.5L9 22Z" fill="black"/>
  <rect x="12" y="13" width="24" height="22" rx="7" stroke="black" stroke-width="2" fill="white"/>
  <rect x="15" y="16" width="18" height="13" rx="4" fill="#E2F874" stroke="black" stroke-width="1.5"/>
  <path d="M18 22C19 20 21 20 22 22" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M26 22C27 20 29 20 30 22" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M22 25.5C23 27 25 27 26 25.5" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <rect x="22" y="35" width="4" height="3" fill="black"/>
  <path d="M16 41C17 39 21 38 24 38C27 38 31 39 32 41" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <rect x="10" y="21" width="2" height="6" rx="1" fill="black"/>
  <rect x="36" y="21" width="2" height="6" rx="1" fill="black"/>
</svg>
''';

  // ── 5. UMKM ──
  static const String umkm = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M10 19L13 11H35L38 19H10Z" stroke="black" stroke-width="2" stroke-linejoin="round" fill="white"/>
  <path d="M17 11L15 19H20L21 11H17Z" fill="black"/>
  <path d="M27 11L28 19H33L31 11H27Z" fill="black"/>
  <path d="M10 19C10 21 12 22 14 21C16 22 18 22 19 21C20 22 22 22 24 21C26 22 28 22 29 21C30 22 32 22 34 21C36 22 38 21 38 19" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M12 21V38H36V21" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="21" y="26" width="8" height="12" rx="1" stroke="black" stroke-width="1.8" fill="white"/>
  <circle cx="27" cy="32" r="1" fill="black"/>
  <rect x="14" y="25" width="5" height="6" rx="1" stroke="black" stroke-width="1.5" fill="white"/>
  <path d="M8 38H40" stroke="black" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  // ── 6. Score ──
  static const String score = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M11 32C9 28 9 21 13 16C17 11 24 9 30 11C36 13 40 18 39 25C39 28 37 31 35 33" stroke="black" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M16 29C15 26 15 22 18 19C21 16 26 15 30 16C34 18 35 22 34 27" stroke="black" stroke-width="1.2" stroke-dasharray="2 3"/>
  <circle cx="24" cy="30" r="3.5" fill="black"/>
  <path d="M24 30L32 17" stroke="black" stroke-width="2.5" stroke-linecap="round"/>
  <path d="M37 11L38 8L39 11L42 12L39 13L38 16L37 13L34 12L37 11Z" fill="black"/>
  <path d="M10 37H38" stroke="black" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  // ── 7. Kupon ──
  static const String kupon = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <g transform="rotate(-6 24 24)">
    <path d="M9 16C9 14.5 10.5 13 12 13H36C37.5 13 39 14.5 39 16V21C37 21 35.5 22.5 35.5 24C35.5 25.5 37 27 39 27V32C39 33.5 37.5 35 36 35H12C10.5 35 9 33.5 9 32V27C11 27 12.5 25.5 12.5 24C12.5 22.5 11 21 9 21V16Z" stroke="black" stroke-width="2" fill="white" stroke-linejoin="round"/>
    <path d="M28 14V34" stroke="black" stroke-width="1.8" stroke-dasharray="2.5 2.5" stroke-linecap="round"/>
    <circle cx="17" cy="20" r="1.8" fill="black"/>
    <path d="M23 19L17 29" stroke="black" stroke-width="2" stroke-linecap="round"/>
    <circle cx="23" cy="28" r="1.8" fill="black"/>
    <path d="M33 21L33.5 19L34 21L36 21.5L34 22L33.5 24L33 22L31 21.5L33 21Z" fill="black"/>
  </g>
</svg>
''';

  // ── 8. Lihat Semua ──
  static const String lihatSemua = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="11" y="11" width="10" height="10" rx="3" stroke="black" stroke-width="2" fill="white"/>
  <rect x="27" y="11" width="10" height="10" rx="3" stroke="black" stroke-width="2" fill="black"/>
  <rect x="11" y="27" width="10" height="10" rx="3" stroke="black" stroke-width="2" fill="black"/>
  <rect x="27" y="27" width="10" height="10" rx="3" stroke="black" stroke-width="2" fill="white"/>
  <circle cx="16" cy="16" r="1.5" fill="black"/>
  <circle cx="32" cy="32" r="1.5" fill="black"/>
</svg>
''';

  // ── 9. Corporate ──
  static const String corporate = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M14 40V12C14 10.5 15.5 9 17 9H31C32.5 9 34 10.5 34 12V40" stroke="black" stroke-width="2" stroke-linejoin="round" fill="white"/>
  <path d="M19 15H21M27 15H29M19 21H21M27 21H29M19 27H21M27 27H29M19 33H21M27 33H29" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <rect x="22" y="34" width="4" height="6" fill="black"/>
  <path d="M8 40H40" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M34 24H39V40" stroke="black" stroke-width="1.8"/>
  <path d="M9 28H14V40" stroke="black" stroke-width="1.8"/>
</svg>
''';

  // ── 10. Free Counseling ──
  static const String freeCounseling = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M14 11C14 9.5 15.5 8 17 8H25C26.5 8 28 9.5 28 11V37C28 38.5 26.5 40 25 40H17C15.5 40 14 38.5 14 37V11Z" stroke="black" stroke-width="2" fill="white"/>
  <circle cx="21" cy="36" r="1.5" fill="black"/>
  <line x1="19" y1="11" x2="23" y2="11" stroke="black" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M25 15H39C40.5 15 41.5 16 41.5 17.5V25C41.5 26.5 40.5 27.5 39 27.5H32L28 31V27.5H25C23.5 27.5 22.5 26.5 22.5 25V17.5C22.5 16 23.5 15 25 15Z" fill="#F4FF81" stroke="black" stroke-width="1.8" stroke-linejoin="round"/>
  <path d="M26 19H29.5M26 21.5H28.5M26 19V24M31 19V24M31 19H33.5C34.3 19 34.5 19.8 34.5 20.5C34.5 21.2 34 21.8 33.2 21.8H31M33 21.8L35 24" stroke="black" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  // ── 11. Audit Portofolio ──
  static const String auditPortofolio = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="27" width="5" height="12" stroke="black" stroke-width="1.8" fill="black"/>
  <rect x="18" y="21" width="5" height="18" stroke="black" stroke-width="1.8" fill="white"/>
  <rect x="26" y="15" width="5" height="24" stroke="black" stroke-width="1.8" fill="black"/>
  <path d="M8 39H36" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M12 22L20 16L28 11L35 15" stroke="black" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="33" cy="22" r="6" stroke="black" stroke-width="2" fill="white"/>
  <path d="M37.5 26.5L42 31" stroke="black" stroke-width="2.5" stroke-linecap="round"/>
  <path d="M31 20C32 19 33.5 19 34.5 20" stroke="black" stroke-width="1.2" stroke-linecap="round"/>
</svg>
''';

  // ── 12. Tes Finansial ──
  static const String tesFinansial = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="12" y="11" width="24" height="29" rx="3" stroke="black" stroke-width="2" fill="white"/>
  <path d="M19 11V9C19 8 20 7 21 7H27C28 7 29 8 29 9V11H19Z" stroke="black" stroke-width="1.8" fill="white"/>
  <circle cx="18" cy="18" r="1.5" fill="black"/>
  <path d="M22 18H31" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <circle cx="18" cy="24" r="1.5" fill="black"/>
  <path d="M22 24H31" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M16 32L19 32L21 28L23 35L25 30L27 33L32 33" stroke="black" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  // ── 13. Tes Kepribadian ──
  static const String tesKepribadian = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M16 39V35C16 33 18 31 20 30L20 27C17 26 15 23 15 19C15 13.5 19 10 24 10C29 10 33 13.5 33 19C33 23 31 26 28 27V30C30 31 32 33 32 35V39" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="white"/>
  <path d="M22 19C22 17.5 22.8 16.5 24 16.5C25.2 16.5 26 17.5 26 19C26 20 25.5 20.5 25 21V23H23V21C22.5 20.5 22 20 22 19Z" stroke="black" stroke-width="1.5" fill="#F4FF81"/>
  <path d="M24 13V14M20 15L21 16M28 15L27 16" stroke="black" stroke-width="1.5" stroke-linecap="round"/>
</svg>
''';

  // ── 14. Kalkulator ──
  static const String kalkulator = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="13" y="9" width="22" height="30" rx="4" stroke="black" stroke-width="2" fill="white"/>
  <rect x="17" y="13" width="14" height="6" rx="1.5" fill="#E2F874" stroke="black" stroke-width="1.5"/>
  <circle cx="18" cy="24" r="1.5" fill="black"/>
  <circle cx="24" cy="24" r="1.5" fill="black"/>
  <circle cx="30" cy="24" r="1.5" fill="black"/>
  <circle cx="18" cy="29" r="1.5" fill="black"/>
  <circle cx="24" cy="29" r="1.5" fill="black"/>
  <circle cx="30" cy="29" r="1.5" fill="black"/>
  <rect x="17" y="33" width="7" height="3" rx="1" fill="black"/>
  <circle cx="30" cy="34.5" r="1.5" fill="black"/>
</svg>
''';

  // ── 15. Bebas Hutang ──
  static const String bebasHutang = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="14" width="28" height="18" rx="3" stroke="black" stroke-width="1.8" fill="white"/>
  <path d="M10 19H38" stroke="black" stroke-width="1.5"/>
  <circle cx="17" cy="33" r="3" stroke="black" stroke-width="1.8"/>
  <circle cx="26" cy="35" r="3" stroke="black" stroke-width="1.8"/>
  <path d="M19 31L33 13" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M24 33L16 23" stroke="black" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  // ── 16. Bills ──
  static const String bills = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M14 9H34V37L31 35L28 37L24 35L20 37L17 35L14 37V9Z" stroke="black" stroke-width="2" fill="white" stroke-linejoin="round"/>
  <path d="M18 15H30M18 19H27M18 23H30M18 27H24" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M18 31H19M21 31H23M25 31H26M28 31H30" stroke="black" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  // ── 17. Goals ──
  static const String goals = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M14 26C11 26 9 24 9 22C9 19 12 17 15 17C17 12 25 10 32 14C35 13 37 14 36 17C38 19 39 21 39 24C39 29 33 33 26 33C24 33 21 32 19 31L16 33L15 29C14.5 28 14 27 14 26Z" stroke="black" stroke-width="2" fill="white" stroke-linejoin="round"/>
  <path d="M18 32V36M28 33V36" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <circle cx="33" cy="20" r="1.3" fill="black"/>
  <ellipse cx="38" cy="24" rx="1.5" ry="2.5" stroke="black" stroke-width="1.5" fill="white"/>
  <path d="M22 13H28" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <circle cx="25" cy="8" r="3" stroke="black" stroke-width="1.8" fill="#F4FF81"/>
</svg>
''';

  // ── 18. Kelas Online ──
  static const String kelasOnline = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="13" y="11" width="22" height="17" rx="2" stroke="black" stroke-width="2" fill="white"/>
  <path d="M22 16L27 19.5L22 23V16Z" fill="black" stroke="black" stroke-width="1.5" stroke-linejoin="round"/>
  <path d="M9 28H39L37 32H11L9 28Z" stroke="black" stroke-width="2" fill="white" stroke-linejoin="round"/>
  <path d="M21 30H27" stroke="black" stroke-width="1.5" stroke-linecap="round"/>
</svg>
''';

  // ── 19. Webinar CFP ──
  static const String webinarCfp = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 11L9 18L24 25L39 18L24 11Z" stroke="black" stroke-width="2" fill="black" stroke-linejoin="round"/>
  <path d="M16 22V29C16 33 24 35 24 35C24 35 32 33 32 29V22" stroke="black" stroke-width="2" fill="white"/>
  <path d="M36 19.5V28C36 29 37 30 38 30C39 30 40 29 40 28V27" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <circle cx="24" cy="38" r="2" fill="black"/>
</svg>
''';

  // ── 20. E-Book ──
  static const String ebook = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 14C20 12 14 12 9 14V34C14 32 20 32 24 34C28 32 34 32 39 34V14C34 12 28 12 24 14Z" stroke="black" stroke-width="2" fill="white" stroke-linejoin="round"/>
  <path d="M24 14V34" stroke="black" stroke-width="2"/>
  <path d="M13 18H20M13 23H20M13 28H18" stroke="black" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M28 18H35M28 23H35M28 28H33" stroke="black" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M22 10V18L24 16L26 18V10H22Z" fill="black"/>
</svg>
''';

  // ── 21. Gift Card ──
  static const String giftCard = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="12" y="20" width="24" height="18" rx="2" stroke="black" stroke-width="2" fill="white"/>
  <rect x="10" y="16" width="28" height="6" rx="2" stroke="black" stroke-width="2" fill="white"/>
  <path d="M24 16V38" stroke="black" stroke-width="2.5"/>
  <path d="M10 19H38" stroke="black" stroke-width="1"/>
  <path d="M24 16C21 11 16 11 18 14C19 16 22 16 24 16Z" fill="black" stroke="black" stroke-width="1.5"/>
  <path d="M24 16C27 11 32 11 30 14C29 16 26 16 24 16Z" fill="black" stroke="black" stroke-width="1.5"/>
</svg>
''';

  // ── 22. Referral ──
  static const String referral = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M8 22L15 16L23 22L17 28L8 22Z" stroke="black" stroke-width="1.8" fill="white" stroke-linejoin="round"/>
  <path d="M40 22L33 16L25 22L31 28L40 22Z" stroke="black" stroke-width="1.8" fill="white" stroke-linejoin="round"/>
  <path d="M20 20L24 23L27 20" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M21 24L24 26L26 24" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <path d="M24 8L25 11L28 12L25 13L24 16L23 13L20 12L23 11L24 8Z" fill="black"/>
</svg>
''';

  // ── 23. Riwayat (History) ──
  static const String riwayat = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="14" stroke="black" stroke-width="2" fill="white"/>
  <path d="M24 16V24L29 27" stroke="black" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M10 20L8 24L12 24" stroke="black" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  // ── 24. Voice AI ──
  static const String voiceAi = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="18" y="10" width="12" height="19" rx="6" stroke="black" stroke-width="2.2" fill="white"/>
  <line x1="21" y1="15" x2="27" y2="15" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <line x1="21" y1="19" x2="27" y2="19" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <line x1="21" y1="23" x2="27" y2="23" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M12 21C12 28.5 17 32.5 24 32.5C31 32.5 36 28.5 36 21" stroke="black" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M24 32.5V39" stroke="black" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M16 39H32" stroke="black" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M9 18C7.5 19.5 7.5 22.5 9 24" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M39 18C40.5 19.5 40.5 22.5 39 24" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <circle cx="36" cy="11" r="2.5" fill="#CCFF00" stroke="black" stroke-width="1.2"/>
</svg>
''';

  // ── 25. OCR Scan ──
  static const String ocrScan = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M9 16V10H15" stroke="black" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M33 10H39V16" stroke="black" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M9 32V38H15" stroke="black" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M33 38H39V32" stroke="black" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M16 13H32V35L29 33.5L26 35L23 33.5L20 35L16 33V13Z" stroke="black" stroke-width="2" fill="white" stroke-linejoin="round"/>
  <line x1="20" y1="18" x2="28" y2="18" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <line x1="20" y1="22" x2="26" y2="22" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <line x1="20" y1="26" x2="28" y2="26" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <line x1="12" y1="24" x2="36" y2="24" stroke="#CCFF00" stroke-width="2.5" stroke-linecap="round"/>
  <line x1="12" y1="24" x2="36" y2="24" stroke="black" stroke-width="1.5" stroke-dasharray="2 3" stroke-linecap="round"/>
</svg>
''';

  // ── 26. Manual Add ──
  static const String manualAdd = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="9" width="22" height="30" rx="3" stroke="black" stroke-width="2.2" fill="white"/>
  <line x1="15" y1="16" x2="25" y2="16" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <line x1="15" y1="21" x2="23" y2="21" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <line x1="15" y1="26" x2="26" y2="26" stroke="black" stroke-width="1.8" stroke-linecap="round"/>
  <circle cx="16" cy="31" r="1.5" fill="#CCFF00" stroke="black" stroke-width="1"/>
  <g transform="rotate(32 30 26)">
    <rect x="25" y="12" width="7" height="20" rx="1.5" stroke="black" stroke-width="1.8" fill="white"/>
    <path d="M25 32L28.5 37L32 32H25Z" stroke="black" stroke-width="1.8" fill="black" stroke-linejoin="round"/>
    <line x1="28.5" y1="12" x2="28.5" y2="32" stroke="black" stroke-width="1.2"/>
    <rect x="25" y="12" width="7" height="4" fill="#CCFF00" stroke="black" stroke-width="1.5"/>
  </g>
</svg>
''';

  // Alias for quick action
  static const String aiChat = aiClarafin;

  static String getSvg(String key) {
    switch (key) {
      case 'individu':
        return individu;
      case 'pasangan':
        return pasangan;
      case 'keluarga':
        return keluarga;
      case 'ai_clarafin':
      case 'ai_chat':
        return aiClarafin;
      case 'voice_ai':
        return voiceAi;
      case 'ocr_scan':
        return ocrScan;
      case 'manual_add':
        return manualAdd;
      case 'umkm':
        return umkm;
      case 'score':
        return score;
      case 'kupon':
        return kupon;
      case 'lihat_semua':
        return lihatSemua;
      case 'corporate':
        return corporate;
      case 'free_counseling':
        return freeCounseling;
      case 'audit_portofolio':
        return auditPortofolio;
      case 'tes_finansial':
        return tesFinansial;
      case 'tes_kepribadian':
        return tesKepribadian;
      case 'kalkulator':
        return kalkulator;
      case 'bebas_hutang':
        return bebasHutang;
      case 'bills':
        return bills;
      case 'goals':
        return goals;
      case 'kelas_online':
        return kelasOnline;
      case 'webinar_cfp':
        return webinarCfp;
      case 'ebook':
        return ebook;
      case 'gift_card':
        return giftCard;
      case 'referral':
        return referral;
      case 'riwayat':
        return riwayat;
      default:
        return lihatSemua;
    }
  }
}
