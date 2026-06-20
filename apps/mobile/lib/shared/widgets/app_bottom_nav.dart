import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/session/presentation/screens/quick_action_sheets.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(navigationShell: navigationShell),
    );
  }
}

class AppBottomNav extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  
  const AppBottomNav({super.key, required this.navigationShell});

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    // FAB is center index (2)
    if (index == 2) {
      showQuickActionMenuSheet(context, ref);
      return;
    }
    
    // Convert 5-item index to 4-branch index
    int branchIndex = index > 2 ? index - 1 : index;
    
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Non-positioned child: CustomPaint with NotchedNavBarPainter to create a beautiful cutout/hollow center notch
        Padding(
          padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 20),
          child: CustomPaint(
            painter: NotchedNavBarPainter(
              backgroundColor: AppColors.navBg,
              shadowColor: Colors.black,
              notchRadius: 38.0, // perfect cutout size around the 60x60 FAB
            ),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(context, ref, 0, Icons.home_filled, Icons.home_outlined, 'Home'),
                  _buildNavItem(context, ref, 1, Icons.chat_bubble, Icons.chat_bubble_outline, 'Consult'),
                  const SizedBox(width: 60), // Space for FAB
                  _buildNavItem(context, ref, 3, Icons.work, Icons.work_outline, 'Wallet'),
                  _buildNavItem(context, ref, 4, Icons.account_balance_wallet, Icons.account_balance_wallet_outlined, 'Budget'),
                ],
              ),
            ),
          ),
        ),
        // Positioned FAB - now perfectly sized (60x60) and fully inside the Stack bounds for 100% clickability
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: () => _onTap(context, ref, 2),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _buildCalendarPlusIcon(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarPlusIcon() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Calendar body
          Positioned(
            top: 7,
            bottom: 3,
            left: 5,
            right: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Binder Ring Left
          Positioned(
            top: 3,
            left: 9,
            child: Container(
              width: 3,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          // Binder Ring Right
          Positioned(
            top: 3,
            right: 9,
            child: Container(
              width: 3,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          // Plus symbol in the bottom right corner (overlapping the body)
          Positioned(
            right: 2,
            bottom: 1,
            child: Container(
              padding: const EdgeInsets.all(0.5),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.black,
                size: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, WidgetRef ref, int index, IconData activeIcon, IconData icon, String label) {
    // Current branch index maps to 0, 1, 3, 4
    final branchIndex = index > 2 ? index - 1 : index;
    final isActive = (index != 2) && (navigationShell.currentIndex == branchIndex);
    final color = isActive ? AppColors.primaryDark : AppColors.textSecondary;
    
    return GestureDetector(
      onTap: () => _onTap(context, ref, index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotchedNavBarPainter extends CustomPainter {
  final Color backgroundColor;
  final Color shadowColor;
  final double notchRadius;

  NotchedNavBarPainter({
    required this.backgroundColor,
    required this.shadowColor,
    this.notchRadius = 38.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('NOTCH_PAINTER: size=$size, notchRadius=$notchRadius');
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final r = 20.0; // border radius of the navbar
    final w = size.width;
    final h = size.height;
    final R = notchRadius; // radius of the notch

    // Start at top-left, after the corner radius
    path.moveTo(r, 0);

    // Left flat edge
    path.lineTo(w / 2 - R, 0);

    // Notch curve (smooth dip in the middle with horizontal tangents)
    path.cubicTo(
      w / 2 - R * 0.5, 0,
      w / 2 - R * 0.5, R,
      w / 2, R,
    );
    path.cubicTo(
      w / 2 + R * 0.5, R,
      w / 2 + R * 0.5, 0,
      w / 2 + R, 0,
    );

    // Right flat edge
    path.lineTo(w - r, 0);

    // Top-right corner
    path.arcToPoint(
      Offset(w, r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // Right vertical edge
    path.lineTo(w, h - r);

    // Bottom-right corner
    path.arcToPoint(
      Offset(w - r, h),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // Bottom flat edge
    path.lineTo(r, h);

    // Bottom-left corner
    path.arcToPoint(
      Offset(0, h - r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // Left vertical edge
    path.lineTo(0, r);

    // Top-left corner
    path.arcToPoint(
      Offset(r, 0),
      radius: Radius.circular(r),
      clockwise: true,
    );

    path.close();

    // Draw shadow
    canvas.drawShadow(
      path,
      shadowColor.withValues(alpha: 0.18),
      12.0, // elevation
      false, // transparentOccluder
    );

    // Draw background
    canvas.drawPath(path, paint);

    // Draw a subtle border
    final borderPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
