import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/session_item_model.dart';

class SessionSheets {
  static void showPaket(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheetContainer(
        title: 'Paket Konsultasi Saya',
        subtitle: 'Pilihan benefit & paket pendampingan finansial',
        content: Column(
          children: [
            _buildPaketItem(
              title: 'Akses Chat Konsultan 3 Hari',
              desc: 'Termasuk tinjauan cashflow & draft rekomendasi',
              status: 'AKTIF',
              badgeColor: NeoBrutalism.lime,
            ),
            const SizedBox(height: 10),
            _buildPaketItem(
              title: 'Review Portofolio Tahunan',
              desc: 'Tersedia 1 kuota sesi komprehensif',
              status: 'TERSEDIA',
              badgeColor: NeoBrutalism.mint,
            ),
          ],
        ),
      ),
    );
  }

  static void showGift(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheetContainer(
        title: 'Gift & Voucher Konsultasi',
        subtitle: 'Kupon promo & kartu hadiah sesi',
        content: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFFCC7),
                borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
                border: NeoBrutalism.border(width: 2.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard_rounded, color: Color(0xFF0F758A), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diskon Rp 50.000 Sesi Pertama',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                        Text(
                          'Gunakan kode: CLARAFIN50',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F758A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeoBrutalism.lime,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/vouchers');
                },
                child: Text(
                  'Lihat Semua Kupon',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showDetail(BuildContext context, SessionItemModel session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheetContainer(
        title: 'Detail Sesi Konsultasi',
        subtitle: session.sessionTitle,
        content: Column(
          children: [
            _buildRow('Perencana', session.consultantName),
            const SizedBox(height: 8),
            _buildRow('Waktu Jadwal', session.scheduleTime),
            const SizedBox(height: 8),
            _buildRow('Metode', session.sessionMethod),
            const SizedBox(height: 8),
            _buildRow('Kode Booking', session.bookingCode),
          ],
        ),
      ),
    );
  }

  static Widget _buildSheetContainer({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Colors.black, width: 2),
          left: BorderSide(color: Colors.black, width: 2),
          right: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900)),
          Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          content,
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static Widget _buildPaketItem({
    required String title,
    required String desc,
    required String status,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: NeoBrutalism.border(width: 2.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
                Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
              border: NeoBrutalism.border(width: 1.5),
            ),
            child: Text(status, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  static Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
