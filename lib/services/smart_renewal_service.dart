import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/license_model.dart';
import '../models/user_license_model.dart';
import '../models/renewal_automation_model.dart';
import 'government_portal_service.dart';
import 'notification_service.dart';

class SmartRenewalService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GovernmentPortalService _portalService = GovernmentPortalService();
  final NotificationService _notificationService = NotificationService();

  // Cache for automation status
  final Map<String, RenewalAutomation> _automationCache = {};

  /// Check for fee changes and document updates
  Future<RenewalIntelligence> analyzeRenewal({
    required LicenseModel license,
    required UserLicenseModel userLicense,
    required String city,
  }) async {
     // Fetch live fee from government portal
     final liveFee = await _portalService.verifyLicenseFee(
       licenseType: license.id.split('_').last,
       city: city,
     );

     // Check for fee changes
    final feeChanged = liveFee != null && liveFee != license.fee;
    final feeIncrease = feeChanged ? liveFee - license.fee : 0;

    // Check for document updates
    final documentChanges = await _checkDocumentUpdates(license.id);

    // Calculate optimal renewal date
    final optimalDate = _calculateOptimalRenewalDate(
      expiryDate: userLicense.expiryDate,
      processingTime: license.processingTime,
    );

    // Determine urgency
    final daysUntilExpiry =
        userLicense.expiryDate.difference(DateTime.now()).inDays;
    final urgency = _determineUrgency(daysUntilExpiry, optimalDate);

    return RenewalIntelligence(
      license: license,
      userLicense: userLicense,
      currentFee: license.fee,
      liveFee: liveFee,
      feeChanged: feeChanged,
      feeIncrease: feeIncrease,
      documentChanges: documentChanges,
      optimalRenewalDate: optimalDate,
      daysUntilExpiry: daysUntilExpiry,
      urgency: urgency,
      recommendation: _generateRecommendation(
        feeChanged: feeChanged,
        feeIncrease: feeIncrease,
        documentChanges: documentChanges,
        urgency: urgency,
        optimalDate: optimalDate,
      ),
    );
  }

  /// Check for document requirement updates
  Future<List<String>> _checkDocumentUpdates(String licenseId) async {
    try {
      final doc = await _firestore
          .collection('license_document_updates')
          .doc(licenseId)
          .get();

      if (doc.exists) {
        final updates = doc.data()!['new_documents'] as List?;
        if (updates != null) {
          return List<String>.from(updates);
        }
      }
    } catch (e) {
      debugPrint('Error checking document updates: $e');
    }

    return [];
  }

  /// Calculate optimal renewal date
  DateTime _calculateOptimalRenewalDate({
    required DateTime expiryDate,
    required String processingTime,
  }) {
    // Parse processing time (e.g., "15-30 days")
    final days = _parseProcessingTime(processingTime);

    // Add 15-day buffer
    const bufferDays = 15;
    final totalDays = days + bufferDays;

    return expiryDate.subtract(Duration(days: totalDays));
  }

  int _parseProcessingTime(String processingTime) {
    // Extract maximum days from format like "15-30 days"
    final match = RegExp(r'(\d+)-(\d+)').firstMatch(processingTime);
    if (match != null) {
      return int.parse(match.group(2)!);
    }

    // Extract single number like "30 days"
    final singleMatch = RegExp(r'(\d+)').firstMatch(processingTime);
    if (singleMatch != null) {
      return int.parse(singleMatch.group(1)!);
    }

    return 30; // Default
  }

  RenewalUrgency _determineUrgency(int daysUntilExpiry, DateTime optimalDate) {
    final now = DateTime.now();

    if (daysUntilExpiry < 0) {
      return RenewalUrgency.expired;
    } else if (now.isAfter(optimalDate)) {
      return RenewalUrgency.urgent;
    } else if (daysUntilExpiry <= 60) {
      return RenewalUrgency.soon;
    } else {
      return RenewalUrgency.planned;
    }
  }

  String _generateRecommendation({
    required bool feeChanged,
    required int feeIncrease,
    required List<String> documentChanges,
    required RenewalUrgency urgency,
    required DateTime optimalDate,
  }) {
    final buffer = StringBuffer();

    // Urgency-based recommendation
    switch (urgency) {
      case RenewalUrgency.expired:
        buffer.writeln('🚨 EXPIRED: Renew immediately to avoid penalties!');
        break;
      case RenewalUrgency.urgent:
        buffer.writeln('⚠️ URGENT: Optimal renewal window is NOW');
        break;
      case RenewalUrgency.soon:
        buffer.writeln('📅 Plan renewal by ${_formatDate(optimalDate)}');
        break;
      case RenewalUrgency.planned:
        buffer.writeln(
            '✓ No action needed yet. Optimal date: ${_formatDate(optimalDate)}');
        break;
    }

    // Fee change alert
    if (feeChanged) {
      if (feeIncrease > 0) {
        buffer.writeln('\n💰 Fee increased by ₹$feeIncrease');
        buffer.writeln('Consider renewing before further increases');
      } else {
        buffer.writeln('\n💰 Fee decreased by ₹${-feeIncrease}');
      }
    }

    // Document changes alert
    if (documentChanges.isNotEmpty) {
      buffer.writeln('\n📄 New documents required:');
      for (var doc in documentChanges) {
        buffer.writeln('  • $doc');
      }
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Track fee history (admin function)
  Future<void> recordFeeChange({
    required String licenseId,
    required int newFee,
    required String source,
  }) async {
    await _firestore.collection('license_fee_history').doc(licenseId).set({
      'history': FieldValue.arrayUnion([
        {
          'fee': newFee,
          'recorded_at': FieldValue.serverTimestamp(),
          'source': source,
        }
      ]),
    }, SetOptions(merge: true));
  }

  // ============ AUTOMATION METHODS ============

  /// Enable automation for a license
  Future<void> enableAutomation(
      String licenseId, UserLicenseModel userLicense) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Calculate next action date (60 days before expiry for document prep)
      final nextActionDate =
          userLicense.expiryDate.subtract(const Duration(days: 60));

      final automation = RenewalAutomation(
        licenseId: licenseId,
        enabled: true,
        nextActionDate: nextActionDate,
        completedSteps: [],
        metadata: {
          'license_name': userLicense.licenseName,
          'expiry_date': userLicense.expiryDate.toIso8601String(),
        },
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('license_automation')
          .doc(licenseId)
          .set(automation.toFirestore());

      _automationCache[licenseId] = automation;

      // Schedule automated reminders
      await _scheduleAutomatedReminders(userLicense);

      notifyListeners();
      debugPrint('✅ Automation enabled for $licenseId');
    } catch (e) {
      debugPrint('Error enabling automation: $e');
      rethrow;
    }
  }

  /// Disable automation for a license
  Future<void> disableAutomation(String licenseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('license_automation')
          .doc(licenseId)
          .update({'enabled': false});

      _automationCache[licenseId] =
          _automationCache[licenseId]!.copyWith(enabled: false);

      // Cancel automated reminders
      await _notificationService.cancelRenewalAlerts(licenseId);

      notifyListeners();
      debugPrint('❌ Automation disabled for $licenseId');
    } catch (e) {
      debugPrint('Error disabling automation: $e');
      rethrow;
    }
  }

  /// Get automation status for a license
  Future<RenewalAutomation?> getAutomationStatus(String licenseId) async {
    // Check cache first
    if (_automationCache.containsKey(licenseId)) {
      return _automationCache[licenseId];
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('license_automation')
          .doc(licenseId)
          .get();

      if (doc.exists) {
        final automation = RenewalAutomation.fromFirestore(doc);
        _automationCache[licenseId] = automation;
        return automation;
      }
    } catch (e) {
      debugPrint('Error fetching automation status: $e');
    }

    return null;
  }

  /// Schedule automated reminders based on optimal renewal date
  Future<void> _scheduleAutomatedReminders(UserLicenseModel license) async {
    try {
      // Calculate reminder dates
      final expiryDate = license.expiryDate;
      final documentPrepDate = expiryDate.subtract(const Duration(days: 60));
      final optimalWindowDate = expiryDate.subtract(const Duration(days: 30));
      final urgentDate = expiryDate.subtract(const Duration(days: 7));
      final finalWarningDate = expiryDate.subtract(const Duration(days: 1));

      // Schedule notifications
      await _notificationService.scheduleRenewalReminder(
        license: license,
        reminderDate: documentPrepDate,
        title: '📄 Document Preparation',
        body: 'Start gathering documents for ${license.licenseName} renewal',
      );

      await _notificationService.scheduleRenewalReminder(
        license: license,
        reminderDate: optimalWindowDate,
        title: '⏰ Optimal Renewal Window',
        body: 'Best time to renew ${license.licenseName}',
      );

      await _notificationService.scheduleRenewalReminder(
        license: license,
        reminderDate: urgentDate,
        title: '⚠️ Urgent: Renewal Due Soon',
        body: '${license.licenseName} expires in 7 days',
      );

      await _notificationService.scheduleRenewalReminder(
        license: license,
        reminderDate: finalWarningDate,
        title: '🚨 Final Warning',
        body: '${license.licenseName} expires tomorrow!',
      );

      debugPrint(
          '📅 Scheduled 4 automated reminders for ${license.licenseName}');
    } catch (e) {
      debugPrint('Error scheduling automated reminders: $e');
    }
  }
}

enum RenewalUrgency {
  expired,
  urgent,
  soon,
  planned,
}

class RenewalIntelligence {
  final LicenseModel license;
  final UserLicenseModel userLicense;
  final int currentFee;
  final int? liveFee;
  final bool feeChanged;
  final int feeIncrease;
  final List<String> documentChanges;
  final DateTime optimalRenewalDate;
  final int daysUntilExpiry;
  final RenewalUrgency urgency;
  final String recommendation;

  RenewalIntelligence({
    required this.license,
    required this.userLicense,
    required this.currentFee,
    this.liveFee,
    required this.feeChanged,
    required this.feeIncrease,
    required this.documentChanges,
    required this.optimalRenewalDate,
    required this.daysUntilExpiry,
    required this.urgency,
    required this.recommendation,
  });
}
