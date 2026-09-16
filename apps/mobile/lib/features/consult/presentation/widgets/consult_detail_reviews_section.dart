import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/consultant.dart';

class ConsultDetailReviewsSection extends StatelessWidget {
  final Consultant consultant;

  const ConsultDetailReviewsSection({
    super.key,
    required this.consultant,
  });

  @override
  Widget build(BuildContext context) {
    final reviews = _getReviewsForConsultant(consultant);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ulasan Klien',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${consultant.rating.toStringAsFixed(2)} (${consultant.reviewCount})',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review Cards Horizontal Carousel
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final r = reviews[index];
                return Container(
                  width: 270,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
                    border: NeoBrutalism.border(width: 2.0),
                    boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reviewer row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: NeoBrutalism.dark,
                                child: Text(
                                  r.initials,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                r.name,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: NeoBrutalism.dark,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: NeoBrutalism.lime,
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(color: Colors.black, width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: Colors.black),
                                const SizedBox(width: 2),
                                Text(
                                  r.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Comment
                      Expanded(
                        child: Text(
                          '"${r.comment}"',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_ReviewItem> _getReviewsForConsultant(Consultant c) {
    return [
      _ReviewItem(
        initials: 'AD',
        name: 'Andi Darmawan',
        rating: 5.0,
        comment:
            'Sangat solutif dan sabar menjelaskan strategi keuangan yang realistis untuk kondisi keluarga saya. Sangat berharga!',
      ),
      _ReviewItem(
        initials: 'RS',
        name: 'Rina Sasmita',
        rating: 4.9,
        comment:
            'Penjelasannya runut dan tidak menggurui. Sekarang punya roadmap keuangan yang jelas untuk 5 tahun ke depan.',
      ),
      _ReviewItem(
        initials: 'BW',
        name: 'Budi Wibowo',
        rating: 5.0,
        comment:
            'Membantu merapikan cashflow bisnis dan tabungan darurat dengan actionable steps. Recommended banget!',
      ),
    ];
  }
}

class _ReviewItem {
  final String initials;
  final String name;
  final double rating;
  final String comment;

  const _ReviewItem({
    required this.initials,
    required this.name,
    required this.rating,
    required this.comment,
  });
}
