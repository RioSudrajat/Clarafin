import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/transaction_model.dart';
import 'package:mobile/core/models/wallet_model.dart';
import 'package:mobile/core/network/clarafin_api_client.dart';
import 'package:mobile/core/network/tracker_remote_sync_service.dart';
import 'package:mobile/features/budget/domain/models/bill_model.dart';
import 'package:mobile/features/budget/domain/models/budget_category_model.dart';
import 'package:mobile/features/budget/domain/models/goal_model.dart';
import 'package:mobile/features/session/data/ai_chat_repository.dart';
import 'package:mobile/features/session/data/local_ai_fallback_engine.dart';
import 'package:mobile/features/session/domain/models/ai_chat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AdapterHandler = Future<ResponseBody> Function(
  RequestOptions options,
  Stream<Uint8List>? requestStream,
  Future<void>? cancelFuture,
);

class _FakeHttpClientAdapter implements HttpClientAdapter {
  final AdapterHandler handler;
  final List<RequestOptions> requests = [];
  final List<String> requestBodies = [];

  _FakeHttpClientAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      final bytes = chunks.expand((c) => c).toList();
      requestBodies.add(utf8.decode(bytes, allowMalformed: true));
    } else if (options.data != null) {
      requestBodies.add(jsonEncode(options.data));
    } else {
      requestBodies.add('');
    }
    return handler(options, requestStream, cancelFuture);
  }
}

ClarafinApiClient _buildTestClient(
  _FakeHttpClientAdapter adapter, {
  SharedPreferences? prefs,
  String? accessToken,
}) {
  final config = ClarafinApiConfig.fromUrl('http://127.0.0.1:8080');
  final dio = Dio(BaseOptions(baseUrl: config.normalizedBaseUrl));
  dio.httpClientAdapter = adapter;
  return ClarafinApiClient(
    config: config,
    dio: dio,
    prefs: prefs,
    accessToken: accessToken,
    devEmail: 'tester@clarafin.local',
    devFullName: 'Clarafin Tester',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SSE byte-stream parser', () {
    test('reassembles fragmented multi-byte UTF-8 and split data events', () async {
      final event1 =
          'data: {"type":"thinking_step","step_number":1,"title":"Cek dompet","detail":"GoPay • Aktif ®","status":"in_progress"}\n\n';
      final event2 =
          ': keepalive\r\n\r\nevent: final_response\r\ndata: {"session_id":"s1","client_request_id":"r1","quota_total":40,"quota_remaining":39,"narrative":"Kopi Kenangan Rp 25.000 via GoPay • Selesai"}\r\n\r\n';

      final allBytes = utf8.encode(event1 + event2);
      // Split at the bullet byte (0xE2 0x80 0xA2) and mid-JSON boundaries.
      final bulletIdx = allBytes.indexOf(0xE2);
      expect(bulletIdx, greaterThan(0));

      final controller = StreamController<List<int>>();
      final framesFuture = parseSseByteStream(controller.stream).toList();

      controller.add(allBytes.sublist(0, bulletIdx + 1));
      controller.add(allBytes.sublist(bulletIdx + 1, bulletIdx + 25));
      controller.add(allBytes.sublist(bulletIdx + 25, allBytes.length - 12));
      controller.add(allBytes.sublist(allBytes.length - 12));
      await controller.close();

      final frames = await framesFuture;
      expect(frames.length, equals(2));
      expect(frames[0].event, anyOf(isEmpty, equals('thinking_step')));
      final json0 = jsonDecode(frames[0].data) as Map<String, dynamic>;
      expect(json0['type'], equals('thinking_step'));
      expect(json0['detail'], equals('GoPay • Aktif ®'));

      expect(frames[1].event, equals('final_response'));
      final json1 = jsonDecode(frames[1].data) as Map<String, dynamic>;
      expect(
        json1['narrative'],
        equals('Kopi Kenangan Rp 25.000 via GoPay • Selesai'),
      );
    });
  });

  group('RemoteAiChatRepository', () {
    test('acquires dev token lazily, streams thinking_step + final_response, and compacts history', () async {
      final adapter = _FakeHttpClientAdapter((options, _, _) async {
        if (options.path == '/v1/dev/token') {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'access_token': 'jwt_dev_token_123',
                'token_type': 'Bearer',
                'expires_in': 86400,
                'expires_at': DateTime.now()
                    .toUtc()
                    .add(const Duration(hours: 24))
                    .toIso8601String(),
                'user': {
                  'id': '11111111-1111-4111-8111-111111111111',
                  'email': 'tester@clarafin.local',
                  'full_name': 'Clarafin Tester',
                },
              },
              'meta': {'request_id': 'req_tok'},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        expect(options.path, equals('/v1/ai/chat'));
        expect(options.headers['Authorization'], equals('Bearer jwt_dev_token_123'));

        final sse = [
          'event: thinking_step\n'
              'data: {"step_number":1,"title":"Memeriksa dompet","detail":"GoPay aktif","status":"completed","session_id":"sess_1","client_request_id":"req_1"}\n\n',
          'event: final_response\n'
              'data: {"session_id":"sess_1","client_request_id":"req_1","surface_mode":"quick_sheet","plan_type":"free","quota_total":40,"quota_used":1,"quota_remaining":39,"narrative":"Draf Kopi Kenangan Rp 25.000 siap dicatat.","thinking_summary":[{"step_number":1,"title":"Memeriksa dompet","detail":"GoPay aktif","status":"completed"}],"transaction_draft":{"item_count":1,"total_amount_idr":25000,"items":[{"title":"Kopi Kenangan","amount_idr":25000,"type":"expense","canonical_category":"Food & Beverage • Coffee Shop","canonical_main_category":"Food & Beverage","wallet_id":"w-gopay","wallet_name":"GoPay"}]}}\n\n',
        ];
        final stream = Stream<Uint8List>.fromIterable(
          sse.map((s) => Uint8List.fromList(utf8.encode(s))),
        );
        return ResponseBody(
          stream,
          200,
          headers: {
            Headers.contentTypeHeader: ['text/event-stream'],
          },
        );
      });

      final client = _buildTestClient(adapter);
      final repo = RemoteAiChatRepository(client: client);

      final history = List.generate(
        12,
        (i) => UnifiedAiChatMessage(
          id: 'h-$i',
          sessionId: 'sess_1',
          text: 'Turn $i',
          isUser: i.isEven,
        ),
      );

      final events = await repo
          .streamChat(
            prompt: 'kopi kenangan 25k pake gopay',
            surfaceMode: AiSurfaceMode.quickSheet,
            sessionId: 'sess_1',
            clientRequestId: 'req_1',
            sessionHistory: history,
          )
          .toList();

      expect(events.length, equals(2));
      expect(events[0], isA<AiThinkingStepEvent>());
      final step = events[0] as AiThinkingStepEvent;
      expect(step.title, equals('Memeriksa dompet'));
      expect(step.isDone, isTrue);

      expect(events[1], isA<AiFinalResponseEvent>());
      final finalEv = events[1] as AiFinalResponseEvent;
      expect(finalEv.quotaTotal, equals(40));
      expect(finalEv.quotaRemaining, equals(39));
      expect(finalEv.message.transactionDraftGroup, isNotNull);
      expect(finalEv.message.transactionDraftGroup!.items.first.amount, equals(25000));

      final chatBody = jsonDecode(adapter.requestBodies[1]) as Map<String, dynamic>;
      expect(chatBody['surface_mode'], equals('quick_sheet'));
      expect((chatBody['session_history'] as List).length, equals(10));
    });

    test('converts HTTP 402 QUOTA_EXCEEDED and 429 RATE_LIMITED into AiErrorEvent', () async {
      for (final scenario in [
        (status: 402, code: 'QUOTA_EXCEEDED', msg: 'Monthly AI quota exceeded.'),
        (status: 429, code: 'RATE_LIMITED', msg: 'AI rate limit exceeded.'),
      ]) {
        final adapter = _FakeHttpClientAdapter((options, _, _) async {
          return ResponseBody.fromString(
            jsonEncode({
              'error': {
                'code': scenario.code,
                'message': scenario.msg,
                'request_id': 'req_err',
                'details': {
                  'plan_type': 'free',
                  'quota_total': 40,
                  'quota_remaining': 0,
                },
              },
            }),
            scenario.status,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });

        final client = _buildTestClient(adapter, accessToken: 'valid_jwt');
        final repo = RemoteAiChatRepository(client: client);

        final events = await repo
            .streamChat(
              prompt: 'analisa pengeluaranku',
              surfaceMode: AiSurfaceMode.fullScreen,
              sessionId: 'sess_err',
              clientRequestId: 'req_err_${scenario.status}',
            )
            .toList();

        expect(events.length, equals(1));
        expect(events.first, isA<AiErrorEvent>());
        final err = events.first as AiErrorEvent;
        expect(err.errorCode, equals(scenario.code));
        expect(err.statusCode, equals(scenario.status));
        if (scenario.status == 402) {
          expect(err.isQuotaExceeded, isTrue);
        } else {
          expect(err.isRateLimited, isTrue);
        }
      }
    });

    test('terminates cleanly without unhandled errors on CancelToken cancellation', () async {
      final adapter = _FakeHttpClientAdapter((options, _, cancelFuture) async {
        final controller = StreamController<Uint8List>();
        cancelFuture?.then((_) {
          if (!controller.isClosed) {
            controller.close();
          }
        });
        controller.add(
          Uint8List.fromList(
            utf8.encode(
              'event: thinking_step\ndata: {"step_number":1,"title":"Analisa","status":"in_progress"}\n\n',
            ),
          ),
        );
        return ResponseBody(
          controller.stream,
          200,
          headers: {
            Headers.contentTypeHeader: ['text/event-stream'],
          },
        );
      });

      final client = _buildTestClient(adapter, accessToken: 'valid_jwt');
      final repo = RemoteAiChatRepository(client: client);
      final cancelToken = CancelToken();

      final received = <AiSseEvent>[];
      final sub = repo
          .streamChat(
            prompt: 'cek cashflow',
            surfaceMode: AiSurfaceMode.fullScreen,
            sessionId: 'sess_cancel',
            clientRequestId: 'req_cancel',
            cancelToken: cancelToken,
          )
          .listen(received.add);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      cancelToken.cancel('user cancelled');
      await sub.asFuture<void>();
      await sub.cancel();

      expect(received.length, lessThanOrEqualTo(1));
      expect(received.whereType<AiErrorEvent>(), isEmpty);
    });
  });

  group('TrackerRemoteSyncService', () {
    test('syncs wallets and transactions with strict Go handler fields and idempotent keys', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const walletUuid = '22222222-2222-4222-8222-222222222222';
      const txUuid = '33333333-3333-4333-8333-333333333333';

      final calls = <String>[];
      final sentTxPayloads = <Map<String, dynamic>>[];

      final adapter = _FakeHttpClientAdapter((options, _, _) async {
        calls.add('${options.method} ${options.path}');
        if (options.path == '/v1/dev/token') {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'access_token': 'sync_jwt',
                'token_type': 'Bearer',
                'expires_in': 86400,
                'expires_at': DateTime.now()
                    .toUtc()
                    .add(const Duration(hours: 24))
                    .toIso8601String(),
                'user': {
                  'id': '11111111-1111-4111-8111-111111111111',
                  'email': 'tester@clarafin.local',
                  'full_name': 'Clarafin Tester',
                },
              },
              'meta': {'request_id': 'req_dev'},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        if (options.method == 'GET' && options.path == '/v1/wallets') {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'wallets': <dynamic>[], 'total_balance_idr': 0},
              'meta': {'request_id': 'req_gw'},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        if (options.method == 'POST' && options.path == '/v1/wallets') {
          final body = jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>;
          expect(body['type'], equals('ewallet'));
          expect(body['institution_code'], equals('gopay'));
          expect(body['balance'], equals(250000));
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'id': walletUuid,
                'user_id': '11111111-1111-4111-8111-111111111111',
                'name': body['name'],
                'type': body['type'],
                'institution_code': body['institution_code'],
                'balance': body['balance'],
              },
              'meta': {'request_id': 'req_cw'},
            }),
            201,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        if (options.method == 'PATCH' &&
            options.path == '/v1/wallets/$walletUuid') {
          final body = jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>;
          expect(body['type'], equals('ewallet'));
          expect(body['institution_code'], equals('gopay'));
          expect(body['balance'], equals(250000));
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'id': walletUuid,
                'user_id': '11111111-1111-4111-8111-111111111111',
                'name': body['name'],
                'type': body['type'],
                'institution_code': body['institution_code'],
                'balance': body['balance'],
              },
              'meta': {'request_id': 'req_uw'},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        if (options.method == 'POST' && options.path == '/v1/transactions') {
          final body = jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>;
          sentTxPayloads.add(body);
          expect(body['wallet_id'], equals(walletUuid));
          expect(body['category'], equals('Food & Beverage • Coffee Shop'));
          expect(body['amount'], equals(25000));
          expect(
            (body['client_mutation_id'] as String).length,
            lessThanOrEqualTo(128),
          );
          expect(body.containsKey('destination_wallet_id'), isFalse);
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'transaction': {
                  'id': txUuid,
                  'user_id': '11111111-1111-4111-8111-111111111111',
                  'wallet_id': walletUuid,
                  'type': 'expense',
                  'category': body['category'],
                  'amount': 25000,
                  'title': body['title'],
                },
                'idempotent_replay': false,
                'wallet_balance_idr': 225000,
              },
              'meta': {'request_id': 'req_tx'},
            }),
            201,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        if (options.method == 'GET' && options.path == '/v1/goals') {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'goals': <dynamic>[]},
              'meta': {'request_id': 'req_gg'},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        if (options.method == 'POST' && options.path == '/v1/goals') {
          final body = jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>;
          expect(body['target_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
          expect(body['priority'], equals('urgent'));
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'id': '44444444-4444-4444-8444-444444444444',
                'title': body['title'],
                'target_amount': body['target_amount'],
                'saved_amount': body['saved_amount'],
                'priority': body['priority'],
              },
              'meta': {'request_id': 'req_cg'},
            }),
            201,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        if (options.method == 'POST' && options.path == '/v1/budgets') {
          final body = jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>;
          expect(body['category'], equals('Food & Beverage'));
          expect(body['month_year'], matches(RegExp(r'^\d{4}-\d{2}$')));
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'id': '55555555-5555-4555-8555-555555555555',
                'category': body['category'],
                'month_year': body['month_year'],
                'limit_amount': body['limit_amount'],
              },
              'meta': {'request_id': 'req_cb'},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        if (options.method == 'GET' && options.path == '/v1/bills') {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'bills': <dynamic>[]},
              'meta': {'request_id': 'req_gb'},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        if (options.method == 'POST' && options.path == '/v1/bills') {
          final body = jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>;
          expect(body['due_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'id': '66666666-6666-4666-8666-666666666666',
                'title': body['title'],
                'amount': body['amount'],
                'frequency': body['frequency'],
              },
              'meta': {'request_id': 'req_cbill'},
            }),
            201,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        throw StateError('Unexpected call: ${options.method} ${options.path}');
      });

      final client = _buildTestClient(adapter, prefs: prefs);
      final syncService = TrackerRemoteSyncService(
        client: client,
        prefs: prefs,
        storageScopeKey: 'test_user',
      );

      final summary = await syncService.syncInitialSnapshot(
        wallets: [
          WalletModel(
            id: 'w_local_gopay',
            name: 'GoPay',
            type: 'E-Wallet',
            balance: 250000,
            institutionId: 'gopay',
          ),
        ],
        transactions: [
          TransactionModel(
            id: 'tx_${List.filled(140, 'x').join()}',
            title: 'Kopi Kenangan',
            category: 'kopi kenangan',
            amount: 25000,
            date: DateTime.utc(2026, 11, 17, 1, 0),
            type: 'expense',
            walletId: 'w_local_gopay',
          ),
        ],
        budgets: [
          BudgetCategoryModel(
            id: 'b1',
            name: 'Makanan',
            totalAmount: 1500000,
            spentAmount: 25000,
            icon: Icons.restaurant,
            iconColor: Colors.orange,
            iconBgColor: Colors.orange.shade100,
          ),
        ],
        goals: [
          GoalModel(
            id: 'g1',
            name: 'Dana Darurat',
            targetAmount: 15000000,
            savedAmount: 1000000,
            targetDate: DateTime(2027, 5, 17),
            icon: Icons.shield,
            tagColor: Colors.green,
            tagTextColor: Colors.black,
            priority: 'Urgent',
            sourceAsset: 'GoPay',
          ),
        ],
        bills: [
          BillModel(
            id: 'bill1',
            name: 'Wi-Fi IndiHome',
            dueDate: DateTime(2026, 11, 20),
            amount: 385000,
            isAutoPay: false,
            isPaid: false,
            icon: Icons.wifi,
            iconColor: Colors.blue,
            iconBgColor: Colors.blue.shade100,
          ),
        ],
      );

      expect(summary.walletsSynced, equals(1));
      expect(summary.transactionsSynced, equals(1));
      expect(summary.budgetsSynced, equals(1));
      expect(summary.goalsSynced, equals(1));
      expect(summary.billsSynced, equals(1));
      expect(calls.where((c) => c == 'POST /v1/dev/token').length, equals(1));
      expect(
        calls.where((c) => c == 'PATCH /v1/wallets/$walletUuid').length,
        equals(1),
      );
      expect(sentTxPayloads.first['occurred_at'], endsWith('+07:00'));

      // Re-running without force returns skipped summary cleanly.
      final skipped = await syncService.syncInitialSnapshot(
        wallets: const [],
        transactions: const [],
        budgets: const [],
        goals: const [],
        bills: const [],
      );
      expect(skipped.skippedAlreadySynced, isTrue);
    });
  });

  group('LocalFallbackAiChatRepository', () {
    final now = DateTime(2026, 11, 17, 10, 0);
    final baseSnapshot = AiChatContextSnapshot(
      userName: 'Raka',
      currency: 'IDR',
      planType: 'free',
      quotaTotal: 40,
      quotaRemaining: 40,
      wallets: [
        WalletModel(
          id: 'w-bca',
          name: 'BCA Utama',
          type: 'Bank',
          balance: 5000000,
          institutionId: 'bca',
        ),
        WalletModel(
          id: 'w-gopay',
          name: 'GoPay',
          type: 'E-Wallet',
          balance: 250000,
          institutionId: 'gopay',
        ),
      ],
      transactions: [
        TransactionModel(
          id: 'tx-inc-1',
          title: 'Gaji Bulanan',
          category: 'Income • Salary',
          amount: 10000000,
          date: DateTime(2026, 11, 1, 9, 0),
          type: 'income',
          walletId: 'w-bca',
        ),
        TransactionModel(
          id: 'tx-exp-1',
          title: 'Kopi Kenangan',
          category: 'Food & Beverage • Coffee Shop',
          amount: 50000,
          date: DateTime(2026, 11, 10, 9, 0),
          type: 'expense',
          walletId: 'w-gopay',
        ),
        TransactionModel(
          id: 'tx-exp-2',
          title: 'Kopi Kenangan',
          category: 'Food & Beverage • Coffee Shop',
          amount: 25000,
          date: DateTime(2026, 11, 12, 9, 0),
          type: 'expense',
          walletId: 'w-gopay',
        ),
        TransactionModel(
          id: 'tx-exp-3',
          title: 'Fore Coffee',
          category: 'Food & Beverage • Coffee Shop',
          amount: 35000,
          date: DateTime(2026, 11, 14, 9, 0),
          type: 'expense',
          walletId: 'w-bca',
        ),
        TransactionModel(
          id: 'tx-exp-4',
          title: 'Sewa Kos',
          category: 'Household Needs • Rent / Sewa',
          amount: 2450000,
          date: DateTime(2026, 11, 5, 9, 0),
          type: 'expense',
          walletId: 'w-bca',
        ),
      ],
    );

    LocalFallbackAiChatRepository buildRepo([AiChatContextSnapshot? snap]) {
      return LocalFallbackAiChatRepository(
        contextReader: () => snap ?? baseSnapshot,
        clock: () => now,
      );
    }

    test('handles pure greetings with zero quota consumption', () async {
      final repo = buildRepo();
      final events = await repo
          .streamChat(
            prompt: 'Halo Clarafin!',
            surfaceMode: AiSurfaceMode.quickSheet,
            sessionId: 's-greet',
            clientRequestId: 'r-greet',
          )
          .toList();

      final finalEv = events.whereType<AiFinalResponseEvent>().single;
      expect(finalEv.isPrefiltered, isTrue);
      expect(finalEv.quotaRemaining, equals(40));
      expect(finalEv.message.text.contains('\u2014'), isFalse);
      expect(finalEv.message.transactionDraftGroup, isNull);
    });

    test('parses multi-item Indonesian slang "kopi kenangan 25k + parkir goceng pake gopay"', () async {
      final repo = buildRepo();
      final events = await repo
          .streamChat(
            prompt: 'kopi kenangan 25k + parkir goceng pake gopay',
            surfaceMode: AiSurfaceMode.quickSheet,
            sessionId: 's-slang',
            clientRequestId: 'r-slang',
          )
          .toList();

      expect(events.whereType<AiThinkingStepEvent>().isNotEmpty, isTrue);
      final finalEv = events.whereType<AiFinalResponseEvent>().single;
      expect(finalEv.isPrefiltered, isFalse);
      expect(finalEv.quotaRemaining, equals(39));

      final group = finalEv.message.transactionDraftGroup;
      expect(group, isNotNull);
      expect(group!.items.length, equals(2));

      expect(group.items[0].title, equals('Kopi Kenangan'));
      expect(group.items[0].amount, equals(25000.0));
      expect(group.items[0].canonicalCategory, equals('Food & Beverage • Coffee Shop'));
      expect(group.items[0].walletId, equals('w-gopay'));

      expect(group.items[1].title, equals('Parkir'));
      expect(group.items[1].amount, equals(5000.0));
      expect(group.items[1].canonicalCategory, equals('Transportation • Parking & Toll'));
      expect(group.items[1].walletId, equals('w-gopay'));
    });

    test('withholds transaction draft and emits WalletCreationDraft for missing "bank jago", "jenius", "seabank", "blu"', () async {
      final repo = buildRepo();
      final cases = <String, String>{
        'abis makan 45rb pake bank jago': 'jago',
        'beli kopi 25rb pake jenius': 'jenius',
        'bayar parkir 5rb lewat seabank': 'seabank',
        'jajan bakso 20rb pake blu': 'blu',
      };

      for (final entry in cases.entries) {
        final events = await repo
            .streamChat(
              prompt: entry.key,
              surfaceMode: AiSurfaceMode.quickSheet,
              sessionId: 's-miss-${entry.value}',
              clientRequestId: 'r-miss-${entry.value}',
            )
            .toList();

        final finalEv = events.whereType<AiFinalResponseEvent>().single;
        expect(
          finalEv.message.transactionDraftGroup,
          isNull,
          reason: 'Must withhold transaction draft for ${entry.value}',
        );
        final walletDraft = finalEv.message.walletCreationDraft;
        expect(walletDraft, isNotNull, reason: 'Expected wallet draft for ${entry.value}');
        expect(walletDraft!.institutionId, equals(entry.value));
        expect(walletDraft.existingWalletIds, equals(['w-bca', 'w-gopay']));
      }
    });

    test('computes MoneyFlowCard for "uangku lari ke mana aja?" without NaN on populated or empty state', () async {
      final repo = buildRepo();
      final events = await repo
          .streamChat(
            prompt: 'uangku lari ke mana aja?',
            surfaceMode: AiSurfaceMode.fullScreen,
            sessionId: 's-flow',
            clientRequestId: 'r-flow',
          )
          .toList();

      final finalEv = events.whereType<AiFinalResponseEvent>().single;
      final flow = finalEv.message.moneyFlowCard;
      expect(flow, isNotNull);
      expect(flow!.totalIncome, equals(10000000.0));
      expect(flow.totalExpense, equals(2560000.0));
      expect(flow.netCashflow, equals(7440000.0));
      expect(flow.transactionCount, equals(5));
      expect(flow.incomeSources.isNotEmpty, isTrue);
      expect(flow.expenseCategories.length, equals(2));
      expect(flow.flows.isNotEmpty, isTrue);

      // Empty transactions must not produce NaN.
      final emptyRepo = buildRepo(
        AiChatContextSnapshot(
          wallets: baseSnapshot.wallets,
          transactions: const [],
        ),
      );
      final emptyEvents = await emptyRepo
          .streamChat(
            prompt: 'uangku lari ke mana aja?',
            surfaceMode: AiSurfaceMode.fullScreen,
            sessionId: 's-flow-empty',
            clientRequestId: 'r-flow-empty',
          )
          .toList();
      final emptyFlow = emptyEvents.whereType<AiFinalResponseEvent>().single.message.moneyFlowCard;
      expect(emptyFlow, isNotNull);
      expect(emptyFlow!.totalIncome, equals(0.0));
      expect(emptyFlow.totalExpense, equals(0.0));
      expect(emptyFlow.netCashflow.isNaN, isFalse);
    });

    test('computes SpendingTableCard for "pengeluaran kopi" and planning drafts for goal/budget/bill', () async {
      final repo = buildRepo();

      final kopiEvents = await repo
          .streamChat(
            prompt: 'pengeluaran kopi bulan ini berapa?',
            surfaceMode: AiSurfaceMode.fullScreen,
            sessionId: 's-kopi',
            clientRequestId: 'r-kopi',
          )
          .toList();
      final table = kopiEvents.whereType<AiFinalResponseEvent>().single.message.spendingTableCard;
      expect(table, isNotNull);
      expect(table!.totalAmount, equals(110000.0));
      expect(table.totalTransactions, equals(3));
      expect(table.rows.first.merchant, equals('Kopi Kenangan'));
      expect(table.rows.first.totalAmount, equals(75000.0));

      final goalEvents = await repo
          .streamChat(
            prompt: 'buatin goal dana darurat 15 juta target 6 bulan lagi, prioritas urgent',
            surfaceMode: AiSurfaceMode.quickSheet,
            sessionId: 's-goal',
            clientRequestId: 'r-goal',
          )
          .toList();
      final goal = goalEvents.whereType<AiFinalResponseEvent>().single.message.goalDraft;
      expect(goal, isNotNull);
      expect(goal!.targetAmount, equals(15000000.0));
      expect(goal.monthlySavingEstimate, equals(2500000.0));

      final budgetEvents = await repo
          .streamChat(
            prompt: 'aturin budget makan 1,5jt dong',
            surfaceMode: AiSurfaceMode.quickSheet,
            sessionId: 's-budget',
            clientRequestId: 'r-budget',
          )
          .toList();
      final budget = budgetEvents.whereType<AiFinalResponseEvent>().single.message.budgetDraft;
      expect(budget, isNotNull);
      expect(budget!.category, equals('Food & Beverage'));
      expect(budget.limitAmount, equals(1500000.0));

      final billEvents = await repo
          .streamChat(
            prompt: 'ingetin tagihan wifi indihome 385rb jatuh tempo tiap tanggal 20',
            surfaceMode: AiSurfaceMode.quickSheet,
            sessionId: 's-bill',
            clientRequestId: 'r-bill',
          )
          .toList();
      final bill = billEvents.whereType<AiFinalResponseEvent>().single.message.billDraft;
      expect(bill, isNotNull);
      expect(bill!.amount, equals(385000.0));
      expect(bill.dueDay, equals(20));
    });

    test('answers "cicilan paylater 40% gaji" with neutral hint, soft boundary, CatalogPackage, and c1-c6 consultants', () async {
      final repo = buildRepo();
      final events = await repo
          .streamChat(
            prompt: 'cicilan paylater 40% gaji, enaknya dilunasin yg mana dulu?',
            surfaceMode: AiSurfaceMode.fullScreen,
            sessionId: 's-consult',
            clientRequestId: 'r-consult',
          )
          .toList();

      final msg = events.whereType<AiFinalResponseEvent>().single.message;
      expect(msg.transactionDraftGroup, isNull);
      expect(msg.text.contains('\u2014'), isFalse);
      expect(msg.text.toLowerCase(), contains('snowball'));
      expect(msg.text.toLowerCase(), contains('avalanche'));
      expect(msg.recommendedPackage, isNotNull);
      expect(msg.recommendedPackage!.packageCode, equals('personal_basic'));
      expect(msg.recommendedConsultants.isNotEmpty, isTrue);
      expect(msg.recommendedConsultants.length, lessThanOrEqualTo(3));
      expect(
        msg.recommendedConsultants.map((c) => c.consultantId).toList(),
        anyElement(isIn(['c1', 'c2', 'c3', 'c4', 'c5', 'c6'])),
      );
      for (final c in msg.recommendedConsultants) {
        expect(c.matchReason.contains('\u2014'), isFalse);
      }
    });

    test('ClarafinApiClient refreshes dev token automatically on 404 User account not found', () async {
      var quotaCalls = 0;
      var devTokenCalls = 0;
      ResponseBody jsonResp(int status, Map<String, dynamic> body) {
        return ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }

      final adapter = _FakeHttpClientAdapter((options, _, _) async {
        if (options.path == '/v1/dev/token') {
          devTokenCalls++;
          return jsonResp(200, {
            'data': {
              'access_token': 'fresh-dev-jwt-$devTokenCalls',
              'expires_in': 3600,
              'user': {'id': 'u-fresh'},
            },
          });
        }
        if (options.path == '/v1/ai/quota') {
          quotaCalls++;
          if (quotaCalls == 1) {
            return jsonResp(404, {
              'error': {
                'code': 'NOT_FOUND',
                'message': 'User account not found.',
              },
            });
          }
          expect(options.headers['Authorization'], equals('Bearer fresh-dev-jwt-2'));
          return jsonResp(200, {
            'data': {
              'plan_type': 'free',
              'quota_total': 40,
              'quota_used': 0,
              'quota_remaining': 40,
              'renewal_date': '2026-12-01T00:00:00+07:00',
            },
          });
        }
        throw StateError('Unexpected path: ${options.path}');
      });

      final client = _buildTestClient(adapter);
      final res = await client.getJson('/v1/ai/quota');
      expect(devTokenCalls, equals(2));
      expect(quotaCalls, equals(2));
      expect(res['quota_remaining'], equals(40));
    });
  });
}
