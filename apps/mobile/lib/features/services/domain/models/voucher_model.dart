import 'package:flutter/material.dart';

/// Domain model representing a promo voucher / discount ticket in Clarafin.
class VoucherModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final String discountHighlight;
  final String validUntil;
  final String category; // 'all', 'counseling', 'investment'
  final String minTransaction;
  final bool isClaimed;
  final Color accentColor;

  const VoucherModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountHighlight,
    required this.validUntil,
    this.category = 'all',
    this.minTransaction = 'Tanpa min. transaksi',
    this.isClaimed = false,
    required this.accentColor,
  });

  VoucherModel copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? discountHighlight,
    String? validUntil,
    String? category,
    String? minTransaction,
    bool? isClaimed,
    Color? accentColor,
  }) {
    return VoucherModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountHighlight: discountHighlight ?? this.discountHighlight,
      validUntil: validUntil ?? this.validUntil,
      category: category ?? this.category,
      minTransaction: minTransaction ?? this.minTransaction,
      isClaimed: isClaimed ?? this.isClaimed,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}
