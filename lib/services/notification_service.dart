import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../models/user_license_model.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    // 1. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    // 2. Fetch internal notifications
    await fetchNotifications();
  }

  Future<void> requestPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'rulewise_alerts',
      'RuleWise Alerts',
      channelDescription: 'Critical compliance alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  // --- Settings Methods ---

  Future<bool> areNotificationsEnabled() async {
    // In a real app, check system permissions or shared preferences
    // For now, default to true or fetch from user profile if stored
    return true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    // Store preference in SharedPreferences or Firestore
    // For now, just log it
    debugPrint('Notifications enabled set to: $enabled');
  }

  // --- Scheduling Methods ---

  Future<void> scheduleAllRenewalAlerts(UserLicenseModel license) async {
    // Ideally use flutter_local_notifications here
    debugPrint('Scheduling renewal alerts for ${license.licenseName} (stub)');

    // Also create an in-app notification for "Scheduled"
    // This is optional but nice for verification
  }

  Future<void> cancelRenewalAlerts(String licenseId) async {
    debugPrint('Cancelling renewal alerts for license ID: $licenseId (stub)');
  }

  /// Schedule a specific renewal reminder
  Future<void> scheduleRenewalReminder({
    required UserLicenseModel license,
    required DateTime reminderDate,
    required String title,
    required String body,
  }) async {
    // Only schedule if the reminder date is in the future
    if (reminderDate.isBefore(DateTime.now())) {
      debugPrint('⏭️ Skipping past reminder for ${license.licenseName}');
      return;
    }

    try {
      // Calculate delay from now
      final delay = reminderDate.difference(DateTime.now());

      // For now, just log the scheduled reminder
      // In production, you'd use flutter_local_notifications with proper timezone support
      debugPrint(
          '📅 Scheduled reminder for ${license.licenseName} in ${delay.inDays} days');

      // TODO: Implement actual notification scheduling with flutter_local_notifications
      // This requires proper timezone initialization which should be done in main.dart
    } catch (e) {
      debugPrint('Error scheduling renewal reminder: $e');
    }
  }

  Future<void> fetchNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      _notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      // If empty, seed some sample notifications for demo
      if (_notifications.isEmpty) {
        await _seedSampleNotifications(userId);
        // recursive call to fetch seeded
        await fetchNotifications();
        return;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'is_read': true});

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          timestamp: _notifications[index].timestamp,
          isRead: true,
          actionRoute: _notifications[index].actionRoute,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _seedSampleNotifications(String userId) async {
    final batch = _firestore.batch();
    final collection =
        _firestore.collection('users').doc(userId).collection('notifications');

    final samples = [
      {
        'title': 'Welcome to RuleWise!',
        'message':
            'Your compliance journey starts here. Complete your profile to get personalized insights.',
        'type': 'info',
        'timestamp': Timestamp.now(),
        'is_read': false,
      },
      {
        'title': 'FSSAI Renewal Reminder',
        'message':
            'This is a sample alert. In a real scenario, you would be reminded of upcoming expiries.',
        'type': 'alert',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 2))),
        'is_read': false,
        'action_route': '/smart_renewal',
      },
      {
        'title': 'New Law Update',
        'message': 'Ministry of Health has updated food safety guidelines.',
        'type': 'update',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
        'is_read': true,
        'action_route': '/law_updates',
      }
    ];

    for (var data in samples) {
      final docRef = collection.doc();
      batch.set(docRef, data);
    }

    await batch.commit();
  }
}
