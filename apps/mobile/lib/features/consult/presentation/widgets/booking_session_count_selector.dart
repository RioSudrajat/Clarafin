import 'package:flutter/material.dart';

class BookingSessionCountSelector extends StatelessWidget {
  final int selectedSessions;
  final ValueChanged<int> onSelectSessions;

  const BookingSessionCountSelector({
    super.key,
    required this.selectedSessions,
    required this.onSelectSessions,
  });

  @override
  Widget build(BuildContext context) {
    final sessionOptions = [
      (1, '1 Sesi', null),
      (2, '2 Sesi', null),
      (3, '3 Sesi', '👍 Lebih Hemat'),
      (8, '8 Sesi', null),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sessionOptions.map((opt) {
          final count = opt.$1;
          final label = opt.$2;
          final badge = opt.$3;
          final isSelected = selectedSessions == count;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onSelectSessions(count),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: badge != null ? 100 : 76,
                height: 54,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE8F4F8) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0F758A) : const Color(0xFFD1D5DB),
                    width: isSelected ? 2.0 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: badge != null
                    ? Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFE4E6) : const Color(0xFFFEE2E2),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF9F1239),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  color: isSelected ? const Color(0xFF0F758A) : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected ? const Color(0xFF0F758A) : Colors.black,
                          ),
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
