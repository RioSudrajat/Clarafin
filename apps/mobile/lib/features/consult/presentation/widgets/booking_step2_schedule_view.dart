import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_provider.dart';
import 'booking_date_picker_strip.dart';
import 'booking_time_slots_grid.dart';

class BookingStep2ScheduleView extends ConsumerStatefulWidget {
  final String consultantId;
  final ValueChanged<bool> onValidationChanged;

  const BookingStep2ScheduleView({
    super.key,
    required this.consultantId,
    required this.onValidationChanged,
  });

  @override
  ConsumerState<BookingStep2ScheduleView> createState() => _BookingStep2ScheduleViewState();
}

class _BookingStep2ScheduleViewState extends ConsumerState<BookingStep2ScheduleView> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final List<String> _selectedTimes = [];
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = List.generate(14, (i) => today.add(Duration(days: i + 1)));
    _selectedDate = _dates.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(bookingProvider);
      final count = _parseSessionCount(state.selectedTier);
      if (state.selectedTime.isNotEmpty && _selectedTimes.isEmpty) {
        _selectedTimes.add(state.selectedTime);
      }
      widget.onValidationChanged(_selectedTimes.length == count);
    });
  }

  int _parseSessionCount(String tier) {
    final match = RegExp(r'\((\d+)\s+Sesi\)').firstMatch(tier);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }
    return 1;
  }

  void _onToggleTime(String slot, int maxSessions, BookingNotifier notifier) {
    setState(() {
      if (_selectedTimes.contains(slot)) {
        _selectedTimes.remove(slot);
      } else {
        if (_selectedTimes.length < maxSessions) {
          _selectedTimes.add(slot);
        } else if (maxSessions == 1) {
          _selectedTimes.clear();
          _selectedTimes.add(slot);
        }
      }
    });

    final isComplete = _selectedTimes.length == maxSessions;
    widget.onValidationChanged(isComplete);

    if (_selectedTimes.isNotEmpty) {
      notifier.updateDateTimeList(
        List.filled(_selectedTimes.length, _selectedDate),
        _selectedTimes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final bookingNotifier = ref.read(bookingProvider.notifier);
    final sessionCount = _parseSessionCount(bookingState.selectedTier);
    final isComplete = _selectedTimes.length == sessionCount;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sessionCount > 1) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isComplete ? const Color(0xFFE0F2F6) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    isComplete ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    size: 18,
                    color: isComplete ? const Color(0xFF0F758A) : Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paket $sessionCount Sesi: ${_selectedTimes.length}/$sessionCount slot terpilih',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          BookingDatePickerStrip(
            dates: _dates,
            selectedDate: _selectedDate,
            onSelectDate: (date) {
              setState(() => _selectedDate = date);
              if (_selectedTimes.isNotEmpty) {
                bookingNotifier.updateDateTimeList(
                  List.filled(_selectedTimes.length, date),
                  _selectedTimes,
                );
              }
            },
          ),
          const SizedBox(height: 24),
          BookingTimeSlotsGrid(
            selectedTimes: _selectedTimes,
            onToggleTime: (slot) => _onToggleTime(slot, sessionCount, bookingNotifier),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
