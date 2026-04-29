import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/unified_login_screen.dart';
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

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final useBiometric = prefs.getBool('use_biometric') ?? false;

        if (useBiometric) {
          final biometricService = BiometricService();
          if (await biometricService.isBiometricAvailable()) {
            final authenticated = await biometricService.authenticate(
              reason: 'Please authenticate to access RuleWise',
            );
            
            if (!mounted) return;
            
            if (!authenticated) {
              // Failed or canceled biometric, fallback to login or exit
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
              );
              return;
            }
          }
        }
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
        );
      }
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
