import 'package:flutter/material.dart';

class BookingTimeSlotsGrid extends StatelessWidget {
  final List<String> selectedTimes;
  final ValueChanged<String> onToggleTime;

  const BookingTimeSlotsGrid({
    super.key,
    required this.selectedTimes,
    required this.onToggleTime,
  });

  static const _pagiSlots = ['09:00 - 10:00', '10:30 - 11:30'];
  static const _siangSlots = ['13:00 - 14:00', '14:00 - 15:00'];
  static const _soreSlots = ['16:00 - 17:00', '17:00 - 18:00'];
  static const _malamSlots = ['19:00 - 20:00', '20:00 - 21:00'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Waktu',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        // ── Timezone Info Banner ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: const Text(
            'Waktu konseling yang ditampilkan sudah\ndisesuaikan dengan zona waktu perangkat anda\n(WIB)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F758A),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _buildTimeSection('Pagi', _pagiSlots),
        const SizedBox(height: 16),
        _buildTimeSection('Siang', _siangSlots),
        const SizedBox(height: 16),
        _buildTimeSection('Sore', _soreSlots),
        const SizedBox(height: 16),
        _buildTimeSection('Malam', _malamSlots),
      ],
    );
  }

  Widget _buildTimeSection(String title, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = selectedTimes.contains(slot);

            return GestureDetector(
              onTap: () => onToggleTime(slot),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE0F2F6) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.black : const Color(0xFFD1D5DB),
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
                  slot,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.black : const Color(0xFF374151),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
