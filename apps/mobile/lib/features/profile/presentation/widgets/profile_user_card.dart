import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/models/user_profile_model.dart';

class ProfileUserCard extends StatelessWidget {
  final UserProfile profile;

  const ProfileUserCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NeoBrutalism.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 3.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with 2px border and badge
                Stack(
                  children: [
                    UserAvatar(
                      avatarUrl: profile.avatarUrl,
                      size: 64,
                      borderWidth: 2.0,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: NeoBrutalism.primary,
                          shape: BoxShape.circle,
                          border: NeoBrutalism.border(width: 1.5),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          size: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isEmpty ? 'Pengguna Clarafin' : profile.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.email.isEmpty ? 'Belum terhubung ke email' : profile.email,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: NeoBrutalism.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: NeoBrutalism.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: NeoBrutalism.border(width: 1.5),
                          boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                        ),
                        child: Text(
                          profile.tier,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit Profile Action Button
                GestureDetector(
                  onTap: () => context.push('/profile/edit'),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: NeoBrutalism.border(width: 1.8),
                      boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
