import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth/unified_login_screen.dart';
// Unused import removed
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      debugPrint('🚀 SplashScreen: Starting auth check...');
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) {
        debugPrint('⚠️ SplashScreen: Widget unmounted during wait');
        return;
      }

      debugPrint('🔍 SplashScreen: Reading AuthService...');
      final authService = context.read<AuthService>();
      final user = authService.currentUser;

      debugPrint('👤 SplashScreen: Current user: ${user?.email ?? "null"}');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              user != null ? const MainScreen() : const UnifiedLoginScreen(),
        ),
      );
      debugPrint('✅ SplashScreen: Navigation complete');
    } catch (e, stackTrace) {
      debugPrint('❌ SplashScreen Error: $e');
      debugPrint(stackTrace.toString());

      // Fallback to login screen on error
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gavel,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'RuleWise',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Government Compliance Assistant',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
