import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/booking_provider.dart';

class BookingPaymentScreen extends ConsumerStatefulWidget {
  final String consultantId;
  const BookingPaymentScreen({super.key, required this.consultantId});

  @override
  ConsumerState<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends ConsumerState<BookingPaymentScreen> {
  String? _paymentMethod;
  final bool _promoApplied = true; // Match the screenshot promo item applied

  String _calculateEndTime(String startTime, String tier) {
    final parts = startTime.split(':');
    if (parts.length != 2) return startTime;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return startTime;
    
    final durationMinutes = tier.contains('5 Sesi') ? 90 : (tier.contains('3 Sesi') ? 75 : 60);
    final startDt = DateTime(2020, 1, 1, hour, minute);
    final endDt = startDt.add(Duration(minutes: durationMinutes));
    
    final formatter = DateFormat('HH:mm');
    return formatter.format(endDt);
  }

  void _selectPaymentMethod() {
    setState(() {
      _paymentMethod = 'Mandiri Virtual Account';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Metode pembayaran "Mandiri Virtual Account" terpilih!'),
        backgroundColor: Color(0xFF073351),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String formattedDate = '';
    try {
      formattedDate = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(bookingState.selectedDate);
    } catch (_) {
      formattedDate = DateFormat('EEEE, d MMM yyyy').format(bookingState.selectedDate);
    }

    final platformFee = 15000.0;
    final discount = _promoApplied ? (bookingState.totalPrice * 0.05).clamp(0.0, 18000.0) : 0.0;
    final totalPayable = bookingState.totalPrice + platformFee - discount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detail Booking'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 44, // Make app bar more compact
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const ClampingScrollPhysics(), // Prevent bouncing overscroll
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1: Session Summary Details
                  _buildSessionSummaryCard(bookingState, formattedDate),
                  const SizedBox(height: 24),
                  
                  // Divider: Detail Klien & Perencana
                  _buildDividerText('Detail Klien & Perencana'),
                  const SizedBox(height: 12),
                  
                  // Card 2: Client & Planner Profiles
                  _buildProfilesCard(bookingState),
                  const SizedBox(height: 24),
                  
                  // Divider: Detail Pembayaran
                  _buildDividerText('Detail Pembayaran'),
                  const SizedBox(height: 12),
                  
                  // Card 3: Payment Method button
                  _buildPaymentMethodButton(),
                  const SizedBox(height: 16),
                  
                  // Card 4: Payment Summary
                  _buildPaymentSummaryCard(bookingState, currencyFormat, platformFee, discount),
                  const SizedBox(height: 16),
                  
                  // Card 5: Promo Chip card
                  _buildPromoCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Bottom Sticky Bar (Bayar button active if method is selected)
          _buildStickyBottomBar(totalPayable, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildSessionSummaryCard(BookingState state, String formattedDate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildSummaryDetailRow(
            icon: Icons.bookmark_outline,
            iconColor: const Color(0xFF073351),
            value: state.selectedTier,
          ),
          const SizedBox(height: 12),
          _buildSummaryDetailRow(
            icon: Icons.calendar_today_outlined,
            iconColor: Colors.orange,
            value: formattedDate,
          ),
          const SizedBox(height: 12),
          _buildSummaryDetailRow(
            icon: Icons.access_time_outlined,
            iconColor: Colors.grey,
            value: '${state.selectedTime} - ${_calculateEndTime(state.selectedTime, state.selectedTier)} (Local Time)',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDetailRow({required IconData icon, required Color iconColor, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildDividerText(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
      ],
    );
  }

  Widget _buildProfilesCard(BookingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Planner Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=100&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.person, color: Colors.grey, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F3E5F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Perencana',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0F3E5F)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Maria Rayna Kartika Winata, CFP®',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 12),
          
          // Client Row (Rio Sudrajat)
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=100&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.person, color: Colors.grey, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Diri Sendiri',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Rio Sudrajat',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton() {
    return GestureDetector(
      onTap: _selectPaymentMethod,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF073351), // deep navy
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.payment_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _paymentMethod ?? 'Pilih Metode Pembayaran',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard(
    BookingState state,
    NumberFormat format,
    double platformFee,
    double discount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pembayaran',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          _buildSummaryPriceRow(state.selectedTier, format.format(state.totalPrice)),
          const SizedBox(height: 10),
          _buildSummaryPriceRow('Platform Fee', format.format(platformFee)),
          if (discount > 0) ...[
            const SizedBox(height: 10),
            _buildSummaryPriceRow('Promo Discount', '- ${format.format(discount)}', valueColor: Colors.red.shade600),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryPriceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12.5, color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer, color: Color(0xFF0D9488), size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promo New User',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Potongan 5% (max Rp 18.000)',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(double totalPayable, NumberFormat format) {
    final hasMethod = _paymentMethod != null;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Harga',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    format.format(totalPayable),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bayar Button
            SizedBox(
              width: 170,
              height: 48,
              child: ElevatedButton(
                onPressed: hasMethod
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pembayaran Berhasil! Sesi konsultasi telah dijadwalkan.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        context.go('/home');
                      }
                    : null, // Disabled if payment method is not selected
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasMethod ? AppColors.primary : Colors.grey.shade300,
                  foregroundColor: hasMethod ? AppColors.textPrimary : Colors.grey.shade500,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Bayar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
