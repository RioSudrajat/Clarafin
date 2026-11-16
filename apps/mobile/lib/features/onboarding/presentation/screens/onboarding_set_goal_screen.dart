import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../budget/presentation/providers/finance_providers.dart';
import '../widgets/onboarding_goal_card.dart';
import '../widgets/onboarding_step_header.dart';

class OnboardingSetGoalScreen extends ConsumerStatefulWidget {
  const OnboardingSetGoalScreen({super.key});

  @override
  ConsumerState<OnboardingSetGoalScreen> createState() => _OnboardingSetGoalScreenState();
}

class _OnboardingSetGoalScreenState extends ConsumerState<OnboardingSetGoalScreen> {
  String _selectedGoalId = 'emergency_fund';

  static const List<Map<String, dynamic>> _goals = [
    {
      'id': 'emergency_fund',
      'title': 'Dana Darurat 6 Bulan',
      'desc': 'Pondasi utama rasa aman finansial keluarga',
      'target': 'Rp 30.000.000',
      'badge': 'REKOMENDASI',
      'icon': Icons.shield_outlined,
    },
    {
      'id': 'vacation',
      'title': 'Liburan Akhir Tahun',
      'desc': 'Travelling tanpa beban pikiran utang',
      'target': 'Rp 15.000.000',
      'badge': 'POPULER',
      'icon': Icons.flight_takeoff_outlined,
    },
    {
      'id': 'gadget',
      'title': 'Upgrade Device Kerja',
      'desc': 'Investasi alat tempur penunjang produktivitas',
      'target': 'Rp 20.000.000',
      'icon': Icons.devices_outlined,
    },
    {
      'id': 'custom',
      'title': 'Target Tabungan Bebas',
      'desc': 'Tentukan nama impian dan nominalmu sendiri',
      'target': 'Rp 10.000.000',
      'icon': Icons.edit_note_outlined,
    },
  ];

  void _handleFinish() {
    final selected = _goals.firstWhere(
      (g) => g['id'] == _selectedGoalId,
      orElse: () => _goals.first,
    );

    final targetText = (selected['target'] as String).replaceAll(RegExp(r'[^0-9]'), '');
    final targetAmount = double.tryParse(targetText) ?? 10000000.0;

    final newGoal = GoalModel(
      id: 'g_init_${DateTime.now().millisecondsSinceEpoch}',
      name: selected['title'] as String,
      targetAmount: targetAmount,
      savedAmount: 0.0,
      targetDate: DateTime.now().add(const Duration(days: 180)),
      icon: selected['icon'] as IconData,
      tagColor: NeoBrutalism.mint,
      tagTextColor: Colors.black,
      priority: selected['badge'] == 'REKOMENDASI' ? 'Urgent' : 'Needs',
      sourceAsset: 'Dompet Utama',
    );

    ref.read(goalsProvider.notifier).addGoal(newGoal);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingStepHeader(
                step: 2,
                totalSteps: 2,
                title: 'Tentukan Goal Pertamamu',
                subtitle: 'Pilih impian finansial yang ingin kamu capai lebih awal bersama Clarafin.',
                onBack: () => context.pop(),
                onSkip: () => context.go('/home'),
              ),
              const SizedBox(height: 20),
              Text(
                'PILIH REKOMENDASI IMPIAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: NeoBrutalism.dark,
                ),
              ),
              const SizedBox(height: 10),
              ..._goals.map((goal) {
                final isSelected = _selectedGoalId == goal['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OnboardingGoalCard(
                    title: goal['title'] as String,
                    description: goal['desc'] as String,
                    targetNominal: goal['target'] as String,
                    badge: goal['badge'] as String?,
                    icon: goal['icon'] as IconData,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedGoalId = goal['id'] as String),
                  ),
                );
              }),
              const SizedBox(height: 18),
              _buildSubmitButton(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: NeoBrutalism.lime,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
          border: NeoBrutalism.border(width: 2.0),
          boxShadow: NeoBrutalism.shadow(yOffset: 3.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
            onTap: _handleFinish,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selesai & Masuk ke Beranda',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.dark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.rocket_launch_outlined, size: 18, color: NeoBrutalism.dark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
