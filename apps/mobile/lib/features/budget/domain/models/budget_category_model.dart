// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';

class BudgetCategoryModel {
  final String id;
  final String name;
  final double totalAmount;
  final double spentAmount;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  BudgetCategoryModel({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.spentAmount,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  BudgetCategoryModel copyWith({
    String? id,
    String? name,
    double? totalAmount,
    double? spentAmount,
    IconData? icon,
    Color? iconColor,
    Color? iconBgColor,
  }) {
    return BudgetCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      iconBgColor: iconBgColor ?? this.iconBgColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'totalAmount': totalAmount,
    'spentAmount': spentAmount,
    'iconCode': icon.codePoint,
    'iconFontFamily': icon.fontFamily,
    'iconColor': iconColor.toARGB32(),
    'iconBgColor': iconBgColor.toARGB32(),
  };

  factory BudgetCategoryModel.fromJson(Map<String, dynamic> json) => BudgetCategoryModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
    icon: IconData(
      json['iconCode'] as int? ?? Icons.category.codePoint,
      fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
    ),
    iconColor: Color(json['iconColor'] as int? ?? 0xFFEA580C),
    iconBgColor: Color(json['iconBgColor'] as int? ?? 0xFFFFEDD5),
  );
}
