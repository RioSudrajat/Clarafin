import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../features/budget/domain/models/bill_model.dart';
import '../../features/budget/domain/models/budget_category_model.dart';
import '../../features/budget/domain/models/goal_model.dart';
import '../../features/profile/presentation/providers/user_profile_provider.dart';
import '../institutions/institution_registry.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../services/local_storage_service.dart';
import '../utils/ai_category_normalizer.dart';
import 'clarafin_api_client.dart';
import 'tracker_remote_models.dart';

export 'tracker_remote_models.dart';

/// Synchronizes local tracker entities and confirmed AI drafts with Go `/v1/*` handlers.
class TrackerRemoteSyncService {
  static const int maxClientMutationIdLength = 128;

  final ClarafinApiClient _client;
  final SharedPreferences? _prefs;
  final String _storageScopeKey;
  final DateTime Function() _clock;
  final Map<String, String> _walletIdMap = {};
  bool _initialSyncCompleted = false;

  TrackerRemoteSyncService({
    required ClarafinApiClient client,
    SharedPreferences? prefs,
    String storageScopeKey = 'default',
    DateTime Function()? clock,
  }) : _client = client,
       _prefs = prefs,
       _storageScopeKey = storageScopeKey.trim().isEmpty
           ? 'default'
           : storageScopeKey.trim(),
       _clock = clock ?? DateTime.now {
    _loadPersistedState();
  }

  String get _walletMapPrefKey => 'clarafin_remote_wallet_map_$_storageScopeKey';
  String get _syncedFlagPrefKey => 'clarafin_remote_synced_$_storageScopeKey';

  String? resolveRemoteWalletId(String localOrRemoteId) {
    final trimmed = localOrRemoteId.trim();
    if (trimmed.isEmpty) return null;
    if (_walletIdMap.containsKey(trimmed)) {
      return _walletIdMap[trimmed];
    }
    return _validNonNilUuid(trimmed);
  }

  Future<RemoteQuotaStatus> fetchQuota({CancelToken? cancelToken}) async {
    final data = await _client.getJson('/v1/ai/quota', cancelToken: cancelToken);
    return RemoteQuotaStatus.fromJson(data);
  }

  Future<RemoteWalletResult> createWallet({
    required String name,
    required String type,
    String? institutionCode,
    double balance = 0,
    bool isAutoSync = false,
    String? customColorHex,
    String? accountNumberMasked,
    bool isVolatile = false,
    double? returnPercentage,
    DateTime? dividendDropDate,
    bool hasClaimedDividend = false,
    String? localWalletId,
    CancelToken? cancelToken,
  }) async {
    final resolvedInst = _trimOrNull(institutionCode) ??
        InstitutionRegistry.findByWallet(name: name, type: type).id;
    final payload = <String, dynamic>{
      'name': name.trim(),
      'type': normalizeWalletTypeForApi(type),
      'institution_code': resolvedInst,
      'account_number_masked': _trimOrNull(accountNumberMasked),
      'balance': balance.round(),
      'is_auto_sync': isAutoSync,
      'custom_color_hex': _trimOrNull(customColorHex),
      'return_percentage': returnPercentage,
      'dividend_drop_date':
          dividendDropDate != null ? formatWibRfc3339(dividendDropDate) : null,
      'is_volatile': isVolatile,
      'has_claimed_dividend': hasClaimedDividend,
    };
    final data = await _client.postJson(
      '/v1/wallets',
      data: payload,
      cancelToken: cancelToken,
    );
    final result = RemoteWalletResult.fromJson(data);
    if (localWalletId != null &&
        localWalletId.trim().isNotEmpty &&
        result.id.isNotEmpty) {
      _walletIdMap[localWalletId.trim()] = result.id;
      await _persistWalletMap();
    }
    return result;
  }

  Future<RemoteWalletResult> updateWallet({
    required String walletId,
    required String name,
    required String type,
    String? institutionCode,
    required double balance,
    bool? isAutoSync,
    String? customColorHex,
    String? accountNumberMasked,
    bool? isVolatile,
    double? returnPercentage,
    DateTime? dividendDropDate,
    bool? hasClaimedDividend,
    CancelToken? cancelToken,
  }) async {
    final resolvedWalletId = resolveRemoteWalletId(walletId) ?? walletId.trim();
    final resolvedInst = _trimOrNull(institutionCode) ??
        InstitutionRegistry.findByWallet(name: name, type: type).id;
    final masked = _trimOrNull(accountNumberMasked);
    final customHex = _trimOrNull(customColorHex);
    final dropDateStr =
        dividendDropDate != null ? formatWibRfc3339(dividendDropDate) : null;
    final payload = <String, dynamic>{
      'name': name.trim(),
      'type': normalizeWalletTypeForApi(type),
      'institution_code': resolvedInst,
      'account_number_masked': ?masked,
      'balance': balance.round(),
      'is_auto_sync': ?isAutoSync,
      'custom_color_hex': ?customHex,
      'return_percentage': ?returnPercentage,
      'dividend_drop_date': ?dropDateStr,
      'is_volatile': ?isVolatile,
      'has_claimed_dividend': ?hasClaimedDividend,
    };
    final data = await _client.patchJson(
      '/v1/wallets/$resolvedWalletId',
      data: payload,
      cancelToken: cancelToken,
    );
    return RemoteWalletResult.fromJson(data);
  }

  Future<RemoteTransactionResult> createTransaction({
    required String walletId,
    String? destinationWalletId,
    String? targetGoalId,
    required String type,
    required String category,
    required double amount,
    required String title,
    String? note,
    DateTime? occurredAt,
    String source = 'ai_text',
    required String clientMutationId,
    CancelToken? cancelToken,
  }) async {
    final normalizedType = type.trim().toLowerCase();
    final isTransfer = normalizedType == 'transfer';
    final isIncome = normalizedType == 'income';
    final canonicalCategory = AiCategoryNormalizer.normalize(
      category,
      isIncome: isIncome,
      allowCrossType: false,
      contextHint: title,
    );
    final resolvedWalletId = resolveRemoteWalletId(walletId) ?? walletId.trim();
    final resolvedDestId = isTransfer && destinationWalletId != null
        ? (resolveRemoteWalletId(destinationWalletId) ??
            destinationWalletId.trim())
        : null;
    final resolvedGoalId = isTransfer ? _validNonNilUuid(targetGoalId) : null;

    // Enforce strict Go DisallowUnknownFields() keys matching CreateTransactionInput.
    final payload = <String, dynamic>{
      'wallet_id': resolvedWalletId,
      if (isTransfer && resolvedDestId != null)
        'destination_wallet_id': resolvedDestId,
      if (isTransfer && resolvedGoalId != null)
        'target_goal_id': resolvedGoalId,
      'type': normalizedType,
      'category': isTransfer ? 'Transfer' : canonicalCategory,
      'amount': amount.round(),
      'title': title.trim(),
      if (_trimOrNull(note) != null) 'note': _trimOrNull(note),
      'occurred_at': formatWibRfc3339(occurredAt ?? _clock()),
      'source': _normalizeTxSource(source),
      'client_mutation_id': sanitizeClientMutationId(clientMutationId),
    };
    final data = await _client.postJson(
      '/v1/transactions',
      data: payload,
      cancelToken: cancelToken,
    );
    return RemoteTransactionResult.fromJson(data);
  }

  Future<RemoteGoalResult> createGoal({
    required String title,
    required double targetAmount,
    double savedAmount = 0,
    DateTime? targetDate,
    String priority = 'wants',
    String? linkedWalletId,
    String? sourceAssetLabel,
    CancelToken? cancelToken,
  }) async {
    final resolvedWallet = linkedWalletId != null
        ? _validNonNilUuid(resolveRemoteWalletId(linkedWalletId))
        : null;
    final payload = <String, dynamic>{
      'linked_wallet_id': ?resolvedWallet,
      'title': title.trim(),
      'target_amount': targetAmount.round(),
      'saved_amount': savedAmount.round(),
      if (targetDate != null) 'target_date': formatWibDate(targetDate),
      'priority': _normalizeGoalPriority(priority),
      if (_trimOrNull(sourceAssetLabel) != null)
        'source_asset_label': _trimOrNull(sourceAssetLabel),
    };
    final data = await _client.postJson(
      '/v1/goals',
      data: payload,
      cancelToken: cancelToken,
    );
    return RemoteGoalResult.fromJson(data);
  }

  Future<RemoteBudgetResult> upsertBudget({
    required String category,
    required double limitAmount,
    String? monthYear,
    CancelToken? cancelToken,
  }) async {
    final canonicalCategory =
        AiCategoryNormalizer.normalizeBudgetCategory(category);
    final payload = <String, dynamic>{
      'category': canonicalCategory,
      'month_year':
          _trimOrNull(monthYear) ?? formatWibMonthYear(_clock()),
      'limit_amount': limitAmount.round(),
    };
    final data = await _client.postJson(
      '/v1/budgets',
      data: payload,
      cancelToken: cancelToken,
    );
    return RemoteBudgetResult.fromJson(data);
  }

  Future<RemoteBillResult> createBill({
    required String title,
    String? category,
    required double amount,
    DateTime? dueDate,
    String frequency = 'monthly',
    bool autoPay = false,
    CancelToken? cancelToken,
  }) async {
    final normalizedCategory = AiCategoryNormalizer.normalize(
      category ?? 'Bills & Utilities',
      isIncome: false,
      allowCrossType: false,
      contextHint: title,
    );
    final payload = <String, dynamic>{
      'title': title.trim(),
      'category': normalizedCategory,
      'amount': amount.round(),
      if (dueDate != null) 'due_date': formatWibDate(dueDate),
      'frequency': _normalizeBillFrequency(frequency),
      'auto_pay': autoPay,
    };
    final data = await _client.postJson(
      '/v1/bills',
      data: payload,
      cancelToken: cancelToken,
    );
    return RemoteBillResult.fromJson(data);
  }

  /// Idempotently mirrors local tracker state onto the authenticated Go backend.
  Future<TrackerSyncSummary> syncInitialSnapshot({
    required List<WalletModel> wallets,
    required List<TransactionModel> transactions,
    required List<BudgetCategoryModel> budgets,
    required List<GoalModel> goals,
    required List<BillModel> bills,
    bool force = false,
    CancelToken? cancelToken,
  }) async {
    if (!force && _initialSyncCompleted) {
      return const TrackerSyncSummary(skippedAlreadySynced: true);
    }

    final walletCount = await _syncWallets(wallets, cancelToken: cancelToken);
    final txCount = await _syncTransactions(
      transactions,
      cancelToken: cancelToken,
    );
    if (txCount > 0 || walletCount > 0) {
      await _reconcileWalletBalances(wallets, cancelToken: cancelToken);
    }
    var budgetCount = 0;
    for (final b in budgets) {
      if (b.totalAmount <= 0) continue;
      await upsertBudget(
        category: b.name,
        limitAmount: b.totalAmount,
        cancelToken: cancelToken,
      );
      budgetCount++;
    }
    final goalCount = await _syncGoals(goals, cancelToken: cancelToken);
    final billCount = await _syncBills(bills, cancelToken: cancelToken);

    _initialSyncCompleted = true;
    await _prefs?.setBool(_syncedFlagPrefKey, true);
    return TrackerSyncSummary(
      walletsSynced: walletCount,
      transactionsSynced: txCount,
      budgetsSynced: budgetCount,
      goalsSynced: goalCount,
      billsSynced: billCount,
    );
  }

  Future<int> _syncWallets(
    List<WalletModel> localWallets, {
    CancelToken? cancelToken,
  }) async {
    final remoteRes = await _client.getJson(
      '/v1/wallets',
      cancelToken: cancelToken,
    );
    final remoteList = (remoteRes['wallets'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => RemoteWalletResult.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    var synced = 0;
    for (final w in localWallets) {
      final mapped = resolveRemoteWalletId(w.id);
      if (mapped != null && remoteList.any((rw) => rw.id == mapped)) {
        continue;
      }
      final apiType = normalizeWalletTypeForApi(w.type);
      final match = remoteList.where(
        (rw) =>
            rw.name.toLowerCase().trim() == w.name.toLowerCase().trim() &&
            rw.type == apiType,
      );
      if (match.isNotEmpty) {
        _walletIdMap[w.id] = match.first.id;
        continue;
      }
      await createWallet(
        name: w.name,
        type: w.type,
        institutionCode: w.institutionId,
        balance: w.balance,
        isAutoSync: w.isAutoSync,
        customColorHex: w.customColorHex,
        accountNumberMasked: w.maskedCardNumber,
        isVolatile: w.isVolatile,
        returnPercentage: w.returnPercentage,
        dividendDropDate: w.dividendDropDate,
        hasClaimedDividend: w.hasClaimedDividend,
        localWalletId: w.id,
        cancelToken: cancelToken,
      );
      synced++;
    }
    await _persistWalletMap();
    return synced;
  }

  Future<int> _syncTransactions(
    List<TransactionModel> txs, {
    CancelToken? cancelToken,
  }) async {
    var synced = 0;
    for (final tx in txs) {
      if (tx.amount <= 0) continue;
      final walletUuid = resolveRemoteWalletId(tx.walletId);
      if (walletUuid == null) continue;
      final destUuid = tx.targetWalletId != null
          ? resolveRemoteWalletId(tx.targetWalletId!)
          : null;
      if (tx.type.toLowerCase() == 'transfer' && destUuid == null) continue;

      await createTransaction(
        walletId: walletUuid,
        destinationWalletId: destUuid,
        type: tx.type,
        category: tx.category,
        amount: tx.amount,
        title: tx.title,
        note: tx.notes,
        occurredAt: tx.date,
        source: 'manual',
        clientMutationId: sanitizeClientMutationId('sync_tx_${tx.id}'),
        cancelToken: cancelToken,
      );
      synced++;
    }
    return synced;
  }

  Future<void> _reconcileWalletBalances(
    List<WalletModel> localWallets, {
    CancelToken? cancelToken,
  }) async {
    for (final w in localWallets) {
      final remoteId = resolveRemoteWalletId(w.id);
      if (remoteId == null) continue;
      await updateWallet(
        walletId: remoteId,
        name: w.name,
        type: w.type,
        institutionCode: w.institutionId,
        balance: w.balance,
        isAutoSync: w.isAutoSync,
        customColorHex: w.customColorHex,
        accountNumberMasked: w.maskedCardNumber,
        isVolatile: w.isVolatile,
        returnPercentage: w.returnPercentage,
        dividendDropDate: w.dividendDropDate,
        hasClaimedDividend: w.hasClaimedDividend,
        cancelToken: cancelToken,
      );
    }
  }

  Future<int> _syncGoals(
    List<GoalModel> goals, {
    CancelToken? cancelToken,
  }) async {
    final res = await _client.getJson('/v1/goals', cancelToken: cancelToken);
    final existing = (res['goals'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => RemoteGoalResult.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    var synced = 0;
    for (final g in goals) {
      if (g.targetAmount <= 0) continue;
      final exists = existing.any(
        (rg) =>
            rg.title.toLowerCase().trim() == g.name.toLowerCase().trim() &&
            rg.targetAmount == g.targetAmount.round(),
      );
      if (exists) continue;
      await createGoal(
        title: g.name,
        targetAmount: g.targetAmount,
        savedAmount: g.savedAmount,
        targetDate: g.targetDate,
        priority: g.priority,
        sourceAssetLabel: g.sourceAsset,
        cancelToken: cancelToken,
      );
      synced++;
    }
    return synced;
  }

  Future<int> _syncBills(
    List<BillModel> bills, {
    CancelToken? cancelToken,
  }) async {
    final res = await _client.getJson('/v1/bills', cancelToken: cancelToken);
    final existing = (res['bills'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => RemoteBillResult.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    var synced = 0;
    for (final b in bills) {
      if (b.amount <= 0) continue;
      final exists = existing.any(
        (rb) =>
            rb.title.toLowerCase().trim() == b.name.toLowerCase().trim() &&
            rb.amount == b.amount.round(),
      );
      if (exists) continue;
      await createBill(
        title: b.name,
        amount: b.amount,
        dueDate: b.dueDate,
        autoPay: b.isAutoPay,
        cancelToken: cancelToken,
      );
      synced++;
    }
    return synced;
  }

  static String normalizeWalletTypeForApi(String rawType) {
    final normalized = rawType.trim().toLowerCase().replaceAll(' ', '_');
    return switch (normalized) {
      'bank' => 'bank',
      'ewallet' || 'e-wallet' || 'e_wallet' => 'ewallet',
      'cash' => 'cash',
      'deposit' => 'deposit',
      'mutual_fund' => 'mutual_fund',
      'bond' => 'bond',
      'stock' => 'stock',
      'cex' => 'cex',
      'dex' => 'dex',
      'web3_wallet' => 'web3_wallet',
      'crypto' => 'crypto',
      'investment' => 'investment',
      _ => 'other',
    };
  }

  static String sanitizeClientMutationId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const Uuid().v4();
    if (trimmed.length <= maxClientMutationIdLength) return trimmed;
    return const Uuid().v5(Namespace.oid.value, trimmed);
  }

  static DateTime toWib(DateTime dt) =>
      dt.toUtc().add(const Duration(hours: 7));

  static String formatWibDate(DateTime dt) {
    final wib = toWib(dt);
    return '${wib.year.toString().padLeft(4, '0')}-'
        '${wib.month.toString().padLeft(2, '0')}-'
        '${wib.day.toString().padLeft(2, '0')}';
  }

  static String formatWibMonthYear(DateTime dt) {
    final wib = toWib(dt);
    return '${wib.year.toString().padLeft(4, '0')}-'
        '${wib.month.toString().padLeft(2, '0')}';
  }

  static String formatWibRfc3339(DateTime dt) {
    final wib = toWib(dt);
    return '${formatWibDate(dt)}T'
        '${wib.hour.toString().padLeft(2, '0')}:'
        '${wib.minute.toString().padLeft(2, '0')}:'
        '${wib.second.toString().padLeft(2, '0')}+07:00';
  }

  static String _normalizeTxSource(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'manual' || 'ai_text' || 'ai_voice' || 'ocr' || 'gmail' =>
        raw.trim().toLowerCase(),
      _ => 'ai_text',
    };
  }

  static String _normalizeGoalPriority(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'urgent' || 'needs' || 'wants' => raw.trim().toLowerCase(),
      _ => 'wants',
    };
  }

  static String _normalizeBillFrequency(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'once' || 'weekly' || 'monthly' || 'yearly' => raw.trim().toLowerCase(),
      _ => 'monthly',
    };
  }

  static String? _validNonNilUuid(String? raw) {
    final trimmed = _trimOrNull(raw);
    if (trimmed == null) return null;
    if (trimmed == '00000000-0000-0000-0000-000000000000') return null;
    return Uuid.isValidUUID(fromString: trimmed) ? trimmed : null;
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  void _loadPersistedState() {
    _initialSyncCompleted = _prefs?.getBool(_syncedFlagPrefKey) ?? false;
    final rawMap = _prefs?.getString(_walletMapPrefKey);
    if (rawMap != null && rawMap.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMap);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            _walletIdMap[entry.key.toString()] = entry.value.toString();
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _persistWalletMap() async {
    await _prefs?.setString(_walletMapPrefKey, jsonEncode(_walletIdMap));
  }
}

final trackerRemoteSyncServiceProvider = Provider<TrackerRemoteSyncService>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    prefs = null;
  }
  String email = 'default';
  try {
    final userEmail =
        ref.watch(userProfileProvider.select((u) => u.email)).trim();
    if (userEmail.isNotEmpty) {
      email = userEmail;
    }
  } catch (_) {
    email = 'default';
  }
  return TrackerRemoteSyncService(
    client: ref.watch(clarafinApiClientProvider),
    prefs: prefs,
    storageScopeKey: email,
  );
});
