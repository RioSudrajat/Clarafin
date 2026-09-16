import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/institutions/institution_logo_widget.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Header card for ManualWalletEntryScreen showing institution logo and title.
class ManualWalletHeaderCard extends StatelessWidget {
  final String? institutionId;
  final String institutionName;
  final String selectedType;

  const ManualWalletHeaderCard({
    super.key,
    this.institutionId,
    required this.institutionName,
    required this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: const Color(0xFFEFFCC7),
        borderRadius: 20,
        shadowOffset: 2.5,
      ),
      child: Row(
        children: [
          InstitutionLogoWidget(
            institutionId: institutionId,
            walletName: institutionName,
            walletType: selectedType,
            size: 44,
            borderWidth: 2.0,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institutionName.isNotEmpty ? institutionName : 'Akun Manual Baru',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: NeoBrutalism.dark,
                  ),
                ),
                Text(
                  'Catat mandiri tanpa sinkronisasi otomatis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NeoBrutalism.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
