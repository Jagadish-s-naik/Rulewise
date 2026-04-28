import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_license_model.dart';
import '../models/license_model.dart';
import 'notification_service.dart';

/// Service for managing user licenses with expiry tracking
class UserLicenseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserLicenseModel> _userLicenses = [];
  bool _isLoading = false;

  List<UserLicenseModel> get userLicenses => _userLicenses;
  bool get isLoading => _isLoading;

  /// Load all user licenses
  Future<void> loadUserLicenses() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('📥 Loading licenses for user: $userId');
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_licenses')
          .get();

      debugPrint('📄 Found ${snapshot.docs.length} license documents');

      _userLicenses = snapshot.docs
          .map((doc) {
            try {
              return UserLicenseModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('⚠️ Error parsing license ${doc.id}: $e');
              return null;
            }
          })
          .whereType<UserLicenseModel>() // Filter out nulls
          .toList();

      debugPrint('✅ Successfully parsed ${_userLicenses.length} licenses');

      // Sort by expiry date (soonest first)
      _userLicenses.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

      // Schedule renewal alerts for all licenses
      await _scheduleAllRenewalAlerts();
    } catch (e) {
      debugPrint('❌ Error loading user licenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Schedule renewal alerts for all user licenses
  Future<void> _scheduleAllRenewalAlerts() async {
    try {
      final notificationService = NotificationService();

      for (final license in _userLicenses) {
        if (license.renewalAlertsEnabled) {
          await notificationService.scheduleAllRenewalAlerts(license);
        }
      }
    } catch (e) {
      debugPrint('Error scheduling renewal alerts: $e');
    }
  }

  /// Add a new user license
  Future<void> addLicense({
    required LicenseModel license,
    required String licenseNumber,
    required String issuingAuthority,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? documentUrl,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final userLicense = UserLicenseModel(
        id: '', // Will be set by Firestore
        licenseId: license.id,
        licenseName: license.name,
        licenseNumber: licenseNumber,
        issuingAuthority: issuingAuthority,
        issueDate: issueDate,
        expiryDate: expiryDate,
        status: LicenseStatus.active,
        documentUrl: documentUrl,
        userVerified: true,
        renewalAlertsEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_licenses')
          .add(userLicense.toFirestore());

      // Reload licenses
      await loadUserLicenses();

      // Schedule renewal alerts for the new license
      if (userLicense.renewalAlertsEnabled) {
        final notificationService = NotificationService();
        // Get the newly added license with its ID
        final addedLicense = _userLicenses.firstWhere(
          (l) => l.licenseNumber == licenseNumber,
        );
        await notificationService.scheduleAllRenewalAlerts(addedLicense);
      }
    } catch (e) {
      debugPrint('Error adding license: $e');
      rethrow;
    }
  }

  /// Update an existing license
  Future<void> updateLicense(UserLicenseModel license) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_licenses')
          .doc(license.id)
          .update(license.toFirestore());

      // Reload licenses
      await loadUserLicenses();

      // Reschedule renewal alerts
      final notificationService = NotificationService();
      await notificationService.cancelRenewalAlerts(license.id);
      if (license.renewalAlertsEnabled) {
        await notificationService.scheduleAllRenewalAlerts(license);
      }
    } catch (e) {
      debugPrint('Error updating license: $e');
      rethrow;
    }
  }

  /// Delete a license
  Future<void> deleteLicense(String licenseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_licenses')
          .doc(licenseId)
          .delete();

      // Cancel renewal alerts
      final notificationService = NotificationService();
      await notificationService.cancelRenewalAlerts(licenseId);

      _userLicenses.removeWhere((l) => l.id == licenseId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting license: $e');
      rethrow;
    }
  }

  /// Get licenses by status
  List<UserLicenseModel> getLicensesByStatus(LicenseStatus status) {
    return _userLicenses.where((l) => l.currentStatus == status).toList();
  }

  /// Get expiring soon licenses (within 30 days)
  List<UserLicenseModel> getExpiringSoonLicenses() {
    return _userLicenses.where((l) => l.isExpiringSoon).toList();
  }

  /// Get expired licenses
  List<UserLicenseModel> getExpiredLicenses() {
    return _userLicenses.where((l) => l.isExpired).toList();
  }

  /// Check if user has a specific license
  bool hasLicense(String licenseId) {
    return _userLicenses.any((l) => l.licenseId == licenseId);
  }

  /// Get user license for a specific compliance license
  UserLicenseModel? getUserLicense(String licenseId) {
    try {
      return _userLicenses.firstWhere((l) => l.licenseId == licenseId);
    } catch (e) {
      return null;
    }
  }

  /// Add a generic user license/document directly
  Future<void> addUserLicense({
    required String licenseId,
    required String licenseNumber,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? documentUrl,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Create a specific ID for this document if not provided
      final docId = licenseId.isEmpty
          ? 'doc_${DateTime.now().millisecondsSinceEpoch}'
          : licenseId;

      final userLicense = UserLicenseModel(
        id: '', // Will be set by Firestore
        licenseId: docId,
        licenseName: documentUrl ?? 'Uploaded Document', // Use filename as name
        licenseNumber: licenseNumber,
        issuingAuthority: 'Self Uploaded',
        issueDate: issueDate,
        expiryDate: expiryDate,
        status: LicenseStatus.active,
        documentUrl: documentUrl,
        userVerified: true,
        renewalAlertsEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_licenses')
          .add(userLicense.toFirestore());

      // Reload licenses
      await loadUserLicenses();
    } catch (e) {
      debugPrint('Error adding user license: $e');
      rethrow;
    }
  }
}
