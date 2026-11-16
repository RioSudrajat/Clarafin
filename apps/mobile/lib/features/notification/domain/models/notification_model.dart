import 'package:flutter/material.dart';

enum NotificationCategory {
  all,
  transaksi,
  konsultasi,
  promo,
  sistem,
}

extension NotificationCategoryExt on NotificationCategory {
  String get label {
    switch (this) {
      case NotificationCategory.all:
        return 'Semua';
      case NotificationCategory.transaksi:
        return 'Transaksi';
      case NotificationCategory.konsultasi:
        return 'Konsultasi';
      case NotificationCategory.promo:
        return 'Promo';
      case NotificationCategory.sistem:
        return 'Sistem';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationCategory.all:
        return Icons.notifications_active_outlined;
      case NotificationCategory.transaksi:
        return Icons.account_balance_wallet_outlined;
      case NotificationCategory.konsultasi:
        return Icons.support_agent_outlined;
      case NotificationCategory.promo:
        return Icons.local_offer_outlined;
      case NotificationCategory.sistem:
        return Icons.info_outline;
    }
  }

  Color get accentColor {
    switch (this) {
      case NotificationCategory.all:
        return const Color(0xFFCCFF00);
      case NotificationCategory.transaksi:
        return const Color(0xFF0F758A);
      case NotificationCategory.konsultasi:
        return const Color(0xFFFFB74D);
      case NotificationCategory.promo:
        return const Color(0xFFCCFF00);
      case NotificationCategory.sistem:
        return const Color(0xFF4FC3F7);
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationCategory category;
  final bool isRead;
  final String? actionRoute;
  final String? actionLabel;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    this.isRead = false,
    this.actionRoute,
    this.actionLabel,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationCategory? category,
    bool? isRead,
    String? actionRoute,
    String? actionLabel,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      actionLabel: actionLabel ?? this.actionLabel,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'category': category.name,
    'isRead': isRead,
    'actionRoute': actionRoute,
    'actionLabel': actionLabel,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id'] as String,
    title: json['title'] as String,
    message: json['message'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    category: NotificationCategory.values.firstWhere(
      (c) => c.name == (json['category'] as String),
      orElse: () => NotificationCategory.sistem,
    ),
    isRead: json['isRead'] as bool? ?? false,
    actionRoute: json['actionRoute'] as String?,
    actionLabel: json['actionLabel'] as String?,
  );
}
