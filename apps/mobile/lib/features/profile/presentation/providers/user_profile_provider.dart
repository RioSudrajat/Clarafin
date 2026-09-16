import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../domain/models/user_profile_model.dart';

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final currentUserName = ref.watch(userNameProvider);
    return UserProfile(
      name: currentUserName,
      email: 'budi.santoso@example.com',
      phone: '+62 812-3456-7890',
      avatarUrl: 'assets/images/avatars/avatar_1.png',
      selectedAvatarIndex: 1,
      currency: 'IDR',
      language: 'Bahasa Indonesia',
    );
  }

  void updateProfile({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    int? selectedAvatarIndex,
  }) {
    if (name != null && name.trim().isNotEmpty) {
      ref.read(userNameProvider.notifier).state = name.trim();
    }
    state = state.copyWith(
      name: name?.trim(),
      phone: phone?.trim(),
      email: email?.trim(),
      avatarUrl: avatarUrl,
      selectedAvatarIndex: selectedAvatarIndex,
    );
  }

  void selectNotionAvatar(int index) {
    if (index < 1 || index > UserProfile.notionAvatars.length) return;
    state = state.copyWith(
      selectedAvatarIndex: index,
      avatarUrl: UserProfile.notionAvatars[index - 1],
    );
  }

  void setCustomAvatar(String url) {
    state = state.copyWith(
      avatarUrl: url,
      clearAvatarIndex: true,
    );
  }

  void setCurrency(String currencyCode) {
    state = state.copyWith(currency: currencyCode);
  }

  void setLanguage(String languageName) {
    state = state.copyWith(language: languageName);
  }

  void toggleBiometrics() {
    state = state.copyWith(biometricsEnabled: !state.biometricsEnabled);
  }

  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }

  void togglePromoAlerts() {
    state = state.copyWith(promoAlertsEnabled: !state.promoAlertsEnabled);
  }

  void setPin(String newPin) {
    state = state.copyWith(pin: newPin);
  }
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});
