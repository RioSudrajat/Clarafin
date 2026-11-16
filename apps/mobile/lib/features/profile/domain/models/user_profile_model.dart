class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String tier;
  final String memberSince;
  final bool biometricsEnabled;
  final bool notificationsEnabled;
  final bool sessionRemindersEnabled;
  final bool billRemindersEnabled;
  final bool promoAlertsEnabled;
  final String pin;
  final String currency; // 'IDR', 'USD', 'SGD', 'MYR', 'EUR', 'JPY'
  final String language; // 'Bahasa Indonesia', 'English'
  final int? selectedAvatarIndex; // 1 to 6, or null for custom photo

  // Wave P3 fields
  final String subscriptionPlan; // 'free', 'pro_monthly', 'unlimited'
  final int aiQuotaRemaining; // 40, 400, or -1 (unlimited)
  final bool isGmailConnected;
  final String trackingHistorySource; // 'fresh_start', 'other_app', 'spreadsheet'
  final List<String> trackerFocuses; // e.g. ['cashflow', 'budget', 'goals']
  final String advisoryFocus; // 'basic', 'medium', 'couple', 'umkm', 'premium'
  final bool dailyReminderEnabled;
  final String dailyReminderTime; // '20:00'

  static const List<String> notionAvatars = [
    'assets/images/avatars/avatar_1.png',
    'assets/images/avatars/avatar_2.png',
    'assets/images/avatars/avatar_3.png',
    'assets/images/avatars/avatar_4.png',
    'assets/images/avatars/avatar_5.png',
    'assets/images/avatars/avatar_6.png',
  ];

  static const List<Map<String, String>> currencyOptions = [
    {'code': 'IDR', 'symbol': 'Rp ', 'name': 'Rupiah Indonesia'},
    {'code': 'USD', 'symbol': r'$', 'name': 'US Dollar'},
    {'code': 'SGD', 'symbol': r'S$', 'name': 'Singapore Dollar'},
    {'code': 'MYR', 'symbol': 'RM ', 'name': 'Malaysian Ringgit'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  ];

  static const List<Map<String, String>> languageOptions = [
    {'code': 'id', 'name': 'Bahasa Indonesia', 'desc': 'Bahasa Utama'},
    {'code': 'en', 'name': 'English (US)', 'desc': 'International'},
  ];

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    this.tier = 'Clarafin Pro Member',
    this.memberSince = 'Januari 2024',
    this.biometricsEnabled = true,
    this.notificationsEnabled = true,
    this.sessionRemindersEnabled = true,
    this.billRemindersEnabled = true,
    this.promoAlertsEnabled = false,
    this.pin = '123456',
    this.currency = 'IDR',
    this.language = 'Bahasa Indonesia',
    this.selectedAvatarIndex = 1,
    this.subscriptionPlan = 'free',
    this.aiQuotaRemaining = 40,
    this.isGmailConnected = false,
    this.trackingHistorySource = 'fresh_start',
    this.trackerFocuses = const [],
    this.advisoryFocus = 'basic',
    this.dailyReminderEnabled = true,
    this.dailyReminderTime = '20:00',
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? tier,
    String? memberSince,
    bool? biometricsEnabled,
    bool? notificationsEnabled,
    bool? sessionRemindersEnabled,
    bool? billRemindersEnabled,
    bool? promoAlertsEnabled,
    String? pin,
    String? currency,
    String? language,
    int? selectedAvatarIndex,
    bool clearAvatarIndex = false,
    String? subscriptionPlan,
    int? aiQuotaRemaining,
    bool? isGmailConnected,
    String? trackingHistorySource,
    List<String>? trackerFocuses,
    String? advisoryFocus,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tier: tier ?? this.tier,
      memberSince: memberSince ?? this.memberSince,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      sessionRemindersEnabled: sessionRemindersEnabled ?? this.sessionRemindersEnabled,
      billRemindersEnabled: billRemindersEnabled ?? this.billRemindersEnabled,
      promoAlertsEnabled: promoAlertsEnabled ?? this.promoAlertsEnabled,
      pin: pin ?? this.pin,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      selectedAvatarIndex: clearAvatarIndex ? null : (selectedAvatarIndex ?? this.selectedAvatarIndex),
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      aiQuotaRemaining: aiQuotaRemaining ?? this.aiQuotaRemaining,
      isGmailConnected: isGmailConnected ?? this.isGmailConnected,
      trackingHistorySource: trackingHistorySource ?? this.trackingHistorySource,
      trackerFocuses: trackerFocuses ?? this.trackerFocuses,
      advisoryFocus: advisoryFocus ?? this.advisoryFocus,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'tier': tier,
    'memberSince': memberSince,
    'biometricsEnabled': biometricsEnabled,
    'notificationsEnabled': notificationsEnabled,
    'sessionRemindersEnabled': sessionRemindersEnabled,
    'billRemindersEnabled': billRemindersEnabled,
    'promoAlertsEnabled': promoAlertsEnabled,
    'pin': pin,
    'currency': currency,
    'language': language,
    'selectedAvatarIndex': selectedAvatarIndex,
    'subscriptionPlan': subscriptionPlan,
    'aiQuotaRemaining': aiQuotaRemaining,
    'isGmailConnected': isGmailConnected,
    'trackingHistorySource': trackingHistorySource,
    'trackerFocuses': trackerFocuses,
    'advisoryFocus': advisoryFocus,
    'dailyReminderEnabled': dailyReminderEnabled,
    'dailyReminderTime': dailyReminderTime,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String? ?? 'assets/images/avatars/avatar_1.png',
    tier: json['tier'] as String? ?? 'Clarafin Pro Member',
    memberSince: json['memberSince'] as String? ?? 'Januari 2024',
    biometricsEnabled: json['biometricsEnabled'] as bool? ?? true,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    sessionRemindersEnabled: json['sessionRemindersEnabled'] as bool? ?? true,
    billRemindersEnabled: json['billRemindersEnabled'] as bool? ?? true,
    promoAlertsEnabled: json['promoAlertsEnabled'] as bool? ?? false,
    pin: json['pin'] as String? ?? '123456',
    currency: json['currency'] as String? ?? 'IDR',
    language: json['language'] as String? ?? 'Bahasa Indonesia',
    selectedAvatarIndex: json['selectedAvatarIndex'] as int? ?? 1,
    subscriptionPlan: json['subscriptionPlan'] as String? ?? 'free',
    aiQuotaRemaining: json['aiQuotaRemaining'] as int? ?? 40,
    isGmailConnected: json['isGmailConnected'] as bool? ?? false,
    trackingHistorySource: json['trackingHistorySource'] as String? ?? 'fresh_start',
    trackerFocuses: (json['trackerFocuses'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const ['cashflow', 'budget', 'goals'],
    advisoryFocus: json['advisoryFocus'] as String? ?? 'basic',
    dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? true,
    dailyReminderTime: json['dailyReminderTime'] as String? ?? '20:00',
  );
}
