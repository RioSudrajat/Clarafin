import 'package:flutter/material.dart';

class ServiceModel {
  final String title;
  final String subtitle;
  final String shortDesc;
  final String fullDesc;
  final List<String> features;
  final double basePricePerSession;

  const ServiceModel({
    required this.title,
    required this.subtitle,
    required this.shortDesc,
    required this.fullDesc,
    required this.features,
    required this.basePricePerSession,
  });
}

class BookingServiceTierCard extends StatefulWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const BookingServiceTierCard({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<BookingServiceTierCard> createState() => _BookingServiceTierCardState();
}

class _BookingServiceTierCardState extends State<BookingServiceTierCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final service = widget.service;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          width: double.infinity,
          padding: EdgeInsets.all(isSelected ? 16 : 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F4F8) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.black,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: isSelected ? const Offset(0, 3) : const Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0F758A) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Icon(
                      service.title.contains('Quick') || service.title.contains('Counseling')
                          ? Icons.chat_bubble_outline_rounded
                          : Icons.insights_rounded,
                      color: isSelected ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.subtitle,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFF0F758A) : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          service.title,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                child: isSelected
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            service.fullDesc,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              color: Color(0xFF374151),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Colors.black12),
                          const SizedBox(height: 10),
                          ...service.features.map(
                            (feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: Color(0xFF0F758A),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
