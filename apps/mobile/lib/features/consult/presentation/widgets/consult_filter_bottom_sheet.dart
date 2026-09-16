import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/consultant_filter_provider.dart';

class ConsultFilterBottomSheet extends ConsumerStatefulWidget {
  const ConsultFilterBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ConsultFilterBottomSheet(),
    );
  }

  @override
  ConsumerState<ConsultFilterBottomSheet> createState() =>
      _ConsultFilterBottomSheetState();
}

class _ConsultFilterBottomSheetState
    extends ConsumerState<ConsultFilterBottomSheet> {
  late RangeValues _currentRange;

  static const List<String> _allSpecializations = [
    'Investasi Reksadana',
    'Cashflow & Budgeting',
    'Dana Darurat',
    'Pajak & Bisnis',
    'Dana Pensiun',
    'Asuransi Jiwa',
    'Restrukturisasi Utang',
    'Pasangan Baru',
    'Keluarga',
  ];

  @override
  void initState() {
    super.initState();
    final filter = ref.read(consultantFilterProvider);
    _currentRange = RangeValues(filter.minFee, filter.maxFee);
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)} jt';
    }
    return 'Rp ${(value / 1000).round()} rb';
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(consultantFilterProvider);
    final filterNotifier = ref.read(consultantFilterProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.5),
          left: BorderSide(color: Colors.black, width: 2.0),
          right: BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Filter Konsultan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      if (filter.hasActiveFilters) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: NeoBrutalism.lime,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Text(
                            '${filter.activeFilterCount}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      filterNotifier.reset();
                      setState(() {
                        _currentRange = const RangeValues(100000, 1500000);
                      });
                    },
                    child: Text(
                      'Reset Semua',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.black12, thickness: 1, height: 1),

            // Filter Options Scroll Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Rentang Tarif
                    Text(
                      'Rentang Tarif per Sesi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Text(
                            _formatCurrency(_currentRange.start),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          '—',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Text(
                            _formatCurrency(_currentRange.end),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _currentRange,
                      min: 100000,
                      max: 1500000,
                      divisions: 28,
                      activeColor: Colors.black,
                      inactiveColor: const Color(0xFFE5E7EB),
                      onChanged: (values) {
                        setState(() {
                          _currentRange = values;
                        });
                        filterNotifier.setFeeRange(values.start, values.end);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Rating Minimal
                    Text(
                      'Rating Minimal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [0.0, 4.5, 4.8, 4.9].map((rate) {
                        final isSelected = filter.minRating == rate;
                        final label = rate == 0.0 ? 'Semua' : '⭐ ${rate.toStringAsFixed(1)}+';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => filterNotifier.setMinRating(rate),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? NeoBrutalism.lime : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black, width: 1.5),
                                boxShadow: isSelected
                                    ? const [
                                        BoxShadow(
                                          color: Colors.black,
                                          offset: Offset(0, 1.5),
                                          blurRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Metode Konsultasi
                    Text(
                      'Metode Sesi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Online', 'Tatap Muka'].map((m) {
                        final isSelected = filter.methods.contains(m);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => filterNotifier.toggleMethod(m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? NeoBrutalism.lime : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black, width: 1.5),
                                boxShadow: isSelected
                                    ? const [
                                        BoxShadow(
                                          color: Colors.black,
                                          offset: Offset(0, 1.5),
                                          blurRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    m == 'Online'
                                        ? Icons.video_camera_front_outlined
                                        : Icons.people_alt_outlined,
                                    size: 15,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    m,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Topik & Spesialisasi
                    Text(
                      'Spesialisasi Masalah Finansial',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allSpecializations.map((spec) {
                        final isSelected = filter.specializations.contains(spec);
                        return GestureDetector(
                          onTap: () => filterNotifier.toggleSpecialization(spec),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? NeoBrutalism.lime : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black, width: 1.5),
                              boxShadow: isSelected
                                  ? const [
                                      BoxShadow(
                                        color: Colors.black,
                                        offset: Offset(0, 1.5),
                                        blurRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              spec,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Action
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: NeoBrutalism.lime,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Terapkan Filter',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
