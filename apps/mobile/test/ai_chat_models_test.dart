import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/session/domain/models/ai_chat_models.dart';

void main() {
  group('AiSurfaceMode', () {
    test('exposes backend apiValue and parses wire strings safely', () {
      expect(AiSurfaceMode.quickSheet.apiValue, equals('quick_sheet'));
      expect(AiSurfaceMode.fullScreen.apiValue, equals('full_screen'));
      expect(
        AiSurfaceMode.fromApiValue('full_screen'),
        equals(AiSurfaceMode.fullScreen),
      );
      expect(
        AiSurfaceMode.fromApiValue('quick_sheet'),
        equals(AiSurfaceMode.quickSheet),
      );
      expect(
        AiSurfaceMode.fromApiValue(null),
        equals(AiSurfaceMode.quickSheet),
      );
    });
  });

  group('UnifiedAiChatMessage SSE final_response deserialization', () {
    test('parses complete multimodal SSE payload with all card types', () {
      final payload = <String, dynamic>{
        'id': 'msg-001',
        'session_id': 'sess-abc',
        'narrative': 'Berikut ringkasan keuangan Oktober 2026 dan opsi tindakanmu.',
        'is_user': false,
        'timestamp': '2026-10-31T10:15:30Z',
        'thinking_summary': {
          'duration_ms': 1420,
          'is_live': false,
          'steps': [
            {
              'id': 'step-1',
              'label': 'Memeriksa dompet aktif',
              'detail': 'BCA dan GoPay terdeteksi',
              'is_done': true,
            },
            {
              'id': 'step-2',
              'label': 'Menghitung arus kas Oktober 2026',
              'is_done': true,
            },
          ],
        },
        'money_flow_card': {
          'period_label': 'Okt 2026',
          'total_income': 10320000,
          'total_expense': 5942000,
          'net_cashflow': 4378000,
          'transaction_count': 67,
          'income_sources': [
            {
              'label': 'Gaji',
              'amount': 10230000,
              'color_hex': '#10B981',
              'percentage': 99.1,
            },
            {
              'label': 'Bunga',
              'amount': 90000,
              'color_hex': '#0F758A',
              'percentage': 0.9,
            },
          ],
          'expense_categories': [
            {
              'label': 'Kos / Sewa',
              'amount': 2450000,
              'color_hex': '#F59E0B',
              'percentage': 41.2,
            },
            {
              'label': 'Makan Luar',
              'amount': 3492000,
              'color_hex': '#DC2626',
              'percentage': 58.8,
            },
          ],
          'flows': [
            {'source_index': 0, 'target_index': 0, 'amount': 2450000},
            {'source_index': 0, 'target_index': 1, 'amount': 3402000},
            {'source_index': 1, 'target_index': 1, 'amount': 90000},
          ],
          'breakdown_summary': 'Kos / Sewa menjadi pos pengeluaran terbesar (41.2%).',
        },
        'spending_breakdown_table_card': {
          'title': 'Rincian pengeluaran kopi (1-31 Okt 2026)',
          'rows': [
            {
              'merchant': 'Kopi Kenangan',
              'transaction_count': 9,
              'total_amount': 195000,
            },
            {
              'merchant': 'Fore Coffee',
              'tx_count': 3,
              'total_amount': 84000,
            },
          ],
          'total_amount': 279000,
          'total_transactions': 12,
          'footnote': 'Dibayar lewat GoPay dan BCA pada kategori Food & Beverage.',
        },
        'wallet_creation_draft_card': {
          'institution_id': 'jago',
          'institution_name': 'Bank Jago',
          'wallet_type': 'bank',
          'existing_wallet_ids': ['w-bca', 'w-gopay'],
          'initial_balance': 500000,
          'is_created': false,
        },
        'transaction_draft_card': {
          'client_mutation_id': 'mut-tx-01',
          'items': [
            {
              'title': 'Kopi Kenangan',
              'amount_idr': 28000,
              'type': 'expense',
              'canonical_category': 'Food & Beverage • Coffee Shop',
              'wallet_id': 'w-gopay',
              'wallet_name': 'GoPay',
              'occurred_at': '2026-10-31T08:30:00Z',
            },
            {
              'title': 'GoRide Stasiun',
              'amount': 15000,
              'type': 'expense',
              'category': 'Transportation • Ride Hailing / Taxi',
              'wallet_id': 'w-gopay',
              'wallet_name': 'GoPay',
              'occurred_at': '2026-10-31T08:45:00Z',
            },
          ],
        },
        'goal_draft': {
          'client_mutation_id': 'mut-goal-01',
          'name': 'Dana Nikah',
          'target_amount': 50000000,
          'deadline': '2027-12-31',
          'linked_wallet_id': 'w-bca',
          'monthly_saving_estimate': 3571429,
        },
        'budget_draft': {
          'client_mutation_id': 'mut-budget-01',
          'category': 'Food & Beverage',
          'limit_amount': 1500000,
          'avg_30d_spend': 1850000,
          'is_update': true,
        },
        'bill_draft': {
          'client_mutation_id': 'mut-bill-01',
          'title': 'Indihome',
          'amount': 385000,
          'due_day': 20,
          'due_date': '2026-11-20',
          'frequency': 'monthly',
          'category': 'Bills & Utilities • Internet & WiFi',
        },
        'recommended_package': {
          'package_code': 'couple_pre_marriage',
          'category_tag': 'Couple Advisory • Pre-Marriage',
          'package_title': 'Siap Menikah Tanpa Drama Finansial',
          'price_idr': 349000,
          'duration_minutes': 60,
          'session_count': 1,
        },
        'recommended_consultants': [
          {
            'consultant_id': 'c1',
            'name': 'Chrysan Gomargana, S.E., CFP®',
            'certifications': ['CFP®'],
            'avatar_url': 'https://example.com/c1.jpg',
            'tier_label': 'Medium',
            'rating_avg': 4.95,
            'total_sessions_completed': 380,
            'match_reason': 'Spesialis keuangan pranikah dan manajemen kas',
            'next_available_slot_at': '2026-11-01T19:00:00+07:00',
            'next_available_slot_label': 'Besok, 19:00 WIB',
            'is_staff_pinned': true,
            'selected_package_code': 'couple_pre_marriage',
            'unit_price': 349000,
            'recommended_topics': ['Keuangan Pranikah', 'Dana Nikah'],
            'prefilled_description': 'Ingin menyusun dana nikah Rp 50 jt.',
            'prefilled_expectations': 'Pembagian rekening pasutri yang adil.',
          },
        ],
      };

      final msg = UnifiedAiChatMessage.fromJson(payload);

      expect(msg.id, equals('msg-001'));
      expect(msg.sessionId, equals('sess-abc'));
      expect(
        msg.text,
        equals('Berikut ringkasan keuangan Oktober 2026 dan opsi tindakanmu.'),
      );
      expect(msg.isUser, isFalse);

      expect(msg.thinkingTrace, isNotNull);
      expect(msg.thinkingTrace!.durationMs, equals(1420));
      expect(msg.thinkingTrace!.isLive, isFalse);
      expect(msg.thinkingTrace!.steps.length, equals(2));
      expect(msg.thinkingTrace!.steps.first.detail, equals('BCA dan GoPay terdeteksi'));

      expect(msg.moneyFlowCard, isNotNull);
      expect(msg.moneyFlowCard!.periodLabel, equals('Okt 2026'));
      expect(msg.moneyFlowCard!.totalIncome, equals(10320000.0));
      expect(msg.moneyFlowCard!.totalExpense, equals(5942000.0));
      expect(msg.moneyFlowCard!.netCashflow, equals(4378000.0));
      expect(msg.moneyFlowCard!.transactionCount, equals(67));
      expect(msg.moneyFlowCard!.incomeSources.length, equals(2));
      expect(msg.moneyFlowCard!.expenseCategories.length, equals(2));
      expect(msg.moneyFlowCard!.flows.length, equals(3));

      expect(msg.spendingTableCard, isNotNull);
      expect(msg.spendingTableCard!.rows.length, equals(2));
      expect(msg.spendingTableCard!.rows[0].merchant, equals('Kopi Kenangan'));
      expect(msg.spendingTableCard!.rows[1].transactionCount, equals(3));
      expect(msg.spendingTableCard!.totalAmount, equals(279000.0));
      expect(msg.spendingTableCard!.totalTransactions, equals(12));

      expect(msg.walletCreationDraft, isNotNull);
      expect(msg.walletCreationDraft!.institutionId, equals('jago'));
      expect(msg.walletCreationDraft!.institutionName, equals('Bank Jago'));
      expect(msg.walletCreationDraft!.existingWalletIds, equals(['w-bca', 'w-gopay']));
      expect(msg.walletCreationDraft!.initialBalance, equals(500000.0));

      expect(msg.transactionDraftGroup, isNotNull);
      expect(msg.transactionDraftGroup!.clientMutationId, equals('mut-tx-01'));
      expect(msg.transactionDraftGroup!.items.length, equals(2));
      expect(msg.transactionDraftGroup!.items[0].title, equals('Kopi Kenangan'));
      expect(msg.transactionDraftGroup!.items[0].amount, equals(28000.0));
      expect(msg.transactionDraftGroup!.items[1].canonicalCategory, equals('Transportation • Ride Hailing / Taxi'));

      expect(msg.goalDraft, isNotNull);
      expect(msg.goalDraft!.name, equals('Dana Nikah'));
      expect(msg.goalDraft!.targetAmount, equals(50000000.0));
      expect(msg.goalDraft!.monthlySavingEstimate, equals(3571429.0));

      expect(msg.budgetDraft, isNotNull);
      expect(msg.budgetDraft!.category, equals('Food & Beverage'));
      expect(msg.budgetDraft!.limitAmount, equals(1500000.0));
      expect(msg.budgetDraft!.avg30dSpend, equals(1850000.0));
      expect(msg.budgetDraft!.isUpdate, isTrue);

      expect(msg.billDraft, isNotNull);
      expect(msg.billDraft!.title, equals('Indihome'));
      expect(msg.billDraft!.dueDay, equals(20));
      expect(msg.billDraft!.frequency, equals('monthly'));

      expect(msg.recommendedPackage, isNotNull);
      expect(msg.recommendedPackage!.packageCode, equals('couple_pre_marriage'));
      expect(msg.recommendedPackage!.priceIdr, equals(349000.0));

      expect(msg.recommendedConsultants.length, equals(1));
      expect(msg.recommendedConsultants.first.consultantId, equals('c1'));
      expect(msg.recommendedConsultants.first.isStaffPinned, isTrue);
      expect(msg.recommendedConsultants.first.recommendedTopics, equals(['Keuangan Pranikah', 'Dana Nikah']));
    });

    test('parses single-object transaction_draft and transaction type/category aliases cleanly', () {
      final singleDraftPayload = <String, dynamic>{
        'id': 'msg-single',
        'session_id': 'sess-1',
        'text': 'Saya siapkan draf transaksi.',
        'client_mutation_id': 'mut-top-level',
        'transaction_draft': {
          'title': 'Gaji Bulanan',
          'amount': 8500000,
          'type': 'income',
          'category': 'Income • Salary',
          'wallet_id': 'w-bca',
          'wallet_name': 'BCA',
        },
      };

      final msg = UnifiedAiChatMessage.fromJson(singleDraftPayload);
      expect(msg.transactionDraftGroup, isNotNull);
      expect(msg.transactionDraftGroup!.clientMutationId, equals('mut-top-level'));
      expect(msg.transactionDraftGroup!.items.length, equals(1));

      final item = msg.transactionDraftGroup!.items.first;
      expect(item.title, equals('Gaji Bulanan'));
      expect(item.amount, equals(8500000.0));
      expect(item.type, equals('income'));
      expect(item.canonicalCategory, equals('Income • Salary'));
      expect(item.walletId, equals('w-bca'));
      expect(item.walletName, equals('BCA'));
      expect(item.occurredAt, isA<DateTime>());

      final transferItem = AiTransactionDraftItem.fromJson({
        'title': 'Topup GoPay',
        'amount_idr': '100000',
        'type': 'transfer',
        'wallet_id': 'w-bca',
        'wallet_name': 'BCA',
        'target_wallet_id': 'w-gopay',
      });
      expect(transferItem.type, equals('transfer'));
      expect(transferItem.amount, equals(100000.0));
      expect(transferItem.targetWalletId, equals('w-gopay'));
      expect(transferItem.canonicalCategory, equals('Transfer'));
    });

    test('handles Go tool payloads and missing optional fields without null-cast crashes', () {
      final emptyMsg = UnifiedAiChatMessage.fromJson(<String, dynamic>{});
      expect(emptyMsg.id, equals(''));
      expect(emptyMsg.text, equals(''));
      expect(emptyMsg.isUser, isFalse);
      expect(emptyMsg.recommendedConsultants, isEmpty);
      expect(emptyMsg.moneyFlowCard, isNull);
      expect(emptyMsg.transactionDraftGroup, isNull);

      final goCompatible = UnifiedAiChatMessage.fromJson({
        'narrative': 'Cek aliran kas dan rekomendasi konsultan.',
        'thinking_summary': 'Menganalisa 2 dompet dan jadwal praktisi',
        'money_flow_card': {
          'period_label': 'November 2026',
          'total_income_idr': 10000000,
          'total_expense_idr': 4000000,
          'income_sources': [
            {'category': 'Salary', 'amount': 10000000, 'share_pct': 100.0},
          ],
          'expense_categories': [
            {'category': 'Food & Beverage', 'amount': 4000000, 'share_pct': 100.0},
          ],
          'flow_edges': [
            {
              'source_category': 'Salary',
              'target_category': 'Food & Beverage',
              'flow_amount': 4000000,
            },
          ],
        },
        'wallet_creation_draft': {
          'institution_id': 'jenius',
          'institution_name': 'Jenius',
          'institution_type': 'bank',
          'existing_wallets': [
            {'id': 'w-1', 'name': 'BCA'},
            {'id': 'w-2', 'name': 'GoPay'},
          ],
        },
        'recommended_package': {
          'package_code': 'personal_basic',
          'selected_tier_label': 'Personal Advisory • Basic',
          'package_title': 'Fondasi Arus Kas & Utang',
          'online_price_idr': 199000,
          'online_duration_minutes': 60,
          'recommended_method': 'Online',
        },
        'prefilled_intake_summary': {
          'recommended_topics': ['Arus Kas', 'Utang'],
          'prefilled_description': 'Butuh merapikan cashflow bulanan.',
          'prefilled_expectations': 'Punya rencana aksi 30 hari.',
        },
        'recommended_consultants': [
          {
            'consultant_id': 'c3',
            'display_name': 'Rian Pratama, S.Ak., QWP®, AWP®',
            'certifications': ['QWP®', 'AWP®'],
            'tier': 'Basic',
            'rating': 4.88,
            'total_sessions_completed': 190,
            'match_reason': 'Cocok untuk fondasi arus kas',
            'next_available_slot_iso': '2026-11-18T10:00:00+07:00',
            'next_available_slot_label': 'Besok, 10:00 WIB',
            'package_code': 'personal_basic',
            'online_price_idr': 199000,
          },
        ],
      });

      expect(goCompatible.thinkingTrace?.steps.first.label, equals('Menganalisa 2 dompet dan jadwal praktisi'));
      expect(goCompatible.moneyFlowCard!.netCashflow, equals(6000000.0));
      expect(goCompatible.moneyFlowCard!.flows.first.sourceIndex, equals(0));
      expect(goCompatible.moneyFlowCard!.flows.first.targetIndex, equals(0));
      expect(goCompatible.moneyFlowCard!.flows.first.amount, equals(4000000.0));
      expect(goCompatible.walletCreationDraft!.walletType, equals('bank'));
      expect(goCompatible.walletCreationDraft!.existingWalletIds, equals(['w-1', 'w-2']));
      expect(goCompatible.recommendedPackage!.priceIdr, equals(199000.0));
      expect(goCompatible.recommendedConsultants.first.name, equals('Rian Pratama, S.Ak., QWP®, AWP®'));
      expect(goCompatible.recommendedConsultants.first.recommendedTopics, equals(['Arus Kas', 'Utang']));
    });
  });

  group('copyWith and toJson round-trip', () {
    test('updates mutable draft states cleanly via copyWith', () {
      const walletDraft = AiWalletCreationDraft(
        institutionId: 'jago',
        institutionName: 'Bank Jago',
        walletType: 'bank',
        existingWalletIds: ['w-bca'],
        initialBalance: 0,
      );
      final createdWallet = walletDraft.copyWith(
        initialBalance: 250000,
        isCreated: true,
        createdWalletId: 'w-jago-new',
      );
      expect(createdWallet.initialBalance, equals(250000.0));
      expect(createdWallet.isCreated, isTrue);
      expect(createdWallet.createdWalletId, equals('w-jago-new'));

      final txGroup = AiTransactionDraftGroup(
        clientMutationId: 'mut-1',
        items: [
          AiTransactionDraftItem(
            title: 'Kopi',
            amount: 28000,
            type: 'expense',
            canonicalCategory: 'Food & Beverage • Coffee Shop',
            walletId: 'w-gopay',
            walletName: 'GoPay',
            occurredAt: DateTime.utc(2026, 11, 1, 9, 0),
          ),
        ],
      );
      final submitting = txGroup.copyWith(isSubmitting: true);
      final confirmed = submitting.copyWith(isSubmitting: false, isConfirmed: true);
      expect(submitting.isSubmitting, isTrue);
      expect(confirmed.isSubmitting, isFalse);
      expect(confirmed.isConfirmed, isTrue);
      expect(confirmed.isCancelled, isFalse);

      final msg = UnifiedAiChatMessage(
        id: 'm1',
        sessionId: 's1',
        text: 'Draf siap',
        isUser: false,
        transactionDraftGroup: txGroup,
      );
      final updatedMsg = msg.copyWith(transactionDraftGroup: confirmed);
      final roundTrip = UnifiedAiChatMessage.fromJson(updatedMsg.toJson());
      expect(roundTrip.transactionDraftGroup?.isConfirmed, isTrue);
      expect(roundTrip.transactionDraftGroup?.items.first.title, equals('Kopi'));
    });
  });

  group('toCompactedHistoryText()', () {
    test('compacts confirmed transaction card to 1-line factual text', () {
      final msg = UnifiedAiChatMessage(
        id: 'm-tx',
        sessionId: 's1',
        text: 'Ini draf transaksi kopi kamu, silakan konfirmasi ya.',
        isUser: false,
        transactionDraftGroup: AiTransactionDraftGroup(
          clientMutationId: 'mut-tx',
          isConfirmed: true,
          items: [
            AiTransactionDraftItem(
              title: 'Kopi',
              amount: 28000,
              type: 'expense',
              canonicalCategory: 'Food & Beverage • Coffee Shop',
              walletId: 'w-gopay',
              walletName: 'GoPay',
              occurredAt: DateTime.utc(2026, 11, 1, 9, 0),
            ),
          ],
        ),
      );

      expect(
        msg.toCompactedHistoryText(),
        equals('[User mengonfirmasi draf: Kopi Rp 28.000 via GoPay]'),
      );
    });

    test('compacts created wallet, confirmed goal/budget/bill, and cancelled drafts', () {
      final walletMsg = UnifiedAiChatMessage(
        id: 'm-wallet',
        sessionId: 's1',
        text: 'Dompet Bank Jago belum ada.',
        isUser: false,
        walletCreationDraft: const AiWalletCreationDraft(
          institutionId: 'jago',
          institutionName: 'Bank Jago',
          walletType: 'bank',
          isCreated: true,
          createdWalletId: 'w-jago',
        ),
      );
      expect(
        walletMsg.toCompactedHistoryText(),
        equals('[User membuat dompet: Bank Jago]'),
      );

      final goalMsg = UnifiedAiChatMessage(
        id: 'm-goal',
        sessionId: 's1',
        text: 'Draf goal dana nikah siap.',
        isUser: false,
        goalDraft: const AiGoalDraft(
          clientMutationId: 'mut-g',
          name: 'Dana Nikah',
          targetAmount: 50000000,
          isConfirmed: true,
        ),
      );
      expect(
        goalMsg.toCompactedHistoryText(),
        equals('[User menyetujui Goal: Dana Nikah Rp 50.000.000]'),
      );

      final budgetMsg = UnifiedAiChatMessage(
        id: 'm-budget',
        sessionId: 's1',
        text: 'Draf budget siap.',
        isUser: false,
        budgetDraft: const AiBudgetDraft(
          clientMutationId: 'mut-b',
          category: 'Food & Beverage',
          limitAmount: 1500000,
          isConfirmed: true,
        ),
      );
      expect(
        budgetMsg.toCompactedHistoryText(),
        equals('[User menyetujui Budget: Food & Beverage Rp 1.500.000]'),
      );

      final billMsg = UnifiedAiChatMessage(
        id: 'm-bill',
        sessionId: 's1',
        text: 'Draf tagihan siap.',
        isUser: false,
        billDraft: const AiBillDraft(
          clientMutationId: 'mut-bill',
          title: 'Indihome',
          amount: 385000,
          frequency: 'monthly',
          category: 'Bills & Utilities',
          isConfirmed: true,
        ),
      );
      expect(
        billMsg.toCompactedHistoryText(),
        equals('[User menyetujui Tagihan: Indihome Rp 385.000]'),
      );

      final cancelledTxMsg = UnifiedAiChatMessage(
        id: 'm-cancel',
        sessionId: 's1',
        text: 'Draf dibatalkan.',
        isUser: false,
        transactionDraftGroup: AiTransactionDraftGroup(
          clientMutationId: 'mut-c',
          isCancelled: true,
          items: [
            AiTransactionDraftItem(
              title: 'Kopi',
              amount: 28000,
              type: 'expense',
              canonicalCategory: 'Food & Beverage • Coffee Shop',
              walletId: 'w-gopay',
              walletName: 'GoPay',
              occurredAt: DateTime.utc(2026, 11, 1, 9, 0),
            ),
          ],
        ),
      );
      expect(
        cancelledTxMsg.toCompactedHistoryText(),
        equals('[User membatalkan draf transaksi: Kopi Rp 28.000 via GoPay]'),
      );
    });

    test('strips bloated chart JSON from analytical cards and bounds length <= 1000 runes', () {
      final analyticalMsg = UnifiedAiChatMessage(
        id: 'm-flow',
        sessionId: 's1',
        text: 'Pada Okt 2026, pengeluaranmu Rp 5.942.000 dari 67 transaksi.',
        isUser: false,
        moneyFlowCard: const AiMoneyFlowData(
          periodLabel: 'Okt 2026',
          totalIncome: 10320000,
          totalExpense: 5942000,
          netCashflow: 4378000,
          transactionCount: 67,
          incomeSources: [
            AiMoneyFlowNode(
              label: 'Gaji',
              amount: 10320000,
              colorHex: '#10B981',
              percentage: 100.0,
            ),
          ],
          expenseCategories: [
            AiMoneyFlowNode(
              label: 'Kos / Sewa',
              amount: 2450000,
              colorHex: '#F59E0B',
              percentage: 41.2,
            ),
          ],
          flows: [
            AiMoneyFlowEdge(sourceIndex: 0, targetIndex: 0, amount: 2450000),
          ],
          breakdownSummary: 'Kos / Sewa adalah pos terbesar.',
        ),
      );

      final compacted = analyticalMsg.toCompactedHistoryText();
      expect(compacted, contains('Pada Okt 2026, pengeluaranmu Rp 5.942.000'));
      expect(compacted.contains('income_sources'), isFalse);
      expect(compacted.contains('source_index'), isFalse);
      expect(compacted.length, lessThanOrEqualTo(1000));

      final veryLongMsg = UnifiedAiChatMessage(
        id: 'm-long',
        sessionId: 's1',
        text: List.filled(300, 'panjang').join(' '),
        isUser: true,
      );
      expect(veryLongMsg.toCompactedHistoryText().runes.length, lessThanOrEqualTo(1000));
    });
  });
}
