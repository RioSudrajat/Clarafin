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

  void setSubscriptionPlan(String plan) {
    int quota = 40;
    String tier = 'Clarafin Free Member';
    if (plan == 'pro_monthly') {
      quota = 400;
      tier = 'Clarafin Pro Member';
    } else if (plan == 'unlimited') {
      quota = -1;
      tier = 'Clarafin Unlimited Member';
    }
    state = state.copyWith(
      subscriptionPlan: plan,
      aiQuotaRemaining: quota,
      tier: tier,
    );
    _persist();
  }

  void setAiQuotaRemaining(int quota) {
    state = state.copyWith(aiQuotaRemaining: quota);
    _persist();
  }

  void decrementAiQuota([int amount = 1]) {
    if (state.aiQuotaRemaining > 0) {
      state = state.copyWith(aiQuotaRemaining: state.aiQuotaRemaining - amount);
      _persist();
    }
  }

  void setGmailConnected(bool connected) {
    state = state.copyWith(isGmailConnected: connected);
    _persist();
  }

  void toggleGmailConnection([bool? connected]) {
    setGmailConnected(connected ?? !state.isGmailConnected);
  }

  void setTrackingHistorySource(String source) {
    state = state.copyWith(trackingHistorySource: source);
    _persist();
  }

  void setTrackerFocuses(List<String> focuses) {
    state = state.copyWith(trackerFocuses: focuses);
    _persist();
  }

  void setAdvisoryFocus(String focus) {
    state = state.copyWith(advisoryFocus: focus);
    _persist();
  }

  void setDailyReminder(bool enabled, String time) {
    state = state.copyWith(
      dailyReminderEnabled: enabled,
      dailyReminderTime: time,
    );
    _persist();
  }

  void toggleBiometrics() {
    state = state.copyWith(biometricsEnabled: !state.biometricsEnabled);
    _persist();
  }

  void toggleNotifications([bool? value]) {
    state = state.copyWith(notificationsEnabled: value ?? !state.notificationsEnabled);
    _persist();
  }

  void toggleSessionReminders([bool? value]) {
    state = state.copyWith(sessionRemindersEnabled: value ?? !state.sessionRemindersEnabled);
    _persist();
  }

  void toggleBillReminders([bool? value]) {
    state = state.copyWith(billRemindersEnabled: value ?? !state.billRemindersEnabled);
    _persist();
  }

  void togglePromoAlerts([bool? value]) {
    state = state.copyWith(promoAlertsEnabled: value ?? !state.promoAlertsEnabled);
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
