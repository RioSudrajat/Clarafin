import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_stepper.dart';
import '../widgets/sticky_booking_bottom_bar.dart';

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    path.addRRect(rect);

    const dashWidth = 5.0;
    final dashSpace = gap;
    
    for (final pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final length = dashWidth;
        final drawPath = pathMetric.extractPath(distance, distance + length);
        canvas.drawPath(drawPath, paint);
        distance += length + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      gap != oldDelegate.gap;
}

class BookingPreConsultationScreen extends ConsumerStatefulWidget {
  final String consultantId;
  const BookingPreConsultationScreen({super.key, required this.consultantId});

  @override
  ConsumerState<BookingPreConsultationScreen> createState() => _BookingPreConsultationScreenState();
}

class _BookingPreConsultationScreenState extends ConsumerState<BookingPreConsultationScreen> {
  final List<String> _topics = [
    'Review Investasi',
    'Perencanaan Pensiun',
    'Manajemen Utang',
    'Dana Pendidikan',
    'Cashflow Bulanan',
    'Dana Darurat',
    'Asuransi & Proteksi'
  ];

  final List<String> _selectedTopics = [];
  bool _isOngoingClient = false;
  bool _agreed = false;
  
  final _issueController = TextEditingController();
  final _expectationController = TextEditingController();
  
  int _issueCharCount = 0;
  String? _uploadedFileName;
  String? _uploadedFileSize;

  @override
  void initState() {
    super.initState();
    _issueController.addListener(() {
      setState(() {
        _issueCharCount = _issueController.text.length;
      });
    });
    
    // Prefill from provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(bookingProvider);
      if (state.topic.isNotEmpty) {
        setState(() {
          _selectedTopics.clear();
          _selectedTopics.addAll(state.topic.split(', '));
        });
      }
      _issueController.text = state.description;
    });
  }

  @override
  void dispose() {
    _issueController.dispose();
    _expectationController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _selectedTopics.isNotEmpty &&
        _issueController.text.trim().isNotEmpty &&
        _expectationController.text.trim().isNotEmpty &&
        _agreed;
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
          // Step progress indicator (Step 3 Active)
          const BookingStepper(activeStep: 3),
          // Hapus garis pembatas dibawah stepper
          
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // Prevent bouncing overscroll
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title 1: Topics Selection
                    const Text(
                      'Topik permasalahan yang dihadapi *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Silahkan pilih topik permasalahan yang sedang dihadapi, dapat memilih lebih dari 1',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    
                    // Choice chips wrap
                    _buildTopicsWrap(),
                    const SizedBox(height: 16),
                    
                    // Checkbox ongoing client
                    _buildOngoingClientCheckbox(),
                    const SizedBox(height: 24),

                    // Title 2: Issue Description
                    const Text(
                      'Deskripsikan Masalah *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    _buildTextAreaField(
                      controller: _issueController,
                      hint: 'Tulis disini',
                      maxLines: 4,
                      maxLength: 255,
                    ),
                    const SizedBox(height: 4),
                    _buildCharCounterAndWarning(),
                    const SizedBox(height: 24),

                    // Title 3: Expectation Description
                    const Text(
                      'Harapan Setelah Konseling *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    _buildTextAreaField(
                      controller: _expectationController,
                      hint: 'Tulis disini',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Title 4: Upload Document Section
                    const Text(
                      'Upload Dokumen Pendukung (Opsional)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    _buildUploadBox(),
                    const SizedBox(height: 24),

                    // Title 5: Agreement Checkbox
                    _buildAgreementCheckbox(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          
          // Sticky Bottom Bar (linked to form validation)
          StickyBookingBottomBar(
            price: bookingState.totalPrice,
            buttonText: 'Selanjutnya',
            onTap: _isFormValid()
                ? () {
                    // Update provider and navigate to step 4
                    bookingNotifier.updatePreConsult(
                      topic: _selectedTopics.join(', '),
                      description: _issueController.text,
                      fileName: _uploadedFileName ?? (_isOngoingClient ? 'ongoing_client' : null),
                    );
                    context.push('/booking/${widget.consultantId}/payment');
                  }
                : null, // disabled if validation fails
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _topics.map((topic) {
        final isSelected = _selectedTopics.contains(topic);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTopics.remove(topic);
              } else {
                _selectedTopics.add(topic);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.15) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              topic,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF0F766E) : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOngoingClientCheckbox() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isOngoingClient = !_isOngoingClient;
        });
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isOngoingClient ? const Color(0xFF0F766E) : Colors.grey.shade400,
                width: 1.5,
              ),
              color: _isOngoingClient ? AppColors.primary : Colors.transparent,
            ),
            child: _isOngoingClient
                ? const Icon(Icons.check, size: 14, color: AppColors.textPrimary)
                : null,
          ),
          const SizedBox(width: 10),
          const Text(
            'Saya merupakan klien lanjutan',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAreaField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildCharCounterAndWarning() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$_issueCharCount/255',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildUploadBox() {
    final hasFile = _uploadedFileName != null;

    return CustomPaint(
      painter: DashedRectPainter(
        color: hasFile ? const Color(0xFF0F766E) : Colors.grey.shade300,
        strokeWidth: 1.5,
        gap: 5.0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: hasFile
            ? Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _uploadedFileName!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _uploadedFileSize!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                    onPressed: () {
                      setState(() {
                        _uploadedFileName = null;
                        _uploadedFileSize = null;
                      });
                    },
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.upload_file,
                    size: 38,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih File Dokumen Pendukung',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Format PDF, JPG, PNG. Maksimal 5MB',
                    style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _uploadedFileName = 'laporan_keuangan.pdf';
                        _uploadedFileSize = '1.2 MB';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0F766E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Pilih File',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAgreementCheckbox() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _agreed = !_agreed;
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _agreed ? const Color(0xFF0F766E) : Colors.grey.shade400,
                width: 1.5,
              ),
              color: _agreed ? AppColors.primary : Colors.transparent,
            ),
            child: _agreed
                ? const Icon(Icons.check, size: 14, color: AppColors.textPrimary)
                : null,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Saya memastikan informasi yang diberikan benar.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
