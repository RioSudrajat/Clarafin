import 'package:flutter/material.dart';

class InstitutionModel {
  final String id;
  final String name;
  final String shortName;
  final String type; // Bank, E-Wallet, Mutual Fund, Stock, Crypto, Cash
  final String logoAsset;
  final Color brandColor;
  final IconData fallbackIcon;
  final bool isSvg;
  final bool supportsAutoSync;

  const InstitutionModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.type,
    required this.logoAsset,
    required this.brandColor,
    required this.fallbackIcon,
    this.isSvg = true,
    this.supportsAutoSync = true,
  });
}
