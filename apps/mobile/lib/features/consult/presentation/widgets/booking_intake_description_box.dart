import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class BookingIntakeDescriptionBox extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController expectationsController;
  final bool agreed;
  final ValueChanged<bool> onAgreedChanged;

  const BookingIntakeDescriptionBox({
    super.key,
    required this.controller,
    required this.expectationsController,
    required this.agreed,
    required this.onAgreedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Kendala / Tujuan
        const Text(
          'Kendala atau Tujuan Keuangan',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ceritakan ringkas kondisi portofolio atau target finansialmu saat ini:',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: NeoBrutalism.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        _buildInputField(
          controller: controller,
          hintText: 'Contoh: Ingin evaluasi alokasi reksadana dan restrukturisasi dana darurat...',
          maxLines: 3,
        ),
        const SizedBox(height: 18),

        // Section 2: Harapan Setelah Konseling (NEW)
        const Text(
          'Harapan Setelah Konseling',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ceritakan ekspektasi atau hasil nyata yang ingin kamu raih:',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: NeoBrutalism.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        _buildInputField(
          controller: expectationsController,
          hintText: 'Contoh: Rencana anggaran bulanan rapi dan strategi investasi pensiun yang terukur...',
          maxLines: 3,
        ),
        const SizedBox(height: 18),

        // Checkbox Agreement
        GestureDetector(
          onTap: () => onAgreedChanged(!agreed),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: agreed ? NeoBrutalism.lime : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 2.0),
                ),
                child: agreed
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
                    : null,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Saya menyetujui data pre-assessment dibagikan secara rahasia dan aman ke perencana keuangan.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        cursorColor: Colors.black,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 13,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: Colors.black38,
          ),
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}
