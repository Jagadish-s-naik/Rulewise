import 'package:flutter/material.dart';
import '../screens/emergency/emergency_mode_screen.dart';
import '../screens/law_updates/law_updates_screen.dart';
import '../screens/fine_simulator/fine_simulator_screen.dart';
import '../screens/timeline/timeline_view_screen.dart';
import '../screens/growth/growth_advisor_screen.dart';

class AppNavigation {
  /// Navigate to Emergency Mode screen
  static void toEmergencyMode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyModeScreen()),
    );
  }

  /// Navigate to Law Updates screen
  static void toLawUpdates(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LawUpdatesScreen()),
    );
  }

  /// Navigate to Fine Simulator screen
  static void toFineSimulator(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FineSimulatorScreen()),
    );
  }

  /// Navigate to Timeline View screen
  static void toTimelineView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimelineViewScreen()),
    );
  }

  /// Navigate to Growth Advisor screen
  static void toGrowthAdvisor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GrowthAdvisorScreen()),
    );
  }
}
