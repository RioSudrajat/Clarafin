import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class PrivacyPolicyBottomSheet extends StatelessWidget {
  const PrivacyPolicyBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrivacyPolicyBottomSheet(),
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
                        child: const Icon(Icons.privacy_tip_outlined, size: 18, color: Colors.black),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Kebijakan Privasi',
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
                      'Privasi dan keamanan data finansial Anda adalah prioritas mutlak kami.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildPrivacyCard(
                      icon: Icons.shield_outlined,
                      title: 'Enkripsi Tingkat Perbankan (AES-256)',
                      description:
                          'Seluruh data saldo, transaksi rekening, dan catatan anggaran diamankan menggunakan standar enkripsi simetris modern saat transmisi maupun di perangkat.',
                    ),
                    const SizedBox(height: 12),

                    _buildPrivacyCard(
                      icon: Icons.no_accounts_outlined,
                      title: 'Tidak Ada Penjualan Data Pengguna',
                      description:
                          'Clarafin memegang prinsip integritas penuh: kami tidak akan pernah menjual atau menyewakan profil finansial Anda kepada jaringan iklan pihak ketiga mana pun.',
                    ),
                    const SizedBox(height: 12),

                    _buildPrivacyCard(
                      icon: Icons.storage_outlined,
                      title: 'Penyimpanan & Kendali Lokal',
                      description:
                          'Preferensi aplikasi, token keamanan biometrik, dan catatan harian disimpan secara terisolasi. Anda memegang kendali penuh atas kapan data diekspor atau dihapus.',
                    ),
                    const SizedBox(height: 12),

                    _buildPrivacyCard(
                      icon: Icons.delete_forever_outlined,
                      title: 'Hak Penghapusan Akun',
                      description:
                          'Anda memiliki hak sewaktu-waktu untuk mengajukan penutupan akun secara permanen. Seluruh riwayat sesi konsultasi dan data transaksi akan dihapus dari server.',
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Confirm Button
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
                    'Tutup Kebijakan Privasi',
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

  Widget _buildPrivacyCard({
    required IconData icon,
    required String title,
    required String description,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: NeoBrutalism.lime.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 1.45,
                    color: const Color(0xFF4B5563),
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
