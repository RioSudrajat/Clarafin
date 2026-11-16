import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/presentation/providers/user_profile_provider.dart';

class AiQuotaState {
  final String planType; // 'free', 'pro_monthly', 'unlimited'
  final int quotaTotal; // 40, 400, or -1
  final int quotaRemaining;
  final String renewalDate;

  const AiQuotaState({
    required this.planType,
    required this.quotaTotal,
    required this.quotaRemaining,
    required this.renewalDate,
  });

  bool get isUnlimited => planType == 'unlimited' || quotaTotal == -1;

  String get displayQuotaBadge {
    if (isUnlimited) return 'Unlimited';
    return '$quotaRemaining/$quotaTotal';
  }

  AiQuotaState copyWith({
    String? planType,
    int? quotaTotal,
    int? quotaRemaining,
    String? renewalDate,
  }) {
    return AiQuotaState(
      planType: planType ?? this.planType,
      quotaTotal: quotaTotal ?? this.quotaTotal,
      quotaRemaining: quotaRemaining ?? this.quotaRemaining,
      renewalDate: renewalDate ?? this.renewalDate,
    );
  }
}

class AiQuotaNotifier extends Notifier<AiQuotaState> {
  @override
  AiQuotaState build() {
    final profile = ref.watch(userProfileProvider);
    final plan = profile.subscriptionPlan;
    final remaining = profile.aiQuotaRemaining;

    int total = 40;
    String renewal = 'Tiap tgl 1 WIB';
    if (plan == 'pro_monthly') {
      total = 400;
      renewal = '30 Hari dari aktivasi';
    } else if (plan == 'unlimited') {
      total = -1;
      renewal = 'Berlangganan Aktif';
    }

    return AiQuotaState(
      planType: plan,
      quotaTotal: total,
      quotaRemaining: remaining,
      renewalDate: renewal,
    );
  }

  void useQuota([int amount = 1]) {
    if (!state.isUnlimited) {
      ref.read(userProfileProvider.notifier).decrementAiQuota(amount);
    }
  }

  void upgradePlan(String plan) {
    ref.read(userProfileProvider.notifier).setSubscriptionPlan(plan);
  }
}

final aiQuotaProvider = NotifierProvider<AiQuotaNotifier, AiQuotaState>(() {
  return AiQuotaNotifier();
});
