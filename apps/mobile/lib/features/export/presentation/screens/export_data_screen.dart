import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../widgets/export_format_selector.dart';
import '../widgets/export_options_checklist.dart';

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
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
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        backgroundColor: NeoBrutalism.primary,
      ),
    );
  }

  void _handleSendEmail(String userEmail) async {
    final targetEmail = userEmail.isNotEmpty ? userEmail : 'email terdaftar Anda';
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isExporting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Laporan terenkripsi telah dikirim ke $targetEmail!',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        backgroundColor: NeoBrutalism.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final authUser = ref.watch(authProvider).currentUser;
    final activeEmail = profile.email.isNotEmpty
        ? profile.email
        : (authUser?.email ?? '');

    final periods = ['Bulan Ini', '3 Bulan Terakhir', 'Tahun 2026', 'Semua Data'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F758A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeoBrutalism.brandGradient,
        ),
        child: Column(
          children: [
            // Pinned Neo-Brutalist Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/profile');
                        }
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: NeoBrutalism.border(width: 2.0),
                          boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_rounded, size: 22, color: NeoBrutalism.dark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Ekspor Data Finansial',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main White Container with Curvature
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 2.0),
                    left: BorderSide(color: Colors.black, width: 2.0),
                    right: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Highlight Info Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: NeoBrutalism.surfaceWarm,
                            borderRadius: BorderRadius.circular(16),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: NeoBrutalism.primary,
                                  shape: BoxShape.circle,
                                  border: NeoBrutalism.border(width: 1.5),
                                ),
                                child: const Icon(Icons.security_rounded, size: 20, color: Colors.black),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dokumen Terproteksi Kata Sandi',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'File PDF/CSV dikirim terenkripsi ke: ${activeEmail.isNotEmpty ? activeEmail : 'Email terdaftar'}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: NeoBrutalism.textMuted,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Period Selection
                        Text(
                          'Periode Waktu Laporan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
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
                                      color: isSelected ? NeoBrutalism.primary : Colors.white,
                                      borderRadius: BorderRadius.circular(9999),
                                      border: NeoBrutalism.border(width: 1.8),
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
                                      style: GoogleFonts.plusJakartaSans(
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
                        GestureDetector(
                          onTap: _isExporting ? null : _handleDownload,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: NeoBrutalism.primary,
                              borderRadius: BorderRadius.circular(14),
                              border: NeoBrutalism.border(width: 2.0),
                              boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                            ),
                            child: _isExporting
                                ? const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.download_rounded, size: 20, color: Colors.black),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Unduh Dokumen Sekarang',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        // Secondary Email Button
                        GestureDetector(
                          onTap: _isExporting ? null : () => _handleSendEmail(activeEmail),
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: NeoBrutalism.border(width: 2.0),
                              boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.email_outlined, size: 18, color: Colors.black),
                                const SizedBox(width: 8),
                                Text(
                                  'Kirim Salinan ke Email',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
}
