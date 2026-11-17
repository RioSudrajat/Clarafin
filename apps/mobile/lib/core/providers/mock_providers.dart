import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../services/local_storage_service.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/budget/presentation/providers/finance_providers.dart';
import '../../../features/profile/presentation/providers/user_profile_provider.dart';

// --- User Provider ---
// User balance will be calculated dynamically in UI from wallets, 
// so totalBalance here is just an initial or dummy value.
final userProvider = Provider<UserModel>((ref) {
  final name = ref.watch(userNameProvider);
  return UserModel(
    id: 'u1',
    name: name.isEmpty ? 'Pengguna Baru' : name,
    email: '',
    totalBalance: 0, 
  );
});

// --- User Name Provider (Derived from userProfileProvider) ---
final userNameProvider = Provider<String>((ref) {
  return ref.watch(userProfileProvider.select((p) => p.name));
});

// --- Wallets Provider ---
class WalletsNotifier extends Notifier<List<WalletModel>> {
  @override
  List<WalletModel> build() {
    final simulationTimer = _startSimulation();
    final dividendTimer = _startDividendCheck();
    
    ref.onDispose(() {
      simulationTimer.cancel();
      dividendTimer.cancel();
    });

    final userId = ref.watch(authProvider.select((s) => s.currentUser?.id));
    if (userId == null || userId.isEmpty) return [];
    return ref.read(localStorageServiceProvider).getWallets(userId);
  }

  void _persist() {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      ref.read(localStorageServiceProvider).saveWallets(userId, state);
    }
  }

  Timer _startSimulation() {
    // Simulate real-time data for volatile assets
    return Timer.periodic(const Duration(seconds: 3), (timer) {
      final random = Random();
      state = state.map((wallet) {
        if (wallet.isVolatile) {
          // Fluctuate return percentage slightly (between -0.5% and +0.5%)
          double change = (random.nextDouble() - 0.5);
          double newReturn = (wallet.returnPercentage ?? 0.0) + change;
          // Calculate new balance based on the slight change
          double newBalance = wallet.balance * (1 + (change / 100));
          return wallet.copyWith(returnPercentage: newReturn, balance: newBalance);
        }
        return wallet;
      }).toList();
    });
  }

  Timer _startDividendCheck() {
    // Check daily (or frequently) for dividend drops
    return Timer.periodic(const Duration(seconds: 10), (timer) {
      final now = DateTime.now();
      state = state.map((wallet) {
        if (wallet.dividendDropDate != null && !wallet.hasClaimedDividend) {
          // If the drop date is reached or passed
          if (now.isAfter(wallet.dividendDropDate!) || now.isAtSameMomentAs(wallet.dividendDropDate!)) {
            // Accumulate dividend (e.g. 2% of balance)
            double dividendAmount = wallet.balance * ((wallet.returnPercentage ?? 2.0) / 100);
            return wallet.copyWith(
              balance: wallet.balance + dividendAmount,
              hasClaimedDividend: true, // prevent double claim
            );
          }
        }
        return wallet;
      }).toList();
    });
  }

  void addWallet(WalletModel wallet) {
    state = [...state, wallet];
    _persist();
  }

  void updateWallet(WalletModel wallet) {
    state = [
      for (final w in state)
        if (w.id == wallet.id) wallet else w
    ];
    _persist();
  }

  void deleteWallet(String id) {
    state = state.where((w) => w.id != id).toList();
    _persist();
  }

  void updateBalance(String id, double amount, {bool isExpense = false}) {
    state = state.map((wallet) {
      if (wallet.id == id) {
        double newBalance = isExpense ? wallet.balance - amount : wallet.balance + amount;
        return wallet.copyWith(balance: newBalance);
      }
      return wallet;
    }).toList();
    _persist();
  }
}

final walletsProvider = NotifierProvider<WalletsNotifier, List<WalletModel>>(() {
  return WalletsNotifier();
});

// --- Transactions Provider ---
class TransactionsNotifier extends Notifier<List<TransactionModel>> {
  @override
  List<TransactionModel> build() {
    final userId = ref.watch(authProvider.select((s) => s.currentUser?.id));
    if (userId == null || userId.isEmpty) return [];
    return ref.read(localStorageServiceProvider).getTransactions(userId);
  }

  void _persist() {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      ref.read(localStorageServiceProvider).saveTransactions(userId, state);
    }
  }

  void addTransaction(TransactionModel transaction) {
    state = [transaction, ...state];
    _persist();
    
    // Check for reverse goal transfer: source is 'goal:<goalId>:<walletId>'
    if (transaction.type == 'transfer' && transaction.walletId.startsWith('goal:')) {
      final parts = transaction.walletId.split(':');
      if (parts.length == 3) {
        final goalId = parts[1];
        final sourceWalletId = parts[2];
        // Remove savings from goal
        ref.read(goalsProvider.notifier).removeSavings(goalId, sourceWalletId, transaction.amount);
        // Add back to the target wallet
        if (transaction.targetWalletId != null) {
          ref.read(walletsProvider.notifier).updateBalance(transaction.targetWalletId!, transaction.amount, isExpense: false);
        }
      }
      return;
    }

    // Update wallet balance automatically
    if (transaction.type == 'expense') {
      ref.read(walletsProvider.notifier).updateBalance(transaction.walletId, transaction.amount, isExpense: true);
    } else if (transaction.type == 'income') {
      ref.read(walletsProvider.notifier).updateBalance(transaction.walletId, transaction.amount, isExpense: false);
    } else if (transaction.type == 'transfer') {
      // Deduct from source wallet
      ref.read(walletsProvider.notifier).updateBalance(transaction.walletId, transaction.amount, isExpense: true);
      
      if (transaction.targetGoalId != null) {
        // Transfer to goal — add savings
        ref.read(goalsProvider.notifier).addSavings(
          transaction.targetGoalId!, 
          transaction.walletId, 
          transaction.amount,
        );
      } else if (transaction.targetWalletId != null) {
        // Transfer to another wallet
        ref.read(walletsProvider.notifier).updateBalance(transaction.targetWalletId!, transaction.amount, isExpense: false);
      }
    }
  }

  void deleteTransaction(String id) {
    state = state.where((t) => t.id != id).toList();
    _persist();
  }
}

final transactionsProvider = NotifierProvider<TransactionsNotifier, List<TransactionModel>>(() {
  return TransactionsNotifier();
});
