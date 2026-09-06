import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class BranchSessionScreen extends StatefulWidget {
  const BranchSessionScreen({super.key});

  @override
  State<BranchSessionScreen> createState() => _BranchSessionScreenState();
}

class _SessionData {
  final String id;
  final String name;
  final String role;
  final String sessionTitle;
  final String subtitle;
  final Color subtitleColor;
  final String actionLabel;
  final Color actionColor;
  final String avatarUrl;
  final IconData? avatarIcon;
  final String? statusBadge;
  final Color? statusBadgeColor;
  final Color? statusBadgeTextColor;
  final bool isActive;
  final bool isCompleted;
  final bool isCancelled = false;
  double? userRating;

  _SessionData({
    required this.id,
    required this.name,
    required this.role,
    required this.sessionTitle,
    required this.subtitle,
    required this.subtitleColor,
    required this.actionLabel,
    required this.actionColor,
    required this.avatarUrl,
    this.avatarIcon,
    this.statusBadge,
    this.statusBadgeColor,
    this.statusBadgeTextColor,
    required this.isActive,
    this.isCompleted = false,
    this.userRating,
  });
}

class _BranchSessionScreenState extends State<BranchSessionScreen> {
  int _selectedFilter = 0;
  final _filters = ['Semua', 'Aktif', 'Selesai', 'Batal'];

  late List<_SessionData> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = [
      _SessionData(
        id: 's1',
        name: 'Sarah Jenkins',
        role: 'Tax Consultant',
        sessionTitle: 'Konsultasi SPT Tahunan (3 Hari)',
        subtitle: 'Sisa Waktu: 1 Hari 4 Jam',
        subtitleColor: const Color(0xFFF97316), // Orange
        actionLabel: 'Chat',
        actionColor: AppColors.primary,
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
        isActive: true,
      ),
      _SessionData(
        id: 's2',
        name: 'Budi Santoso',
        role: 'Financial Planner',
        sessionTitle: 'Virtual Meet (Zoom)',
        subtitle: 'Jadwal: Besok, 10:00 WIB',
        subtitleColor: const Color(0xFF2563EB), // Blue
        actionLabel: 'Detail',
        actionColor: const Color(0xFF2563EB),
        avatarUrl: 'https://i.pravatar.cc/150?img=11',
        isActive: true,
        statusBadge: 'Menunggu Jadwal',
        statusBadgeColor: const Color(0xFFFEF3C7),
        statusBadgeTextColor: const Color(0xFFD97706),
      ),
      _SessionData(
        id: 's3',
        name: 'PT Clarafin Insurance',
        role: 'Review Portofolio Asuransi',
        sessionTitle: 'Evaluasi Polis & Klaim',
        subtitle: 'Selesai pada: 12 Jan 2026',
        subtitleColor: const Color(0xFF6B7280),
        actionLabel: 'Nilai',
        actionColor: const Color(0xFF10B981),
        avatarUrl: '',
        avatarIcon: Icons.business_rounded,
        isActive: false,
        isCompleted: true,
        userRating: 4.5,
      ),
      _SessionData(
        id: 's4',
        name: 'Dewi Rahmawati',
        role: 'Investment Advisor',
        sessionTitle: 'Rekomendasi Portofolio Reksa Dana',
        subtitle: 'Selesai pada: 5 Jan 2026',
        subtitleColor: const Color(0xFF6B7280),
        actionLabel: 'Nilai',
        actionColor: const Color(0xFF10B981),
        avatarUrl: 'https://i.pravatar.cc/150?img=47',
        isActive: false,
        isCompleted: true,
      ),
    ];
  }

  List<_SessionData> get _filteredSessions {
    switch (_selectedFilter) {
      case 1: // Aktif
        return _sessions.where((s) => s.isActive).toList();
      case 2: // Selesai
        return _sessions.where((s) => s.isCompleted).toList();
      case 3: // Batal
        return _sessions.where((s) => s.isCancelled).toList();
      default: // Semua
        return _sessions;
    }
  }

  void _handleAction(BuildContext context, _SessionData session) {
    if (session.actionLabel == 'Chat') {
      context.push('/consult/chat');
    } else if (session.actionLabel == 'Detail') {
      _showDetailBottomSheet(context, session);
    } else if (session.actionLabel == 'Nilai') {
      _showRatingBottomSheet(context, session);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSessions;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Sesi & Konsultasi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Redesigned
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: List.generate(_filters.length, (i) {
                final selected = _selectedFilter == i;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: i == 0 ? 0 : 4,
                      right: i == _filters.length - 1 ? 0 : 4,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.divider,
                            width: 1.2,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _filters[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Session List Area
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : _buildSessionList(filtered),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1.5),
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tidak Ada Sesi ${_filters[_selectedFilter]}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Belum ada konsultasi atau jadwal aktif di kategori ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Session List ──────────────────────────────────────────────────────────

  Widget _buildSessionList(List<_SessionData> list) {
    // Group dynamically if filter is 'Semua'
    if (_selectedFilter == 0) {
      final active = list.where((s) => s.isActive).toList();
      final completed = list.where((s) => s.isCompleted).toList();
      
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          if (active.isNotEmpty) ...[
            _buildSectionLabel('SESI AKTIF'),
            const SizedBox(height: 10),
            ...active.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSessionCard(s),
                )),
            const SizedBox(height: 16),
          ],
          if (completed.isNotEmpty) ...[
            _buildSectionLabel('RIWAYAT KONSULTASI'),
            const SizedBox(height: 10),
            ...completed.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSessionCard(s),
                )),
          ],
          const SizedBox(height: 80),
        ],
      );
    }

    // Otherwise standard direct list
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSessionCard(list[index]),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  // ─── Session Card Redesigned ───────────────────────────────────────────────

  Widget _buildSessionCard(_SessionData s) {
    final avatarIsUrl = s.avatarUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: s.isActive ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider,
          width: s.isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _handleAction(context, s),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar Redesigned
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: s.isActive
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: avatarIsUrl
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                s.avatarUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              s.avatarIcon ?? Icons.person_rounded,
                              size: 26,
                              color: AppColors.textSecondary,
                            ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            s.role,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action Button Redesigned
                    _buildActionButton(s),
                  ],
                ),
                
                // Content Divider
                if (s.sessionTitle.isNotEmpty || s.statusBadge != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
                ],

                // Sesi Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (s.sessionTitle.isNotEmpty) ...[
                            Text(
                              s.sessionTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                          ],
                          Row(
                            children: [
                              Icon(
                                s.isActive ? Icons.schedule_rounded : Icons.check_circle_outline_rounded,
                                size: 14,
                                color: s.subtitleColor,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  s.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: s.subtitleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (s.statusBadge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: s.statusBadgeColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          s.statusBadge!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: s.statusBadgeTextColor,
                          ),
                        ),
                      ),
                    if (s.isCompleted && s.userRating != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                          const SizedBox(width: 3),
                          Text(
                            s.userRating!.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(_SessionData s) {
    final isChat = s.actionLabel == 'Chat';
    final buttonColor = isChat ? AppColors.primary : s.actionColor;
    
    return Container(
      decoration: BoxDecoration(
        color: isChat ? buttonColor : buttonColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isChat
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _handleAction(context, s),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              s.actionLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isChat ? AppColors.textPrimary : s.actionColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Rating Bottom Sheet ───────────────────────────────────────────────────

  void _showRatingBottomSheet(BuildContext context, _SessionData session) {
    double rating = session.userRating ?? 5.0;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Beri Penilaian Konsultasi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bagaimana pengalaman konsultasimu bersama ${session.name}?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isSelected = rating >= starValue;
                      return IconButton(
                        icon: Icon(
                          isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 40,
                          color: isSelected ? Colors.orange : AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        onPressed: () {
                          setModalState(() => rating = starValue.toDouble());
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          session.userRating = rating;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Terima kasih! Rating ${rating.toInt()} bintang berhasil dikirim.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.textPrimary,
                          ),
                        );
                      },
                      child: const Text(
                        'Kirim Penilaian',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Detail Bottom Sheet ───────────────────────────────────────────────────

  void _showDetailBottomSheet(BuildContext context, _SessionData session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Detail Jadwal Konsultasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              
              // Consultant Info Card inside Sheet
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(session.avatarUrl),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          session.role,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Session Parameters
              _buildSheetRow(Icons.video_camera_back_rounded, 'Tipe Sesi', 'Virtual Meet (Zoom)'),
              const SizedBox(height: 12),
              _buildSheetRow(Icons.event_available_rounded, 'Waktu Mulai', 'Besok, 26 Mei 2026 • 10:00 WIB'),
              const SizedBox(height: 12),
              _buildSheetRow(Icons.vpn_key_rounded, 'Kode Booking', 'HF-PLAN-99281'),
              
              const SizedBox(height: 28),
              
              // Start Meet Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.video_call_rounded, size: 22),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Membuka aplikasi Zoom Cloud Meetings...'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFF2563EB),
                      ),
                    );
                  },
                  label: const Text(
                    'Gabung Zoom Meeting',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}
