import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../widgets/onboarding_step_header.dart';

class OnboardingHistoryScreen extends ConsumerStatefulWidget {
  const OnboardingHistoryScreen({super.key});

  @override
  ConsumerState<OnboardingHistoryScreen> createState() => _OnboardingHistoryScreenState();
}

class _OnboardingHistoryScreenState extends ConsumerState<OnboardingHistoryScreen> {
  String _selectedSource = 'fresh_start';

  static const List<Map<String, dynamic>> _options = [
    {
      'id': 'fresh_start',
      'title': 'Belum, mulai dari sini',
      'desc': 'Selama ini belum rutin mencatat atau masih memakai buku fisik.',
      'icon': Icons.auto_awesome_rounded,
      'badge': 'PEMULA RAMAH',
      'accent': NeoBrutalism.mint,
    },
    {
      'id': 'other_app',
      'title': 'Sudah, pakai aplikasi lain',
      'desc': 'Pernah pakai Money Manager, Money Lover, Sribuu, dll.',
      'badge': 'MIGRASI DATA',
      'icon': Icons.phone_android_rounded,
      'accent': NeoBrutalism.yellow,
    },
    {
      'id': 'spreadsheet',
      'title': 'Sudah, pakai Spreadsheet / CSV',
      'desc': 'Punya rekapan Google Sheets, Excel, atau file ekspor CSV.',
      'badge': 'IMPOR CEPAT',
      'icon': Icons.table_chart_rounded,
      'accent': Color(0xFFE0E7FF),
    },
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(userProfileProvider).trackingHistorySource;
    if (current.isNotEmpty) {
      _selectedSource = current;
    }
  }

  void _handleContinue() {
    ref.read(userProfileProvider.notifier).setTrackingHistorySource(_selectedSource);
    context.go('/onboarding/tracker-focus');
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
                step: 2,
                totalSteps: 6,
                title: 'Sudah pernah catat keuangan?',
                subtitle: 'Biar Clarafin sesuaikan alur awal untukmu. Kalau sudah punya catatan, riwayatmu bisa ikut pindah.',
                onBack: () => context.go('/onboarding'),
                onSkip: () => context.go('/onboarding/tracker-focus'),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _options.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = _options[index];
                    final isSelected = _selectedSource == item['id'];
                    return _buildOptionCard(item, isSelected);
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

  Widget _buildOptionCard(Map<String, dynamic> item, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedSource = item['id'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? NeoBrutalism.lime : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: NeoBrutalism.border(width: 2.0),
              ),
              child: Icon(
                item['icon'] as IconData,
                size: 22,
                color: NeoBrutalism.dark,
              ),
            ),
            const SizedBox(width: 14),
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
                          color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: NeoBrutalism.border(width: 1.0),
                        ),
                        child: Text(
                          item['badge'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: NeoBrutalism.lime,
                            borderRadius: BorderRadius.circular(6),
                            border: NeoBrutalism.border(width: 1.5),
                          ),
                          child: const Icon(Icons.check_rounded, size: 16, color: NeoBrutalism.dark),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['desc'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
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
                'Lanjut ke Fokus Fitur',
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
