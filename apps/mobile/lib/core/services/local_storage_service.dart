import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../../features/budget/domain/models/goal_model.dart';
import '../../features/budget/domain/models/budget_category_model.dart';
import '../../features/budget/domain/models/bill_model.dart';
import '../../features/profile/domain/models/user_profile_model.dart';
import '../../features/notification/domain/models/notification_model.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService(ref.watch(sharedPreferencesProvider));
});

class LocalStorageService {
  final SharedPreferences _prefs;
  LocalStorageService(this._prefs);

  // Wallets
  List<WalletModel> getWallets(String userId) {
    final key = 'clarafin_wallets_$userId';
    final list = _prefs.getStringList(key);
    if (list == null) return [];
    return list.map((item) => WalletModel.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
  }

  Future<void> saveWallets(String userId, List<WalletModel> wallets) async {
    final key = 'clarafin_wallets_$userId';
    final list = wallets.map((w) => jsonEncode(w.toJson())).toList();
    await _prefs.setStringList(key, list);
  }

  // Transactions
  List<TransactionModel> getTransactions(String userId) {
    final key = 'clarafin_transactions_$userId';
    final list = _prefs.getStringList(key);
    if (list == null) return [];
    return list.map((item) => TransactionModel.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
  }

  Future<void> saveTransactions(String userId, List<TransactionModel> transactions) async {
    final key = 'clarafin_transactions_$userId';
    final list = transactions.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs.setStringList(key, list);
  }

  // Goals
  List<GoalModel> getGoals(String userId) {
    final key = 'clarafin_goals_$userId';
    final list = _prefs.getStringList(key);
    if (list == null) return [];
    return list.map((item) => GoalModel.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
  }

  Future<void> saveGoals(String userId, List<GoalModel> goals) async {
    final key = 'clarafin_goals_$userId';
    final list = goals.map((g) => jsonEncode(g.toJson())).toList();
    await _prefs.setStringList(key, list);
  }

  // Budgets
  List<BudgetCategoryModel> getBudgets(String userId) {
    final key = 'clarafin_budgets_$userId';
    final list = _prefs.getStringList(key);
    if (list == null) return [];
    return list.map((item) => BudgetCategoryModel.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
  }

  Future<void> saveBudgets(String userId, List<BudgetCategoryModel> budgets) async {
    final key = 'clarafin_budgets_$userId';
    final list = budgets.map((b) => jsonEncode(b.toJson())).toList();
    await _prefs.setStringList(key, list);
  }

  // Bills
  List<BillModel> getBills(String userId) {
    final key = 'clarafin_bills_$userId';
    final list = _prefs.getStringList(key);
    if (list == null) return [];
    return list.map((item) => BillModel.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
  }

  Future<void> saveBills(String userId, List<BillModel> bills) async {
    final key = 'clarafin_bills_$userId';
    final list = bills.map((b) => jsonEncode(b.toJson())).toList();
    await _prefs.setStringList(key, list);
  }

  // Profile
  UserProfile? getProfile(String userId) {
    final key = 'clarafin_profile_$userId';
    final jsonStr = _prefs.getString(key);
    if (jsonStr == null) return null;
    return UserProfile.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  Future<void> saveProfile(String userId, UserProfile profile) async {
    final key = 'clarafin_profile_$userId';
    await _prefs.setString(key, jsonEncode(profile.toJson()));
  }

  // Notifications
  List<NotificationItem> getNotifications(String userId) {
    final key = 'clarafin_notifications_$userId';
    final list = _prefs.getStringList(key);
    if (list == null) return [];
    return list.map((item) => NotificationItem.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
  }

  Future<void> saveNotifications(String userId, List<NotificationItem> notifications) async {
    final key = 'clarafin_notifications_$userId';
    final list = notifications.map((n) => jsonEncode(n.toJson())).toList();
    await _prefs.setStringList(key, list);
  }

  // Total Budget
  double getTotalBudget(String userId) {
    final key = 'clarafin_total_budget_$userId';
    return _prefs.getDouble(key) ?? 5000000.0;
  }

  Future<void> saveTotalBudget(String userId, double amount) async {
    final key = 'clarafin_total_budget_$userId';
    await _prefs.setDouble(key, amount);
  }

  // Clear operations for Account Deletion
  Future<void> clearUserData(String userId) async {
    final keys = _prefs.getKeys().where((k) => k.contains(userId)).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
