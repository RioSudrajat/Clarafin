import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/export_format_selector.dart';
import '../widgets/export_options_checklist.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  String _selectedPeriod = '3 Bulan Terakhir';
  String _selectedFormat = 'PDF';
  bool _isExporting = false;

  final Map<String, bool> _options = {
    'transactions': true,
    'bills': true,
    'goals': true,
    'consultations': false,
  };

  void _handleDownload() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isExporting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Laporan $_selectedFormat ($_selectedPeriod) berhasil diunduh ke perangkat!',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        backgroundColor: NeoBrutalism.lime,
      ),
    );
  }

  void _handleSendEmail() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isExporting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Laporan terenkripsi telah dikirim ke budi.santoso@example.com!',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        backgroundColor: NeoBrutalism.lime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periods = ['Bulan Ini', '3 Bulan Terakhir', 'Tahun 2026', 'Semua Data'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 2.0),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2.0),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
              ],
            ),
            child: const Icon(Icons.arrow_back, size: 18, color: Colors.black),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Ekspor Data Finansial',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selection
            const Text(
              'Periode Waktu Laporan',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: periods.map((p) {
                  final isSelected = _selectedPeriod == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? NeoBrutalism.lime : Colors.white,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: Colors.black, width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              offset: isSelected ? const Offset(0, 2) : const Offset(0, 1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 22),
            ExportFormatSelector(
              selectedFormat: _selectedFormat,
              onFormatChanged: (fmt) => setState(() => _selectedFormat = fmt),
            ),

            const SizedBox(height: 22),
            ExportOptionsChecklist(
              selectedOptions: _options,
              onOptionToggled: (key, val) => setState(() => _options[key] = val),
            ),

            const SizedBox(height: 28),
            // Primary Download Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isExporting ? null : _handleDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeoBrutalism.lime,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  side: const BorderSide(color: Colors.black, width: 2.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isExporting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.download_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Unduh Dokumen Sekarang',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),
            // Secondary Email Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isExporting ? null : _handleSendEmail,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 2.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.email_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Kirim Salinan ke Email',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
