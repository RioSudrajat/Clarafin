import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/consultant.dart';

class ConsultDetailAccordions extends StatelessWidget {
  final Consultant consultant;

  const ConsultDetailAccordions({
    super.key,
    required this.consultant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          // 1. Spesialisasi & Keahlian Dropdown
          _buildSpecializationAccordion(
            title: 'Spesialisasi & Keahlian',
            icon: Icons.psychology_alt_outlined,
            specializations: consultant.specializations,
          ),
          const SizedBox(height: 10),

          // 2. Sertifikasi & Lisensi Resmi
          _buildAccordion(
            title: 'Sertifikasi & Lisensi Resmi',
            icon: Icons.verified_user_outlined,
            content:
                'Telah diverifikasi resmi oleh Clarafin & Badan Sertifikasi Keuangan: ${consultant.credentials}. Seluruh konsultasi memenuhi kode etik profesi perencana keuangan independen.',
          ),
          const SizedBox(height: 10),

          // 3. Pengalaman & Rekam Jejak
          _buildAccordion(
            title: 'Pengalaman & Rekam Jejak',
            icon: Icons.work_history_outlined,
            content:
                'Memiliki pengalaman aktif lebih dari ${consultant.experienceYears} dengan ${consultant.totalSessions}+ sesi konsultasi sukses mendampingi berbagai profil nasabah perorangan, keluarga, dan pemilik usaha.',
          ),
          const SizedBox(height: 10),

          // 4. Kerahasiaan & Kebijakan Reschedule
          _buildAccordion(
            title: 'Kerahasiaan & Kebijakan Reschedule',
            icon: Icons.shield_outlined,
            content:
                '100% Data finansial dilindungi enkripsi standar perbankan. Reschedule sesi gratis maksimal 24 jam sebelum jadwal konsultasi dimulai.',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationAccordion({
    required String title,
    required IconData icon,
    required List<String> specializations,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: NeoBrutalism.lime,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, size: 16, color: NeoBrutalism.dark),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: NeoBrutalism.dark,
            ),
          ),
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: specializations.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccordion({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: NeoBrutalism.mint,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, size: 16, color: NeoBrutalism.dark),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: NeoBrutalism.dark,
            ),
          ),
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            Text(
              content,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
