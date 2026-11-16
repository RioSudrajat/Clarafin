import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../widgets/onboarding_step_header.dart';

class OnboardingAdvisoryFocusScreen extends ConsumerStatefulWidget {
  const OnboardingAdvisoryFocusScreen({super.key});

  @override
  ConsumerState<OnboardingAdvisoryFocusScreen> createState() => _OnboardingAdvisoryFocusScreenState();
}

class _OnboardingAdvisoryFocusScreenState extends ConsumerState<OnboardingAdvisoryFocusScreen> {
  final Set<String> _selectedFocuses = {};

  static const List<Map<String, dynamic>> _advisoryTiers = [
    {
      'id': 'basic',
      'title': 'Fondasi Arus Kas & Utang',
      'license': 'QWP® / AWP®',
      'desc': 'Gaji cepat habis, cicilan PayLater menumpuk, & membangun dana darurat.',
      'accent': NeoBrutalism.mint,
      'icon': Icons.savings_outlined,
    },
    {
      'id': 'medium',
      'title': 'Optimalisasi Aset & Proteksi',
      'license': 'CFP®',
      'desc': 'Mulai portofolio investasi terarah, bedah polis asuransi, & simulasi KPR.',
      'accent': Color(0xFFEFF6FF),
      'icon': Icons.trending_up_rounded,
    },
    {
      'id': 'couple',
      'title': 'Siap Menikah & Keluarga',
      'license': 'CFP® Family',
      'desc': 'Transparansi uang pranikah, pos anggaran rumah tangga, & dana anak.',
      'accent': Color(0xFFFDF2F8),
      'icon': Icons.favorite_border_rounded,
    },
    {
      'id': 'umkm',
      'title': 'Omzet & Pajak Usaha',
      'license': 'CFP® / BKP',
      'desc': 'Pisah rekening pribadi vs toko/usaha, hitung HPP, & kepatuhan pajak.',
      'accent': NeoBrutalism.yellow,
      'icon': Icons.storefront_outlined,
    },
    {
      'id': 'premium',
      'title': 'Kebebasan Finansial & Waris',
      'license': 'CFP® / CFA®',
      'desc': 'Peta jalan pensiun dini (FIRE), optimalisasi kekayaan, & suksesi waris.',
      'accent': Color(0xFFF3E8FF),
      'icon': Icons.diamond_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(userProfileProvider).advisoryFocus;
    if (current.isNotEmpty) {
      _selectedFocuses.addAll(current.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
  }

  void _toggleFocus(String id) {
    setState(() {
      if (_selectedFocuses.contains(id)) {
        _selectedFocuses.remove(id);
      } else {
        _selectedFocuses.add(id);
      }
    });
  }

  void _handleContinue() {
    final toSave = _selectedFocuses.isEmpty ? 'basic' : _selectedFocuses.join(',');
    ref.read(userProfileProvider.notifier).setAdvisoryFocus(toSave);
    context.go('/onboarding/wallet-goal');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingStepHeader(
                step: 4,
                totalSteps: 6,
                title: 'Topik konsultasi apa yang paling relevan?',
                subtitle: 'Kami cocokkan dengan konsultan berlisensi resmi (QWP®, CFP®, CFA®, BKP) sesuai kondisimu.',
                onBack: () => context.go('/onboarding/tracker-focus'),
                onSkip: () => context.go('/onboarding/wallet-goal'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _advisoryTiers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _advisoryTiers[index];
                    final isSelected = _selectedFocuses.contains(item['id']);
                    return _buildTierCard(item, isSelected);
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(Map<String, dynamic> item, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleFocus(item['id'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? item['accent'] as Color : Colors.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
          border: NeoBrutalism.border(width: isSelected ? 2.5 : 2.0),
          boxShadow: NeoBrutalism.shadow(yOffset: isSelected ? 4.0 : 2.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? NeoBrutalism.lime : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: NeoBrutalism.border(width: 1.5),
              ),
              child: Icon(
                item['icon'] as IconData,
                size: 20,
                color: NeoBrutalism.dark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: NeoBrutalism.teal,
                          borderRadius: BorderRadius.circular(6),
                          border: NeoBrutalism.border(width: 1.0),
                        ),
                        child: Text(
                          item['license'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: NeoBrutalism.lime,
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected ? NeoBrutalism.lime : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: NeoBrutalism.border(width: 2.0),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, size: 16, color: NeoBrutalism.dark)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['desc'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _handleContinue,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: NeoBrutalism.lime,
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
            border: NeoBrutalism.border(width: 2.0),
            boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lanjut ke Setup Awal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalism.dark,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: NeoBrutalism.dark),
            ],
          ),
        ),
      ),
    );
  }
}
