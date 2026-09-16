import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConsultantFilterState {
  final Set<String> specializations;
  final double minFee;
  final double maxFee;
  final double minRating;
  final Set<String> methods;
  final int minExperienceYears;

  const ConsultantFilterState({
    this.specializations = const {},
    this.minFee = 100000,
    this.maxFee = 1500000,
    this.minRating = 0.0,
    this.methods = const {},
    this.minExperienceYears = 0,
  });

  bool get hasActiveFilters {
    return specializations.isNotEmpty ||
        minFee > 100000 ||
        maxFee < 1500000 ||
        minRating > 0.0 ||
        methods.isNotEmpty ||
        minExperienceYears > 0;
  }

  int get activeFilterCount {
    int count = 0;
    if (specializations.isNotEmpty) count += specializations.length;
    if (minFee > 100000 || maxFee < 1500000) count++;
    if (minRating > 0.0) count++;
    if (methods.isNotEmpty) count += methods.length;
    if (minExperienceYears > 0) count++;
    return count;
  }

  ConsultantFilterState copyWith({
    Set<String>? specializations,
    double? minFee,
    double? maxFee,
    double? minRating,
    Set<String>? methods,
    int? minExperienceYears,
  }) {
    return ConsultantFilterState(
      specializations: specializations ?? this.specializations,
      minFee: minFee ?? this.minFee,
      maxFee: maxFee ?? this.maxFee,
      minRating: minRating ?? this.minRating,
      methods: methods ?? this.methods,
      minExperienceYears: minExperienceYears ?? this.minExperienceYears,
    );
  }
}

class ConsultantFilterNotifier extends Notifier<ConsultantFilterState> {
  @override
  ConsultantFilterState build() => const ConsultantFilterState();

  void toggleSpecialization(String spec) {
    final current = Set<String>.from(state.specializations);
    if (current.contains(spec)) {
      current.remove(spec);
    } else {
      current.add(spec);
    }
    state = state.copyWith(specializations: current);
  }

  void setFeeRange(double min, double max) {
    state = state.copyWith(minFee: min, maxFee: max);
  }

  void setMinRating(double rating) {
    state = state.copyWith(minRating: rating);
  }

  void toggleMethod(String method) {
    final current = Set<String>.from(state.methods);
    if (current.contains(method)) {
      current.remove(method);
    } else {
      current.add(method);
    }
    state = state.copyWith(methods: current);
  }

  void setMinExperienceYears(int years) {
    state = state.copyWith(minExperienceYears: years);
  }

  void reset() {
    state = const ConsultantFilterState();
  }
}

final consultantFilterProvider =
    NotifierProvider<ConsultantFilterNotifier, ConsultantFilterState>(() {
  return ConsultantFilterNotifier();
});
