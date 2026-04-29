import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../firebase_options.dart';
import 'notification_service.dart';

const String simplePeriodicTask = "simplePeriodicTask";

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

      // 3. Background task kept minimal since UserLicenseService
      // already schedules notifications when app is in foreground.
      // Workmanager serves as safety net for periodic checks.

      debugPrint("Background task completed successfully.");
    } catch (err) {
      debugPrint(
          "Background task failed: $err"); // Logger.error(err.toString());
      // throw err; // Don't throw if you want to retry?
    }

    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher,
        isInDebugMode:
            kDebugMode // If enabled, it posts a notification whenever the task runs
        );

    // continually runs every 24 hours
    await Workmanager().registerPeriodicTask(
      "daily-license-check",
      simplePeriodicTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType:
            NetworkType.connected, // Only run if online (to fetch new data)
      ),
      existingWorkPolicy:
          ExistingPeriodicWorkPolicy.keep, // Don't re-schedule if exists
    );
    debugPrint("Background Service Initialized - Periodic Task Scheduled");
  }
}
