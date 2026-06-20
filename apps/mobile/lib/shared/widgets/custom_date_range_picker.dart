import 'package:flutter/material.dart';

Future<DateTimeRange?> showCustomDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialRange,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          child: CustomDateRangePickerContent(initialRange: initialRange),
        ),
      );
    },
  );
}

class CustomDateRangePickerContent extends StatefulWidget {
  final DateTimeRange? initialRange;
  const CustomDateRangePickerContent({super.key, this.initialRange});

  @override
  State<CustomDateRangePickerContent> createState() => _CustomDateRangePickerContentState();
}

class _CustomDateRangePickerContentState extends State<CustomDateRangePickerContent> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialRange?.start;
    _endDate = widget.initialRange?.end;
    _currentMonth = _startDate ?? DateTime.now();
  }

  void _onDateClick(DateTime date) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = date;
        _endDate = null;
      } else {
        if (date.isBefore(_startDate!)) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      }
    });
  }

  String _formatDateHeader(DateTime? date) {
    if (date == null) return '-';
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day.toString().padLeft(2, '0')} $monthName';
  }

  String _formatMonthYear(DateTime month) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  List<DateTime> _generateCalendarDays(DateTime month) {
    final year = month.year;
    final m = month.month;
    final firstDay = DateTime(year, m, 1);
    final totalDays = DateTime(year, m + 1, 0).day;
    
    final padding = firstDay.weekday - 1; 
    final days = <DateTime>[];
    
    final prevYear = m == 1 ? year - 1 : year;
    final prevMonth = m == 1 ? 12 : m - 1;
    final prevTotalDays = DateTime(prevYear, prevMonth + 1, 0).day;
    for (int i = padding - 1; i >= 0; i--) {
      days.add(DateTime(prevYear, prevMonth, prevTotalDays - i));
    }
    
    for (int i = 1; i <= totalDays; i++) {
      days.add(DateTime(year, m, i));
    }
    
    final remaining = 42 - days.length;
    final nextYear = m == 12 ? year + 1 : year;
    final nextMonth = m == 12 ? 1 : m + 1;
    for (int i = 1; i <= remaining; i++) {
      days.add(DateTime(nextYear, nextMonth, i));
    }
    
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _generateCalendarDays(_currentMonth);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Selection Display Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Dari', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateHeader(_startDate),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF073351), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 32, color: Colors.grey.shade200),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Hingga', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateHeader(_endDate),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF073351), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Divider(color: Colors.grey.shade100, height: 1),
        const SizedBox(height: 16),

        // Month Selection Header with Arrows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                });
              },
            ),
            Text(
              _formatMonthYear(_currentMonth),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF073351)),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Day of Week Header row
        Row(
          children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'].map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF073351)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 0,
            childAspectRatio: 1,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            return _buildCell(days[index]);
          },
        ),
        const SizedBox(height: 24),

        // Actions Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF073351),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (_startDate != null && _endDate != null)
                    ? () => Navigator.of(context).pop(DateTimeRange(start: _startDate!, end: _endDate!))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF073351),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: Colors.grey.shade400,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Terapkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCell(DateTime date) {
    final isCurrentMonth = date.month == _currentMonth.month;
    final isStart = _startDate != null && DateUtils.isSameDay(date, _startDate);
    final isEnd = _endDate != null && DateUtils.isSameDay(date, _endDate);
    final inRange = _startDate != null && _endDate != null && date.isAfter(_startDate!) && date.isBefore(_endDate!);

    Widget cellContent = Center(
      child: Text(
        '${date.day}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: (isStart || isEnd) ? FontWeight.bold : FontWeight.w500,
          color: (isStart || isEnd)
              ? Colors.white
              : (isCurrentMonth
                  ? const Color(0xFF073351)
                  : Colors.grey.shade300),
        ),
      ),
    );

    Widget? highlightBackground;
    if (_startDate != null && _endDate != null && !DateUtils.isSameDay(_startDate, _endDate)) {
      if (inRange) {
        highlightBackground = Container(
          color: const Color(0xFFB2C5D4).withValues(alpha: 0.5), // Match screenshot light blue-gray
        );
      } else if (isStart) {
        highlightBackground = Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            Expanded(
              child: Container(
                color: const Color(0xFFB2C5D4).withValues(alpha: 0.5),
              ),
            ),
          ],
        );
      } else if (isEnd) {
        highlightBackground = Row(
          children: [
            Expanded(
              child: Container(
                color: const Color(0xFFB2C5D4).withValues(alpha: 0.5),
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        );
      }
    }

    return GestureDetector(
      onTap: () => _onDateClick(date),
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            if (highlightBackground != null) Positioned.fill(child: highlightBackground),
            Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isStart || isEnd) ? const Color(0xFF073351) : Colors.transparent,
                ),
                child: cellContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
