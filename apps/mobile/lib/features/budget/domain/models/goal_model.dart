// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';

class GoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;
  final IconData icon;
  final Color tagColor;
  final Color tagTextColor;
  final String priority; // Urgent, Needs, Wants
  final String sourceAsset; // Legacy label for display
  /// Tracks contributions from multiple wallets: walletId -> amount
  final Map<String, double> contributions;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
    required this.icon,
    required this.tagColor,
    required this.tagTextColor,
    required this.priority,
    required this.sourceAsset,
    this.contributions = const {},
  });

  GoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    IconData? icon,
    Color? tagColor,
    Color? tagTextColor,
    String? priority,
    String? sourceAsset,
    Map<String, double>? contributions,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      tagColor: tagColor ?? this.tagColor,
      tagTextColor: tagTextColor ?? this.tagTextColor,
      priority: priority ?? this.priority,
      sourceAsset: sourceAsset ?? this.sourceAsset,
      contributions: contributions ?? this.contributions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'targetDate': targetDate.toIso8601String(),
    'iconCode': icon.codePoint,
    'iconFontFamily': icon.fontFamily,
    'tagColor': tagColor.toARGB32(),
    'tagTextColor': tagTextColor.toARGB32(),
    'priority': priority,
    'sourceAsset': sourceAsset,
    'contributions': contributions,
  };

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
    savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0.0,
    targetDate: DateTime.tryParse(json['targetDate'] as String? ?? '') ?? DateTime.now(),
    icon: IconData(
      json['iconCode'] as int? ?? Icons.flag.codePoint,
      fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
    ),
    tagColor: Color(json['tagColor'] as int? ?? 0xFFF3F4F6),
    tagTextColor: Color(json['tagTextColor'] as int? ?? 0xFF4B5563),
    priority: json['priority'] as String? ?? 'Wants',
    sourceAsset: json['sourceAsset'] as String? ?? 'Liquid',
    contributions: (json['contributions'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    ) ?? const {},
  );
}
