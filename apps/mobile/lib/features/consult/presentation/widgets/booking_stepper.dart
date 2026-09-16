import 'package:flutter/material.dart';

class BookingStepper extends StatefulWidget {
  final int activeStep; // 1, 2, or 3

  const BookingStepper({super.key, required this.activeStep});

  @override
  State<BookingStepper> createState() => _BookingStepperState();
}

class _BookingStepperState extends State<BookingStepper> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveStep();
    });
  }

  @override
  void didUpdateWidget(BookingStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeStep != widget.activeStep) {
      _scrollToActiveStep();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveStep() {
    if (!_scrollController.hasClients) return;
    double offset = 0.0;
    if (widget.activeStep == 2) {
      offset = 60.0;
    } else if (widget.activeStep == 3) {
      offset = 140.0;
    }
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 52,
      width: double.infinity,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildStep(1, 'Layanan'),
            _buildConnector(1),
            _buildStep(2, 'Waktu'),
            _buildConnector(2),
            _buildStep(3, 'Pre-Assessment'),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int stepNumber, String title) {
    final isActive = widget.activeStep == stepNumber;
    final isCompleted = widget.activeStep > stepNumber;

    Widget circleChild;
    Color circleBgColor;

    if (isCompleted) {
      circleBgColor = const Color(0xFF0F758A);
      circleChild = const Icon(Icons.check_rounded, color: Colors.white, size: 14);
    } else if (isActive) {
      circleBgColor = const Color(0xFF0F758A);
      circleChild = const Icon(Icons.edit_rounded, color: Colors.white, size: 14);
    } else {
      circleBgColor = Colors.white;
      circleChild = Text(
        '$stepNumber',
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: circleBgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isCompleted ? Colors.black : const Color(0xFFD1D5DB),
              width: 2.0,
            ),
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: circleChild,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: (isActive || isCompleted) ? Colors.black : const Color(0xFF9CA3AF),
            fontWeight: (isActive || isCompleted) ? FontWeight.w900 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int stepAfter) {
    final isPassed = widget.activeStep > stepAfter;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: isPassed ? const Color(0xFF0F758A) : const Color(0xFFE5E7EB),
    );
  }
}
