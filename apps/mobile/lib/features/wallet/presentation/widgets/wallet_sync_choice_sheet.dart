import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/institutions/institution_logo_widget.dart';
import '../../../../core/institutions/institution_model.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../screens/manual_wallet_entry_screen.dart';
import 'sync_option_card.dart';

/// Neo-Brutalist bottom sheet for choosing sync method.
class WalletSyncChoiceSheet extends ConsumerWidget {
  final InstitutionModel institution;

  const WalletSyncChoiceSheet({
    super.key,
    required this.institution,
  });

  static Future<void> show({
    required BuildContext context,
    required InstitutionModel institution,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WalletSyncChoiceSheet(institution: institution),
    );
  }

  void _handleAutoSync(BuildContext context, WidgetRef ref) {
    Navigator.pop(context); // Close sheet

    final newWallet = WalletModel(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      name: institution.name,
      type: institution.type,
      balance: 15000000.0,
      isAutoSync: true,
      institutionId: institution.id,
    );

    ref.read(walletsProvider.notifier).addWallet(newWallet);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚡ ${institution.name} berhasil terhubung otomatis!',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: NeoBrutalism.dark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );

    Navigator.pop(context); // Pop back to wallet list
  }

  void _handleManualEntry(BuildContext context) {
    Navigator.pop(context); // Close sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualWalletEntryScreen(
          institutionId: institution.id,
          institutionName: institution.name,
          institutionType: institution.type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.5),
          left: BorderSide(color: Colors.black, width: 2.0),
          right: BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header with Logo
          Row(
            children: [
              InstitutionLogoWidget(
                institutionId: institution.id,
                walletName: institution.name,
                walletType: institution.type,
                size: 44,
                borderWidth: 2.0,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Metode Sinkronisasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                    Text(
                      institution.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: NeoBrutalism.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Option 1: Auto Sync
          SyncOptionCard(
            title: 'Hubungkan Otomatis',
            subtitle: 'Transaksi dan saldo ditarik realtime. Terenkripsi & aman.',
            badgeText: 'REKOMENDASI',
            backgroundColor: const Color(0xFFEFFCC7),
            icon: Icons.bolt_rounded,
            iconColor: NeoBrutalism.dark,
            iconBgColor: NeoBrutalism.lime,
            onTap: () => _handleAutoSync(context, ref),
          ),
          const SizedBox(height: 12),

          // Option 2: Manual Input
          SyncOptionCard(
            title: 'Input Saldo Manual',
            subtitle: 'Kamu mencatat saldo awal dan mutasi secara mandiri.',
            backgroundColor: Colors.white,
            icon: Icons.edit_note_rounded,
            iconColor: NeoBrutalism.dark,
            iconBgColor: const Color(0xFFF1F5F9),
            onTap: () => _handleManualEntry(context),
          ),
          const SizedBox(height: 20),

          // Cancel button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 48,
              decoration: NeoBrutalism.cardDecoration(
                backgroundColor: const Color(0xFFF1F5F9),
                borderRadius: 16,
                shadowOffset: 2.0,
                borderWidth: 2.0,
              ),
              alignment: Alignment.center,
              child: Text(
                'BATAL',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: NeoBrutalism.dark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
