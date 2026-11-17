import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingState {
  final String serviceType; // 'Online' | 'Offline'
  final String onlineMethod; // 'Call' | 'Video' | 'Chat'
  final String selectedTier; // 'Quick Consult Premium' | 'Deep Dive Planning Ultimate'
  final String? selectedPackageCode;
  final DateTime selectedDate;
  final String selectedTime; // e.g. '10:00'
  final List<DateTime> selectedDates; // List of dates for multiple sessions
  final List<String> selectedTimes; // List of times for multiple sessions
  final String topic;
  final List<String> prefilledTopics;
  final String description;
  final String expectations;
  final String? fileName;
  final double totalPrice;
  final bool isPrefilledFromAi;

  BookingState({
    required this.serviceType,
    required this.onlineMethod,
    required this.selectedTier,
    this.selectedPackageCode,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedDates,
    required this.selectedTimes,
    required this.topic,
    this.prefilledTopics = const [],
    required this.description,
    this.expectations = '',
    this.fileName,
    required this.totalPrice,
    this.isPrefilledFromAi = false,
  });

  BookingState copyWith({
    String? serviceType,
    String? onlineMethod,
    String? selectedTier,
    String? selectedPackageCode,
    bool clearSelectedPackageCode = false,
    DateTime? selectedDate,
    String? selectedTime,
    List<DateTime>? selectedDates,
    List<String>? selectedTimes,
    String? topic,
    List<String>? prefilledTopics,
    String? description,
    String? expectations,
    String? fileName,
    double? totalPrice,
    bool? isPrefilledFromAi,
  }) {
    return BookingState(
      serviceType: serviceType ?? this.serviceType,
      onlineMethod: onlineMethod ?? this.onlineMethod,
      selectedTier: selectedTier ?? this.selectedTier,
      selectedPackageCode: clearSelectedPackageCode
          ? null
          : (selectedPackageCode ?? this.selectedPackageCode),
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedDates: selectedDates ?? this.selectedDates,
      selectedTimes: selectedTimes ?? this.selectedTimes,
      topic: topic ?? this.topic,
      prefilledTopics: prefilledTopics ?? this.prefilledTopics,
      description: description ?? this.description,
      expectations: expectations ?? this.expectations,
      fileName: fileName ?? this.fileName,
      totalPrice: totalPrice ?? this.totalPrice,
      isPrefilledFromAi: isPrefilledFromAi ?? this.isPrefilledFromAi,
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
      selectedPackageCode: null,
      selectedDate: DateTime.now(),
      selectedTime: '',
      selectedDates: const [],
      selectedTimes: const [],
      topic: '',
      prefilledTopics: const [],
      description: '',
      expectations: '',
      totalPrice: 0.0,
      isPrefilledFromAi: false,
    );
  }

  static int parseSessionCount(String tier) {
    final match = RegExp(r'(\d+)\s+Sesi').firstMatch(tier);
    if (match != null) {
      final parsed = int.tryParse(match.group(1) ?? '');
      if (parsed == 1 || parsed == 2 || parsed == 3 || parsed == 8) {
        return parsed!;
      }
    }
    return 1;
  }

  static double calculatePackagePrice(int sessions, double unitPrice) {
    if (sessions == 3) return (unitPrice * 3 * 0.93).roundToDouble();
    if (sessions == 8) return (unitPrice * 8 * 0.88).roundToDouble();
    return (unitPrice * (sessions > 0 ? sessions : 1)).roundToDouble();
  }

  static double resolveUnitPrice({
    required double basePricePerSession,
    required double offlinePricePerSession,
    required bool isOnline,
  }) {
    if (isOnline) return basePricePerSession;
    return offlinePricePerSession > 0
        ? offlinePricePerSession
        : basePricePerSession * 1.5;
  }

  void updateServiceType(String type) {
    state = state.copyWith(serviceType: type);
  }

  void updateOnlineMethod(String method) {
    state = state.copyWith(onlineMethod: method);
  }

  void updateSelectedTier(String tier, double price, {String? packageCode}) {
    state = state.copyWith(
      selectedTier: tier,
      totalPrice: price,
      selectedPackageCode: packageCode,
      clearSelectedPackageCode: tier.isEmpty && packageCode == null,
    );
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

  void updatePreConsult({
    required String topic,
    required String description,
    String? expectations,
    String? fileName,
  }) {
    state = state.copyWith(
      topic: topic,
      description: description,
      expectations: expectations,
      fileName: fileName,
    );
  }

  void prefillFromAi({
    required String packageCode,
    required String selectedTierLabel,
    required double unitPrice,
    String serviceType = 'Online',
    List<String> topics = const [],
    required String description,
    String expectations = '',
  }) {
    final normalizedType =
        serviceType.trim().toLowerCase() == 'offline' ? 'Offline' : 'Online';
    final normalizedTopics = topics
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    state = BookingState(
      serviceType: normalizedType,
      onlineMethod: 'Video',
      selectedTier: selectedTierLabel,
      selectedPackageCode: packageCode,
      selectedDate: DateTime.now(),
      selectedTime: '',
      selectedDates: const [],
      selectedTimes: const [],
      topic: normalizedTopics.join(', '),
      prefilledTopics: List<String>.unmodifiable(normalizedTopics),
      description: description,
      expectations: expectations,
      fileName: null,
      totalPrice: unitPrice,
      isPrefilledFromAi: true,
    );
  }

  void reset() {
    state = BookingState(
      serviceType: 'Online',
      onlineMethod: 'Video',
      selectedTier: '',
      selectedPackageCode: null,
      selectedDate: DateTime.now(),
      selectedTime: '',
      selectedDates: const [],
      selectedTimes: const [],
      topic: '',
      prefilledTopics: const [],
      description: '',
      expectations: '',
      fileName: null,
      totalPrice: 0.0,
      isPrefilledFromAi: false,
    );
  }
}

final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(() {
  return BookingNotifier();
});
