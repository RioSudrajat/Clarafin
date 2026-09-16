import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/institutions/institution_logo_widget.dart';
import '../../../../core/institutions/institution_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Neo-Brutalist list item for financial institutions.
class WalletInstitutionItem extends StatelessWidget {
  final InstitutionModel institution;
  final VoidCallback onTap;

  const WalletInstitutionItem({
    super.key,
    required this.institution,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: 18,
        shadowOffset: 2.5,
        borderWidth: 2.0,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                InstitutionLogoWidget(
                  institutionId: institution.id,
                  walletName: institution.name,
                  walletType: institution.type,
                  size: 42,
                  borderWidth: 2.0,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        institution.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: NeoBrutalism.dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        institution.shortName.isNotEmpty
                            ? '${institution.shortName} • ${institution.type}'
                            : institution.type,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: NeoBrutalism.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (institution.supportsAutoSync) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: NeoBrutalism.pillDecoration(
                      backgroundColor: NeoBrutalism.lime,
                      borderWidth: 1.5,
                      shadowOffset: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 13, color: Colors.black),
                        const SizedBox(width: 2),
                        Text(
                          'AUTO',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 9.5,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Container(
                  width: 32,
                  height: 32,
                  decoration: NeoBrutalism.circleDecoration(
                    backgroundColor: const Color(0xFFF8FAFC),
                    borderWidth: 1.5,
                    shadowOffset: 0,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
