import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../models/user_license_model.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

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

    _isInitialized = true;

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
    debugPrint('📅 Scheduling all alerts for ${license.licenseName}');
    
    final expiry = license.expiryDate;
    
    // Schedule 30 days before
    await scheduleRenewalReminder(
      license: license,
      reminderDate: expiry.subtract(const Duration(days: 30)),
      title: 'Action Required: ${license.licenseName}',
      body: 'Your license expires in 30 days. Start the renewal process now.',
    );

    // Schedule 7 days before
    await scheduleRenewalReminder(
      license: license,
      reminderDate: expiry.subtract(const Duration(days: 7)),
      title: 'Urgent: ${license.licenseName} Expiring',
      body: 'Your license expires in 7 days. Avoid penalties by renewing today.',
    );

    // Schedule on expiry day
    await scheduleRenewalReminder(
      license: license,
      reminderDate: expiry,
      title: 'Critical: ${license.licenseName} Expired',
      body: 'Your license has expired. You may be liable for penalties.',
    );
  }

  Future<void> cancelRenewalAlerts(String licenseId) async {
    debugPrint('🚫 Cancelling all alerts for license: $licenseId');
    // Using hash of licenseId as group ID for cancellation
    await _localNotifications.cancel(licenseId.hashCode);
    await _localNotifications.cancel(licenseId.hashCode + 1);
    await _localNotifications.cancel(licenseId.hashCode + 2);
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
      return;
    }

    try {
      final scheduledTime = tz.TZDateTime.from(reminderDate, tz.local);
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'renewal_reminders',
        'Renewal Reminders',
        channelDescription: 'Alerts for license renewals',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      // Use a combination of license hashCode and offset to ensure unique IDs for multiple reminders
      int notificationId = license.id.hashCode;
      if (reminderDate.isAtSameMomentAs(license.expiryDate)) {
        notificationId += 2;
      } else if (reminderDate.isAfter(license.expiryDate.subtract(const Duration(days: 8)))) {
        notificationId += 1;
      }

      await _localNotifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'license_id=${license.id}',
      );

      debugPrint('✅ Scheduled: "$title" at $scheduledTime');
    } catch (e) {
      debugPrint('❌ Error scheduling renewal reminder: $e');
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

  void clear() {
    _notifications = [];
    _isLoading = false;
    notifyListeners();
  }
}
