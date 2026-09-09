import 'package:flutter/material.dart';

enum SelectionType { single, multi }

class MatchExpertOption {
  final String id;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? flagCode; // e.g. 'ID', 'GB', 'CN', 'SA'
  final String? emoji;
  final String? svgKey;

  const MatchExpertOption({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.flagCode,
    this.emoji,
    this.svgKey,
  });
}

class MatchExpertQuestion {
  final String id;
  final int stepIndex; // 1 to 12
  final String title;
  final String subtitle;
  final SelectionType selectionType;
  final List<MatchExpertOption> options;
  final bool isGrid; // true: 2 columns grid, false: vertical list
  final bool isOptional;

  const MatchExpertQuestion({
    required this.id,
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.selectionType,
    required this.options,
    this.isGrid = true,
    this.isOptional = false,
  });
}

class MatchedConsultant {
  final String id;
  final String name;
  final String title;
  final String credentials;
  final String avatarUrl;
  final int matchPercentage;
  final int totalSessions;
  final String experienceYears;
  final double rating;
  final int reviewCount;
  final List<String> specializations;
  final int feePerSession;
  final String bio;
  final String gender; // 'Laki-laki' or 'Perempuan'
  final int age;
  final List<String> methods; // 'Online', 'Tatap Muka'
  final List<String> languages; // 'Indonesia', 'Inggris'
  final String consultingStyle; // 'Hangat & Suportif', 'To the point & solutif'

  const MatchedConsultant({
    required this.id,
    required this.name,
    required this.title,
    required this.credentials,
    required this.avatarUrl,
    required this.matchPercentage,
    required this.totalSessions,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    required this.specializations,
    required this.feePerSession,
    required this.bio,
    required this.gender,
    required this.age,
    required this.methods,
    required this.languages,
    required this.consultingStyle,
  });
}

class MatchExpertAnswerState {
  final Map<String, dynamic> answers; // questionId -> String (single) or Set<String> (multi)

  const MatchExpertAnswerState({
    this.answers = const {},
  });

  bool hasAnswer(String questionId) {
    final val = answers[questionId];
    if (val == null) return false;
    if (val is String) return val.isNotEmpty;
    if (val is Set<String>) return val.isNotEmpty;
    return false;
  }

  String? getSingle(String questionId) {
    final val = answers[questionId];
    return val is String ? val : null;
  }

  Set<String> getMulti(String questionId) {
    final val = answers[questionId];
    return val is Set<String> ? val : const {};
  }

  MatchExpertAnswerState copyWithUpdated(String questionId, dynamic value) {
    final newAnswers = Map<String, dynamic>.from(answers);
    if (value == null) {
      newAnswers.remove(questionId);
    } else {
      newAnswers[questionId] = value;
    }
    return MatchExpertAnswerState(answers: newAnswers);
  }
}
