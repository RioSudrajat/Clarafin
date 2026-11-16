import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/consultation_session_provider.dart';
import '../widgets/consultation_transactions_sheet.dart';
import '../widgets/session_header_widget.dart';
import '../widgets/session_past_card.dart';
import '../widgets/session_quick_actions.dart';
import '../widgets/session_sheets.dart';
import '../widgets/session_upcoming_card.dart';
import '../widgets/session_upcoming_empty_card.dart';

class BranchSessionScreen extends ConsumerStatefulWidget {
  const BranchSessionScreen({super.key});

  @override
  ConsumerState<BranchSessionScreen> createState() => _BranchSessionScreenState();
}

class _BranchSessionScreenState extends ConsumerState<BranchSessionScreen> {
  bool _isSortNewest = true;
  bool _filterOnlyPaket = false;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(consultationSessionProvider);

    var pastList = [...sessionState.pastSessions];
    if (_filterOnlyPaket) {
      pastList = pastList
          .where((s) =>
              s.sessionTitle.toLowerCase().contains('paket') ||
              s.sessionMethod.toLowerCase().contains('paket'))
          .toList();
    }
    if (_isSortNewest) {
      pastList.sort((a, b) => b.scheduleTime.compareTo(a.scheduleTime));
    } else {
      pastList.sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F758A),
        body: Container(
          decoration: const BoxDecoration(
            gradient: NeoBrutalism.brandGradient,
          ),
          child: Column(
            children: [
              const SessionHeaderWidget(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                      top: BorderSide(color: Colors.black, width: 2.0),
                      left: BorderSide(color: Colors.black, width: 2.0),
                      right: BorderSide(color: Colors.black, width: 2.0),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SessionQuickActions(
                            onTapPaket: () => SessionSheets.showPaket(context),
                            onTapTransaksi: () => ConsultationTransactionsSheet.show(
                              context,
                              sessionState.transactions,
                            ),
                            onTapGift: () => SessionSheets.showGift(context),
                          ),
                          const SizedBox(height: 24),
                          _buildUpcomingHeader(sessionState.upcomingSessions.length),
                          const SizedBox(height: 12),
                          if (sessionState.upcomingSessions.isEmpty)
                            const SessionUpcomingEmptyCard()
                          else
                            ...sessionState.upcomingSessions.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SessionUpcomingCard(
                                  session: item,
                                  onTapChat: () => context.push('/consult/chat'),
                                  onTapDetail: () => SessionSheets.showDetail(context, item),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          _buildPastHeader(),
                          const SizedBox(height: 12),
                          if (pastList.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: NeoBrutalism.surfaceWarm,
                                borderRadius: BorderRadius.circular(14),
                                border: NeoBrutalism.border(width: 1.8),
                              ),
                              child: Center(
                                child: Text(
                                  'Tidak ada sesi berlalu untuk filter ini.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: NeoBrutalism.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...pastList.map(
                              (item) => SessionPastCard(
                                session: item,
                                onTapDetail: () => SessionSheets.showDetail(context, item),
                                onTapRebook: () => context.go('/consult'),
                              ),
                            ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Jadwal Mendatang',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: NeoBrutalism.dark,
            letterSpacing: -0.3,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: count == 0 ? const Color(0xFFF3F4F6) : NeoBrutalism.lime,
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
            border: NeoBrutalism.border(width: 1.5),
          ),
          child: Text(
            count == 0 ? 'Jadwal Kosong' : '$count Aktif',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: NeoBrutalism.dark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPastHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Telah Berlalu',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: NeoBrutalism.dark,
            letterSpacing: -0.3,
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _isSortNewest = !_isSortNewest);
              },
              child: _buildFilterPill(
                _isSortNewest ? 'Terbaru' : 'Terlama',
                true,
                icon: _isSortNewest ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                setState(() => _filterOnlyPaket = !_filterOnlyPaket);
              },
              child: _buildFilterPill(
                _filterOnlyPaket ? 'Paket Sesi' : 'Semua Jadwal',
                _filterOnlyPaket,
                icon: Icons.filter_alt_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterPill(String label, bool isSelected, {IconData icon = Icons.keyboard_arrow_down_rounded}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? NeoBrutalism.mint : Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
        border: NeoBrutalism.border(width: 1.5),
        boxShadow: isSelected ? NeoBrutalism.shadow(yOffset: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: NeoBrutalism.dark,
            ),
          ),
          const SizedBox(width: 3),
          Icon(icon, size: 13, color: NeoBrutalism.dark),
        ],
      ),
    );
  }
}
