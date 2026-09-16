import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_document_uploader.dart';
import '../widgets/booking_intake_description_box.dart';
import '../widgets/booking_intake_topics_grid.dart';
import '../widgets/booking_stepper.dart';
import '../widgets/consultant_mini_profile.dart';
import '../widgets/sticky_booking_bottom_bar.dart';

class BookingPreConsultationScreen extends ConsumerStatefulWidget {
  final String consultantId;
  const BookingPreConsultationScreen({super.key, required this.consultantId});

  @override
  ConsumerState<BookingPreConsultationScreen> createState() => _BookingPreConsultationScreenState();
}

class _BookingPreConsultationScreenState extends ConsumerState<BookingPreConsultationScreen> {
  final List<String> _selectedTopics = ['Review Investasi'];
  final _issueController = TextEditingController();
  final _expectationsController = TextEditingController();
  bool _agreed = true;
  String? _uploadedFileName;
  String? _uploadedFileSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(bookingProvider);
      if (state.topic.isNotEmpty) {
        setState(() {
          _selectedTopics.clear();
          _selectedTopics.addAll(state.topic.split(', '));
        });
      }
      if (state.description.isNotEmpty) {
        _issueController.text = state.description;
      }
      if (state.fileName != null) {
        _uploadedFileName = state.fileName;
        _uploadedFileSize = '1.4 MB';
      }
    });
  }

  @override
  void dispose() {
    _issueController.dispose();
    _expectationsController.dispose();
    super.dispose();
  }

  void _onToggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        if (_selectedTopics.length > 1) _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  void _onProceed(BookingNotifier notifier) {
    notifier.updatePreConsult(
      topic: _selectedTopics.join(', '),
      description: _issueController.text.trim(),
      fileName: _uploadedFileName,
    );
    context.push('/booking/${widget.consultantId}/payment');
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final bookingNotifier = ref.read(bookingProvider.notifier);
    final isValid = _selectedTopics.isNotEmpty && _agreed;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Pre-Assessment Konsultasi',
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
          const BookingStepper(activeStep: 3),
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
                        BookingIntakeTopicsGrid(
                          selectedTopics: _selectedTopics,
                          onToggleTopic: _onToggleTopic,
                        ),
                        const SizedBox(height: 24),
                        BookingIntakeDescriptionBox(
                          controller: _issueController,
                          expectationsController: _expectationsController,
                          agreed: _agreed,
                          onAgreedChanged: (value) => setState(() => _agreed = value),
                        ),
                        const SizedBox(height: 24),
                        BookingDocumentUploader(
                          fileName: _uploadedFileName,
                          fileSize: _uploadedFileSize,
                          onUpload: () {
                            setState(() {
                              _uploadedFileName = 'Laporan_Keuangan_2026.pdf';
                              _uploadedFileSize = '1.4 MB';
                            });
                          },
                          onRemove: () {
                            setState(() {
                              _uploadedFileName = null;
                              _uploadedFileSize = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          StickyBookingBottomBar(
            price: bookingState.totalPrice,
            buttonText: 'Lanjut ke Pembayaran',
            onTap: isValid ? () => _onProceed(bookingNotifier) : null,
          ),
        ],
      ),
    );
  }
}
