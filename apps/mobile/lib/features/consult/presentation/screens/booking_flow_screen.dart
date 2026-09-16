import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_step1_service_view.dart';
import '../widgets/booking_step2_schedule_view.dart';
import '../widgets/booking_step3_intake_view.dart';
import '../widgets/booking_stepper.dart';
import '../widgets/sticky_booking_bottom_bar.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  final String consultantId;
  final int initialStep;

  const BookingFlowScreen({
    super.key,
    required this.consultantId,
    this.initialStep = 0,
  });

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  late final PageController _pageController;
  late int _currentStep;

  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _expectationsController = TextEditingController();
  List<String> _currentTopics = ['Review Investasi'];
  String? _currentFileName;

  bool _step1Valid = false;
  bool _step2Valid = false;
  bool _step3Valid = false;

  static const List<String> _titles = [
    'Pilih Layanan Konsultasi',
    'Pilih Jadwal Konsultasi',
    'Pre-Assessment Konsultasi',
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, 2);
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _issueController.dispose();
    _expectationsController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_currentStep > 0) {
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.pop();
    }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else if (_currentStep == 1) {
      _pageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else if (_currentStep == 2) {
      ref.read(bookingProvider.notifier).updatePreConsult(
            topic: _currentTopics.join(', '),
            description: _issueController.text.trim(),
            expectations: _expectationsController.text.trim(),
            fileName: _currentFileName,
          );
      context.push('/booking/${widget.consultantId}/payment');
    }
  }

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 0:
        return _step1Valid;
      case 1:
        return _step2Valid;
      case 2:
        return _step3Valid;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
            onPressed: _handleBack,
          ),
          title: Text(
            _titles[_currentStep],
            style: const TextStyle(
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
            BookingStepper(activeStep: _currentStep + 1),
            const Divider(height: 1.5, color: Colors.black12),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentStep = page),
                children: [
                  BookingStep1ServiceView(
                    consultantId: widget.consultantId,
                    onValidationChanged: (val) => setState(() => _step1Valid = val),
                  ),
                  BookingStep2ScheduleView(
                    consultantId: widget.consultantId,
                    onValidationChanged: (val) => setState(() => _step2Valid = val),
                  ),
                  BookingStep3IntakeView(
                    consultantId: widget.consultantId,
                    issueController: _issueController,
                    expectationsController: _expectationsController,
                    onValidationChanged: (val) => setState(() => _step3Valid = val),
                    onDataChanged: (topics, file) {
                      _currentTopics = topics;
                      _currentFileName = file;
                    },
                  ),
                ],
              ),
            ),
            StickyBookingBottomBar(
              price: bookingState.totalPrice,
              buttonText: 'Selanjutnya',
              onTap: _isCurrentStepValid ? _handleNext : null,
            ),
          ],
        ),
      ),
    );
  }
}
