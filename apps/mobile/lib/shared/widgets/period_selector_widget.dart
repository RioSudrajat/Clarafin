import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutalism_decorations.dart';
import 'custom_date_range_picker.dart';

enum PeriodType { day, week, month, year, custom }

class PeriodSelectorWidget extends StatefulWidget {
  final PeriodType initialType;
  final Function(PeriodType type, DateTime start, DateTime end) onPeriodChanged;

  const PeriodSelectorWidget({
    super.key,
    this.initialType = PeriodType.month,
    required this.onPeriodChanged,
  });

  @override
  State<PeriodSelectorWidget> createState() => _PeriodSelectorWidgetState();
}

class _PeriodSelectorWidgetState extends State<PeriodSelectorWidget> {
  late PeriodType _selectedType;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    // Delay slightly to avoid triggering state update during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerCallback();
    });
  }

  void _triggerCallback() {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (_selectedType) {
      case PeriodType.day:
        start = now.subtract(const Duration(days: 1));
        end = now;
        break;
      case PeriodType.week:
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
      case PeriodType.month:
        start = now.subtract(const Duration(days: 30));
        end = now;
        break;
      case PeriodType.year:
        start = now.subtract(const Duration(days: 365));
        end = now;
        break;
      case PeriodType.custom:
        if (_customRange != null) {
          start = DateTime(_customRange!.start.year, _customRange!.start.month, _customRange!.start.day);
          final chosenEnd = DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day, 23, 59, 59, 999);
          end = chosenEnd.isAfter(now) ? now : chosenEnd;
        } else {
          start = now.subtract(const Duration(days: 7));
          end = now;
          _customRange = DateTimeRange(start: start, end: end);
        }
        break;
    }
    widget.onPeriodChanged(_selectedType, start, end);
  }

  Future<void> _selectCustomRange() async {
    final now = DateTime.now();
    final initialRange = _customRange ?? DateTimeRange(
      start: now.subtract(const Duration(days: 6)),
      end: now,
    );

    final picked = await showCustomDateRangePicker(
      context,
      initialRange: initialRange,
    );

    if (picked != null) {
      setState(() {
        _selectedType = PeriodType.custom;
        _customRange = picked;
      });
      _triggerCallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            _buildChip(PeriodType.day, 'Hari'),
            const SizedBox(width: 8),
            _buildChip(PeriodType.week, 'Minggu'),
            const SizedBox(width: 8),
            _buildChip(PeriodType.month, 'Bulan'),
            const SizedBox(width: 8),
            _buildChip(PeriodType.year, 'Tahun'),
            const SizedBox(width: 8),
            _buildCustomChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(PeriodType type, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
        _triggerCallback();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? NeoBrutalism.lime : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.black,
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: isSelected ? NeoBrutalism.dark : const Color(0xFF4B5563),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomChip() {
    final isSelected = _selectedType == PeriodType.custom;
    String label = 'Custom';
    if (isSelected && _customRange != null) {
      final df = DateFormat('dd MMM', 'id_ID');
      String startStr;
      String endStr;
      try {
        startStr = df.format(_customRange!.start);
        endStr = df.format(_customRange!.end);
      } catch (e) {
        final dfFallback = DateFormat('d MMM');
        startStr = dfFallback.format(_customRange!.start);
        endStr = dfFallback.format(_customRange!.end);
      }
      label = '$startStr – $endStr';
    }

    return GestureDetector(
      onTap: () async {
        await _selectCustomRange();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? NeoBrutalism.lime : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.black,
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: isSelected ? NeoBrutalism.dark : const Color(0xFF4B5563),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: isSelected ? NeoBrutalism.dark : const Color(0xFF4B5563),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
