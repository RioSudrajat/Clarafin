import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class TermsConditionsBottomSheet extends StatelessWidget {
  const TermsConditionsBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TermsConditionsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          children: [
            // Top Bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: NeoBrutalism.lime,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: const Icon(Icons.gavel_outlined, size: 18, color: Colors.black),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Syarat & Ketentuan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: NeoBrutalism.circleDecoration(
                        backgroundColor: const Color(0xFFF3F4F6),
                        shadowOffset: 1.5,
                        borderWidth: 1.5,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.black, thickness: 1.5, height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terakhir diperbarui: 1 Januari 2026',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildSectionCard(
                      number: '01',
                      title: 'Ketentuan Umum Layanan',
                      content:
                          'Aplikasi Clarafin disediakan sebagai asisten manajemen keuangan pribadi dan platform penjadwalan konsultasi perencana keuangan terverifikasi (CFP®/RFC®). Dengan mengakses aplikasi, Anda menyatakan setuju untuk terikat dengan seluruh syarat dan ketentuan yang berlaku.',
                    ),
                    const SizedBox(height: 12),

                    _buildSectionCard(
                      number: '02',
                      title: 'Keamanan Akun & Kredensial',
                      content:
                          'Pengguna bertanggung jawab penuh untuk menjaga kerahasiaan nomor telepon, email, kode PIN, dan otentikasi biometrik yang terpasang pada perangkat. Clarafin tidak akan pernah meminta PIN transaksi Anda melalui kanal komunikasi apa pun.',
                    ),
                    const SizedBox(height: 12),

                    _buildSectionCard(
                      number: '03',
                      title: 'Disclaimer Finansial & Konsultasi',
                      content:
                          'Materi, analisa portofolio, dan rekomendasi yang diberikan oleh konsultan mitra bersifat edukasi dan perencanaan finansial terstruktur. Keputusan akhir atas transaksi instrumen investasi (seperti reksadana, saham, obligasi) sepenuhnya merupakan tanggung jawab pengguna.',
                    ),
                    const SizedBox(height: 12),

                    _buildSectionCard(
                      number: '04',
                      title: 'Hak Kekayaan Intelektual',
                      content:
                          'Semua logo merek, desain antarmuka, ilustrasi, algoritma kalkulator finansial, dan modul perangkat lunak Clarafin dilindungi oleh undang-undang hak cipta Republik Indonesia.',
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Agree Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
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
                    'Saya Memahami & Menyetujui',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
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
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  number,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.45,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
