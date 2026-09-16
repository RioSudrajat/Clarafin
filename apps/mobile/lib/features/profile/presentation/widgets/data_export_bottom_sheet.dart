import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class DataExportBottomSheet extends StatefulWidget {
  const DataExportBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DataExportBottomSheet(),
    );
  }

  @override
  State<DataExportBottomSheet> createState() => _DataExportBottomSheetState();
}

class _DataExportBottomSheetState extends State<DataExportBottomSheet> {
  String _selectedFormat = 'PDF';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.5),
          left: BorderSide(color: Colors.black, width: 2.0),
          right: BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
            const SizedBox(height: 18),

            // Header
            Row(
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
                      child: const Icon(Icons.file_download_outlined, size: 18, color: Colors.black),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Ekspor Data Finansial',
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
            const SizedBox(height: 6),
            Text(
              'Unduh salinan riwayat transaksi, alokasi dompet, dan rekap konsultasi Anda.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),

            // Format Selection
            Row(
              children: [
                _buildFormatPill('PDF', 'Laporan Rapi'),
                const SizedBox(width: 10),
                _buildFormatPill('CSV / Excel', 'Analisa Data'),
                const SizedBox(width: 10),
                _buildFormatPill('JSON', 'Raw Data'),
              ],
            ),
            const SizedBox(height: 20),

            // Download Action Button
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Laporan ($_selectedFormat) berhasil dibuat dan diunduh!',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    backgroundColor: NeoBrutalism.lime,
                  ),
                );
              },
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
                  'Unduh Data Sekarang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatPill(String title, String subtitle) {
    final isSelected = _selectedFormat == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFormat = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? NeoBrutalism.lime.withValues(alpha: 0.3) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: isSelected ? 2.2 : 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: isSelected ? const Offset(0, 2.5) : const Offset(0, 1.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
