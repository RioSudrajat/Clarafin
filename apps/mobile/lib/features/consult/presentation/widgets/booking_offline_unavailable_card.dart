import 'package:flutter/material.dart';

class BookingOfflineUnavailableCard extends StatelessWidget {
  final VoidCallback? onRequestSchedule;

  const BookingOfflineUnavailableCard({super.key, this.onRequestSchedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Jadwal konsultasi offline pada konsultan terkait sedang tidak ada',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (onRequestSchedule != null) {
                onRequestSchedule!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Permintaan jadwal offline berhasil diajukan.',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: Color(0xFF0F758A),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(bottom: 90, left: 16, right: 16),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F758A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Text(
                'Ajukan Permintaan Jadwal',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
