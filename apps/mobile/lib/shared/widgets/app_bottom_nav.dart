import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/neo_brutalism_decorations.dart';
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
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 92,
            child: GestureDetector(
              onTap: () => context.push('/session'),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: NeoBrutalism.lime,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: NeoBrutalism.shadow(yOffset: 3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.black,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 8),
        child: SizedBox(
          height: 70,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Floating Box Navbar Container (Rounded corners)
              Container(
                height: 64,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: NeoBrutalism.shadow(yOffset: 4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      context,
                      ref,
                      0,
                      'assets/icons/home_filled.svg',
                      'assets/icons/home_outlined.svg',
                      'Home',
                    ),
                    _buildNavItem(
                      context,
                      ref,
                      1,
                      'assets/icons/consult_filled.svg',
                      'assets/icons/consult_outlined.svg',
                      'Consult',
                    ),
                    // Space for center FAB
                    const SizedBox(width: 58),
                    _buildNavItem(
                      context,
                      ref,
                      3,
                      'assets/icons/wallet_filled.svg',
                      'assets/icons/wallet_outlined.svg',
                      'Wallet',
                    ),
                    _buildNavItem(
                      context,
                      ref,
                      4,
                      'assets/icons/budget_filled.svg',
                      'assets/icons/budget_outlined.svg',
                      'Budget',
                    ),
                  ],
                ),
              ),
              // Center FAB (Neo-Brutalism Squircle Button)
              Positioned(
                top: -6,
                child: GestureDetector(
                  onTap: () => _onTap(context, ref, 2),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: NeoBrutalism.lime,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: NeoBrutalism.shadow(yOffset: 4),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.black,
                        size: 28,
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

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    String activeIconPath,
    String iconPath,
    String label,
  ) {
    // Current branch index maps to 0, 1, 3, 4
    final branchIndex = index > 2 ? index - 1 : index;
    final isActive =
        (index != 2) && (navigationShell.currentIndex == branchIndex);
    final color = isActive ? NeoBrutalism.dark : const Color(0xFF9CA3AF);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(context, ref, index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                isActive ? activeIconPath : iconPath,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                width: 20,
                height: 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
