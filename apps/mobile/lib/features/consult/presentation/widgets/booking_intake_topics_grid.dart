import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/consultant.dart';

class BookingIntakeTopicsGrid extends StatefulWidget {
  final List<String> selectedTopics;
  final ValueChanged<String> onToggleTopic;
  final Consultant? consultant;
  final String? selectedTier;

  const BookingIntakeTopicsGrid({
    super.key,
    required this.selectedTopics,
    required this.onToggleTopic,
    this.consultant,
    this.selectedTier,
  });

  @override
  State<BookingIntakeTopicsGrid> createState() => _BookingIntakeTopicsGridState();
}

class _BookingIntakeTopicsGridState extends State<BookingIntakeTopicsGrid> {
  static const List<String> _defaultTopics = [
    'Review Portofolio Investasi',
    'Perencanaan Pensiun (FIRE)',
    'Manajemen & Pelunasan Utang',
    'Dana Pendidikan Anak',
    'Cashflow Bulanan & Budgeting',
    'Dana Darurat Pertama',
    'Asuransi & Proteksi Jiwa',
    'Pajak Pribadi & SPT',
  ];

  List<String> _resolveTopics() {
    final consultant = widget.consultant;
    final tier = widget.selectedTier;

    if (consultant == null) return _defaultTopics;

    final Set<String> topics = {};
    final specs = consultant.specializations.map((s) => s.toLowerCase()).toList();

    for (final spec in specs) {
      if (spec.contains('perencanaan keuangan') || spec.contains('arus kas') || spec.contains('utang')) {
        topics.addAll(['Cashflow Bulanan', 'Dana Darurat Pertama', 'Pelunasan Cicilan & PayLater']);
      }
      if (spec.contains('investasi') || spec.contains('saham') || spec.contains('reksadana')) {
        topics.addAll(['Review Portofolio Investasi', 'Alokasi Reksadana & SBN', 'Strategi DCA Saham']);
      }
      if (spec.contains('kpr') || spec.contains('properti') || spec.contains('rumah')) {
        topics.addAll(['Simulasi Kelayakan KPR', 'Kalkulasi DP Rumah Pertama', 'Strategi Lunas KPR Cepat']);
      }
      if (spec.contains('pajak') || spec.contains('bkp') || spec.contains('legal')) {
        topics.addAll(['Kepatuhan SPT Tahunan', 'Efisiensi Pajak Penghasilan', 'Pajak UMKM & Usaha']);
      }
      if (spec.contains('umkm') || spec.contains('bisnis') || spec.contains('usaha')) {
        topics.addAll(['Pisah Rekening Usaha & Pribadi', 'Hitung HPP & Margin Bersih', 'Dana Cadangan Operasional']);
      }
      if (spec.contains('nikah') || spec.contains('keluarga') || spec.contains('pasangan')) {
        topics.addAll(['Transparansi Uang Pranikah', 'Pos Budgeting Rumah Tangga', 'Model Rekening 1 vs 2 Pintu']);
      }
      if (spec.contains('generasi sandwich') || spec.contains('pendidikan')) {
        topics.addAll(['Strategi Generasi Sandwich', 'Dana Pendidikan Anak', 'Proteksi Penghasilan Keluarga']);
      }
      if (spec.contains('pensiun') || spec.contains('fire') || spec.contains('wealth') || spec.contains('waris')) {
        topics.addAll(['Peta Jalan FIRE (Pensiun Dini)', 'Passive Income Dividen/Properti', 'Perencanaan Waris & Hibah']);
      }
    }

    if (tier != null) {
      final t = tier.toLowerCase();
      if (t.contains('basic')) {
        topics.add('Action Plan 30 Hari');
      } else if (t.contains('medium')) {
        topics.add('Audit Polis Asuransi');
      } else if (t.contains('premium') || t.contains('360')) {
        topics.add('Master Financial Blueprint');
      }
    }

    if (topics.isEmpty) {
      topics.addAll(_defaultTopics);
    }

    return topics.toList();
  }

  @override
  Widget build(BuildContext context) {
    final availableTopics = _resolveTopics();
    final consultant = widget.consultant;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: NeoBrutalism.mint,
              borderRadius: BorderRadius.circular(8),
              border: NeoBrutalism.border(width: 1.5),
            ),
            child: const Icon(
              Icons.psychology_alt_outlined,
              size: 20,
              color: NeoBrutalism.dark,
            ),
          ),
          title: Text(
            'Topik Sesuai Spesialisasi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: NeoBrutalism.dark,
            ),
          ),
          subtitle: Text(
            '${widget.selectedTopics.length} dipilih • ${consultant?.name ?? "Konsultan"}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: NeoBrutalism.textMuted,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (consultant != null && consultant.specializations.isNotEmpty) ...[
                    Text(
                      'KEAHLIAN KONSULTAN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: NeoBrutalism.teal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: consultant.specializations.map((spec) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black26, width: 1.0),
                          ),
                          child: Text(
                            spec,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: NeoBrutalism.dark,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'PILIH TOPIK YANG INGIN DIBEDAH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTopics.map((topic) {
                      final isSelected = widget.selectedTopics.contains(topic);

                      return GestureDetector(
                        onTap: () => widget.onToggleTopic(topic),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
