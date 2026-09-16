import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'booking_document_uploader.dart';
import 'booking_intake_description_box.dart';
import 'booking_intake_topics_grid.dart';
import 'consultant_mini_profile.dart';

class BookingStep3IntakeView extends ConsumerStatefulWidget {
  final String consultantId;
  final TextEditingController issueController;
  final TextEditingController expectationsController;
  final ValueChanged<bool> onValidationChanged;
  final Function(List<String> topics, String? fileName)? onDataChanged;

  const BookingStep3IntakeView({
    super.key,
    required this.consultantId,
    required this.issueController,
    required this.expectationsController,
    required this.onValidationChanged,
    this.onDataChanged,
  });

  @override
  ConsumerState<BookingStep3IntakeView> createState() => _BookingStep3IntakeViewState();
}

class _BookingStep3IntakeViewState extends ConsumerState<BookingStep3IntakeView> {
  final List<String> _selectedTopics = ['Review Investasi'];
  String? _uploadedFileName;
  String? _uploadedFileSize;
  bool _agreed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyValidation();
    });
  }

  void _notifyValidation() {
    final isValid = _selectedTopics.isNotEmpty && _agreed;
    widget.onValidationChanged(isValid);
    widget.onDataChanged?.call(_selectedTopics, _uploadedFileName);
  }

  void _onToggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
    _notifyValidation();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                  controller: widget.issueController,
                  expectationsController: widget.expectationsController,
                  agreed: _agreed,
                  onAgreedChanged: (val) {
                    setState(() => _agreed = val);
                    _notifyValidation();
                  },
                ),
                const SizedBox(height: 24),
                BookingDocumentUploader(
                  fileName: _uploadedFileName,
                  fileSize: _uploadedFileSize,
                  onUpload: () {
                    setState(() {
                      _uploadedFileName = 'ringkasan_portofolio_2026.pdf';
                      _uploadedFileSize = '1.2 MB';
                    });
                    _notifyValidation();
                  },
                  onRemove: () {
                    setState(() {
                      _uploadedFileName = null;
                      _uploadedFileSize = null;
                    });
                    _notifyValidation();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
