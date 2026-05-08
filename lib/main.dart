import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rulewise/l10n/app_localizations.dart';
import 'package:rulewise/services/locale_provider.dart';
import 'package:rulewise/services/remote_config_service.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
}


void main() async {
  // 1. Ensure initialization is first
  WidgetsFlutterBinding.ensureInitialized();
  
  RemoteConfigService? remoteConfigService;
  final notificationService = NotificationService();
  final stopwatch = Stopwatch()..start();

  debugPrint('🚀 RuleWise starting up...');

  try {
    // 2. Initialize Firebase with a safety net
    try {
      debugPrint('🔥 Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('⚠️ Firebase initialization timed out after 10s');
        throw Exception('Firebase Timeout');
      });

      if (!kIsWeb) {
        debugPrint('📲 Setting up background messaging...');
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }
    } catch (e) {
      debugPrint('❌ Firebase Error: $e');
    }

    // 3. Initialize Remote Config (critical for features, but non-blocking for boot)
    try {
      debugPrint('⚙️ Initializing Remote Config...');
      remoteConfigService = await RemoteConfigService.init()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('⚠️ Remote Config timed out after 5s');
        return RemoteConfigService.init(); // Retry or just return partially initialized
      });
    } catch (e) {
      debugPrint('❌ Remote Config Error: $e');
    }

    // 4. Initialize timezones and storage
    try {
      tz.initializeTimeZones();
      await Hive.initFlutter().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('❌ Hive/TZ Error: $e');
    }

    // 5. Initialize Notification Service (Mobile only for heavy init)
    if (!kIsWeb) {
      try {
        await notificationService.initialize().timeout(const Duration(seconds: 5));
        await notificationService.requestPermissions();
      } catch (e) {
        debugPrint('❌ Notification Service Error: $e');
      }
      
      // 6. Initialize Background Services (Mobile only)
      _initializeBackgroundServices();
    }

  } catch (e, stack) {
    debugPrint('🚨 Critical startup failure: $e');
    debugPrint(stack.toString());
  } finally {
    stopwatch.stop();
    debugPrint('🏁 Startup process finished in ${stopwatch.elapsedMilliseconds}ms');
    
    // ALWAYS run the app, even if errors occurred
    runApp(RuleWiseApp(
      remoteConfigService: remoteConfigService,
      notificationService: notificationService,
    ));
  }
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
