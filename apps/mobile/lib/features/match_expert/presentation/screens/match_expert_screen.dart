import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/data/match_expert_questions_data.dart';
import '../providers/match_expert_provider.dart';
import '../widgets/match_expert_consultant_detail_sheet.dart';
import '../widgets/match_expert_podium_widget.dart';
import '../widgets/match_expert_question_scaffold.dart';
import '../widgets/match_expert_welcome_view.dart';

class MatchExpertScreen extends ConsumerWidget {
  const MatchExpertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchExpertProvider);
    final notifier = ref.read(matchExpertProvider.notifier);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF073B4C),
              Color(0xFF0F758A),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _buildCurrentView(context, ref, state, notifier),
        ),
      ),
    );
  }

  Widget _buildCurrentView(
    BuildContext context,
    WidgetRef ref,
    MatchExpertState state,
    MatchExpertNotifier notifier,
  ) {
    // Step 0: Welcome
    if (state.currentStep == 0) {
      return MatchExpertWelcomeView(
        onStart: () => notifier.nextStep(),
        onBack: () => context.pop(),
      );
    }

    // Step 1 to 12: Questions
    if (state.currentStep >= 1 && state.currentStep <= 12) {
      final question = MatchExpertQuestionsData.questions[state.currentStep - 1];
      return MatchExpertQuestionScaffold(
        question: question,
        answers: state.answers,
        canProceed: state.isCurrentStepAnswered,
        onSelectSingle: (optionId) => notifier.selectSingle(question.id, optionId),
        onToggleMulti: (optionId) => notifier.toggleMulti(question.id, optionId),
        onNext: () => notifier.nextStep(),
        onBack: () => notifier.prevStep(),
      );
    }

    // Step 13: Result
    return _buildResultView(context, state, notifier);
  }

  Widget _buildResultView(
    BuildContext context,
    MatchExpertState state,
    MatchExpertNotifier notifier,
  ) {
    final activeConsultant = state.activeConsultant;

    return Column(
      children: [
        // Header bar with back and reset buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => notifier.prevStep(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chevron_left, color: Colors.white, size: 24),
                    SizedBox(width: 4),
                    Text(
                      'Kembali',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => notifier.reset(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Ulangi Tes',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable content (Podium + details)
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Title & subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Rekomendasi Ahli Untukmu',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Berdasarkan preferensi dan profil kebutuhan finansial yang telah kamu lengkapi.',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFE2E8F0),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Top 3 Podium
                MatchExpertPodiumWidget(
                  consultants: state.matchedConsultants,
                  selectedId: state.selectedConsultantId,
                  onSelectConsultant: (id) => notifier.selectConsultant(id),
                ),

                const SizedBox(height: 16),

                // Consultant Detail Sheet
                if (activeConsultant != null)
                  MatchExpertConsultantDetailSheet(
                    consultant: activeConsultant,
                    onBookSession: () {
                      context.push('/booking/${activeConsultant.id}/service');
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
