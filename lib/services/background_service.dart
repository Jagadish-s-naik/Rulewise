import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For FirebaseFirestore and FieldValue
import '../firebase_options.dart';
import 'notification_service.dart';

const String simplePeriodicTask = "simplePeriodicTask";
const String weeklyResetTask = "weeklyResetTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Native called background task: $task");

    try {
      // 1. Initialize Firebase (Essential for background isolate)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Initialize Notifications
      final notificationService = NotificationService();
      await notificationService.initialize();

      // 3. Route to appropriate task
      if (task == weeklyResetTask) {
        await _handleWeeklyReset();
      } else {
        // Default daily task
        debugPrint("Daily background task executed.");
      }

      debugPrint("Background task completed successfully.");
    } catch (err) {
      debugPrint("Background task failed: $err");
    }

    return Future.value(true);
  });
}

/// Resets weekly AI query counters for all active users
  Future<void> _handleWeeklyReset() async {
    try {
      debugPrint('🔄 Starting weekly AI query reset...');
      final firestore = FirebaseFirestore.instance;

      // Get all users with non-zero ai_queries_this_week
      final query = await firestore
          .collection('users')
          .where('ai_queries_this_week', isNotEqualTo: 0)
          .get();

      debugPrint('📊 Resetting ${query.docs.length} users');

      // Batch update to reset counters
      final batch = firestore.batch();
      for (var doc in query.docs) {
        batch.update(doc.reference, {
          'ai_queries_this_week': 0,
          'last_reset_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ Weekly AI query reset completed');
    } catch (e) {
      debugPrint('❌ Weekly reset failed: $e');
    }
  }

  class BackgroundService {
    static Future<void> initialize() async {
      await Workmanager().initialize(callbackDispatcher);

      // Daily task - continually runs every 24 hours
      await Workmanager().registerPeriodicTask(
        "daily-license-check",
        simplePeriodicTask,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );

      // Weekly task - reset AI query counters every Monday at midnight
      await Workmanager().registerPeriodicTask(
        "weekly-ai-reset",
        weeklyResetTask,
        frequency: const Duration(days: 7),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );

      debugPrint(
          "Background Service Initialized - Daily & Weekly tasks scheduled");
    }
  }
