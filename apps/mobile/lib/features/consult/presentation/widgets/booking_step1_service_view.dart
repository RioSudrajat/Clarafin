import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/consultant.dart';
import '../providers/booking_provider.dart';
import 'booking_service_mock_data.dart';
import 'booking_service_tier_card.dart';
import 'booking_service_type_selector.dart';
import 'booking_session_count_selector.dart';
import 'booking_terms_card.dart';
import 'consultant_mini_profile.dart';

class BookingStep1ServiceView extends ConsumerStatefulWidget {
  final String consultantId;
  final ValueChanged<bool> onValidationChanged;

  const BookingStep1ServiceView({
    super.key,
    required this.consultantId,
    required this.onValidationChanged,
  });

  @override
  ConsumerState<BookingStep1ServiceView> createState() => _BookingStep1ServiceViewState();
}

class _BookingStep1ServiceViewState extends ConsumerState<BookingStep1ServiceView> {
  int _selectedServiceIndex = -1;
  int _selectedSessions = 1;
  bool _agreedToTerms = true;
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _cardKeys = [GlobalKey(), GlobalKey()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).reset();
      widget.onValidationChanged(false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _calculatePrice(int sessions, double basePrice) {
    if (sessions == 3) return basePrice == 399000.0 ? 1119000.0 : (basePrice * 3 * 0.93);
    if (sessions == 8) return basePrice * 8 * 0.88;
    return basePrice * (sessions > 0 ? sessions : 1);
  }

  void _onSelectTier(int index, List<ServiceModel> services) {
    setState(() {
      if (_selectedServiceIndex == index) {
        _selectedServiceIndex = -1;
        ref.read(bookingProvider.notifier).updateSelectedTier('', 0.0);
        widget.onValidationChanged(false);
      } else {
        _selectedServiceIndex = index;
        final service = services[index];
        final total = _calculatePrice(_selectedSessions, service.basePricePerSession);
        ref.read(bookingProvider.notifier).updateSelectedTier('${service.title} ${service.subtitle} ($_selectedSessions Sesi)', total);
        widget.onValidationChanged(_agreedToTerms);
        _scrollToCard(index);
      }
    });
  }

  void _scrollToCard(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cardCtx = _cardKeys[index].currentContext;
      if (cardCtx != null && cardCtx.mounted) {
        Scrollable.ensureVisible(cardCtx, duration: const Duration(milliseconds: 380), curve: Curves.easeInOutCubic, alignment: 0.1);
      }
    });
  }

  void _onSelectSessions(int count, List<ServiceModel> services) {
    setState(() {
      _selectedSessions = count;
      if (_selectedServiceIndex != -1) {
        final service = services[_selectedServiceIndex];
        final price = _calculatePrice(count, service.basePricePerSession);
        ref.read(bookingProvider.notifier).updateSelectedTier('${service.title} ${service.subtitle} ($count Sesi)', price);
        widget.onValidationChanged(_agreedToTerms);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(bookingProvider.select((s) => s.serviceType), (prev, next) {
      if (prev != null && prev != next && mounted) {
        setState(() {
          _selectedServiceIndex = -1;
          _selectedSessions = 1;
        });
        ref.read(bookingProvider.notifier).updateSelectedTier('', 0.0);
        widget.onValidationChanged(false);
      }
    });

    final bookingState = ref.watch(bookingProvider);
    final bookingNotifier = ref.read(bookingProvider.notifier);
    final consultant = ConsultantRepository.getById(widget.consultantId) ??
        ConsultantRepository.initialConsultants.first;
    final location = consultant.location.split(',').first.trim();
    final hasOffline = consultant.methods.contains('Tatap Muka') && !consultant.isFullyBooked;
    final isOnline = bookingState.serviceType == 'Online';
    final services = isOnline ? BookingServiceMockData.onlineServices : BookingServiceMockData.offlineServices;

    return SingleChildScrollView(
      controller: _scrollController,
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
                  location: location,
                  hasOfflineSchedule: hasOffline,
                ),
                const SizedBox(height: 16),
                ...List.generate(services.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BookingServiceTierCard(
                      key: _cardKeys[index],
                      service: services[index],
                      isSelected: _selectedServiceIndex == index,
                      onTap: (isOnline || hasOffline)
                          ? () => _onSelectTier(index, services)
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Jadwal offline belum tersedia untuk konsultan ini.'),
                                  backgroundColor: Color(0xFF0F758A),
                                ),
                              );
                            },
                    ),
                  );
                }),
                const SizedBox(height: 4),
                const Text(
                  'Pilih Paket',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                ),
                const SizedBox(height: 10),
                if (_selectedServiceIndex == -1)
                  const BookingServicePlaceholder()
                else ...[
                  BookingSessionCountSelector(
                    selectedSessions: _selectedSessions,
                    onSelectSessions: (count) => _onSelectSessions(count, services),
                  ),
                  const SizedBox(height: 14),
                  BookingTermsCard(
                    agreed: _agreedToTerms,
                    onChanged: (val) {
                      setState(() {
                        _agreedToTerms = val ?? false;
                        widget.onValidationChanged(_selectedServiceIndex != -1 && _agreedToTerms);
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
