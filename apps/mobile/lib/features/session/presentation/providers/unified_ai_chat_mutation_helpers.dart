import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/institutions/institution_registry.dart';
import '../../../../core/models/transaction_category_model.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/network/clarafin_api_client.dart';
import '../../../../core/utils/ai_category_normalizer.dart';
import '../../../budget/presentation/providers/finance_providers.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../data/local_ai_nlp_helpers.dart';
import '../../domain/models/ai_chat_models.dart';

/// Stateless domain mapping, quota sync, and formatting helpers for [UnifiedAiChatNotifier].
class UnifiedAiChatMutationHelpers {
  UnifiedAiChatMutationHelpers._();

  static const Uuid _uuid = Uuid();
  static const Set<String> _knownPlanTypes = {
    'free',
    'pro_monthly',
    'unlimited',
  };

  /// Extracts pending transaction draft items from a user prompt when a
  /// prerequisite wallet is missing and the transaction draft was withheld.
  static List<AiTransactionDraftItem> extractPendingTxItemsFromPrompt(
    String prompt, {
    required String fallbackWalletName,
    DateTime? now,
  }) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return const [];

    final timestamp = now ?? DateTime.now();
    final isIncome = LocalAiNlpHelpers.isIncomePrompt(trimmed);
    final clauses = LocalAiNlpHelpers.splitItemClauses(trimmed);
    final items = <AiTransactionDraftItem>[];

    for (final clause in clauses) {
      final amount = LocalAiNlpHelpers.parseAmount(clause);
      if (amount == null || amount <= 0) continue;
      final catRes = AiCategoryNormalizer.normalizeDetailed(
        clause,
        isIncome: isIncome,
        contextHint: clause,
      );
      items.add(
        AiTransactionDraftItem(
          title: LocalAiNlpHelpers.extractItemTitle(
            clause,
            catRes.canonicalCategory,
          ),
          amount: amount,
          type: catRes.type,
          canonicalCategory: catRes.canonicalCategory,
          walletId: '',
          walletName: fallbackWalletName,
          occurredAt: timestamp,
        ),
      );
    }
    return items;
  }

  /// Resolves the UI display type for a newly created [WalletModel].
  static String resolveDisplayWalletType(AiWalletCreationDraft draft) {
    final byId = InstitutionRegistry.findById(draft.institutionId);
    if (byId != null && byId.type.isNotEmpty) {
      return byId.type;
    }
    return switch (draft.walletType.trim().toLowerCase()) {
      'bank' => 'Bank',
      'ewallet' || 'e-wallet' || 'e_wallet' => 'E-Wallet',
      'cash' => 'Cash',
      'mutual_fund' => 'Mutual Fund',
      'stock' => 'Stock',
      'bond' => 'Bond',
      'deposit' => 'Deposit',
      'cex' => 'CEX',
      'dex' => 'DEX',
      'web3_wallet' => 'Web3 Wallet',
      'crypto' => 'Crypto',
      _ => 'Bank',
    };
  }

  /// Resolves a valid local wallet ID in [wallets] for [item].
  static String resolveLocalWalletId(
    AiTransactionDraftItem item,
    List<WalletModel> wallets,
  ) {
    if (item.walletId.isNotEmpty &&
        wallets.any((w) => w.id == item.walletId)) {
      return item.walletId;
    }
    if (item.walletName.isNotEmpty) {
      final matched = LocalAiNlpHelpers.matchWalletStrict(
        item.walletName,
        wallets,
      );
      if (matched != null) return matched.id;
    }
    if (item.walletId.isNotEmpty) return item.walletId;
    if (wallets.isNotEmpty) return wallets.first.id;
    return 'w_main';
  }

  /// Resolves an optional target wallet ID for transfer drafts.
  static String? resolveTargetWalletId(
    String? rawTargetWalletId,
    List<WalletModel> wallets,
  ) {
    final trimmed = rawTargetWalletId?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (wallets.any((w) => w.id == trimmed)) return trimmed;
    final matched = LocalAiNlpHelpers.matchWalletStrict(trimmed, wallets);
    return matched?.id ?? trimmed;
  }

  /// Normalizes an AI draft item's category into a verbatim canonical string
  /// so local budgets and remote tracker storage agree.
  static String normalizeLocalTransactionCategory(AiTransactionDraftItem item) {
    if (item.type.trim().toLowerCase() == 'transfer') {
      return 'Transfer';
    }
    return AiCategoryNormalizer.normalize(
      item.canonicalCategory,
      isIncome: item.type.trim().toLowerCase() == 'income',
      allowCrossType: false,
      contextHint: item.title,
    );
  }

  /// Builds a [GoalModel] from an approved [AiGoalDraft].
  static GoalModel buildGoalModel(
    AiGoalDraft draft,
    List<WalletModel> wallets, {
    String? clientMutationIdOverride,
  }) {
    var sourceLabel = 'Liquid';
    if (draft.linkedWalletId != null && draft.linkedWalletId!.isNotEmpty) {
      final matched = wallets
          .where((w) => w.id == draft.linkedWalletId)
          .firstOrNull;
      if (matched != null) {
        sourceLabel = matched.name;
      }
    }
    final mutationId = clientMutationIdOverride ?? draft.clientMutationId;
    return GoalModel(
      id: mutationId.isNotEmpty ? mutationId : 'goal_${_uuid.v4()}',
      name: draft.name.trim(),
      targetAmount: draft.targetAmount,
      savedAmount: 0.0,
      targetDate:
          draft.deadline ?? DateTime.now().add(const Duration(days: 180)),
      icon: Icons.flag_rounded,
      tagColor: const Color(0xFFCCFF00),
      tagTextColor: Colors.black,
      priority: 'Wants',
      sourceAsset: sourceLabel,
    );
  }

  /// Resolves a canonical top-level expense category name for budgets.
  static String resolveCanonicalBudgetCategory(String rawCategory) {
    final directCat = TransactionCategories.findCategory(
      rawCategory,
      isIncome: false,
    );
    if (directCat != null) return directCat.name;
    return AiCategoryNormalizer.normalizeBudgetCategory(rawCategory);
  }

  /// Applies an approved [AiBudgetDraft] by updating an existing category
  /// budget or adding a new canonical category budget.
  static String applyBudgetDraftToProvider(
    Ref ref,
    AiBudgetDraft draft, {
    String? canonicalCategoryOverride,
    String? clientMutationIdOverride,
  }) {
    final canonicalName =
        canonicalCategoryOverride ??
        resolveCanonicalBudgetCategory(draft.category);
    final catMeta = TransactionCategories.findCategory(
      canonicalName,
      isIncome: false,
    );

    final existingBudgets = ref.read(budgetsProvider);
    final existingMatch = existingBudgets.where((b) {
      return b.name.trim().toLowerCase() == canonicalName.toLowerCase() ||
          b.name.trim().toLowerCase() == draft.category.trim().toLowerCase();
    }).firstOrNull;

    if (existingMatch != null) {
      ref.read(budgetsProvider.notifier).updateBudget(
            existingMatch.copyWith(
              name: canonicalName,
              totalAmount: draft.limitAmount,
              icon: catMeta?.icon ?? existingMatch.icon,
              iconColor: catMeta?.color ?? existingMatch.iconColor,
              iconBgColor: catMeta?.bgColor ?? existingMatch.iconBgColor,
            ),
          );
    } else {
      final mutationId = clientMutationIdOverride ?? draft.clientMutationId;
      ref.read(budgetsProvider.notifier).addBudget(
            BudgetCategoryModel(
              id: mutationId.isNotEmpty ? mutationId : 'budget_${_uuid.v4()}',
              name: canonicalName,
              totalAmount: draft.limitAmount,
              spentAmount: 0.0,
              icon: catMeta?.icon ?? Icons.pie_chart_outline_rounded,
              iconColor: catMeta?.color ?? const Color(0xFFEA580C),
              iconBgColor: catMeta?.bgColor ?? const Color(0xFFFFEDD5),
            ),
          );
    }
    return canonicalName;
  }

  /// Builds a [BillModel] from an approved [AiBillDraft].
  static BillModel buildBillModel(
    AiBillDraft draft, {
    DateTime? now,
    String? clientMutationIdOverride,
  }) {
    final current = now ?? DateTime.now();
    final DateTime dueDate;
    if (draft.dueDate != null) {
      dueDate = draft.dueDate!;
    } else if (draft.dueDay != null && draft.dueDay! >= 1) {
      final targetDay = draft.dueDay!.clamp(1, 31);
      final thisMonthMax = DateTime(current.year, current.month + 1, 0).day;
      var candidate = DateTime(
        current.year,
        current.month,
        min(targetDay, thisMonthMax),
      );
      if (candidate.isBefore(
        DateTime(current.year, current.month, current.day),
      )) {
        final nextMonthMax = DateTime(current.year, current.month + 2, 0).day;
        candidate = DateTime(
          current.year,
          current.month + 1,
          min(targetDay, nextMonthMax),
        );
      }
      dueDate = candidate;
    } else {
      dueDate = current.add(const Duration(days: 7));
    }

    final normalizedCat = AiCategoryNormalizer.normalize(
      draft.category,
      isIncome: false,
      allowCrossType: false,
      contextHint: draft.title,
    );
    final display = TransactionCategories.getCategoryDisplay(normalizedCat);
    final mutationId = clientMutationIdOverride ?? draft.clientMutationId;

    return BillModel(
      id: mutationId.isNotEmpty ? mutationId : 'bill_${_uuid.v4()}',
      name: draft.title.trim(),
      dueDate: dueDate,
      amount: draft.amount,
      isAutoPay: false,
      isPaid: false,
      icon: display.icon,
      iconColor: display.color,
      iconBgColor: display.bgColor,
    );
  }

  /// Applies plan and remaining quota updates to [userProfileProvider] without
  /// resetting custom quota counts when plan stays unchanged.
  static void applyQuotaUpdate({
    required UserProfileNotifier profileNotifier,
    required String currentPlan,
    String? planType,
    int? quotaRemaining,
    required bool isPrefiltered,
    required bool isQuotaExceeded,
    required void Function(int amount) onUseLocalQuota,
  }) {
    final normalizedPlan = planType?.trim().toLowerCase();
    if (normalizedPlan != null &&
        _knownPlanTypes.contains(normalizedPlan) &&
        normalizedPlan != currentPlan) {
      profileNotifier.setSubscriptionPlan(normalizedPlan);
    }
    if (quotaRemaining != null) {
      profileNotifier.setAiQuotaRemaining(quotaRemaining);
    } else if (isQuotaExceeded) {
      profileNotifier.setAiQuotaRemaining(0);
    } else if (!isPrefiltered) {
      onUseLocalQuota(1);
    }
  }

  /// Converts backend or network exceptions into concise user-facing Indonesian errors.
  static String formatSyncError(Object error) {
    if (error is ClarafinApiException) {
      final msg = error.message.trim();
      if (msg.isNotEmpty) return msg;
    }
    if (error is DioException) {
      final msg = error.message?.trim() ?? '';
      if (msg.isNotEmpty) return msg;
      return 'Koneksi ke server Clarafin bermasalah. Silakan coba lagi.';
    }
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return 'Gagal menyinkronkan data ke server Clarafin.';
    }
    return 'Gagal menyinkronkan data: $raw';
  }
}
