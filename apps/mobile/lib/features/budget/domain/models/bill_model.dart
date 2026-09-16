// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';

class BillModel {
  final String id;
  final String name;
  final DateTime? dueDate;
  final double amount;
  final bool isAutoPay;
  final bool isPaid;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  BillModel({
    required this.id,
    required this.name,
    this.dueDate,
    required this.amount,
    required this.isAutoPay,
    required this.isPaid,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  BillModel copyWith({
    String? id,
    String? name,
    DateTime? dueDate,
    double? amount,
    bool? isAutoPay,
    bool? isPaid,
    IconData? icon,
    Color? iconColor,
    Color? iconBgColor,
  }) {
    return BillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      isAutoPay: isAutoPay ?? this.isAutoPay,
      isPaid: isPaid ?? this.isPaid,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      iconBgColor: iconBgColor ?? this.iconBgColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dueDate': dueDate?.toIso8601String(),
    'amount': amount,
    'isAutoPay': isAutoPay,
    'isPaid': isPaid,
    'iconCode': icon.codePoint,
    'iconFontFamily': icon.fontFamily,
    'iconColor': iconColor.toARGB32(),
    'iconBgColor': iconBgColor.toARGB32(),
  };

  factory BillModel.fromJson(Map<String, dynamic> json) => BillModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'] as String) : null,
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    isAutoPay: json['isAutoPay'] as bool? ?? false,
    isPaid: json['isPaid'] as bool? ?? false,
    icon: IconData(
      json['iconCode'] as int? ?? Icons.receipt.codePoint,
      fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
    ),
    iconColor: Color(json['iconColor'] as int? ?? 0xFFDC2626),
    iconBgColor: Color(json['iconBgColor'] as int? ?? 0xFF000000),
  );
}
