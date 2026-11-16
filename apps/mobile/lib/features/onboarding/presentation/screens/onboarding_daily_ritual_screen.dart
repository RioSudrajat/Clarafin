import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../widgets/interactive_clock_picker.dart';
import '../widgets/onboarding_step_header.dart';

class OnboardingDailyRitualScreen extends ConsumerStatefulWidget {
  const OnboardingDailyRitualScreen({super.key});

  @override
  ConsumerState<OnboardingDailyRitualScreen> createState() => _OnboardingDailyRitualScreenState();
}

class _OnboardingDailyRitualScreenState extends ConsumerState<OnboardingDailyRitualScreen> {
  String _time = '20:00';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _time = profile.dailyReminderTime.isNotEmpty ? profile.dailyReminderTime : '20:00';
  }

  void _handleSaveAndFinish() {
    // Automatically enable reminder with selected time, can be disabled later in settings
    ref.read(userProfileProvider.notifier).setDailyReminder(true, _time);
    context.go('/home');
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
                step: 6,
                totalSteps: 6,
                title: 'Satu menit, tiap malam.',
                subtitle: 'Rutinitas kecil sebelum tidur untuk mengunci pencatatan harianmu agar tidak pernah terlewat.',
                onBack: () => context.go('/onboarding/wallet-goal'),
                onSkip: () => context.go('/home'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildPushNotificationPreview(),
                      const SizedBox(height: 24),
                      InteractiveClockPicker(
                        initialTime: _time,
                        onTimeChanged: (newTime) {
                          setState(() {
                            _time = newTime;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPrimaryButton(),
              const SizedBox(height: 10),
              _buildSkipButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPushNotificationPreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: NeoBrutalism.mint,
              borderRadius: BorderRadius.circular(10),
              border: NeoBrutalism.border(width: 1.5),
            ),
            child: Image.asset(
              'assets/images/logo_clarafin_symbol.png',
              width: 22,
              height: 22,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.notifications_active_rounded,
                size: 20,
                color: NeoBrutalism.dark,
              ),
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
                    Text(
                      'CLARAFIN • $_time WIB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: NeoBrutalism.teal,
                      ),
                    ),
                    Text(
                      'baru saja',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Waktunya tutup hari!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: NeoBrutalism.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Catat pengeluaranmu dalam 1 menit sebelum istirahat.',
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
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _handleSaveAndFinish,
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
                'Atur Ritme Harianku',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalism.dark,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.check_rounded, size: 20, color: NeoBrutalism.dark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: () => context.go('/home'),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Nanti Saja',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
