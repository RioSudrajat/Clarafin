import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';

class DraftReviewTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const DraftReviewTopBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: NeoBrutalism.circleDecoration(shadowOffset: 2.0),
                child: const Icon(Icons.arrow_back_rounded, size: 22, color: NeoBrutalism.dark),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Review Transaksi AI',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DraftDetectionBanner extends StatelessWidget {
  final int count;
  final String activeTitle;

  const DraftDetectionBanner({
    super.key,
    required this.count,
    required this.activeTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NeoBrutalism.surfaceWarm,
        borderRadius: BorderRadius.circular(16),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: NeoBrutalism.primary,
              shape: BoxShape.circle,
              border: NeoBrutalism.border(width: 1.5),
            ),
            child: const Icon(Icons.receipt_long_rounded, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Transaksi Terdeteksi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Periksa detail "$activeTitle", sesuaikan kategori dan dompet sebelum menyimpan.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF4B5563),
                    height: 1.3,
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

class DraftIndexTabs extends StatelessWidget {
  final int count;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const DraftIndexTabs({
    super.key,
    required this.count,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(count, (i) {
          final selected = i == activeIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelect(i),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? NeoBrutalism.lime : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: NeoBrutalism.border(width: 1.8),
                  boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                ),
                child: Text(
                  'Draf ${i + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: NeoBrutalism.dark,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class DraftReviewActionBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const DraftReviewActionBar({
    super.key,
    required this.count,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onCancel,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: NeoBrutalism.coral,
                borderRadius: BorderRadius.circular(14),
                border: NeoBrutalism.border(width: 2.0),
                boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
              ),
              alignment: Alignment.center,
              child: Text(
                'Batalkan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onConfirm,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: NeoBrutalism.primary,
                borderRadius: BorderRadius.circular(14),
                border: NeoBrutalism.border(width: 2.0),
                boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 1 ? 'Konfirmasi & Simpan ($count)' : 'Konfirmasi & Simpan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
