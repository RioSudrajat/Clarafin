import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/consultant.dart';

class ConsultDetailAboutSection extends StatelessWidget {
  final Consultant consultant;

  const ConsultDetailAboutSection({
    super.key,
    required this.consultant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'Tentang Konsultan',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Bio Text
          Text(
            consultant.bio,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          // Key Meta Chips (Location, Methods, Languages)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
              border: Border.all(color: Colors.black12, width: 1.5),
            ),
            child: Column(
              children: [
                _buildMetaRow(
                  icon: Icons.location_on_rounded,
                  label: 'Lokasi',
                  value: consultant.location,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Colors.black12),
                ),
                _buildMetaRow(
                  icon: Icons.video_camera_front_rounded,
                  label: 'Metode',
                  value: consultant.methods.join(', '),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Colors.black12),
                ),
                _buildMetaRow(
                  icon: Icons.translate_rounded,
                  label: 'Bahasa',
                  value: consultant.languages.join(', '),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Specializations
          const Text(
            'Spesialisasi & Keahlian',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: consultant.specializations.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  border: NeoBrutalism.border(width: 1.5),
                  boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: NeoBrutalism.dark,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: NeoBrutalism.darkTeal),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: NeoBrutalism.dark,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}
