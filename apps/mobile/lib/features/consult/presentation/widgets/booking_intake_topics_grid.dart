import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class BookingIntakeTopicsGrid extends StatelessWidget {
  final List<String> selectedTopics;
  final ValueChanged<String> onToggleTopic;

  const BookingIntakeTopicsGrid({
    super.key,
    required this.selectedTopics,
    required this.onToggleTopic,
  });

  static const List<String> availableTopics = [
    'Review Investasi',
    'Perencanaan Pensiun',
    'Manajemen Utang',
    'Dana Pendidikan',
    'Cashflow Bulanan',
    'Dana Darurat',
    'Asuransi & Proteksi',
    'Pajak & Legal',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Topik Utama Konsultasi',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pilih 1 atau lebih topik yang ingin kamu prioritaskan:',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: NeoBrutalism.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTopics.map((topic) {
            final isSelected = selectedTopics.contains(topic);

            return GestureDetector(
              onTap: () => onToggleTopic(topic),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? NeoBrutalism.lime : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset: isSelected ? const Offset(0, 2) : const Offset(0, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check_rounded, size: 13, color: Colors.black),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      topic,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
