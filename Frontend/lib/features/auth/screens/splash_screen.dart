import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    
    // Wait until loading finishes if it's still loading
    while (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      if (authProvider.isManager) {
        context.go('/manager');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo (SVG asset)
            SvgPicture.asset(
              'assets/logodrive.svg',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            Text(
              'Drive Connect',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00628b),
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
