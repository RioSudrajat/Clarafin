import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/custom_date_range_picker.dart';

class BookingDatePickerStrip extends StatelessWidget {
  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<DateTimeRange>? onSelectRange;

  const BookingDatePickerStrip({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.onSelectDate,
    this.onSelectRange,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatRange() {
    if (dates.isEmpty) return '';
    try {
      final start = DateFormat('d MMM', 'id_ID').format(dates.first);
      final end = DateFormat('d MMM', 'id_ID').format(dates.last);
      return '$start - $end';
    } catch (_) {
      final start = DateFormat('d MMM').format(dates.first);
      final end = DateFormat('d MMM').format(dates.last);
      return '$start - $end';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Tanggal',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        // ── Date Range Header Card (Tap to open Custom Date Range Picker) ──
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final initialRange = dates.isNotEmpty
                ? DateTimeRange(start: dates.first, end: dates.last)
                : DateTimeRange(start: now, end: now.add(const Duration(days: 13)));
            final picked = await showCustomDateRangePicker(
              context,
              initialRange: initialRange,
            );
            if (picked != null && onSelectRange != null) {
              onSelectRange!(picked);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black, width: 1.8),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_month_outlined, size: 20, color: Colors.black87),
                    SizedBox(width: 10),
                    Text(
                      'Pilih tanggal',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      _formatRange(),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F758A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F758A), size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Horizontal Date Cards Strip ──
        SizedBox(
          height: 74,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            itemCount: dates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = _isSameDay(date, selectedDate);

              String dayName = '';
              String monthName = '';
              try {
                dayName = DateFormat('EEE', 'id_ID').format(date);
                monthName = DateFormat('MMM', 'id_ID').format(date);
              } catch (_) {
                dayName = DateFormat('EEE').format(date);
                monthName = DateFormat('MMM').format(date);
              }

              return GestureDetector(
                onTap: () => onSelectDate(date),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 66,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE0F2F6) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? Colors.black : const Color(0xFFD1D5DB),
                      width: isSelected ? 2.0 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(0, 2.5),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day} $monthName',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFF0F758A) : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dayName,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.black : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
