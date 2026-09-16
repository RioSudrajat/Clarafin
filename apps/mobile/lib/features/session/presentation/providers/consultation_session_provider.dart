import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/session_item_model.dart';
import '../../domain/models/consultation_transaction_model.dart';

class ConsultationSessionState {
  final List<SessionItemModel> upcomingSessions;
  final List<SessionItemModel> pastSessions;
  final List<ConsultationTransactionModel> transactions;

  const ConsultationSessionState({
    required this.upcomingSessions,
    required this.pastSessions,
    required this.transactions,
  });

  ConsultationSessionState copyWith({
    List<SessionItemModel>? upcomingSessions,
    List<SessionItemModel>? pastSessions,
    List<ConsultationTransactionModel>? transactions,
  }) {
    return ConsultationSessionState(
      upcomingSessions: upcomingSessions ?? this.upcomingSessions,
      pastSessions: pastSessions ?? this.pastSessions,
      transactions: transactions ?? this.transactions,
    );
  }
}

class ConsultationSessionNotifier extends Notifier<ConsultationSessionState> {
  @override
  ConsultationSessionState build() {
    return ConsultationSessionState(
      upcomingSessions: const [], // Empty by default as requested
      pastSessions: const [
        // Minimal 1 mock data sesi yang telah berlalu as requested
        SessionItemModel(
          id: 'past-01',
          consultantName: 'Rian Pratama, CFP®',
          consultantRole: 'Perencana Keuangan Independen',
          sessionTitle: 'Konsultasi CFP® Komprehensif',
          scheduleTime: '10 Sep 2026 • 10:00 WIB',
          sessionMethod: 'Chat Konsultasi (Selesai)',
          status: SessionStatus.completed,
          bookingCode: 'HF-CFP-89210',
          avatarUrl: 'https://i.pravatar.cc/150?img=12',
          rating: 5.0,
        ),
      ],
      transactions: List.from(ConsultationTransactionModel.initialDummyTransactions),
    );
  }

  void addBookingSession({
    required SessionItemModel session,
    required ConsultationTransactionModel transaction,
  }) {
    state = state.copyWith(
      upcomingSessions: [session, ...state.upcomingSessions],
      transactions: [transaction, ...state.transactions],
    );
  }

  void updateRating(String sessionId, double rating) {
    final updatedPast = state.pastSessions.map((session) {
      if (session.id == sessionId) {
        return SessionItemModel(
          id: session.id,
          consultantName: session.consultantName,
          consultantRole: session.consultantRole,
          sessionTitle: session.sessionTitle,
          scheduleTime: session.scheduleTime,
          sessionMethod: session.sessionMethod,
          status: session.status,
          bookingCode: session.bookingCode,
          avatarUrl: session.avatarUrl,
          rating: rating,
        );
      }
      return session;
    }).toList();

    state = state.copyWith(pastSessions: updatedPast);
  }
}

final consultationSessionProvider =
    NotifierProvider<ConsultationSessionNotifier, ConsultationSessionState>(() {
  return ConsultationSessionNotifier();
});
