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
import 'package:rulewise/screens/main_screen.dart';
import 'package:rulewise/screens/auth/unified_login_screen.dart';
import 'package:rulewise/screens/splash_screen.dart';
import 'package:rulewise/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rulewise/l10n/app_localizations.dart';
import 'package:rulewise/services/locale_provider.dart';
import 'package:rulewise/services/remote_config_service.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env in background isolate: $e");
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}


void main() async {
  RemoteConfigService? remoteConfigService;
  final notificationService = NotificationService();
  
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize environment variables
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✅ Environment variables loaded');
    } catch (e) {
      debugPrint('⚠️ Warning: .env file not found. Using default values.');
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
    }

    // Initialize Remote Config
    try {
      remoteConfigService = await RemoteConfigService.init();
    } catch (e) {
      debugPrint('Warning: Remote Config init failed: $e');
    }

    // Initialize timezone data for notifications
    tz.initializeTimeZones();

    // Initialize Hive for offline storage
    await Hive.initFlutter();

    // Initialize notification service early
    try {
      await notificationService.initialize();
      notificationService.requestPermissions();
    } catch (e) {
      debugPrint('Warning: Notification init failed: $e');
    }

    // Initialize Background Services
    _initializeBackgroundServices();
  } catch (e) {
    debugPrint('Critical Initialization Error: $e');
  }

  runApp(RuleWiseApp(
    remoteConfigService: remoteConfigService,
    notificationService: notificationService,
  ));
}

Future<void> _initializeBackgroundServices() async {
  try {
    await BackgroundService.initialize();
  } catch (e) {
    debugPrint('Warning: Background Service init failed: $e');
  }

  try {
    final fcmService = FCMService();
    await fcmService.initialize();
  } catch (e) {
    debugPrint('Warning: FCM init failed: $e');
  }
}

class RuleWiseApp extends StatelessWidget {
  final RemoteConfigService? remoteConfigService;
  final NotificationService notificationService;

  const RuleWiseApp({
    super.key,
    this.remoteConfigService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<RemoteConfigService?>.value(value: remoteConfigService),
        ChangeNotifierProvider(create: (_) => AuthService()),

        // Services that depend on Auth state for data clearing
        ChangeNotifierProxyProvider<AuthService, ProfileService>(
          create: (_) => ProfileService(),
          update: (_, auth, profile) {
            if (!auth.isAuthenticated) profile?.clear();
            return profile!;
          },
        ),
        ChangeNotifierProxyProvider<AuthService, ComplianceService>(
          create: (_) => ComplianceService(),
          update: (_, auth, compliance) {
            if (!auth.isAuthenticated) compliance?.clear();
            return compliance!;
          },
        ),
        ChangeNotifierProxyProvider<AuthService, ValidationService>(
          create: (_) => ValidationService(),
          update: (_, auth, validation) => validation!,
        ),
        ChangeNotifierProxyProvider<AuthService, NotificationService>(
          create: (_) => notificationService,
          update: (_, auth, notifications) {
            if (!auth.isAuthenticated) notifications?.clear();
            return notifications!;
          },
        ),
        ChangeNotifierProxyProvider2<AuthService, NotificationService,
            UserLicenseService>(
          create: (_) => UserLicenseService(),
          update: (_, auth, notifications, license) {
            if (!auth.isAuthenticated) license?.clear();
            return license!..updateNotificationService(notifications);
          },
        ),
        ChangeNotifierProxyProvider2<AuthService, RemoteConfigService?,
            SubscriptionService>(
          create: (_) => SubscriptionService()..init(),
          update: (_, auth, remoteConfig, subscription) {
            if (!auth.isAuthenticated) subscription?.clear();
            return subscription!..updateRemoteConfig(remoteConfig);
          },
        ),
        ChangeNotifierProxyProvider<AuthService, LawChangeRadarService>(
          create: (_) => LawChangeRadarService(),
          update: (_, auth, radar) {
            if (!auth.isAuthenticated) radar?.clear();
            return radar!;
          },
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ProxyProvider<SubscriptionService, PaymentService>(
          create: (ctx) => PaymentService(ctx.read<SubscriptionService>()),
          update: (_, subscriptionService, previous) =>
              previous ?? PaymentService(subscriptionService),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'RuleWise',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: localeProvider.locale,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/dashboard': (context) => const MainScreen(),
              '/login': (context) => const UnifiedLoginScreen(),
            },
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
