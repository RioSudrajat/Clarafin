import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_date_picker_strip.dart';
import '../widgets/booking_stepper.dart';
import '../widgets/booking_time_slots_grid.dart';
import '../widgets/sticky_booking_bottom_bar.dart';

class BookingTimeScreen extends ConsumerStatefulWidget {
  final String consultantId;
  const BookingTimeScreen({super.key, required this.consultantId});

  @override
  ConsumerState<BookingTimeScreen> createState() => _BookingTimeScreenState();
}

class _BookingTimeScreenState extends ConsumerState<BookingTimeScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final List<String> _selectedTimes = [];

  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = List.generate(14, (i) => today.add(Duration(days: i + 1)));
    _selectedDate = _dates.first;
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Pilih Jadwal Konsultasi',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: Colors.black12),
        ),
      ),
      body: Column(
        children: [
          const BookingStepper(activeStep: 2),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                        // Date picker strip
                        BookingDatePickerStrip(
                          dates: _dates,
                          selectedDate: _selectedDate,
                          onSelectDate: (date) {
                            setState(() => _selectedDate = date);
                          },
                          onSelectRange: (range) {
                            final count = range.end.difference(range.start).inDays + 1;
                            final newDates = List.generate(count, (i) => range.start.add(Duration(days: i)));
                            setState(() {
                              _dates = newDates;
                              _selectedDate = range.start;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Time slots grid
                        BookingTimeSlotsGrid(
                          selectedTimes: _selectedTimes,
                          onToggleTime: (slot) => _onToggleTime(slot, sessionCount, bookingNotifier),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          StickyBookingBottomBar(
            price: bookingState.totalPrice,
            buttonText: 'Lanjut Pre-Assessment',
            onTap: isComplete
                ? () => context.push('/booking/${widget.consultantId}/pre-consult')
                : null,
          ),
        ],
      ),
    );
  }
}
