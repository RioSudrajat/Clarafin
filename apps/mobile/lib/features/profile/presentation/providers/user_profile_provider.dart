import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/user_profile_model.dart';

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final activeUser = ref.watch(authProvider.select((s) => s.currentUser));
    if (activeUser == null) {
      return const UserProfile(
        name: '',
        email: '',
        phone: '',
        avatarUrl: 'assets/images/avatars/avatar_1.png',
        selectedAvatarIndex: 1,
        currency: 'IDR',
        language: 'Bahasa Indonesia',
      );
    }

    final saved = ref.read(localStorageServiceProvider).getProfile(activeUser.id);
    if (saved != null) return saved;

    return UserProfile(
      name: activeUser.name,
      email: activeUser.email,
      phone: '',
      avatarUrl: activeUser.avatarUrl.isNotEmpty
          ? activeUser.avatarUrl
          : 'assets/images/avatars/avatar_1.png',
      selectedAvatarIndex: 1,
      currency: 'IDR',
      language: 'Bahasa Indonesia',
    );
  }

  void _persist() {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      ref.read(localStorageServiceProvider).saveProfile(userId, state);
    }
  }

  void updateProfile({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    int? selectedAvatarIndex,
  }) {
    state = state.copyWith(
      name: name?.trim(),
      phone: phone?.trim(),
      email: email?.trim(),
      avatarUrl: avatarUrl,
      selectedAvatarIndex: selectedAvatarIndex,
    );
    _persist();
  }

  void selectNotionAvatar(int index) {
    if (index < 1 || index > UserProfile.notionAvatars.length) return;
    state = state.copyWith(
      selectedAvatarIndex: index,
      avatarUrl: UserProfile.notionAvatars[index - 1],
    );
    _persist();
  }

  void setCustomAvatar(String url) {
    state = state.copyWith(
      avatarUrl: url,
      clearAvatarIndex: true,
    );
    _persist();
  }

  void setCurrency(String currencyCode) {
    state = state.copyWith(currency: currencyCode);
    _persist();
  }

  void setLanguage(String languageName) {
    state = state.copyWith(language: languageName);
    _persist();
  }

  void toggleBiometrics() {
    state = state.copyWith(biometricsEnabled: !state.biometricsEnabled);
    _persist();
  }

  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
    _persist();
  }

  void togglePromoAlerts() {
    state = state.copyWith(promoAlertsEnabled: !state.promoAlertsEnabled);
    _persist();
  }

  void setPin(String newPin) {
    state = state.copyWith(pin: newPin);
    _persist();
  }
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});
