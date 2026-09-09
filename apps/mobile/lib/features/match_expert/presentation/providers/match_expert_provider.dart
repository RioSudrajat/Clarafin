import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/data/match_expert_consultants_data.dart';
import '../../domain/data/match_expert_questions_data.dart';
import '../../domain/models/match_expert_models.dart';

class MatchExpertState {
  final int currentStep; // 0 = Welcome, 1..12 = Questions, 13 = Result
  final MatchExpertAnswerState answers;
  final String? selectedConsultantId;
  final List<MatchedConsultant> matchedConsultants;

  const MatchExpertState({
    this.currentStep = 0,
    this.answers = const MatchExpertAnswerState(),
    this.selectedConsultantId,
    this.matchedConsultants = const [],
  });

  MatchExpertState copyWith({
    int? currentStep,
    MatchExpertAnswerState? answers,
    String? selectedConsultantId,
    List<MatchedConsultant>? matchedConsultants,
  }) {
    return MatchExpertState(
      currentStep: currentStep ?? this.currentStep,
      answers: answers ?? this.answers,
      selectedConsultantId: selectedConsultantId ?? this.selectedConsultantId,
      matchedConsultants: matchedConsultants ?? this.matchedConsultants,
    );
  }

  bool get isCurrentStepAnswered {
    if (currentStep == 0) return true;
    if (currentStep > 12) return true;
    final question = MatchExpertQuestionsData.questions[currentStep - 1];
    if (question.isOptional) return true;
    return answers.hasAnswer(question.id);
  }

  MatchedConsultant? get activeConsultant {
    if (matchedConsultants.isEmpty) return null;
    if (selectedConsultantId == null) return matchedConsultants.first;
    return matchedConsultants.firstWhere(
      (c) => c.id == selectedConsultantId,
      orElse: () => matchedConsultants.first,
    );
  }
}

class MatchExpertNotifier extends Notifier<MatchExpertState> {
  @override
  MatchExpertState build() {
    return const MatchExpertState();
  }

  void selectSingle(String questionId, String optionId) {
    final current = state.answers.getSingle(questionId);
    final newAnswers = state.answers.copyWithUpdated(
      questionId,
      current == optionId ? null : optionId,
    );
    state = state.copyWith(answers: newAnswers);
  }

  void toggleMulti(String questionId, String optionId) {
    final current = Set<String>.from(state.answers.getMulti(questionId));
    if (current.contains(optionId)) {
      current.remove(optionId);
    } else {
      current.add(optionId);
    }
    final newAnswers = state.answers.copyWithUpdated(questionId, current);
    state = state.copyWith(answers: newAnswers);
  }

  void nextStep() {
    if (state.currentStep < 12) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    } else if (state.currentStep == 12) {
      _calculateMatches();
      state = state.copyWith(currentStep: 13);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void selectConsultant(String id) {
    state = state.copyWith(selectedConsultantId: id);
  }

  void reset() {
    state = const MatchExpertState();
  }

  void _calculateMatches() {
    final pool = List<MatchedConsultant>.from(MatchExpertConsultantsData.pool);
    final target = state.answers.getSingle('target');
    final gender = state.answers.getSingle('gender');
    final mainTopic = state.answers.getSingle('main_topic');

    // Calculate score for each consultant
    final scored = pool.map((c) {
      int score = 75; // base score

      // Target match
      if (target == 'business' && c.specializations.any((s) => s.toLowerCase().contains('bisnis') || s.toLowerCase().contains('umkm'))) {
        score += 15;
      }
      if (target == 'couple' && c.specializations.any((s) => s.toLowerCase().contains('pasangan'))) {
        score += 15;
      }

      // Main topic match
      if (mainTopic == 'debt_cashflow' && c.specializations.any((s) => s.toLowerCase().contains('hutang') || s.toLowerCase().contains('cashflow'))) {
        score += 10;
      }
      if (mainTopic == 'investment' && c.specializations.any((s) => s.toLowerCase().contains('saham') || s.toLowerCase().contains('reksadana'))) {
        score += 10;
      }

      // Gender preference
      if (gender != null && gender != 'flexible') {
        if (gender == 'male' && c.gender == 'Laki-laki') score += 5;
        if (gender == 'female' && c.gender == 'Perempuan') score += 5;
      } else {
        score += 5;
      }

      final matchPct = score.clamp(82, 100);
      return MatchedConsultant(
        id: c.id,
        name: c.name,
        title: c.title,
        credentials: c.credentials,
        avatarUrl: c.avatarUrl,
        matchPercentage: matchPct,
        totalSessions: c.totalSessions,
        experienceYears: c.experienceYears,
        rating: c.rating,
        reviewCount: c.reviewCount,
        specializations: c.specializations,
        feePerSession: c.feePerSession,
        bio: c.bio,
        gender: c.gender,
        age: c.age,
        methods: c.methods,
        languages: c.languages,
        consultingStyle: c.consultingStyle,
      );
    }).toList();

    // Sort by match percentage descending
    scored.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

    // Guarantee rank 1 is 100% Match and rank 2/3 are calibrated
    final top3 = [
      MatchedConsultant(
        id: scored[0].id,
        name: scored[0].name,
        title: scored[0].title,
        credentials: scored[0].credentials,
        avatarUrl: scored[0].avatarUrl,
        matchPercentage: 100,
        totalSessions: scored[0].totalSessions,
        experienceYears: scored[0].experienceYears,
        rating: scored[0].rating,
        reviewCount: scored[0].reviewCount,
        specializations: scored[0].specializations,
        feePerSession: scored[0].feePerSession,
        bio: scored[0].bio,
        gender: scored[0].gender,
        age: scored[0].age,
        methods: scored[0].methods,
        languages: scored[0].languages,
        consultingStyle: scored[0].consultingStyle,
      ),
      MatchedConsultant(
        id: scored[1].id,
        name: scored[1].name,
        title: scored[1].title,
        credentials: scored[1].credentials,
        avatarUrl: scored[1].avatarUrl,
        matchPercentage: (scored[1].matchPercentage * 0.94).round().clamp(88, 96),
        totalSessions: scored[1].totalSessions,
        experienceYears: scored[1].experienceYears,
        rating: scored[1].rating,
        reviewCount: scored[1].reviewCount,
        specializations: scored[1].specializations,
        feePerSession: scored[1].feePerSession,
        bio: scored[1].bio,
        gender: scored[1].gender,
        age: scored[1].age,
        methods: scored[1].methods,
        languages: scored[1].languages,
        consultingStyle: scored[1].consultingStyle,
      ),
      MatchedConsultant(
        id: scored[2].id,
        name: scored[2].name,
        title: scored[2].title,
        credentials: scored[2].credentials,
        avatarUrl: scored[2].avatarUrl,
        matchPercentage: (scored[2].matchPercentage * 0.88).round().clamp(84, 90),
        totalSessions: scored[2].totalSessions,
        experienceYears: scored[2].experienceYears,
        rating: scored[2].rating,
        reviewCount: scored[2].reviewCount,
        specializations: scored[2].specializations,
        feePerSession: scored[2].feePerSession,
        bio: scored[2].bio,
        gender: scored[2].gender,
        age: scored[2].age,
        methods: scored[2].methods,
        languages: scored[2].languages,
        consultingStyle: scored[2].consultingStyle,
      ),
    ];

    state = state.copyWith(
      matchedConsultants: top3,
      selectedConsultantId: top3[0].id,
    );
  }
}

final matchExpertProvider = NotifierProvider<MatchExpertNotifier, MatchExpertState>(() {
  return MatchExpertNotifier();
});
