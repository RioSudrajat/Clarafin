import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_service_tier_card.dart';
import '../widgets/booking_service_type_selector.dart';
import '../widgets/booking_session_count_selector.dart';
import '../widgets/booking_stepper.dart';
import '../widgets/consultant_mini_profile.dart';
import '../widgets/sticky_booking_bottom_bar.dart';

class BookingServiceScreen extends ConsumerStatefulWidget {
  final String consultantId;
  const BookingServiceScreen({super.key, required this.consultantId});

  @override
  ConsumerState<BookingServiceScreen> createState() => _BookingServiceScreenState();
}

class _BookingServiceScreenState extends ConsumerState<BookingServiceScreen> {
  int _selectedServiceIndex = -1;
  int _selectedSessions = -1;

  static const List<ServiceModel> _services = [
    ServiceModel(
      title: 'Quick Consult',
      subtitle: 'Premium',
      shortDesc: 'Konseling praktis via chat/call/video call perencana finansial.',
      fullDesc: 'Konseling keuangan praktis via chat/call/video call dengan perencana keuangan Clarafin. Cocok untuk pembahasan masalah keuangan jangka pendek atau review portofolio cepat.',
      basePricePerSession: 399000.0,
      features: [
        'Perencana keuangan berpengalaman >5 tahun',
        'Memiliki sertifikasi CFP® (Certified Financial Planner)',
        'Termasuk rangkuman hasil konsultasi & rekomendasi aksi',
      ],
    ),
    ServiceModel(
      title: 'Deep-Dive Planning',
      subtitle: 'Ultimate',
      shortDesc: 'Perencanaan keuangan komprehensif & pendampingan intensif.',
      fullDesc: 'Perencanaan keuangan komprehensif & pendampingan intensif untuk merapikan seluruh pos pengeluaran, utang, investasi, hingga waris secara mendalam.',
      basePricePerSession: 599000.0,
      features: [
        'Perencana keuangan senior berpengalaman >8 tahun',
        'Akses premium ke tools analisis cashflow Clarafin',
        'Dibuatkan blueprint perencanaan keuangan kustom (.pdf)',
        'Pendampingan intensif selama periode paket sesi',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).reset();
    });
  }

  double _calculatePrice(int sessions, double basePrice) {
    if (sessions == 3) {
      return basePrice == 399000.0 ? 1119000.0 : 1679000.0;
    }
    if (sessions == 5) {
      return basePrice == 399000.0 ? 1799000.0 : 2699000.0;
    }
    return basePrice * (sessions > 0 ? sessions : 1);
  }

  void _onSelectTier(int index) {
    setState(() {
      if (_selectedServiceIndex == index) {
        _selectedServiceIndex = -1;
        _selectedSessions = -1;
        ref.read(bookingProvider.notifier).updateSelectedTier('', 0.0);
      } else {
        _selectedServiceIndex = index;
        if (_selectedSessions == -1) _selectedSessions = 1;
        final service = _services[index];
        final total = _calculatePrice(_selectedSessions, service.basePricePerSession);
        ref.read(bookingProvider.notifier).updateSelectedTier(
              '${service.title} ${service.subtitle} ($_selectedSessions Sesi)',
              total,
            );
      }
    });
  }

  void _onSelectSessions(int count) {
    setState(() {
      _selectedSessions = count;
      if (_selectedServiceIndex == -1) _selectedServiceIndex = 0;
      final service = _services[_selectedServiceIndex];
      final price = _calculatePrice(count, service.basePricePerSession);
      ref.read(bookingProvider.notifier).updateSelectedTier(
            '${service.title} ${service.subtitle} ($count Sesi)',
            price,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final bookingNotifier = ref.read(bookingProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Pilih Layanan Konsultasi',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: Colors.black12),
        ),
      ),
      body: Column(
        children: [
          const BookingStepper(activeStep: 1),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConsultantMiniProfile(consultantId: widget.consultantId),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BookingServiceTypeSelector(
                          state: bookingState,
                          notifier: bookingNotifier,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Pilih Paket Layanan',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_services.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: BookingServiceTierCard(
                              service: _services[index],
                              isSelected: _selectedServiceIndex == index,
                              onTap: () => _onSelectTier(index),
                            ),
                          );
                        }),
                        if (_selectedServiceIndex != -1) ...[
                          const SizedBox(height: 8),
                          BookingSessionCountSelector(
                            selectedSessions: _selectedSessions,
                            onSelectSessions: _onSelectSessions,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          StickyBookingBottomBar(
            price: bookingState.totalPrice,
            buttonText: 'Lanjut Pilih Waktu',
            onTap: bookingState.selectedTier.isNotEmpty
                ? () => context.push('/booking/${widget.consultantId}/time')
                : null,
          ),
        ],
      ),
    );
  }
}
