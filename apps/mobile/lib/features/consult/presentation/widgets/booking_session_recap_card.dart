import 'package:flutter/material.dart';
import '../providers/booking_provider.dart';

class BookingSessionRecapCard extends StatelessWidget {
  final BookingState bookingState;
  final String? consultantId;
  final String formattedDate;

  const BookingSessionRecapCard({
    super.key,
    required this.bookingState,
    this.consultantId,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final tierTitle = bookingState.selectedTier.isNotEmpty
        ? bookingState.selectedTier
        : 'e-Counseling Premium';
    final rawTime = bookingState.selectedTime.isNotEmpty
        ? bookingState.selectedTime
        : '14:00 - 15:00';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.diamond_outlined,
                size: 22,
                color: Color(0xFF0F758A),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tierTitle,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$rawTime (Local Time)',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
