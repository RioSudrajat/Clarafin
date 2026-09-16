import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/session_item_model.dart';

class SessionCardWidget extends StatelessWidget {
  final SessionItemModel session;
  final VoidCallback onTapChat;
  final VoidCallback onTapDetail;
  final VoidCallback onTapRate;

  const SessionCardWidget({
    super.key,
    required this.session,
    required this.onTapChat,
    required this.onTapDetail,
    required this.onTapRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Consultant Info Row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      session.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.person, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.consultantName,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.consultantRole,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),

            const SizedBox(height: 12),
            Container(color: Colors.black, height: 1.0),
            const SizedBox(height: 12),

            // Session Title & Method
            Text(
              session.sessionTitle,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),

            // Time & Method
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Colors.black87),
                const SizedBox(width: 6),
                Text(
                  session.scheduleTime,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  session.sessionMethod,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Action Button Row
            _buildActionRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String label;

    switch (session.status) {
      case SessionStatus.active:
        badgeColor = NeoBrutalism.lime;
        label = 'SESI AKTIF';
        break;
      case SessionStatus.scheduled:
        badgeColor = const Color(0xFFFEF08A);
        label = 'MENUNGGU JADWAL';
        break;
      case SessionStatus.completed:
        badgeColor = const Color(0xFFDCFCE7);
        label = 'SELESAI';
        break;
      case SessionStatus.cancelled:
        badgeColor = const Color(0xFFFEE2E2);
        label = 'DIBATALKAN';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    if (session.status == SessionStatus.active) {
      return SizedBox(
        width: double.infinity,
        child: InkWell(
          onTap: onTapChat,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: NeoBrutalism.lime,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_rounded, size: 16, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  'Masuk Ruang Chat Konsultasi',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (session.status == SessionStatus.scheduled) {
      return Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTapDetail,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Detail Jadwal & Link',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Completed
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (session.rating != null)
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: Color(0xFFEAB308)),
              const SizedBox(width: 4),
              Text(
                'Rating: ${session.rating!.toStringAsFixed(1)} / 5.0',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          )
        else
          const SizedBox(),
        InkWell(
          onTap: onTapRate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text(
              session.rating != null ? 'Ubah Ulasan' : 'Beri Ulasan',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
