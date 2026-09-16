class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String tier;
  final String memberSince;
  final bool biometricsEnabled;
  final bool notificationsEnabled;
  final bool promoAlertsEnabled;
  final String pin;
  final String currency; // 'IDR', 'USD', 'SGD', 'EUR'
  final String language; // 'Bahasa Indonesia', 'English'
  final int? selectedAvatarIndex; // 1 to 6, or null for custom photo

  static const List<String> notionAvatars = [
    'assets/images/avatars/avatar_1.png',
    'assets/images/avatars/avatar_2.png',
    'assets/images/avatars/avatar_3.png',
    'assets/images/avatars/avatar_4.png',
    'assets/images/avatars/avatar_5.png',
    'assets/images/avatars/avatar_6.png',
  ];

  static const List<Map<String, String>> currencyOptions = [
    {'code': 'IDR', 'symbol': 'Rp', 'name': 'Rupiah Indonesia'},
    {'code': 'USD', 'symbol': r'$', 'name': 'US Dollar'},
    {'code': 'SGD', 'symbol': r'S$', 'name': 'Singapore Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
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
    this.promoAlertsEnabled = false,
    this.pin = '123456',
    this.currency = 'IDR',
    this.language = 'Bahasa Indonesia',
    this.selectedAvatarIndex = 1,
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
    bool? promoAlertsEnabled,
    String? pin,
    String? currency,
    String? language,
    int? selectedAvatarIndex,
    bool clearAvatarIndex = false,
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
      promoAlertsEnabled: promoAlertsEnabled ?? this.promoAlertsEnabled,
      pin: pin ?? this.pin,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      selectedAvatarIndex: clearAvatarIndex ? null : (selectedAvatarIndex ?? this.selectedAvatarIndex),
    );
  }
}
