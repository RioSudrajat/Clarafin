import 'package:flutter/material.dart';

class BookingServicePlaceholder extends StatelessWidget {
  const BookingServicePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Silakan pilih jenis layanan terlebih dahulu',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class BookingTermsCard extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool?> onChanged;

  const BookingTermsCard({
    super.key,
    required this.agreed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: Row(
        children: [
          Checkbox(
            value: agreed,
            activeColor: const Color(0xFF0F758A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: onChanged,
          ),
          const Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  color: Color(0xFF374151),
                ),
                children: [
                  TextSpan(text: 'Saya memahami aturan '),
                  TextSpan(
                    text: 'Syarat & Ketentuan Layanan',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                      color: Color(0xFF0F758A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
