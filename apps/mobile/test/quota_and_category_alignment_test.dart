import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/institutions/institution_registry.dart';
import 'package:mobile/core/models/transaction_category_model.dart';
import 'package:mobile/core/models/transaction_model.dart';
import 'package:mobile/core/models/wallet_model.dart';
import 'package:mobile/core/providers/ai_quota_provider.dart';
import 'package:mobile/core/providers/mock_providers.dart';
import 'package:mobile/core/services/local_storage_service.dart';
import 'package:mobile/core/utils/ai_category_normalizer.dart';
import 'package:mobile/features/budget/presentation/providers/finance_providers.dart';
import 'package:mobile/features/home/presentation/widgets/gmail_drafts_prompt_sheet.dart';
import 'package:mobile/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_saas_plan_card.dart';
import 'package:mobile/features/session/presentation/screens/quick_action_sheets.dart';
import 'package:mobile/features/transaction/presentation/screens/ai_draft_review_screen.dart';
import 'package:mobile/shared/widgets/saas_upgrade_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _createAuthenticatedContainer() async {
  final userMap = {
    'id': 'u_test_32',
    'name': 'Raka Tester',
    'email': 'raka@clarafin.test',
    'password': 'secret',
    'avatarUrl': 'assets/images/avatars/avatar_1.png',
  };
  SharedPreferences.setMockInitialValues({
    'clarafin_registered_accounts': [jsonEncode(userMap)],
    'clarafin_is_logged_in': true,
    'clarafin_active_user_id': 'u_test_32',
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
}

Set<String> _collectVerbatimCategories() {
  final valid = <String>{'Transfer'};
  for (final cat in [
    ...TransactionCategories.expenseCategories,
    ...TransactionCategories.incomeCategories,
  ]) {
    valid.add(cat.name);
    for (final sub in cat.subcategories) {
      valid.add('${cat.name} • ${sub.name}');
    }
  }
  return valid;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Task 3.2: InstitutionRegistry Alignment', () {
    test('includes jago and jenius matching Go catalog', () {
      final jago = InstitutionRegistry.findById('jago');
      final jenius = InstitutionRegistry.findById('jenius');

      expect(jago, isNotNull);
      expect(jago!.name, equals('Bank Jago'));
      expect(jago.type, equals('Bank'));

      expect(jenius, isNotNull);
      expect(jenius!.type, equals('Bank'));
      expect(jenius.shortName, equals('Jenius'));

      expect(
        InstitutionRegistry.findByWallet(name: 'Bank Jago', type: 'Bank').id,
        equals('jago'),
      );
      expect(
        InstitutionRegistry.findByWallet(name: 'Kantong Jago', type: 'Bank').id,
        equals('jago'),
      );
      expect(
        InstitutionRegistry.findByWallet(name: 'Jenius', type: 'Bank').id,
        equals('jenius'),
      );
      expect(
        InstitutionRegistry.findByWallet(name: 'BTPN Jenius', type: 'Bank').id,
        equals('jenius'),
      );
      expect(
        InstitutionRegistry.findByWallet(
          name: 'blu by BCA Digital',
          type: 'Bank',
        ).id,
        equals('blu'),
      );
      expect(InstitutionRegistry.findById('seabank'), isNotNull);
      expect(InstitutionRegistry.findById('cimb'), isNotNull);
      expect(InstitutionRegistry.findById('permata'), isNotNull);
    });
  });

  group('Task 3.2: Canonical Category Normalization & Budget Sync', () {
    test('normalizes colloquialisms and verbatim categories accurately', () {
      final verbatimSet = _collectVerbatimCategories();

      final samples = <String, String>{
        'Makanan': 'Food & Beverage',
        'kopi kenangan': 'Food & Beverage • Coffee Shop',
        'GoFood': 'Food & Beverage • Food delivery',
        'Bensin': 'Transportation • Fuel & Gas',
        'Listrik PLN': 'Bills & Utilities • Electricity / Listrik PLN',
        'Gaji': 'Income • Salary',
        'Belanja': 'Shopping',
        'unknown_category_xyz': 'Others • General Uncategorized',
        'Botol Air Mineral': 'Food & Beverage',
      };

      for (final entry in samples.entries) {
        final got = AiCategoryNormalizer.normalize(entry.key);
        expect(got, equals(entry.value), reason: 'Input: ${entry.key}');
        expect(
          verbatimSet.contains(got),
          isTrue,
          reason: '$got must be verbatim in TransactionCategories',
        );
      }
    });

    test('enforces strict type isolation when isIncome is true', () {
      expect(
        AiCategoryNormalizer.normalize('Gaji', isIncome: true),
        equals('Income • Salary'),
      );
      expect(
        AiCategoryNormalizer.normalize('Other Income', isIncome: true),
        equals('Income • Additional Income'),
      );
      expect(
        AiCategoryNormalizer.normalize('Hadiah', isIncome: true),
        equals('Gift'),
      );
      expect(
        AiCategoryNormalizer.normalize('Hadiah'),
        equals('Donations & Gifts • Gifts & Presents'),
      );
      // Income mode must never leak into expense categories.
      expect(
        AiCategoryNormalizer.normalize('Kopi Kenangan', isIncome: true),
        equals('Income • Additional Income'),
      );
      expect(
        AiCategoryNormalizer.normalize(
          'Others',
          isIncome: true,
          contextHint: 'Kopi Kenangan',
        ),
        equals('Income • Additional Income'),
      );
    });

    test('normalizeBudgetCategory maps to top-level categories and syncs with syncedBudgetsProvider', () async {
      expect(
        AiCategoryNormalizer.normalizeBudgetCategory('Food & Beverage • Coffee Shop'),
        equals('Food & Beverage'),
      );
      expect(
        AiCategoryNormalizer.normalizeBudgetCategory('Makanan'),
        equals('Food & Beverage'),
      );
      expect(
        AiCategoryNormalizer.normalizeBudgetCategory('kopi kenangan'),
        equals('Food & Beverage'),
      );
      expect(
        AiCategoryNormalizer.normalizeBudgetCategory('Belanja'),
        equals('Shopping'),
      );

      final container = await _createAuthenticatedContainer();
      addTearDown(container.dispose);

      container.read(walletsProvider.notifier).addWallet(
            WalletModel(
              id: 'w_jago',
              name: 'Bank Jago',
              type: 'Bank',
              balance: 2000000,
              institutionId: 'jago',
            ),
          );

      container.read(budgetsProvider.notifier).addBudget(
            BudgetCategoryModel(
              id: 'b_fnb',
              name: AiCategoryNormalizer.normalizeBudgetCategory('Makanan'),
              totalAmount: 1000000,
              spentAmount: 0,
              icon: Icons.restaurant,
              iconColor: Colors.orange,
              iconBgColor: Colors.orange.shade100,
            ),
          );

      final now = DateTime.now();
      container.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: 't1',
              title: 'Kopi Kenangan',
              category: AiCategoryNormalizer.normalize('kopi kenangan'),
              amount: 28000,
              date: now,
              type: 'expense',
              walletId: 'w_jago',
            ),
          );
      container.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: 't2',
              title: 'GoFood Malam',
              category: AiCategoryNormalizer.normalize('GoFood'),
              amount: 48000,
              date: now,
              type: 'expense',
              walletId: 'w_jago',
            ),
          );
      container.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: 't3',
              title: 'Tokopedia',
              category: AiCategoryNormalizer.normalize('Belanja'),
              amount: 385000,
              date: now,
              type: 'expense',
              walletId: 'w_jago',
            ),
          );

      final synced = container.read(syncedBudgetsProvider);
      expect(synced.length, equals(1));
      expect(synced.first.name, equals('Food & Beverage'));
      expect(synced.first.spentAmount, equals(76000.0));
    });
  });

  group('Task 3.2: Single-Source AI Quota & Zero Legacy Limit References', () {
    test('aiQuotaProvider transitions free (40) -> pro_monthly (400) -> unlimited (-1)', () async {
      final container = await _createAuthenticatedContainer();
      addTearDown(container.dispose);

      var quota = container.read(aiQuotaProvider);
      expect(quota.planType, equals('free'));
      expect(quota.quotaTotal, equals(40));
      expect(quota.quotaRemaining, equals(40));
      expect(quota.isUnlimited, isFalse);

      container.read(aiQuotaProvider.notifier).useQuota();
      quota = container.read(aiQuotaProvider);
      expect(quota.quotaRemaining, equals(39));

      container.read(aiQuotaProvider.notifier).upgradePlan('pro_monthly');
      quota = container.read(aiQuotaProvider);
      expect(quota.planType, equals('pro_monthly'));
      expect(quota.quotaTotal, equals(400));
      expect(quota.quotaRemaining, equals(400));
      expect(quota.isUnlimited, isFalse);

      container.read(aiQuotaProvider.notifier).upgradePlan('unlimited');
      quota = container.read(aiQuotaProvider);
      expect(quota.planType, equals('unlimited'));
      expect(quota.quotaTotal, equals(-1));
      expect(quota.isUnlimited, isTrue);
      expect(quota.displayQuotaBadge, equals('Unlimited'));

      container.read(aiQuotaProvider.notifier).useQuota();
      expect(container.read(aiQuotaProvider).quotaTotal, equals(-1));
    });

    test('no references to quickActionLimitProvider remain in lib', () {
      final libDir = Directory('lib');
      final offending = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          if (content.contains('quickActionLimitProvider') ||
              content.contains('QuickActionLimitNotifier') ||
              content.contains('QuickActionLimitState')) {
            offending.add(entity.path);
          }
        }
      }
      expect(offending, isEmpty, reason: 'Found legacy quota symbols in: $offending');
    });
  });

  group('Task 3.2: Upgrade Sheet, Quick Actions, & Draft Review Widgets', () {
    testWidgets('ProfileSaasPlanCard shows Rp 49.000 and opens multi-tier SaasUpgradeBottomSheet on 360px viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = await _createAuthenticatedContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: ProfileSaasPlanCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upgrade ke Pro (Rp 49.000 / bln)'), findsOneWidget);
      expect(find.textContaining('29.000'), findsNothing);

      await tester.tap(find.text('Upgrade ke Pro (Rp 49.000 / bln)'));
      await tester.pumpAndSettle();

      expect(find.byType(SaasUpgradeBottomSheet), findsOneWidget);
      expect(find.textContaining('49.000'), findsWidgets);
      expect(find.textContaining('99.000'), findsWidgets);

      await tester.ensureVisible(find.text('Pilih Paket Unlimited'));
      await tester.tap(find.text('Pilih Paket Unlimited'));
      await tester.pumpAndSettle();

      expect(container.read(aiQuotaProvider).planType, equals('unlimited'));
      expect(container.read(aiQuotaProvider).isUnlimited, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('QuickActionMenuSheet triggers SaasUpgradeBottomSheet when aiQuotaProvider is exhausted', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = await _createAuthenticatedContainer();
      container.read(userProfileProvider.notifier).setAiQuotaRemaining(0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showQuickActionMenuSheet(context, ref),
                  child: const Text('Buka Quick Action'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Quick Action'));
      await tester.pumpAndSettle();

      expect(find.text('AI Kuota: 0/40'), findsNWidgets(3));

      await tester.tap(find.text('Voice AI Action'));
      await tester.pumpAndSettle();

      expect(find.byType(SaasUpgradeBottomSheet), findsOneWidget);
      expect(find.textContaining('Voice AI Action'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    test('GmailDraftsPromptSheet uses canonical categories', () {
      final verbatimSet = _collectVerbatimCategories();
      final categories = GmailDraftsPromptSheet.mockGmailDrafts
          .map((d) => d['category'] as String)
          .toList();
      expect(categories, contains('Shopping'));
      expect(categories, contains('Food & Beverage • Food delivery'));
      for (final c in categories) {
        expect(verbatimSet.contains(c), isTrue, reason: '$c must be canonical');
      }
    });

    testWidgets('AiDraftReviewScreen reads GoRouter extra prefillItems and saves canonical transaction', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = await _createAuthenticatedContainer();
      container.read(walletsProvider.notifier).addWallet(
            WalletModel(
              id: 'w_jago',
              name: 'Bank Jago',
              type: 'Bank',
              balance: 1500000,
              institutionId: 'jago',
            ),
          );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push(
                  '/draft/review',
                  extra: {
                    'prefillItems': [
                      {
                        'title': 'Kopi Kenangan Tebet',
                        'amount': 28000,
                        'isExpense': true,
                        'category': 'kopi kenangan',
                        'walletId': 'w_jago',
                        'walletName': 'Bank Jago',
                      },
                    ],
                  },
                ),
                child: const Text('Review Draft'),
              ),
            ),
          ),
          GoRoute(
            path: '/draft/review',
            builder: (context, state) => const AiDraftReviewScreen(),
          ),
          GoRoute(
            path: '/transaction/history',
            builder: (context, state) => const Scaffold(body: Text('History')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review Draft'));
      await tester.pumpAndSettle();

      expect(find.text('Kopi Kenangan Tebet'), findsOneWidget);
      expect(find.text('28.000'), findsOneWidget);
      expect(find.text('Food & Beverage • Coffee Shop'), findsOneWidget);

      await tester.ensureVisible(find.text('Konfirmasi & Simpan'));
      await tester.tap(find.text('Konfirmasi & Simpan'));
      await tester.pumpAndSettle();

      final txs = container.read(transactionsProvider);
      expect(txs.length, equals(1));
      expect(txs.first.title, equals('Kopi Kenangan Tebet'));
      expect(txs.first.category, equals('Food & Beverage • Coffee Shop'));
      expect(txs.first.walletId, equals('w_jago'));

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('GmailDraftsPromptSheet navigates to /draft/review with 2 canonical prefillItems', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = await _createAuthenticatedContainer();
      container.read(walletsProvider.notifier).addWallet(
            WalletModel(
              id: 'w_bca',
              name: 'BCA Rekening Utama',
              type: 'Bank',
              balance: 5000000,
              institutionId: 'bca',
            ),
          );
      container.read(walletsProvider.notifier).addWallet(
            WalletModel(
              id: 'w_gopay',
              name: 'GoPay Utama',
              type: 'E-Wallet',
              balance: 500000,
              institutionId: 'gopay',
            ),
          );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => GmailDraftsPromptSheet.show(context),
                child: const Text('Buka Gmail Drafts'),
              ),
            ),
          ),
          GoRoute(
            path: '/draft/review',
            builder: (context, state) => const AiDraftReviewScreen(),
          ),
          GoRoute(
            path: '/transaction/history',
            builder: (context, state) => const Scaffold(body: Text('History')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Gmail Drafts'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Tinjau Rinci di AI Draft Review'));
      await tester.tap(find.text('Tinjau Rinci di AI Draft Review'));
      await tester.pumpAndSettle();

      expect(find.text('2 Transaksi Terdeteksi'), findsOneWidget);
      expect(find.text('Tokopedia Official Store'), findsOneWidget);
      expect(find.text('Draf 1'), findsOneWidget);
      expect(find.text('Draf 2'), findsOneWidget);

      await tester.tap(find.text('Draf 2'));
      await tester.pumpAndSettle();

      expect(find.text('GoFood - Kopi & Makan Malam'), findsOneWidget);
      expect(find.text('Food & Beverage • Food delivery'), findsOneWidget);

      await tester.ensureVisible(find.text('Konfirmasi & Simpan (2)'));
      await tester.tap(find.text('Konfirmasi & Simpan (2)'));
      await tester.pumpAndSettle();

      final txs = container.read(transactionsProvider);
      expect(txs.length, equals(2));
      expect(txs.map((t) => t.category).toSet(), equals({'Shopping', 'Food & Beverage • Food delivery'}));
      expect(txs.map((t) => t.walletId).toSet(), equals({'w_bca', 'w_gopay'}));

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
  });
}
