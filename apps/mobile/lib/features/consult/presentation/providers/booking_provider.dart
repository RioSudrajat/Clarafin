import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingState {
  final String serviceType; // 'Online' | 'Offline'
  final String onlineMethod; // 'Call' | 'Video' | 'Chat'
  final String selectedTier; // 'Quick Consult Premium' | 'Deep Dive Planning Ultimate'
  final DateTime selectedDate;
  final String selectedTime; // e.g. '10:00'
  final List<DateTime> selectedDates; // List of dates for multiple sessions
  final List<String> selectedTimes; // List of times for multiple sessions
  final String topic;
  final String description;
  final String? fileName;
  final double totalPrice;

  BookingState({
    required this.serviceType,
    required this.onlineMethod,
    required this.selectedTier,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedDates,
    required this.selectedTimes,
    required this.topic,
    required this.description,
    this.fileName,
    required this.totalPrice,
  });

  BookingState copyWith({
    String? serviceType,
    String? onlineMethod,
    String? selectedTier,
    DateTime? selectedDate,
    String? selectedTime,
    List<DateTime>? selectedDates,
    List<String>? selectedTimes,
    String? topic,
    String? description,
    String? fileName,
    double? totalPrice,
  }) {
    return BookingState(
      serviceType: serviceType ?? this.serviceType,
      onlineMethod: onlineMethod ?? this.onlineMethod,
      selectedTier: selectedTier ?? this.selectedTier,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedDates: selectedDates ?? this.selectedDates,
      selectedTimes: selectedTimes ?? this.selectedTimes,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() {
    return BookingState(
      serviceType: 'Online',
      onlineMethod: 'Video',
      selectedTier: '',
      selectedDate: DateTime.now(),
      selectedTime: '',
      selectedDates: const [],
      selectedTimes: const [],
      topic: '',
      description: '',
      totalPrice: 0.0,
    );
  }

  void updateServiceType(String type) {
    state = state.copyWith(serviceType: type);
  }

  void updateOnlineMethod(String method) {
    state = state.copyWith(onlineMethod: method);
  }

  void updateSelectedTier(String tier, double price) {
    state = state.copyWith(selectedTier: tier, totalPrice: price);
  }

  void updateDateTime(DateTime date, String time) {
    state = state.copyWith(selectedDate: date, selectedTime: time);
  }

  void updateDateTimeList(List<DateTime> dates, List<String> times) {
    state = state.copyWith(
      selectedDates: dates,
      selectedTimes: times,
      // Fallback single values to the first session for backward compatibility
      selectedDate: dates.isNotEmpty ? dates[0] : state.selectedDate,
      selectedTime: times.isNotEmpty ? times[0] : state.selectedTime,
    );
  }

  void updatePreConsult({required String topic, required String description, String? fileName}) {
    state = state.copyWith(topic: topic, description: description, fileName: fileName);
  }
  
  void reset() {
    state = BookingState(
      serviceType: 'Online',
      onlineMethod: 'Video',
      selectedTier: '',
      selectedDate: DateTime.now(),
      selectedTime: '',
      selectedDates: const [],
      selectedTimes: const [],
      topic: '',
      description: '',
      totalPrice: 0.0,
    );
  }
}

final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(() {
  return BookingNotifier();
});
