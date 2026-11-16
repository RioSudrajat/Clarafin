import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/consultant.dart';
import 'booking_service_mock_data.dart';

class ConsultantCard extends StatelessWidget {
  final Consultant consultant;

  const ConsultantCard({
    super.key,
    required this.consultant,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final services = BookingServiceMockData.getServicesForConsultant(consultant);
    double minPrice = services.first.basePricePerSession;
    double maxPrice = services.first.offlinePricePerSession;
    for (final s in services) {
      if (s.basePricePerSession < minPrice) minPrice = s.basePricePerSession;
      final highestTier = s.offlinePricePerSession > s.basePricePerSession ? s.offlinePricePerSession : s.basePricePerSession;
      if (highestTier > maxPrice) maxPrice = highestTier;
    }

    return GestureDetector(
      onTap: consultant.isFullyBooked
          ? null
          : () => context.push('/consult/${consultant.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: consultant.isFullyBooked ? const Color(0xFFFAFAFA) : Colors.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
          border: NeoBrutalism.border(
            width: 2.0,
            color: consultant.isFullyBooked ? Colors.grey.shade400 : NeoBrutalism.borderBlack,
          ),
          boxShadow: consultant.isFullyBooked
              ? NeoBrutalism.shadow(yOffset: 2.0, color: Colors.grey.shade300)
              : NeoBrutalism.shadow(yOffset: 4.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Avatar + Consultant Info + Rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Experience Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: NeoBrutalism.border(
                          width: 2.0,
                          color: consultant.isFullyBooked ? Colors.grey.shade400 : NeoBrutalism.borderBlack,
                        ),
                        color: Colors.grey.shade100,
                      ),
                      child: ClipOval(
                        child: Image.network(
                          consultant.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: NeoBrutalism.textMuted,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: consultant.isFullyBooked
                              ? Colors.grey.shade300
                              : NeoBrutalism.lime,
                          borderRadius: BorderRadius.circular(8),
                          border: NeoBrutalism.border(
                            width: 1.5,
                            color: consultant.isFullyBooked ? Colors.grey.shade400 : NeoBrutalism.borderBlack,
                          ),
                        ),
                        child: Text(
                          consultant.experienceYears,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: consultant.isFullyBooked ? Colors.grey.shade700 : NeoBrutalism.dark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name & Role + Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  consultant.name,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: consultant.isFullyBooked
                                        ? Colors.grey.shade600
                                        : NeoBrutalism.dark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  consultant.title,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: consultant.isFullyBooked
                                        ? Colors.grey.shade500
                                        : NeoBrutalism.darkTeal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    consultant.rating.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: NeoBrutalism.dark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${consultant.reviewCount} ulasan',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: NeoBrutalism.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Location & Methods
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: NeoBrutalism.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            consultant.location,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: NeoBrutalism.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Specialization Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...consultant.specializations.take(3).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black26, width: 1.0),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                );
                }),
                if (consultant.specializations.length > 3)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: NeoBrutalism.lime,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    child: Text(
                      '+${consultant.specializations.length - 3}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Divider Line
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 12),

            // Bottom: Price & CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Mulai ',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: NeoBrutalism.textMuted,
                          ),
                        ),
                        Text(
                          currencyFormat.format(maxPrice),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currencyFormat.format(minPrice),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: consultant.isFullyBooked
                                ? Colors.grey.shade600
                                : NeoBrutalism.dark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ sesi',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: NeoBrutalism.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                consultant.isFullyBooked
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                          border: Border.all(color: Colors.grey.shade400, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 14, color: Colors.black54),
                            SizedBox(width: 4),
                            Text(
                              'Jadwal Penuh',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: NeoBrutalism.lime,
                          borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                          border: NeoBrutalism.border(width: 2.0),
                          boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Jadwalkan',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: NeoBrutalism.dark,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.calendar_today_rounded, size: 14, color: NeoBrutalism.dark),
                          ],
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
