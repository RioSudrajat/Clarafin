import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../widgets/onboarding_step_header.dart';

class OnboardingTrackerFocusScreen extends ConsumerStatefulWidget {
  const OnboardingTrackerFocusScreen({super.key});

  @override
  ConsumerState<OnboardingTrackerFocusScreen> createState() => _OnboardingTrackerFocusScreenState();
}

class _OnboardingTrackerFocusScreenState extends ConsumerState<OnboardingTrackerFocusScreen> {
  final Set<String> _selected = {};

  static const List<Map<String, dynamic>> _focusItems = [
    {
      'id': 'cashflow',
      'label': 'Tahu uangku lari ke mana',
      'sub': 'Arus kas & riwayat transaksi',
      'icon': Icons.insights_rounded,
    },
    {
      'id': 'budget',
      'label': 'Biar nggak boncos',
      'sub': 'Batas pengeluaran bulanan',
      'icon': Icons.pie_chart_rounded,
    },
    {
      'id': 'bills',
      'label': 'Beresin tagihan & langganan',
      'sub': 'Pengingat jatuh tempo',
      'icon': Icons.receipt_long_rounded,
    },
    {
      'id': 'goals',
      'label': 'Nabung buat sesuatu',
      'sub': 'Target impian & dana darurat',
      'icon': Icons.flag_rounded,
    },
    {
      'id': 'networth',
      'label': 'Pantau semua kekayaanku',
      'sub': 'Aset multi-dompet & investasi',
      'icon': Icons.account_balance_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(userProfileProvider).trackerFocuses;
    if (current.isNotEmpty) {
      _selected.clear();
      _selected.addAll(current);
    }
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _handleContinue() {
    final toSave = _selected.isEmpty ? ['cashflow'] : _selected.toList();
    ref.read(userProfileProvider.notifier).setTrackerFocuses(toSave);
    context.go('/onboarding/advisory-focus');
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
                step: 3,
                totalSteps: 6,
                title: 'Mau Clarafin bantu apa?',
                subtitle: 'Pilih yang paling kamu butuhkan. Dasbor mini di atas akan menyala otomatis!',
                onBack: () => context.go('/onboarding/history'),
                onSkip: () => context.go('/onboarding/advisory-focus'),
              ),
              const SizedBox(height: 16),
              _buildLiveDashboardPreview(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _focusItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _focusItems[index];
                    final isChecked = _selected.contains(item['id']);
                    return _buildFocusPill(item, isChecked);
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

  Widget _buildLiveDashboardPreview() {
    final hasCashflow = _selected.contains('cashflow');
    final hasBudget = _selected.contains('budget');
    final hasBills = _selected.contains('bills');
    final hasGoals = _selected.contains('goals');
    final hasNetworth = _selected.contains('networth');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.dashboard_customize_rounded, size: 16, color: NeoBrutalism.teal),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE PREVIEW BERANDA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: NeoBrutalism.mint,
                  borderRadius: BorderRadius.circular(6),
                  border: NeoBrutalism.border(width: 1.0),
                ),
                child: Text(
                  '${_selected.length}/5 AKTIF',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Cashflow Bar
              Expanded(
                flex: 3,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasCashflow ? NeoBrutalism.mint : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: NeoBrutalism.border(width: hasCashflow ? 1.5 : 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arus Kas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: hasCashflow ? NeoBrutalism.dark : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '+Rp 2.450.000',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: hasCashflow ? NeoBrutalism.teal : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Budget Meter
              Expanded(
                flex: 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasBudget ? NeoBrutalism.lime : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: NeoBrutalism.border(width: hasBudget ? 1.5 : 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: hasBudget ? NeoBrutalism.dark : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '62% Sisa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: hasBudget ? NeoBrutalism.dark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Bills Indicator
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasBills ? const Color(0xFFFEF08A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: NeoBrutalism.border(width: hasBills ? 1.5 : 1.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 12,
                          color: hasBills ? NeoBrutalism.dark : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '2 Tagihan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: hasBills ? NeoBrutalism.dark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Goals Meter
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasGoals ? NeoBrutalism.mint : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: NeoBrutalism.border(width: hasGoals ? 1.5 : 1.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flag_rounded,
                          size: 12,
                          color: hasGoals ? NeoBrutalism.dark : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Goal 65%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: hasGoals ? NeoBrutalism.dark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Networth Donut
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasNetworth ? const Color(0xFFBFDBFE) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: NeoBrutalism.border(width: hasNetworth ? 1.5 : 1.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wallet_rounded,
                          size: 12,
                          color: hasNetworth ? NeoBrutalism.dark : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '3 Akun',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: hasNetworth ? NeoBrutalism.dark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusPill(Map<String, dynamic> item, bool isChecked) {
    return GestureDetector(
      onTap: () => _toggleItem(item['id'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
          border: NeoBrutalism.border(width: isChecked ? 2.5 : 2.0),
          boxShadow: NeoBrutalism.shadow(yOffset: isChecked ? 3.0 : 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isChecked ? NeoBrutalism.lime : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: NeoBrutalism.border(width: 1.5),
              ),
              child: Icon(
                item['icon'] as IconData,
                size: 18,
                color: NeoBrutalism.dark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                  Text(
                    item['sub'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? NeoBrutalism.lime : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: NeoBrutalism.border(width: 2.0),
              ),
              child: isChecked
                  ? const Icon(Icons.check_rounded, size: 16, color: NeoBrutalism.dark)
                  : null,
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
                'Lanjut ke Kebutuhan Konsultasi',
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
