import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_stepper.dart';
import '../widgets/consultant_mini_profile.dart';
import '../widgets/sticky_booking_bottom_bar.dart';

class ServiceModel {
  final String title;
  final String subtitle;
  final String shortDesc;
  final String fullDesc;
  final List<String> features;
  final double basePricePerSession;

  ServiceModel({
    required this.title,
    required this.subtitle,
    required this.shortDesc,
    required this.fullDesc,
    required this.features,
    required this.basePricePerSession,
  });
}

class BookingServiceScreen extends ConsumerStatefulWidget {
  final String consultantId;
  const BookingServiceScreen({super.key, required this.consultantId});

  @override
  ConsumerState<BookingServiceScreen> createState() => _BookingServiceScreenState();
}

class _BookingServiceScreenState extends ConsumerState<BookingServiceScreen> {
  int _selectedServiceIndex = -1; // -1: Unselected by default
  int _selectedSessions = -1; // -1: Unselected by default

  final List<ServiceModel> _services = [
    ServiceModel(
      title: 'Quick Consult',
      subtitle: 'Premium',
      shortDesc: 'Konseling keuangan praktis via chat/call/video call.',
      fullDesc: 'Konseling keuangan praktis via chat/call/video call dengan perencana keuangan Halofin. Cocok untuk pembahasan masalah keuangan jangka pendek atau review portofolio cepat.',
      basePricePerSession: 399000.0,
      features: [
        'Perencana keuangan berpengalaman >5 tahun',
        'Memiliki sertifikasi CFP® (Certified Financial Planner)',
        'Termasuk rangkuman hasil konsultasi & rekomendasi aksi'
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
        'Akses premium ke tools analisis cashflow Halofin',
        'Dibuatkan blueprint perencanaan keuangan kustom (.pdf)',
        'Pendampingan intensif selama periode paket sesi'
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

  double _getPrice(int sessions, double basePrice) {
    if (sessions == 3) {
      if (basePrice == 399000.0) return 1119000.0;
      return 1679000.0; // Deep Dive 3 Sessions discounted
    }
    if (sessions == 5) {
      if (basePrice == 399000.0) return 1799000.0;
      return 2699000.0; // Deep Dive 5 Sessions discounted
    }
    return basePrice * (sessions > 0 ? sessions : 1);
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final bookingNotifier = ref.read(bookingProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Buat Jadwal'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 44, // Make app bar more compact
      ),
      body: Column(
        children: [
          // Step progress indicator (Step 1 Active)
          const BookingStepper(activeStep: 1),
          // Hapus garis pembatas dibawah stepper
          
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // Prevent top/bottom bouncing overscroll
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mini Profile
                  const ConsultantMiniProfile(),
                  
                  // Content padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Type Selector (Online/Offline) Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pilih Layanan',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(
                              width: 170,
                              child: _buildServiceTypeToggle(bookingState, bookingNotifier),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Online Methods Row
                        if (bookingState.serviceType == 'Online') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Metode Online :',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                              _buildOnlineMethodRow(bookingState, bookingNotifier),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Service details & selection cards
                        const Text(
                          'Pilih Paket Layanan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_services.length, (index) {
                          final service = _services[index];
                          final isSelected = _selectedServiceIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildServiceCard(index, service, isSelected, bookingNotifier),
                          );
                        }),
                        const SizedBox(height: 12),

                        // "Pilih Paket" Section (Horizontal Scrollable Packages) - Only visible if a service is selected
                        if (_selectedServiceIndex != -1) ...[
                          const Text(
                            'Pilih Jumlah Sesi',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          _buildHorizontalPackagesList(bookingNotifier),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Bar
          StickyBookingBottomBar(
            price: bookingState.totalPrice,
            onTap: bookingState.selectedTier.isNotEmpty
                ? () {
                    context.push('/booking/${widget.consultantId}/time');
                  }
                : null, // Disabled if no package selected
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeToggle(BookingState state, BookingNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleItem(
              label: 'Online',
              isSelected: state.serviceType == 'Online',
              onTap: () => notifier.updateServiceType('Online'),
            ),
          ),
          Expanded(
            child: _buildToggleItem(
              label: 'Offline',
              isSelected: state.serviceType == 'Offline',
              onTap: () => notifier.updateServiceType('Offline'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppColors.primaryDark, width: 0.5) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineMethodRow(BookingState state, BookingNotifier notifier) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMethodChip(
          icon: Icons.phone,
          label: 'Call',
          isSelected: state.onlineMethod == 'Call',
          onTap: () => notifier.updateOnlineMethod('Call'),
        ),
        const SizedBox(width: 8),
        _buildMethodChip(
          icon: Icons.videocam,
          label: 'Video',
          isSelected: state.onlineMethod == 'Video',
          onTap: () => notifier.updateOnlineMethod('Video'),
        ),
        const SizedBox(width: 8),
        _buildMethodChip(
          icon: Icons.chat_bubble,
          label: 'Chat',
          isSelected: state.onlineMethod == 'Chat',
          onTap: () => notifier.updateOnlineMethod('Chat'),
        ),
      ],
    );
  }

  Widget _buildMethodChip({required IconData icon, required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.textPrimary : Colors.grey.shade200, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(int index, ServiceModel service, bool isSelected, BookingNotifier notifier) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedServiceIndex == index) {
            // Unselect if clicked again
            _selectedServiceIndex = -1;
            _selectedSessions = -1;
            notifier.updateSelectedTier('', 0.0);
          } else {
            _selectedServiceIndex = index;
            if (_selectedSessions == -1) {
              _selectedSessions = 1; // Auto-select 1 session
            }
            final total = _getPrice(_selectedSessions, service.basePricePerSession);
            notifier.updateSelectedTier('${service.title} ${service.subtitle} ($_selectedSessions Sesi)', total);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF0F766E).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title & Subtitle
            Row(
              children: [
                Icon(
                  index == 0 ? Icons.chat_bubble_outline : Icons.analytics_outlined,
                  color: isSelected ? const Color(0xFF0D9488) : Colors.grey,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF0F766E) : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        service.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFF0D9488) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Description (Short or Full depending on selection)
            Text(
              isSelected ? service.fullDesc : service.shortDesc,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            
            // If expanded (isSelected), show features
            if (isSelected) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
              ...service.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 14, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalPackagesList(BookingNotifier notifier) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHorizontalCard(1, '1 Sesi', null, notifier),
          _buildHorizontalCard(2, '2 Sesi', null, notifier),
          _buildHorizontalCard(3, '3 Sesi', '✓ Lebih Hemat', notifier),
          _buildHorizontalCard(4, '4 Sesi', null, notifier),
          _buildHorizontalCard(5, '5 Sesi', 'Diskon 10%', notifier),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(
    int sessions,
    String label,
    String? promoText,
    BookingNotifier notifier,
  ) {
    final isSelected = _selectedSessions == sessions;
    
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      height: 62, // Constrain height for overlapping badge layout
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Card Container
          Positioned.fill(
            top: 8, // leave space for overlapping badge at top
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSessions = sessions;
                  if (_selectedServiceIndex == -1) {
                    _selectedServiceIndex = 0; // Auto-select first service
                  }
                });
                final service = _services[_selectedServiceIndex];
                final price = _getPrice(sessions, service.basePricePerSession);
                notifier.updateSelectedTier('${service.title} ${service.subtitle} ($sessions Sesi)', price);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF0F766E) : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          
          // Overlapping Promo Badge shifted UP
          if (promoText != null)
            Positioned(
              top: 0,
              left: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2), // soft pink
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDC2626), width: 0.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  promoText,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626), // red text
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
