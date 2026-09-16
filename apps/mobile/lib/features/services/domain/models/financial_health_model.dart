import 'package:flutter/material.dart';

/// Representation of an actionable financial recommendation.
class FinancialRecommendation {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String actionLabel;
  final String actionRoute;
  final Color accentColor;

  const FinancialRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.actionLabel,
    required this.actionRoute,
    required this.accentColor,
  });
}

/// Comprehensive model representing a user's financial health diagnostic.
class FinancialHealthModel {
  final int score;
  final int maxScore;
  final String statusLabel;
  final String summary;
  final double emergencyFundRatio; // 0.0 - 1.0 (e.g. 1.0 = 6/6 months)
  final String emergencyFundText;
  final double debtRatio; // e.g. 0.18 (18%)
  final String debtRatioText;
  final double savingsRatio; // e.g. 0.25 (25%)
  final String savingsRatioText;
  final String insuranceStatusText;
  final List<FinancialRecommendation> recommendations;

  const FinancialHealthModel({
    required this.score,
    this.maxScore = 100,
    required this.statusLabel,
    required this.summary,
    required this.emergencyFundRatio,
    required this.emergencyFundText,
    required this.debtRatio,
    required this.debtRatioText,
    required this.savingsRatio,
    required this.savingsRatioText,
    required this.insuranceStatusText,
    required this.recommendations,
  });
}
