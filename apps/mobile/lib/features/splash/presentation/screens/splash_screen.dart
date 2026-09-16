import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Keep splash screen visible for 2 seconds
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    final authState = ref.read(authProvider);
    if (authState.isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF094E58), // Deep Dark Teal
              Color(0xFF147D8C), // Mid Teal Blue
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clean brand logo symbol without background circle - immediately visible
              Image.asset(
                'assets/images/logo_clarafin_symbol.png',
                height: 96,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              // Official brand wordmark from DESIGN_SYSTEM.md
              Text(
                'clarafin',
                style: GoogleFonts.quicksand(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              // Subtle brand subtitle in Plus Jakarta Sans
              Text(
                'Finansial Cerdas Tanpa Ragu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB2F5EA),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
