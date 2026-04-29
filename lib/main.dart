import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:rulewise/firebase_options.dart';
import 'package:rulewise/services/auth_service.dart';
import 'package:rulewise/services/compliance_service.dart';
import 'package:rulewise/services/validation_service.dart';
import 'package:rulewise/services/profile_service.dart';
import 'package:rulewise/services/user_license_service.dart';
import 'package:rulewise/services/notification_service.dart';
import 'package:rulewise/services/subscription_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rulewise/services/fcm_service.dart';
import 'package:rulewise/services/payment_service.dart';
import 'package:rulewise/services/law_change_radar_service.dart';
import 'package:rulewise/services/background_service.dart';
import 'package:rulewise/screens/splash_screen.dart';
import 'package:rulewise/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rulewise/l10n/app_localizations.dart';
import 'package:rulewise/services/locale_provider.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize environment variables
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✅ Environment variables loaded');
    } catch (e) {
      debugPrint('⚠️ Warning: .env file not found. Using default values.');
      // Continue anyway - app will use default/fallback values
    }

    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Set background handler early
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Warning: Firebase initialization failed: $e');
      // Continue anyway - app handles offline mode
    }

    // Initialize timezone data for notifications
    tz.initializeTimeZones();

    // Initialize Hive for offline storage
    await Hive.initFlutter();

    // Initialize notification service - Soft fail
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      // Don't await permissions here as it might block UI on some OS versions
      notificationService.requestPermissions();
    } catch (e) {
      debugPrint('Warning: Notification init failed: $e');
    }

    // Initialize Background Services (Fire-and-forget to prevent app freeze)
    _initializeBackgroundServices();
  } catch (e) {
    debugPrint('Critical Initialization Error: $e');
  }

  // ALWAYS run the app, even if some services fail
  runApp(const RuleWiseApp());
}

Future<void> _initializeBackgroundServices() async {
  // Initialize Background Service (Workmanager)
  try {
    await BackgroundService.initialize();
  } catch (e) {
    debugPrint('Warning: Background Service init failed: $e');
  }

  // Initialize FCM (Push Notifications)
  try {
    final fcmService = FCMService();
    await fcmService.initialize();
  } catch (e) {
    debugPrint('Warning: FCM init failed: $e');
  }
}

class RuleWiseApp extends StatelessWidget {
  const RuleWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ComplianceService()),
        ChangeNotifierProvider(create: (_) => ValidationService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => UserLicenseService()),
        ChangeNotifierProvider(create: (_) => SubscriptionService()..init()),
        ChangeNotifierProvider(create: (_) => LawChangeRadarService()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ProxyProvider<SubscriptionService, PaymentService>(
          update: (_, subscriptionService, __) =>
              PaymentService(subscriptionService),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'RuleWise',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
