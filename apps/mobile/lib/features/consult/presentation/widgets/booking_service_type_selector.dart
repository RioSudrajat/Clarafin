import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/booking_provider.dart';
import 'booking_method_badge.dart';
import 'booking_offline_unavailable_card.dart';

class BookingServiceTypeSelector extends StatelessWidget {
  final BookingState state;
  final BookingNotifier notifier;
  final String location;
  final bool hasOfflineSchedule;
  final VoidCallback? onRequestSchedule;

  const BookingServiceTypeSelector({
    super.key,
    required this.state,
    required this.notifier,
    this.location = 'Jakarta Selatan',
    this.hasOfflineSchedule = true,
    this.onRequestSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = state.serviceType == 'Online';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pilih Layanan',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            Container(
              width: 170,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildToggleTab('Online', isOnline),
                  _buildToggleTab('Offline', !isOnline),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (isOnline)
          _buildOnlineMethodsBanner()
        else if (hasOfflineSchedule)
          _buildOfflineLocationBanner()
        else
          BookingOfflineUnavailableCard(onRequestSchedule: onRequestSchedule),
      ],
    );
  }

  Widget _buildToggleTab(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => notifier.updateServiceType(label),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? NeoBrutalism.lime : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: isSelected ? NeoBrutalism.dark : const Color(0xFF6B7280),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineMethodsBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Metode Online :',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              BookingMethodBadge(icon: Icons.call_rounded, label: 'Call'),
              SizedBox(width: 6),
              BookingMethodBadge(icon: Icons.videocam_rounded, label: 'Video'),
              SizedBox(width: 6),
              BookingMethodBadge(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineLocationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Lokasi Offline :',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 1.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFE11D48)),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
