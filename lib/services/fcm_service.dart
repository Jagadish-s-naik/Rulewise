import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  Future<void> initialize() async {
    // 1. Request Permission (Critical for Android 13+ and iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get Token (Send this to your backend/console to test)
      String? token = await getToken();
      debugPrint('🔥 FCM Token: $token');

      // 3. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
              'Message also contained a notification: ${message.notification}');

          // Show local notification using our existing service
          _notificationService.showNotification(
            id: message.hashCode,
            title: message.notification!.title ?? 'RuleWise Alert',
            body: message.notification!.body ?? 'Check your compliance status.',
            payload: message.data['route'], // Optional routing logic
          );
        }
      });

      // 4. Handle Background/Terminated Tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        // Navigator.pushNamed(context, '/message', arguments: MessageArguments(message, true));
      });
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Optional: Handle background messages specifically if needed
  // Must be a top-level function.
  // static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //   await Firebase.initializeApp();
  //   print("Handling a background message: ${message.messageId}");
  // }
}
