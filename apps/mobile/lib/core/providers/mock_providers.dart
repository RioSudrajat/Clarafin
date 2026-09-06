import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../../../features/budget/presentation/providers/finance_providers.dart';

// --- User Provider ---
// User balance will be calculated dynamically in UI from wallets, 
// so totalBalance here is just an initial or dummy value.
final userProvider = Provider<UserModel>((ref) {
  return UserModel(
    id: 'u1',
    name: 'Budi Santoso',
    email: 'budi@example.com',
    totalBalance: 0, 
  );
});

// --- Editable User Name Provider ---
class UserNameNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.read(userProvider).name;
  }

  @override
  set state(String value) => super.state = value;
}

final userNameProvider = NotifierProvider<UserNameNotifier, String>(() {
  return UserNameNotifier();
});

// --- Quick Action Limit Provider ---
class QuickActionLimitState {
  final int aiChatCount;
  final int voiceAiCount;
  final int scanCount;

  const QuickActionLimitState({
    required this.aiChatCount,
    required this.voiceAiCount,
    required this.scanCount,
  });

  QuickActionLimitState copyWith({
    int? aiChatCount,
    int? voiceAiCount,
    int? scanCount,
  }) {
    return QuickActionLimitState(
      aiChatCount: aiChatCount ?? this.aiChatCount,
      voiceAiCount: voiceAiCount ?? this.voiceAiCount,
      scanCount: scanCount ?? this.scanCount,
    );
  }
}

class QuickActionLimitNotifier extends Notifier<QuickActionLimitState> {
  @override
  QuickActionLimitState build() {
    return const QuickActionLimitState(
      aiChatCount: 0,
      voiceAiCount: 0,
      scanCount: 0,
    );
  }

  void incrementAiChat() {
    if (state.aiChatCount < 10) {
      state = state.copyWith(aiChatCount: state.aiChatCount + 1);
    }
  }

  void incrementVoiceAi() {
    if (state.voiceAiCount < 5) {
      state = state.copyWith(voiceAiCount: state.voiceAiCount + 1);
    }
  }

  void incrementScan() {
    if (state.scanCount < 8) {
      state = state.copyWith(scanCount: state.scanCount + 1);
    }
  }
}

final quickActionLimitProvider = NotifierProvider<QuickActionLimitNotifier, QuickActionLimitState>(() {
  return QuickActionLimitNotifier();
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

    return [
      WalletModel(id: 'w1', name: 'BCA Utama', type: 'Bank', balance: 12000000, isAutoSync: true, institutionId: 'bca'),
      WalletModel(id: 'w2', name: 'GoPay', type: 'E-Wallet', balance: 500000, isAutoSync: true, institutionId: 'gopay'),
      WalletModel(id: 'w3', name: 'Investasi Bibit', type: 'Mutual Fund', balance: 10000000, isAutoSync: false, returnPercentage: 5.0, institutionId: 'bibit'),
      WalletModel(id: 'w4', name: 'Dompet Tunai', type: 'Cash', balance: 2000000, isAutoSync: false, institutionId: 'cash'),
      WalletModel(id: 'w5', name: 'Bitcoin', type: 'Crypto', balance: 5000000, isAutoSync: false, isVolatile: true, returnPercentage: 2.5, institutionId: 'bitcoin'),
    ];
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
  }

  void updateWallet(WalletModel wallet) {
    state = [
      for (final w in state)
        if (w.id == wallet.id) wallet else w
    ];
  }

  void deleteWallet(String id) {
    state = state.where((w) => w.id != id).toList();
  }

  void updateBalance(String id, double amount, {bool isExpense = false}) {
    state = state.map((wallet) {
      if (wallet.id == id) {
        double newBalance = isExpense ? wallet.balance - amount : wallet.balance + amount;
        return wallet.copyWith(balance: newBalance);
      }
      return wallet;
    }).toList();
  }
}

final walletsProvider = NotifierProvider<WalletsNotifier, List<WalletModel>>(() {
  return WalletsNotifier();
});

// --- Transactions Provider ---
class TransactionsNotifier extends Notifier<List<TransactionModel>> {
  @override
  List<TransactionModel> build() {
    final now = DateTime.now();
    return [
      // Today Dynamic Transactions
      TransactionModel(
        id: 't_today_1',
        title: 'Pembayaran Project Freelance',
        category: 'Freelance',
        amount: 350000,
        date: DateTime(now.year, now.month, now.day, 10, 15),
        type: 'income',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't_today_2',
        title: 'Makan Siang Bento',
        category: 'Makan',
        amount: 45000,
        date: DateTime(now.year, now.month, now.day, 12, 30),
        type: 'expense',
        walletId: 'w2',
      ),
      TransactionModel(
        id: 't_today_3',
        title: 'Kopi Susu Gula Aren',
        category: 'Makan',
        amount: 25000,
        date: DateTime(now.year, now.month, now.day, 15, 45),
        type: 'expense',
        walletId: 'w2',
      ),
      // Historical Transactions
      TransactionModel(
        id: 't1',
        title: 'Makan Siang Bakso',
        category: 'Makan',
        amount: 45000,
        date: DateTime(2026, 6, 14, 12, 30),
        type: 'expense',
        walletId: 'w2',
      ),
      TransactionModel(
        id: 't2',
        title: 'Gojek ke Kantor',
        category: 'Transport',
        amount: 25000,
        date: DateTime(2026, 6, 14, 8, 15),
        type: 'expense',
        walletId: 'w2',
      ),
      TransactionModel(
        id: 't3',
        title: 'Beli Kopi Susu',
        category: 'Makan',
        amount: 30000,
        date: DateTime(2026, 6, 13, 15, 0),
        type: 'expense',
        walletId: 'w2',
      ),
      TransactionModel(
        id: 't4',
        title: 'Project Freelance UI',
        category: 'Freelance',
        amount: 3500000,
        date: DateTime(2026, 6, 13, 10, 0),
        type: 'income',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't5',
        title: 'Makan Malam Sushi',
        category: 'Makan',
        amount: 180000,
        date: DateTime(2026, 6, 12, 19, 30),
        type: 'expense',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't6',
        title: 'Bensin Pertamax',
        category: 'Transport',
        amount: 150000,
        date: DateTime(2026, 6, 11, 14, 20),
        type: 'expense',
        walletId: 'w4',
      ),
      TransactionModel(
        id: 't7',
        title: 'Tagihan Listrik PLN',
        category: 'Tagihan',
        amount: 450000,
        date: DateTime(2026, 6, 10, 9, 0),
        type: 'expense',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't8',
        title: 'Nonton Bioskop',
        category: 'Hiburan',
        amount: 120000,
        date: DateTime(2026, 6, 8, 18, 0),
        type: 'expense',
        walletId: 'w2',
      ),
      TransactionModel(
        id: 't9',
        title: 'Top up Reksa Dana',
        category: 'Investasi',
        amount: 1000000,
        date: DateTime(2026, 6, 5, 11, 0),
        type: 'transfer',
        walletId: 'w1',
        targetWalletId: 'w3',
      ),
      TransactionModel(
        id: 't10',
        title: 'Gaji Bulanan',
        category: 'Gaji',
        amount: 15000000,
        date: DateTime(2026, 6, 1, 9, 0),
        type: 'income',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't11',
        title: 'Internet IndiHome',
        category: 'Tagihan',
        amount: 350000,
        date: DateTime(2026, 6, 1, 10, 0),
        type: 'expense',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't12',
        title: 'Makan Pagi Bubur',
        category: 'Makan',
        amount: 15000,
        date: DateTime(2026, 6, 7, 7, 30),
        type: 'expense',
        walletId: 'w4',
      ),
      TransactionModel(
        id: 't13',
        title: 'Belanja Bulanan Supermarket',
        category: 'Belanja',
        amount: 850000,
        date: DateTime(2026, 6, 3, 16, 0),
        type: 'expense',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't14',
        title: 'Beli Buku Keuangan',
        category: 'Belanja',
        amount: 120000,
        date: DateTime(2026, 6, 6, 14, 0),
        type: 'expense',
        walletId: 'w2',
      ),
      TransactionModel(
        id: 't15',
        title: 'Hasil Dividen Saham',
        category: 'Investasi',
        amount: 250000,
        date: DateTime(2026, 6, 10, 10, 0),
        type: 'income',
        walletId: 'w1',
      ),

      // May 2026
      TransactionModel(
        id: 't16',
        title: 'Makan Malam Seafood',
        category: 'Makan',
        amount: 250000,
        date: DateTime(2026, 5, 28, 20, 0),
        type: 'expense',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't17',
        title: 'Gojek Perjalanan Pulang',
        category: 'Transport',
        amount: 35000,
        date: DateTime(2026, 5, 28, 18, 30),
        type: 'expense',
        walletId: 'w2',
      ),
      TransactionModel(
        id: 't18',
        title: 'Project Website Landing Page',
        category: 'Freelance',
        amount: 4000000,
        date: DateTime(2026, 5, 25, 13, 0),
        type: 'income',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't19',
        title: 'Belanja Baju',
        category: 'Belanja',
        amount: 450000,
        date: DateTime(2026, 5, 20, 15, 0),
        type: 'expense',
        walletId: 'w2',
      ),
      TransactionModel(
        id: 't20',
        title: 'Makan Siang Ramen',
        category: 'Makan',
        amount: 85000,
        date: DateTime(2026, 5, 20, 12, 15),
        type: 'expense',
        walletId: 'w2',
      ),
      TransactionModel(
        id: 't21',
        title: 'Bensin Mobil',
        category: 'Transport',
        amount: 300000,
        date: DateTime(2026, 5, 15, 10, 0),
        type: 'expense',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't22',
        title: 'Subscription Netflix',
        category: 'Tagihan',
        amount: 186000,
        date: DateTime(2026, 5, 15, 6, 0),
        type: 'expense',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't23',
        title: 'Makan Siang Warteg',
        category: 'Makan',
        amount: 25000,
        date: DateTime(2026, 5, 10, 12, 0),
        type: 'expense',
        walletId: 'w4',
      ),
      TransactionModel(
        id: 't24',
        title: 'Gaji Bulanan',
        category: 'Gaji',
        amount: 15000000,
        date: DateTime(2026, 5, 1, 9, 0),
        type: 'income',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't25',
        title: 'Internet IndiHome',
        category: 'Tagihan',
        amount: 350000,
        date: DateTime(2026, 5, 1, 10, 0),
        type: 'expense',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't26',
        title: 'Beli Kopi Latte',
        category: 'Makan',
        amount: 35000,
        date: DateTime(2026, 5, 5, 16, 0),
        type: 'expense',
        walletId: 'w2',
      ),
      TransactionModel(
        id: 't27',
        title: 'Top up Bibit',
        category: 'Investasi',
        amount: 1500000,
        date: DateTime(2026, 5, 5, 11, 0),
        type: 'transfer',
        walletId: 'w1',
        targetWalletId: 'w3',
      ),
      TransactionModel(
        id: 't28',
        title: 'Konser Musik',
        category: 'Hiburan',
        amount: 750000,
        date: DateTime(2026, 5, 12, 19, 0),
        type: 'expense',
        walletId: 'w1',
      ),
      TransactionModel(
        id: 't29',
        title: 'Beli Kaos Polos',
        category: 'Belanja',
        amount: 150000,
        date: DateTime(2026, 5, 18, 14, 0),
        type: 'expense',
        walletId: 'w4',
      ),
      TransactionModel(
        id: 't30',
        title: 'Jual Bitcoin Untung',
        category: 'Investasi',
        amount: 1200000,
        date: DateTime(2026, 5, 22, 10, 0),
        type: 'income',
        walletId: 'w1',
      ),
    ];
  }

  void addTransaction(TransactionModel transaction) {
    state = [transaction, ...state];
    
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
  }
}

final transactionsProvider = NotifierProvider<TransactionsNotifier, List<TransactionModel>>(() {
  return TransactionsNotifier();
});
