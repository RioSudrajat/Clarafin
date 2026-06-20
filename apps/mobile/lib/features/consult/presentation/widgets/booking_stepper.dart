import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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
      offset = 70.0;
    } else if (widget.activeStep == 3) {
      offset = 180.0;
    }
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 48,
      width: double.infinity,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Dummy leading spacing for connectors on scroll
            if (widget.activeStep > 1) const SizedBox(width: 40),
            
            _buildStep(1, 'Layanan'),
            _buildConnector(1),
            _buildStep(2, 'Waktu'),
            _buildConnector(2),
            _buildStep(3, 'Pre-Assessment'),
            
            // Dummy trailing spacing for connector extension
            const SizedBox(width: 40),
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
    Border? circleBorder;

    if (isCompleted) {
      circleBgColor = AppColors.textPrimary;
      circleChild = const Icon(Icons.check, color: Colors.white, size: 14);
      circleBorder = Border.all(color: AppColors.textPrimary);
    } else if (isActive) {
      circleBgColor = AppColors.textPrimary;
      circleChild = const Icon(Icons.edit, color: Colors.white, size: 14);
      circleBorder = Border.all(color: AppColors.textPrimary);
    } else {
      circleBgColor = Colors.white;
      circleChild = Text(
        '$stepNumber',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
      circleBorder = Border.all(color: AppColors.border, width: 1.5);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: circleBgColor,
            shape: BoxShape.circle,
            border: circleBorder,
          ),
          alignment: Alignment.center,
          child: circleChild,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: (isActive || isCompleted)
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontWeight: (isActive || isCompleted) ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int stepAfter) {
    final isPassed = widget.activeStep > stepAfter;
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: isPassed ? AppColors.textPrimary : AppColors.divider,
    );
  }
}
