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
  String? _preferredPackageCode;
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _cardKeys = [GlobalKey(), GlobalKey(), GlobalKey(), GlobalKey()];

  @override
  void initState() {
    super.initState();
    final (matched, needsSync, methodAvailable) = _hydrateFromBookingState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (matched != null && needsSync) {
        final state = ref.read(bookingProvider);
        _applyTierSelection(matched, _selectedSessions, state.serviceType == 'Online', preserveTierLabel: state.selectedTier);
      }
      widget.onValidationChanged(_selectedServiceIndex != -1 && _agreedToTerms && methodAvailable);
    });
  }

  (ServiceModel?, bool, bool) _hydrateFromBookingState() {
    final bookingState = ref.read(bookingProvider);
    final consultant = ConsultantRepository.getById(widget.consultantId) ?? ConsultantRepository.initialConsultants.first;
    final hasOffline = consultant.methods.contains('Tatap Muka') && !consultant.isFullyBooked;
    final isOnline = bookingState.serviceType == 'Online';
    final rawCode = bookingState.selectedPackageCode?.trim();
    _preferredPackageCode = (rawCode != null && rawCode.isNotEmpty) ? rawCode : null;

    final services = BookingServiceMockData.getServicesForConsultant(consultant, isOnline: isOnline, preferredPackageCode: _preferredPackageCode);
    _selectedSessions = BookingNotifier.parseSessionCount(bookingState.selectedTier);

    int matchedIndex = -1;
    if (_preferredPackageCode != null) {
      final canonical = BookingServiceMockData.findPackageByCode(_preferredPackageCode!);
      final targetCode = (canonical?.packageCode ?? _preferredPackageCode!).toLowerCase();
      matchedIndex = services.indexWhere((s) => s.packageCode.toLowerCase() == targetCode);
    }
    if (matchedIndex == -1 && bookingState.selectedTier.isNotEmpty) {
      final tierLower = bookingState.selectedTier.toLowerCase();
      matchedIndex = services.indexWhere((s) => tierLower.contains(s.title.toLowerCase()));
    }

    _selectedServiceIndex = matchedIndex;
    final matched = (matchedIndex >= 0 && matchedIndex < services.length) ? services[matchedIndex] : null;
    final needsSync = matched != null && (bookingState.totalPrice <= 0 || bookingState.selectedTier.isEmpty);
    return (matched, needsSync, isOnline || hasOffline);
  }

  void _applyTierSelection(ServiceModel service, int sessions, bool isOnline, {String preserveTierLabel = ''}) {
    final unitPrice = BookingNotifier.resolveUnitPrice(
      basePricePerSession: service.basePricePerSession,
      offlinePricePerSession: service.offlinePricePerSession,
      isOnline: isOnline,
    );
    final total = BookingNotifier.calculatePackagePrice(sessions, unitPrice);
    final label = preserveTierLabel.isNotEmpty ? preserveTierLabel : '${service.title} (${service.subtitle}) • $sessions Sesi';
    ref.read(bookingProvider.notifier).updateSelectedTier(label, total, packageCode: service.packageCode);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectTier(int index, List<ServiceModel> services, bool isOnline) {
    setState(() {
      if (_selectedServiceIndex == index) {
        _selectedServiceIndex = -1;
        ref.read(bookingProvider.notifier).updateSelectedTier('', 0.0);
        widget.onValidationChanged(false);
      } else {
        _selectedServiceIndex = index;
        _applyTierSelection(services[index], _selectedSessions, isOnline);
        widget.onValidationChanged(_agreedToTerms);
        _scrollToCard(index);
      }
    });
  }

  void _scrollToCard(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index >= _cardKeys.length) return;
      final cardCtx = _cardKeys[index].currentContext;
      if (cardCtx != null && cardCtx.mounted) {
        Scrollable.ensureVisible(cardCtx, duration: const Duration(milliseconds: 380), curve: Curves.easeInOutCubic, alignment: 0.1);
      }
    });
  }

  void _onSelectSessions(int count, List<ServiceModel> services, bool isOnline) {
    setState(() {
      _selectedSessions = count;
      if (_selectedServiceIndex != -1 && _selectedServiceIndex < services.length) {
        _applyTierSelection(services[_selectedServiceIndex], count, isOnline);
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
    final consultant = ConsultantRepository.getById(widget.consultantId) ?? ConsultantRepository.initialConsultants.first;
    final location = consultant.location.split(',').first.trim();
    final hasOffline = consultant.methods.contains('Tatap Muka') && !consultant.isFullyBooked;
    final isOnline = bookingState.serviceType == 'Online';
    final services = BookingServiceMockData.getServicesForConsultant(consultant, isOnline: isOnline, preferredPackageCode: _preferredPackageCode);

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
                BookingServiceTypeSelector(state: bookingState, notifier: bookingNotifier, location: location, hasOfflineSchedule: hasOffline),
                const SizedBox(height: 16),
                ...List.generate(services.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BookingServiceTierCard(
                      key: index < _cardKeys.length ? _cardKeys[index] : null,
                      service: services[index],
                      isSelected: _selectedServiceIndex == index,
                      isOffline: !isOnline,
                      onTap: (isOnline || hasOffline)
                          ? () => _onSelectTier(index, services, isOnline)
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Jadwal offline belum tersedia untuk konsultan ini.'), backgroundColor: Color(0xFF0F758A)),
                              ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                const Text('Pilih Paket', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black)),
                const SizedBox(height: 10),
                if (_selectedServiceIndex == -1)
                  const BookingServicePlaceholder()
                else ...[
                  BookingSessionCountSelector(selectedSessions: _selectedSessions, onSelectSessions: (c) => _onSelectSessions(c, services, isOnline)),
                  const SizedBox(height: 14),
                  BookingTermsCard(
                    agreed: _agreedToTerms,
                    onChanged: (val) => setState(() {
                      _agreedToTerms = val ?? false;
                      widget.onValidationChanged(_selectedServiceIndex != -1 && _agreedToTerms);
                    }),
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
