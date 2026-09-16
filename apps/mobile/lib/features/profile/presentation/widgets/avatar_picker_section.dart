import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/user_profile_model.dart';

/// Interactive Avatar Selection widget allowing users to choose from
/// 6 Notion-face style minimalist templates or pick a custom photo.
class AvatarPickerSection extends ConsumerWidget {
  final int? selectedIndex;
  final ValueChanged<int> onSelectPreset;
  final VoidCallback onCustomPhoto;

  const AvatarPickerSection({
    super.key,
    required this.selectedIndex,
    required this.onSelectPreset,
    required this.onCustomPhoto,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TEMPLAT AVATAR (NOTION STYLE)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: NeoBrutalism.lime,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: Text(
                '6 Pilihan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pilih salah satu karakter minimalis atau gunakan foto kustom Anda.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),

        // 6 Avatars Horizontal Scroll Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(UserProfile.notionAvatars.length, (index) {
              final avatarIndex = index + 1;
              final isSelected = selectedIndex == avatarIndex;
              final assetPath = UserProfile.notionAvatars[index];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onSelectPreset(avatarIndex),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isSelected ? NeoBrutalism.lime.withValues(alpha: 0.35) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: isSelected ? 2.5 : 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: isSelected ? const Offset(0, 3) : const Offset(0, 1.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: ClipOval(
                              child: Image.asset(
                                assetPath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: NeoBrutalism.lime,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 1.8),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Avatar $avatarIndex',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // Custom Photo Upload Option Button
        GestureDetector(
          onTap: onCustomPhoto,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1.8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_a_photo_outlined, size: 18, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  'Atau Unggah Foto dari Galeri',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
