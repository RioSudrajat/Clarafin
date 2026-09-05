import 'package:flutter/material.dart';

class ServiceItem {
  final String id;
  final String title;
  final String category; // 'counseling', 'tracker', 'health_check', 'education', 'rewards'
  final String svgKey;
  final Color badgeColor;
  final String? route;
  final String? description;
  final bool isBadgeNew;
  final bool isBadgeFree;
  final VoidCallback? onTap;

  const ServiceItem({
    required this.id,
    required this.title,
    required this.category,
    required this.svgKey,
    required this.badgeColor,
    this.route,
    this.description,
    this.isBadgeNew = false,
    this.isBadgeFree = false,
    this.onTap,
  });
}
