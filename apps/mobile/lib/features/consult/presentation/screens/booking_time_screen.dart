import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_date_range_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_stepper.dart';
import '../widgets/consultant_mini_profile.dart';
import '../widgets/sticky_booking_bottom_bar.dart';

class BookingTimeScreen extends ConsumerStatefulWidget {
  final String consultantId;
  const BookingTimeScreen({super.key, required this.consultantId});

  @override
  ConsumerState<BookingTimeScreen> createState() => _BookingTimeScreenState();
}

class _BookingTimeScreenState extends ConsumerState<BookingTimeScreen> {
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime(2026, 6, 15),
    end: DateTime(2026, 7, 1),
  );
  DateTime? _selectedDate = DateTime(2026, 6, 15);
  final List<String> _selectedTimes = [];

  final List<String> _pagiSlots = ['09:00 - 10:00', '10:00 - 11:00'];
  final List<String> _siangSlots = ['13:00 - 14:00', '14:00 - 15:00'];
  final List<String> _soreSlots = ['16:00 - 17:00', '17:00 - 18:00'];
  final List<String> _malamSlots = ['19:00 - 20:00', '20:00 - 21:00'];

  int _parseSessionCount(String tier) {
    final match = RegExp(r'\((\d+)\s+Sesi\)').firstMatch(tier);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }
    return 1;
  }

  List<DateTime> _generateDatesInRange(DateTimeRange range) {
    final daysCount = range.end.difference(range.start).inDays + 1;
    return List.generate(daysCount, (index) => range.start.add(Duration(days: index)));
  }

  String _formatDateRangeText(DateTimeRange range) {
    final df = DateFormat('dd MMM', 'id_ID');
    try {
      return '${df.format(range.start)} - ${df.format(range.end)}';
    } catch (_) {
      final dfFallback = DateFormat('dd MMM');
      return '${dfFallback.format(range.start)} - ${dfFallback.format(range.end)}';
    }
  }

  bool _isAllSessionsSelected(int count) {
    return _selectedTimes.length == count && _selectedDate != null;
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final bookingNotifier = ref.read(bookingProvider.notifier);

    final sessionCount = _parseSessionCount(bookingState.selectedTier);

    // Sync from provider if our local selected times is empty but provider has selection
    if (bookingState.selectedTimes.isNotEmpty && _selectedTimes.isEmpty) {
      _selectedDate = bookingState.selectedDates.first;
      _selectedTimes.clear();
      _selectedTimes.addAll(bookingState.selectedTimes);
    }

    final dates = _generateDatesInRange(_selectedRange);

    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Buat Jadwal'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 44, // Make app bar more compact
      ),
      body: Column(
        children: [
          // Step progress indicator (Step 2 Active)
          const BookingStepper(activeStep: 2),
          // Hapus garis pembatas dibawah stepper
          
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // Prevent bouncing overscroll
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mini Profile
                  const ConsultantMiniProfile(),
                  
                  // Content padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date selector header
                        const Text(
                          'Pilih Tanggal',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        
                        // Datepicker Button
                        _buildDatePickerButton(),
                        const SizedBox(height: 12),
                        
                        // Horizontal Date Scroll
                        SizedBox(
                          height: 76,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: dates.length,
                            itemBuilder: (context, index) {
                              final date = dates[index];
                              
                              // Make Tuesday, 16 Jun 2026 disabled to match reference
                              final isDisabled = date.year == 2026 && date.month == 6 && date.day == 16;
                              
                              final isSelected = !isDisabled && _selectedDate != null && DateUtils.isSameDay(date, _selectedDate!);
                              
                              String dayName = '';
                              try {
                                dayName = DateFormat('E', 'id_ID').format(date);
                              } catch (_) {
                                dayName = DateFormat('E').format(date);
                              }

                              String formattedDate = '';
                              try {
                                formattedDate = DateFormat('d MMM', 'id_ID').format(date);
                              } catch (_) {
                                formattedDate = DateFormat('d MMM').format(date);
                              }

                              return GestureDetector(
                                onTap: isDisabled
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedDate = date;
                                          _selectedTimes.clear(); // Clear selected times when date changes
                                        });
                                        _updateProviderData(bookingNotifier);
                                      },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 68,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: isDisabled
                                        ? Colors.grey.shade200
                                        : (isSelected
                                            ? AppColors.accentBlue.withValues(alpha: 0.15)
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0F766E)
                                          : (isDisabled ? Colors.transparent : Colors.grey.shade200),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDisabled
                                              ? Colors.grey.shade500
                                              : (isSelected ? const Color(0xFF0F766E) : AppColors.textSecondary),
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dayName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDisabled ? Colors.grey.shade500 : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Time slots header
                        const Text(
                          'Pilih Waktu',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        
                        // Timezone Blue Banner
                        _buildTimezoneInfoBox(),
                        const SizedBox(height: 20),

                        // Pagi Category
                        _buildTimeCategory('Pagi', _pagiSlots, sessionCount, bookingNotifier),
                        const SizedBox(height: 20),

                        // Siang Category
                        _buildTimeCategory('Siang', _siangSlots, sessionCount, bookingNotifier),
                        const SizedBox(height: 20),

                        // Sore Category
                        _buildTimeCategory('Sore', _soreSlots, sessionCount, bookingNotifier),
                        const SizedBox(height: 20),

                        // Malam Category
                        _buildTimeCategory('Malam', _malamSlots, sessionCount, bookingNotifier),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Bar
          StickyBookingBottomBar(
            price: bookingState.totalPrice,
            onTap: _isAllSessionsSelected(sessionCount)
                ? () {
                    context.push('/booking/${widget.consultantId}/pre-consult');
                  }
                : null, // Disabled if not all slots chosen
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton() {
    return GestureDetector(
      onTap: () async {
        final picked = await showCustomDateRangePicker(
          context,
          initialRange: _selectedRange,
        );
        if (picked != null) {
          setState(() {
            _selectedRange = picked;
            // Select the start date of the new range by default
            _selectedDate = picked.start;
            // Reset selected times when date/range changes
            _selectedTimes.clear();
          });
          _updateProviderData(ref.read(bookingProvider.notifier));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            const Text(
              'Pilih tanggal',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              _formatDateRangeText(_selectedRange),
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimezoneInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
      ),
      child: const Text(
        'Waktu konseling yang ditampilkan sudah disesuaikan dengan zona waktu perangkat anda (WIB)',
        style: TextStyle(
          fontSize: 11.5,
          color: Color(0xFF0F766E),
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildTimeCategory(String title, List<String> slots, int sessionCount, BookingNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: slots.map((slot) {
            final timeStart = slot.split(' - ')[0];
            final isSelected = _selectedTimes.contains(timeStart);
            return GestureDetector(
              onTap: () {
                // Fallback: if no date chosen yet, choose range start
                _selectedDate ??= _selectedRange.start;
                setState(() {
                  if (isSelected) {
                    _selectedTimes.remove(timeStart);
                  } else {
                    if (_selectedTimes.length < sessionCount) {
                      _selectedTimes.add(timeStart);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Anda hanya dapat memilih $sessionCount sesi waktu.'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                });
                _updateProviderData(notifier);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF0F766E) : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _updateProviderData(BookingNotifier notifier) {
    if (_selectedDate == null) return;
    final confirmedDates = List<DateTime>.filled(_selectedTimes.length, _selectedDate!);
    notifier.updateDateTimeList(confirmedDates, List.from(_selectedTimes));
  }
}
