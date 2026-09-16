import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_session_recap_card.dart';
import '../widgets/booking_client_consultant_card.dart';
import '../widgets/booking_section_divider.dart';
import '../widgets/booking_payment_method_trigger_card.dart';
import '../widgets/booking_price_breakdown_card.dart';
import '../widgets/booking_promo_card.dart';
import '../widgets/payment_method_selection_sheet.dart';
import '../widgets/voucher_selection_sheet.dart';
import '../widgets/sticky_booking_bottom_bar.dart';
import '../../domain/models/consultant.dart';
import '../../../session/domain/models/session_item_model.dart';
import '../../../session/domain/models/consultation_transaction_model.dart';
import '../../../session/presentation/providers/consultation_session_provider.dart';

class BookingPaymentScreen extends ConsumerStatefulWidget {
  final String consultantId;
  const BookingPaymentScreen({super.key, required this.consultantId});

  @override
  ConsumerState<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends ConsumerState<BookingPaymentScreen> {
  String _selectedMethodId = 'qris';
  String _voucherCode = 'HALOFINCFP';
  double _discount = 18000.0;

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingProvider);
    String formattedDate = '';
    try {
      formattedDate = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(booking.selectedDate);
    } catch (_) {
      formattedDate = DateFormat('EEEE, d MMM yyyy').format(booking.selectedDate);
    }

    final subtotal = booking.totalPrice > 0 ? booking.totalPrice : 180000.0;
    const platformFee = 15000.0;
    final transactionFee = (subtotal * 0.025).roundToDouble();
    final totalPayable = (subtotal + platformFee + transactionFee - _discount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Booking',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),
                    BookingSessionRecapCard(
                      bookingState: booking,
                      consultantId: widget.consultantId,
                      formattedDate: formattedDate,
                    ),
                    const SizedBox(height: 18),
                    const BookingSectionDivider(title: 'Detail Klien & Konsultan'),
                    const SizedBox(height: 16),
                    BookingClientConsultantCard(consultantId: widget.consultantId),
                    const SizedBox(height: 18),
                    const BookingSectionDivider(title: 'Detail Pembayaran'),
                    const SizedBox(height: 16),
                    BookingPaymentMethodTriggerCard(
                      selectedMethodId: _selectedMethodId,
                      onTap: () => _choosePaymentMethod(),
                    ),
                    const SizedBox(height: 16),
                    BookingPriceBreakdownCard(
                      packageTitle: booking.selectedTier,
                      subtotal: subtotal,
                      platformFee: platformFee,
                      transactionFee: transactionFee,
                      discount: _discount,
                      totalPayable: totalPayable,
                    ),
                    const SizedBox(height: 14),
                    BookingPromoCard(
                      voucherCode: _voucherCode,
                      discountAmount: _discount,
                      onTap: () => _chooseVoucher(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            StickyBookingBottomBar(
              price: totalPayable,
              buttonText: 'Bayar',
              onTap: () => _processPayment(booking, totalPayable),
            ),
          ],
        ),
      ),
    );
  }

  void _choosePaymentMethod() {
    PaymentMethodSelectionSheet.show(context, selectedMethodId: _selectedMethodId)
        .then((s) => s != null ? setState(() => _selectedMethodId = s.id) : null);
  }

  void _chooseVoucher() {
    VoucherSelectionSheet.show(
      context,
      currentCode: _voucherCode,
      onSelected: (v) => setState(() {
        _voucherCode = v?.code ?? '';
        _discount = v?.discountAmount ?? 0.0;
      }),
    );
  }

  void _processPayment(BookingState booking, double totalPayable) {
    final now = DateTime.now();
    final bookingCode = 'HF-CFP-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final consultant = ConsultantRepository.getById(widget.consultantId) ??
        ConsultantRepository.initialConsultants.first;

    final dateStr = DateFormat('d MMM yyyy').format(booking.selectedDate);
    final timeStr = booking.selectedTime.isNotEmpty ? booking.selectedTime : '10:00';

    ref.read(consultationSessionProvider.notifier).addBookingSession(
          session: SessionItemModel(
            id: 'session-${now.millisecondsSinceEpoch}',
            consultantName: consultant.name,
            consultantRole: consultant.title,
            sessionTitle: booking.topic.isNotEmpty ? booking.topic : 'Konsultasi Perencanaan Finansial',
            scheduleTime: '$dateStr • $timeStr WIB',
            sessionMethod: 'Chat Konsultasi (Siap)',
            status: SessionStatus.scheduled,
            bookingCode: bookingCode,
            avatarUrl: consultant.avatarUrl,
          ),
          transaction: ConsultationTransactionModel(
            id: 'TRX-${now.millisecondsSinceEpoch.toString().substring(5)}',
            bookingCode: bookingCode,
            consultantId: consultant.id,
            consultantName: consultant.name,
            packageTitle: booking.selectedTier.isNotEmpty ? booking.selectedTier : 'Konsultasi 1 Sesi',
            paymentMethod: _selectedMethodId.toUpperCase(),
            amount: totalPayable,
            status: 'Berhasil',
            timestamp: now,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pembayaran Berhasil! Sesi konsultasi telah dijadwalkan.'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.go('/session');
    });
  }
}
