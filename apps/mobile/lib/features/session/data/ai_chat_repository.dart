import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/transaction_model.dart';
import '../../../core/models/wallet_model.dart';
import '../../../core/network/clarafin_api_client.dart';
import '../../../core/providers/ai_quota_provider.dart';
import '../../../core/providers/mock_providers.dart';
import '../../budget/presentation/providers/finance_providers.dart';
import '../../profile/presentation/providers/user_profile_provider.dart';
import '../domain/models/ai_chat_models.dart';
import 'local_ai_fallback_engine.dart';
import 'sse_stream_parser.dart';

export 'sse_stream_parser.dart';

/// Live tracker snapshot passed to local fallback mode or sync helpers.
class AiChatContextSnapshot {
  final List<WalletModel> wallets;
  final List<TransactionModel> transactions;
  final List<BudgetCategoryModel> budgets;
  final List<GoalModel> goals;
  final List<BillModel> bills;
  final double totalBudget;
  final String userName;
  final String currency;
  final String planType;
  final int quotaRemaining;
  final int quotaTotal;

  const AiChatContextSnapshot({
    this.wallets = const [],
    this.transactions = const [],
    this.budgets = const [],
    this.goals = const [],
    this.bills = const [],
    this.totalBudget = 5000000.0,
    this.userName = 'Pengguna',
    this.currency = 'IDR',
    this.planType = 'free',
    this.quotaRemaining = 40,
    this.quotaTotal = 40,
  });

  bool get isUnlimited => planType == 'unlimited' || quotaTotal == -1;
}

/// Typed SSE events emitted by [AiChatRepository.streamChat].
sealed class AiSseEvent {
  const AiSseEvent();
}

final class AiThinkingStepEvent extends AiSseEvent {
  final int stepNumber;
  final String id;
  final String title;
  final String? detail;
  final String status;
  final bool isDone;
  final String sessionId;
  final String clientRequestId;

  const AiThinkingStepEvent({
    required this.stepNumber,
    required this.id,
    required this.title,
    this.detail,
    required this.status,
    required this.isDone,
    required this.sessionId,
    required this.clientRequestId,
  });

  AiThinkingStep toThinkingStep() {
    return AiThinkingStep(
      id: id,
      label: title,
      detail: detail,
      isDone: isDone,
    );
  }
}

final class AiFinalResponseEvent extends AiSseEvent {
  final UnifiedAiChatMessage message;
  final String sessionId;
  final String clientRequestId;
  final String? requestId;
  final AiSurfaceMode surfaceMode;
  final bool isPrefiltered;
  final String? planType;
  final int? quotaTotal;
  final int? quotaUsed;
  final int? quotaRemaining;

  const AiFinalResponseEvent({
    required this.message,
    required this.sessionId,
    required this.clientRequestId,
    this.requestId,
    required this.surfaceMode,
    this.isPrefiltered = false,
    this.planType,
    this.quotaTotal,
    this.quotaUsed,
    this.quotaRemaining,
  });
}

final class AiErrorEvent extends AiSseEvent {
  final String errorCode;
  final String message;
  final int? statusCode;
  final String? requestId;
  final String? planType;
  final int? quotaRemaining;
  final int? quotaTotal;

  const AiErrorEvent({
    required this.errorCode,
    required this.message,
    this.statusCode,
    this.requestId,
    this.planType,
    this.quotaRemaining,
    this.quotaTotal,
  });

  bool get isQuotaExceeded => errorCode == 'QUOTA_EXCEEDED' || statusCode == 402;
  bool get isRateLimited => errorCode == 'RATE_LIMITED' || statusCode == 429;
}

/// Contract implemented by both Go backend SSE client and offline fallback engine.
abstract class AiChatRepository {
  Stream<AiSseEvent> streamChat({
    required String prompt,
    required AiSurfaceMode surfaceMode,
    required String sessionId,
    required String clientRequestId,
    List<UnifiedAiChatMessage> sessionHistory = const [],
    AiChatContextSnapshot? contextSnapshot,
    CancelToken? cancelToken,
  });
}

/// Dio SSE repository calling `POST /v1/ai/chat` on the Clarafin Go backend.
class RemoteAiChatRepository implements AiChatRepository {
  static const int maxHistoryTurns = 10;
  static const Uuid _uuid = Uuid();

  final ClarafinApiClient _client;

  RemoteAiChatRepository({required ClarafinApiClient client})
    : _client = client;

  @override
  Stream<AiSseEvent> streamChat({
    required String prompt,
    required AiSurfaceMode surfaceMode,
    required String sessionId,
    required String clientRequestId,
    List<UnifiedAiChatMessage> sessionHistory = const [],
    AiChatContextSnapshot? contextSnapshot,
    CancelToken? cancelToken,
  }) async* {
    if (cancelToken?.isCancelled ?? false) return;

    final reqId = clientRequestId.trim().isEmpty
        ? _uuid.v4()
        : clientRequestId.trim();
    final body = <String, dynamic>{
      'session_id': sessionId.trim(),
      'client_request_id': reqId,
      'message': prompt.trim(),
      'surface_mode': surfaceMode.apiValue,
      'session_history': _serializeHistory(sessionHistory),
    };

    try {
      final response = await _client.postSseStream(
        '/v1/ai/chat',
        data: body,
        cancelToken: cancelToken,
      );
      final stream = response.data?.stream;
      if (stream == null) {
        yield const AiErrorEvent(
          errorCode: 'EMPTY_STREAM',
          message: 'Respons server kosong. Silakan coba lagi.',
        );
        return;
      }

      await for (final frame in parseSseByteStream(stream)) {
        if (cancelToken?.isCancelled ?? false) return;
        final event = _decodeFrame(
          frame,
          fallbackSessionId: sessionId,
          fallbackRequestId: reqId,
          fallbackSurfaceMode: surfaceMode,
        );
        if (event != null) {
          yield event;
        }
      }
    } on DioException catch (err) {
      if (CancelToken.isCancel(err) || (cancelToken?.isCancelled ?? false)) {
        return;
      }
      final apiErr = await ClarafinApiClient.extractApiException(err);
      yield AiErrorEvent(
        errorCode: apiErr.code,
        message: apiErr.message,
        statusCode: apiErr.statusCode,
        requestId: apiErr.requestId,
        planType: apiErr.details?['plan_type']?.toString(),
        quotaRemaining: (apiErr.details?['quota_remaining'] as num?)?.toInt(),
        quotaTotal: (apiErr.details?['quota_total'] as num?)?.toInt(),
      );
    } catch (err) {
      if (cancelToken?.isCancelled ?? false) return;
      yield AiErrorEvent(
        errorCode: 'STREAM_ERROR',
        message: 'Terjadi kendala saat membaca respons AI: $err',
      );
    }
  }

  List<Map<String, String>> _serializeHistory(
    List<UnifiedAiChatMessage> history,
  ) {
    final turns = <Map<String, String>>[];
    for (final msg in history) {
      final compacted = msg.toCompactedHistoryText().trim();
      if (compacted.isEmpty) continue;
      turns.add({
        'role': msg.isUser ? 'user' : 'model',
        'text': compacted,
      });
    }
    if (turns.length <= maxHistoryTurns) return turns;
    return turns.sublist(turns.length - maxHistoryTurns);
  }

  AiSseEvent? _decodeFrame(
    AiSseFrame frame, {
    required String fallbackSessionId,
    required String fallbackRequestId,
    required AiSurfaceMode fallbackSurfaceMode,
  }) {
    if (frame.data.trim().isEmpty) return null;
    final dynamic decoded;
    try {
      decoded = jsonDecode(frame.data);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    final eventType = frame.event.isNotEmpty
        ? frame.event
        : (map['type']?.toString() ?? map['event']?.toString() ?? '');

    if (eventType == 'thinking_step') {
      final stepNumber = (map['step_number'] as num?)?.toInt() ?? 1;
      final status = map['status']?.toString() ?? 'in_progress';
      final isDone =
          status == 'completed' ||
          status == 'done' ||
          (map['is_done'] as bool? ?? false);
      return AiThinkingStepEvent(
        stepNumber: stepNumber,
        id: map['id']?.toString() ?? 'step-$stepNumber',
        title:
            map['title']?.toString() ??
            map['label']?.toString() ??
            'Memproses permintaan',
        detail: map['detail']?.toString(),
        status: status,
        isDone: isDone,
        sessionId: map['session_id']?.toString() ?? fallbackSessionId,
        clientRequestId:
            map['client_request_id']?.toString() ?? fallbackRequestId,
      );
    }

    if (eventType == 'final_response') {
      final msg = UnifiedAiChatMessage.fromJson(map);
      final normalizedMsg = msg.id.isEmpty
          ? msg.copyWith(id: _uuid.v4(), sessionId: fallbackSessionId)
          : msg;
      return AiFinalResponseEvent(
        message: normalizedMsg,
        sessionId: map['session_id']?.toString() ?? fallbackSessionId,
        clientRequestId:
            map['client_request_id']?.toString() ?? fallbackRequestId,
        requestId: map['request_id']?.toString(),
        surfaceMode: map['surface_mode'] != null
            ? AiSurfaceMode.fromApiValue(map['surface_mode']?.toString())
            : fallbackSurfaceMode,
        isPrefiltered: map['is_prefiltered'] as bool? ?? false,
        planType: map['plan_type']?.toString(),
        quotaTotal: (map['quota_total'] as num?)?.toInt(),
        quotaUsed: (map['quota_used'] as num?)?.toInt(),
        quotaRemaining: (map['quota_remaining'] as num?)?.toInt(),
      );
    }

    if (eventType == 'error') {
      return AiErrorEvent(
        errorCode:
            map['error_code']?.toString() ??
            map['code']?.toString() ??
            'INTERNAL_ERROR',
        message:
            map['message']?.toString() ??
            'Terjadi kesalahan saat memproses permintaan.',
        statusCode: (map['status_code'] as num?)?.toInt(),
        requestId: map['request_id']?.toString(),
        planType: map['plan_type']?.toString(),
        quotaRemaining: (map['quota_remaining'] as num?)?.toInt(),
        quotaTotal: (map['quota_total'] as num?)?.toInt(),
      );
    }
    return null;
  }
}

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  final config = ref.watch(clarafinApiConfigProvider);
  if (config.isConfigured) {
    return RemoteAiChatRepository(client: ref.watch(clarafinApiClientProvider));
  }
  return LocalFallbackAiChatRepository(
    contextReader: () {
      final profile = ref.read(userProfileProvider);
      final quota = ref.read(aiQuotaProvider);
      return AiChatContextSnapshot(
        wallets: ref.read(walletsProvider),
        transactions: ref.read(transactionsProvider),
        budgets: ref.read(budgetsProvider),
        goals: ref.read(goalsProvider),
        bills: ref.read(billsProvider),
        totalBudget: ref.read(monthlyTotalBudgetProvider),
        userName: profile.name.isEmpty ? 'Pengguna' : profile.name,
        currency: profile.currency,
        planType: quota.planType,
        quotaRemaining: quota.quotaRemaining,
        quotaTotal: quota.quotaTotal,
      );
    },
  );
});
