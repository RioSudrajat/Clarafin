import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

class HomeTopAppBar extends ConsumerWidget {
  const HomeTopAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Clarafin Brand Logo & Name
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_clarafin_symbol.png',
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              'clarafin',
              style: GoogleFonts.quicksand(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Notification Bell & Profile Avatar
        Row(
          children: [
            // Notification Bell
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: NeoBrutalism.circleDecoration(
                      backgroundColor: Colors.white,
                      shadowOffset: 2,
                      borderWidth: 2,
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                  // Lime Notification Badge Dot
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: NeoBrutalism.lime,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // User Profile Avatar
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: UserAvatar(
                  avatarUrl: profile.avatarUrl,
                  size: 34,
                  borderWidth: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
