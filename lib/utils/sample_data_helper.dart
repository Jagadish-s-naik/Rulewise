import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Helper to add sample license for testing services
import 'package:flutter/foundation.dart';

class SampleDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add a sample FSSAI license for the current user
  static Future<void> addSampleLicense() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('❌ No user logged in');
      throw Exception('No user logged in');
    }
    debugPrint('🔍 Checking for existing licenses for user: $userId');

    // Check if user already has licenses
    final existingLicenses = await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_licenses')
        .limit(1)
        .get();

    if (existingLicenses.docs.isNotEmpty) {
      debugPrint(
          'ℹ️ User already has ${existingLicenses.docs.length} licenses');
      return;
    }

    debugPrint('➕ Adding sample licenses...');

    // Add sample FSSAI license
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_licenses')
        .add({
      'license_id': 'fssai_basic',
      'license_number': 'FSSAI-SAMPLE-123456',
      'license_name': 'FSSAI Basic License',
      'issuing_authority': 'Ministry of Health and Family Welfare',
      'issue_date': Timestamp.now(),
      'expiry_date': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 365)),
      ),
      'status': 'active',
      'document_url': null,
      'user_verified': true,
      'renewal_alerts_enabled': true,
      'created_at': Timestamp.now(),
      'updated_at': Timestamp.now(),
    });

    // Add sample Trade License
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_licenses')
        .add({
      'license_id': 'trade_license',
      'license_number': 'TRADE-SAMPLE-789012',
      'license_name': 'Trade License',
      'issuing_authority': 'Municipal Corporation',
      'issue_date': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 180)),
      ),
      'expiry_date': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 185)),
      ),
      'status': 'active',
      'document_url': null,
      'user_verified': true,
      'renewal_alerts_enabled': true,
      'created_at': Timestamp.now(),
      'updated_at': Timestamp.now(),
    });

    debugPrint('✅ Sample licenses added successfully');
  }

  /// Update user profile with sample data if missing
  static Future<void> ensureUserProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists || userDoc.data()?['business_type'] == null) {
      await _firestore.collection('users').doc(userId).set({
        'email': _auth.currentUser?.email ?? '',
        'business_name': 'Sample Business',
        'business_type': 'food_beverage',
        'location': {
          'city': 'bangalore',
          'state': 'Karnataka',
        },
        'profile_completed': true,
        'subscription_tier': 'free',
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ User profile updated');
    }
  }

  /// Initialize sample data for new users
  static Future<void> initializeSampleData() async {
    try {
      await ensureUserProfile();
      await addSampleLicense();
    } catch (e) {
      debugPrint('Error initializing sample data: $e');
    }
  }
}
