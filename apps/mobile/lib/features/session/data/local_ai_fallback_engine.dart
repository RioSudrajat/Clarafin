import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/wallet_model.dart';
import '../../../core/network/tracker_remote_sync_service.dart';
import '../../../core/utils/ai_category_normalizer.dart';
import '../domain/models/ai_chat_models.dart';
import 'ai_chat_repository.dart';
import 'local_ai_analytics_builders.dart';
import 'local_ai_consultant_matcher.dart';
import 'local_ai_nlp_helpers.dart';

/// Deterministic offline mirror used when `CLARAFIN_API_BASE_URL` is unset or in tests.
class LocalFallbackAiChatRepository implements AiChatRepository {
  static const Uuid _uuid = Uuid();

  final AiChatContextSnapshot Function()? _contextReader;
  final DateTime Function() _clock;
  final Duration _stepDelay;

  LocalFallbackAiChatRepository({
    AiChatContextSnapshot Function()? contextReader,
    DateTime Function()? clock,
    Duration stepDelay = Duration.zero,
  }) : _contextReader = contextReader,
       _clock = clock ?? DateTime.now,
       _stepDelay = stepDelay;

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

    final snapshot =
        contextSnapshot ??
        _contextReader?.call() ??
        const AiChatContextSnapshot();
    final trimmedPrompt = prompt.trim();
    final reqId = clientRequestId.trim().isEmpty
        ? _uuid.v4()
        : clientRequestId.trim();

    // Pure greeting or closing prefilter consumes 0 AI quota.
    final greetingReply = LocalAiNlpHelpers.matchPureGreeting(trimmedPrompt);
    if (greetingReply != null) {
      yield AiFinalResponseEvent(
        sessionId: sessionId,
        clientRequestId: reqId,
        surfaceMode: surfaceMode,
        isPrefiltered: true,
        planType: snapshot.planType,
        quotaTotal: snapshot.quotaTotal,
        quotaUsed: 0,
        quotaRemaining: snapshot.quotaRemaining,
        message: UnifiedAiChatMessage(
          id: _uuid.v4(),
          sessionId: sessionId,
          text: greetingReply,
          isUser: false,
          timestamp: _clock(),
        ),
      );
      return;
    }

    if (!snapshot.isUnlimited && snapshot.quotaRemaining <= 0) {
      yield AiErrorEvent(
        errorCode: 'QUOTA_EXCEEDED',
        statusCode: 402,
        message:
            'Kuota AI bulanan kamu sudah habis. Upgrade paket untuk melanjutkan.',
        planType: snapshot.planType,
        quotaRemaining: 0,
        quotaTotal: snapshot.quotaTotal,
      );
      return;
    }

    final nextRemaining = snapshot.isUnlimited
        ? -1
        : max(0, snapshot.quotaRemaining - 1);

    if (_stepDelay > Duration.zero) {
      await Future<void>.delayed(_stepDelay);
      if (cancelToken?.isCancelled ?? false) return;
    }

    final lower = trimmedPrompt.toLowerCase();

    if (_isGoalIntent(lower)) {
      yield* _emitGoalDraft(trimmedPrompt, snapshot, sessionId, reqId, surfaceMode, nextRemaining);
      return;
    }
    if (_isBudgetIntent(lower)) {
      yield* _emitBudgetDraft(trimmedPrompt, snapshot, sessionId, reqId, surfaceMode, nextRemaining);
      return;
    }
    if (_isBillIntent(lower)) {
      yield* _emitBillDraft(trimmedPrompt, snapshot, sessionId, reqId, surfaceMode, nextRemaining);
      return;
    }
    if (_isMoneyFlowIntent(lower)) {
      yield* _emitMoneyFlow(trimmedPrompt, snapshot, sessionId, reqId, surfaceMode, nextRemaining);
      return;
    }
    if (_isSpendingTableIntent(lower)) {
      yield* _emitSpendingTable(trimmedPrompt, snapshot, sessionId, reqId, surfaceMode, nextRemaining);
      return;
    }
    if (_isWalletBalanceIntent(lower)) {
      yield* _emitWalletBalance(snapshot, sessionId, reqId, surfaceMode, nextRemaining);
      return;
    }
    if (LocalAiConsultantMatcher.isDeepAdvisoryPrompt(trimmedPrompt)) {
      yield* _emitAdvisory(trimmedPrompt, snapshot, sessionId, reqId, surfaceMode, nextRemaining);
      return;
    }

    yield* _emitTransactionOrWalletDraft(
      trimmedPrompt,
      snapshot,
      sessionId,
      reqId,
      surfaceMode,
      nextRemaining,
    );
  }

  bool _isGoalIntent(String lower) =>
      RegExp(r'\b(goal|target tabungan|target nabung|nabung buat)\b').hasMatch(lower) &&
      !lower.contains('?');

  bool _isBudgetIntent(String lower) =>
      RegExp(r'\b(budget|anggaran|pagu)\b').hasMatch(lower) &&
      (RegExp(r'\b(atur|aturin|buat|buatin|set|ubah)\b').hasMatch(lower) ||
          LocalAiNlpHelpers.parseAmount(lower) != null);

  bool _isBillIntent(String lower) =>
      RegExp(r'\b(tagihan|bill|ingetin|pengingat)\b').hasMatch(lower) &&
      (RegExp(r'\b(tanggal|tgl|tiap|bulanan|mingguan|tahunan)\b').hasMatch(lower) ||
          RegExp(r'\b(ingetin|pengingat)\b').hasMatch(lower));

  bool _isMoneyFlowIntent(String lower) => RegExp(
    r'(lari ke mana|lari kemana|aliran uang|aliran kas|cashflow|arus kas|pemasukan vs pengeluaran|ringkasan keuangan)',
  ).hasMatch(lower);

  bool _isSpendingTableIntent(String lower) =>
      RegExp(r'\b(pengeluaran|habis berapa|rincian|total jajan)\b').hasMatch(lower) &&
      !RegExp(r'\b(catat|tadi|barusan|abis beli)\b').hasMatch(lower);

  bool _isWalletBalanceIntent(String lower) =>
      RegExp(r'\b(berapa|cek|lihat|total)\b.*\b(saldo|dompet|rekening)\b')
          .hasMatch(lower);

  Stream<AiSseEvent> _emitMoneyFlow(
    String prompt,
    AiChatContextSnapshot snapshot,
    String sessionId,
    String reqId,
    AiSurfaceMode surfaceMode,
    int nextRemaining,
  ) async* {
    yield AiThinkingStepEvent(
      stepNumber: 1,
      id: 'step-flow-1',
      title: 'Mengagregasi arus kas pengguna',
      detail: 'Menghitung pemasukan dan pengeluaran dari ${snapshot.transactions.length} transaksi',
      status: 'completed',
      isDone: true,
      sessionId: sessionId,
      clientRequestId: reqId,
    );

    final res = LocalAiAnalyticsBuilders.buildMoneyFlow(
      prompt: prompt,
      snapshot: snapshot,
      now: _clock(),
    );

    yield _finalEvent(
      sessionId: sessionId,
      reqId: reqId,
      surfaceMode: surfaceMode,
      snapshot: snapshot,
      nextRemaining: nextRemaining,
      steps: [
        AiThinkingStep(
          id: 'step-flow-1',
          label: 'Mengagregasi arus kas pengguna',
          detail: '${res.txCount} transaksi dianalisa',
          isDone: true,
        ),
      ],
      message: UnifiedAiChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        text: res.narrative,
        isUser: false,
        timestamp: _clock(),
        moneyFlowCard: res.card,
      ),
    );
  }

  Stream<AiSseEvent> _emitSpendingTable(
    String prompt,
    AiChatContextSnapshot snapshot,
    String sessionId,
    String reqId,
    AiSurfaceMode surfaceMode,
    int nextRemaining,
  ) async* {
    final res = LocalAiAnalyticsBuilders.buildSpendingTable(
      prompt: prompt,
      snapshot: snapshot,
      now: _clock(),
    );

    yield AiThinkingStepEvent(
      stepNumber: 1,
      id: 'step-table-1',
      title: 'Menghitung rincian pengeluaran ${res.keyword.isEmpty ? '' : res.keyword}'.trim(),
      detail: 'Menyaring transaksi pengeluaran sesuai kata kunci',
      status: 'completed',
      isDone: true,
      sessionId: sessionId,
      clientRequestId: reqId,
    );

    yield _finalEvent(
      sessionId: sessionId,
      reqId: reqId,
      surfaceMode: surfaceMode,
      snapshot: snapshot,
      nextRemaining: nextRemaining,
      steps: [
        AiThinkingStep(
          id: 'step-table-1',
          label: 'Menyusun tabel pengeluaran',
          detail: '${res.table.totalTransactions} transaksi cocok',
          isDone: true,
        ),
      ],
      message: UnifiedAiChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        text: res.narrative,
        isUser: false,
        timestamp: _clock(),
        spendingTableCard: res.table,
      ),
    );
  }

  Stream<AiSseEvent> _emitWalletBalance(
    AiChatContextSnapshot snapshot,
    String sessionId,
    String reqId,
    AiSurfaceMode surfaceMode,
    int nextRemaining,
  ) async* {
    yield AiThinkingStepEvent(
      stepNumber: 1,
      id: 'step-bal-1',
      title: 'Memeriksa saldo dompet aktif',
      detail: 'Ditemukan ${snapshot.wallets.length} dompet terdaftar',
      status: 'completed',
      isDone: true,
      sessionId: sessionId,
      clientRequestId: reqId,
    );

    final total = snapshot.wallets.fold<double>(0.0, (s, w) => s + w.balance);
    final breakdown = snapshot.wallets
        .map((w) => '${w.name} (${LocalAiNlpHelpers.formatIdr(w.balance)})')
        .join(', ');
    final narrative = snapshot.wallets.isEmpty
        ? 'Kamu belum memiliki dompet terdaftar. Tambahkan dompet terlebih dahulu agar saldo bisa dipantau.'
        : 'Total saldo seluruh dompet aktifmu saat ini adalah ${LocalAiNlpHelpers.formatIdr(total)}, terdiri dari $breakdown.';

    yield _finalEvent(
      sessionId: sessionId,
      reqId: reqId,
      surfaceMode: surfaceMode,
      snapshot: snapshot,
      nextRemaining: nextRemaining,
      steps: [
        AiThinkingStep(
          id: 'step-bal-1',
          label: 'Memeriksa saldo dompet aktif',
          isDone: true,
        ),
      ],
      message: UnifiedAiChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        text: narrative,
        isUser: false,
        timestamp: _clock(),
      ),
    );
  }

  Stream<AiSseEvent> _emitGoalDraft(
    String prompt,
    AiChatContextSnapshot snapshot,
    String sessionId,
    String reqId,
    AiSurfaceMode surfaceMode,
    int nextRemaining,
  ) async* {
    final res = LocalAiAnalyticsBuilders.buildGoalDraft(
      prompt: prompt,
      snapshot: snapshot,
      now: _clock(),
    );

    yield AiThinkingStepEvent(
      stepNumber: 1,
      id: 'step-goal-1',
      title: 'Menghitung jadwal tabungan goal',
      detail:
          'Target ${LocalAiNlpHelpers.formatIdr(res.draft.targetAmount)} untuk ${res.months} bulan',
      status: 'completed',
      isDone: true,
      sessionId: sessionId,
      clientRequestId: reqId,
    );

    yield _finalEvent(
      sessionId: sessionId,
      reqId: reqId,
      surfaceMode: surfaceMode,
      snapshot: snapshot,
      nextRemaining: nextRemaining,
      steps: [
        AiThinkingStep(
          id: 'step-goal-1',
          label: 'Menyiapkan draf goal tabungan',
          isDone: true,
        ),
      ],
      message: UnifiedAiChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        text: res.narrative,
        isUser: false,
        timestamp: _clock(),
        goalDraft: res.draft,
      ),
    );
  }

  Stream<AiSseEvent> _emitBudgetDraft(
    String prompt,
    AiChatContextSnapshot snapshot,
    String sessionId,
    String reqId,
    AiSurfaceMode surfaceMode,
    int nextRemaining,
  ) async* {
    final res = LocalAiAnalyticsBuilders.buildBudgetDraft(
      prompt: prompt,
      snapshot: snapshot,
    );

    yield AiThinkingStepEvent(
      stepNumber: 1,
      id: 'step-budget-1',
      title: 'Menyiapkan draf anggaran bulanan',
      detail:
          'Kategori ${res.draft.category} batas ${LocalAiNlpHelpers.formatIdr(res.draft.limitAmount)}',
      status: 'completed',
      isDone: true,
      sessionId: sessionId,
      clientRequestId: reqId,
    );

    yield _finalEvent(
      sessionId: sessionId,
      reqId: reqId,
      surfaceMode: surfaceMode,
      snapshot: snapshot,
      nextRemaining: nextRemaining,
      steps: [
        AiThinkingStep(
          id: 'step-budget-1',
          label: 'Menyiapkan draf budget',
          isDone: true,
        ),
      ],
      message: UnifiedAiChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        text: res.narrative,
        isUser: false,
        timestamp: _clock(),
        budgetDraft: res.draft,
      ),
    );
  }

  Stream<AiSseEvent> _emitBillDraft(
    String prompt,
    AiChatContextSnapshot snapshot,
    String sessionId,
    String reqId,
    AiSurfaceMode surfaceMode,
    int nextRemaining,
  ) async* {
    final res = LocalAiAnalyticsBuilders.buildBillDraft(
      prompt: prompt,
      now: _clock(),
    );

    yield AiThinkingStepEvent(
      stepNumber: 1,
      id: 'step-bill-1',
      title: 'Menyiapkan pengingat tagihan rutin',
      detail: '${res.draft.title} setiap tanggal ${res.draft.dueDay}',
      status: 'completed',
      isDone: true,
      sessionId: sessionId,
      clientRequestId: reqId,
    );

    yield _finalEvent(
      sessionId: sessionId,
      reqId: reqId,
      surfaceMode: surfaceMode,
      snapshot: snapshot,
      nextRemaining: nextRemaining,
      steps: [
        AiThinkingStep(
          id: 'step-bill-1',
          label: 'Menyiapkan draf tagihan',
          isDone: true,
        ),
      ],
      message: UnifiedAiChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        text: res.narrative,
        isUser: false,
        timestamp: _clock(),
        billDraft: res.draft,
      ),
    );
  }

  Stream<AiSseEvent> _emitAdvisory(
    String prompt,
    AiChatContextSnapshot snapshot,
    String sessionId,
    String reqId,
    AiSurfaceMode surfaceMode,
    int nextRemaining,
  ) async* {
    yield AiThinkingStepEvent(
      stepNumber: 1,
      id: 'step-adv-1',
      title: 'Menganalisa topik konsultasi & profil kas',
      detail: 'Memilih paket dan praktisi berizin yang paling sesuai',
      status: 'completed',
      isDone: true,
      sessionId: sessionId,
      clientRequestId: reqId,
    );

    final match = LocalAiConsultantMatcher.match(prompt, snapshot);
    yield _finalEvent(
      sessionId: sessionId,
      reqId: reqId,
      surfaceMode: surfaceMode,
      snapshot: snapshot,
      nextRemaining: nextRemaining,
      steps: [
        AiThinkingStep(
          id: 'step-adv-1',
          label: 'Mencocokkan paket dan praktisi Clarafin',
          isDone: true,
        ),
      ],
      message: UnifiedAiChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        text: match.narrative,
        isUser: false,
        timestamp: _clock(),
        recommendedPackage: match.recommendedPackage,
        recommendedConsultants: match.recommendedConsultants,
      ),
    );
  }

  Stream<AiSseEvent> _emitTransactionOrWalletDraft(
    String prompt,
    AiChatContextSnapshot snapshot,
    String sessionId,
    String reqId,
    AiSurfaceMode surfaceMode,
    int nextRemaining,
  ) async* {
    final requestedWalletPhrase = LocalAiNlpHelpers.extractWalletPhrase(prompt);
    final requestedInst = requestedWalletPhrase != null
        ? LocalAiNlpHelpers.detectInstitutionMention(requestedWalletPhrase)
        : LocalAiNlpHelpers.detectInstitutionMention(prompt);

    WalletModel? matchedWallet;
    if (requestedWalletPhrase != null) {
      matchedWallet = LocalAiNlpHelpers.matchWalletStrict(
        requestedWalletPhrase,
        snapshot.wallets,
      );
    } else if (requestedInst != null) {
      matchedWallet = LocalAiNlpHelpers.matchWalletStrict(
        requestedInst.name,
        snapshot.wallets,
      );
    } else if (snapshot.wallets.isNotEmpty) {
      matchedWallet = snapshot.wallets.first;
    }

    // Prerequisite wallet check: never substitute another wallet when requested wallet is missing.
    if (matchedWallet == null &&
        (requestedInst != null || snapshot.wallets.isEmpty)) {
      final instName = requestedInst?.name ?? 'Dompet Tunai';
      final instId = requestedInst?.id ?? 'cash';
      final instType = TrackerRemoteSyncService.normalizeWalletTypeForApi(
        requestedInst?.type ?? 'cash',
      );
      final existingIds = snapshot.wallets.map((w) => w.id).toList();
      final existingNames = snapshot.wallets.map((w) => w.name).join(' dan ');

      yield AiThinkingStepEvent(
        stepNumber: 1,
        id: 'step-wallet-check',
        title: 'Memeriksa daftar dompet aktif',
        detail: '$instName belum terdaftar pada akun pengguna',
        status: 'completed',
        isDone: true,
        sessionId: sessionId,
        clientRequestId: reqId,
      );

      final narrative = existingNames.isEmpty
          ? 'Kamu belum memiliki dompet $instName. Buat dompet $instName terlebih dahulu di bawah sebelum mencatat transaksi.'
          : 'Kamu belum memiliki dompet $instName (saat ini baru ada $existingNames). Buat dompet $instName di bawah atau pilih dompetmu yang sudah ada.';

      yield _finalEvent(
        sessionId: sessionId,
        reqId: reqId,
        surfaceMode: surfaceMode,
        snapshot: snapshot,
        nextRemaining: nextRemaining,
        steps: [
          AiThinkingStep(
            id: 'step-wallet-check',
            label: 'Memeriksa dompet prasyarat',
            isDone: true,
          ),
        ],
        message: UnifiedAiChatMessage(
          id: _uuid.v4(),
          sessionId: sessionId,
          text: narrative,
          isUser: false,
          timestamp: _clock(),
          walletCreationDraft: AiWalletCreationDraft(
            institutionId: instId,
            institutionName: instName,
            walletType: instType,
            existingWalletIds: existingIds,
          ),
        ),
      );
      return;
    }

    final wallet = matchedWallet!;
    final isIncome = LocalAiNlpHelpers.isIncomePrompt(prompt);
    final clauses = LocalAiNlpHelpers.splitItemClauses(prompt);
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
          walletId: wallet.id,
          walletName: wallet.name,
          occurredAt: _clock(),
        ),
      );
    }

    if (items.isEmpty) {
      yield _finalEvent(
        sessionId: sessionId,
        reqId: reqId,
        surfaceMode: surfaceMode,
        snapshot: snapshot,
        nextRemaining: nextRemaining,
        steps: const [],
        message: UnifiedAiChatMessage(
          id: _uuid.v4(),
          sessionId: sessionId,
          text:
              'Ceritakan transaksi atau pertanyaan keuanganmu dengan nominalnya, misalnya "kopi kenangan 25k pake gopay" atau "uangku lari ke mana aja?".',
          isUser: false,
          timestamp: _clock(),
        ),
      );
      return;
    }

    yield AiThinkingStepEvent(
      stepNumber: 1,
      id: 'step-tx-1',
      title: 'Memvalidasi dompet & kategori kanonis',
      detail: '${items.length} item dipetakan ke dompet ${wallet.name}',
      status: 'completed',
      isDone: true,
      sessionId: sessionId,
      clientRequestId: reqId,
    );

    final total = items.fold<double>(0.0, (s, i) => s + i.amount);
    final summaryText = items
        .map((i) => '${i.title} ${LocalAiNlpHelpers.formatIdr(i.amount)}')
        .join(' dan ');

    yield _finalEvent(
      sessionId: sessionId,
      reqId: reqId,
      surfaceMode: surfaceMode,
      snapshot: snapshot,
      nextRemaining: nextRemaining,
      steps: [
        AiThinkingStep(
          id: 'step-tx-1',
          label: 'Menyiapkan draf transaksi',
          isDone: true,
        ),
      ],
      message: UnifiedAiChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        text:
            'Draf transaksi via ${wallet.name} untuk $summaryText (total ${LocalAiNlpHelpers.formatIdr(total)}) sudah siap. Periksa lalu konfirmasi di bawah.',
        isUser: false,
        timestamp: _clock(),
        transactionDraftGroup: AiTransactionDraftGroup(
          clientMutationId: TrackerRemoteSyncService.sanitizeClientMutationId(
            'tx_${_uuid.v4()}',
          ),
          items: items,
        ),
      ),
    );
  }

  AiFinalResponseEvent _finalEvent({
    required String sessionId,
    required String reqId,
    required AiSurfaceMode surfaceMode,
    required AiChatContextSnapshot snapshot,
    required int nextRemaining,
    required List<AiThinkingStep> steps,
    required UnifiedAiChatMessage message,
  }) {
    final withTrace = steps.isEmpty
        ? message
        : message.copyWith(
            thinkingTrace: AiThinkingTrace(steps: steps, isLive: false),
          );
    return AiFinalResponseEvent(
      message: withTrace,
      sessionId: sessionId,
      clientRequestId: reqId,
      surfaceMode: surfaceMode,
      isPrefiltered: false,
      planType: snapshot.planType,
      quotaTotal: snapshot.quotaTotal,
      quotaUsed: snapshot.isUnlimited
          ? 0
          : max(0, snapshot.quotaTotal - nextRemaining),
      quotaRemaining: nextRemaining,
    );
  }
}
