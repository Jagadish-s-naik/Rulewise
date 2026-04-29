import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/government_license_data.dart';

class FirestoreSeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedAllData() async {
    debugPrint('🌱 Starting Firestore seeding with 135+ licenses...');

    try {
      final allData = GovernmentLicenseData.getAllData();
      int totalLicenses = 0;

      for (var stateEntry in allData.entries) {
        final state = stateEntry.key;
        final cities = stateEntry.value;

        debugPrint('\n📍 Seeding $state...');

        for (var cityEntry in cities.entries) {
          final city = cityEntry.key;
          final businessTypes = cityEntry.value;

          debugPrint('  🏙️  Seeding $city...');

          for (var businessEntry in businessTypes.entries) {
            final businessType = businessEntry.key;
            final licenses = businessEntry.value;

            debugPrint(
                '    📋 Seeding $businessType (${licenses.length} licenses)...');

            for (var licenseData in licenses) {
              final licenseId = licenseData['id']?.toString() ?? '';
              if (licenseId.isEmpty) {
                debugPrint('⚠️ Skipping license with empty ID');
                continue;
              }

              await _firestore
                  .collection('compliance_data')
                  .doc(state)
                  .collection('cities')
                  .doc(city)
                  .collection('business_types')
                  .doc(businessType)
                  .collection('licenses')
                  .doc(licenseId)
                  .set(licenseData);

              totalLicenses++;
              debugPrint('      ✓ ${licenseData['name']}');
            }
          }
        }
      }

      debugPrint('\n✅ Seeding completed successfully!');
      debugPrint('📊 Total licenses seeded: $totalLicenses');
    } catch (e) {
      debugPrint('❌ Seeding failed: $e');
      rethrow;
    }
  }

  // Seed data for the current user to test dashboard
  Future<void> seedUserScenario(String userId) async {
    debugPrint('👤 Seeding test data for user: $userId');

    // 1. Set user profile to a known test state
    await _firestore.collection('users').doc(userId).set({
      'email': 'test@example.com', // Will be overwritten if merging
      'name': 'Test User',
      'role': 'Owner',
      'business_name': 'Test Restaurant',
      'business_type': 'food_beverage', // Matches master data key
      'location': {
        'state': 'karnataka', // Matches master data key
        'city': 'bengaluru', // Matches master data key
        'address': '123 MG Road',
        'pincode': '560001',
      },
      'employee_count': '10-50',
      'annual_turnover': '10L - 1Cr',
      'created_at': FieldValue.serverTimestamp(),
      'profile_completed': true,
      'subscription_tier': 'free',
    }, SetOptions(merge: true));

    // 2. Fetch required licenses for this profile
    final licenseSnapshot = await _firestore
        .collection('compliance_data')
        .doc('karnataka') // keys are lowercase in master data
        .collection('cities')
        .doc('bengaluru')
        .collection('business_types')
        .doc('food_beverage')
        .collection('licenses')
        .get();

    if (licenseSnapshot.docs.isEmpty) {
      debugPrint('⚠️ No master licenses found. Run seedAllData() first.');
      throw Exception('Master data missing. Please seed database first.');
    }

    // 3. Create a mix of statuses (Active, Expired, Expiring Soon)
    final batch = _firestore.batch();
    final now = DateTime.now();
    int index = 0;

    for (var doc in licenseSnapshot.docs) {
      final licenseId = doc.id;
      final licenseName = doc.data()['name'];

      // Determine simulated status based on index
      // 0, 1: Active
      // 2: Expiring Soon
      // 3: Expired
      // 4: Missing (don't add)

      if (index == 4) {
        index = 0;
        continue; // Skip calculating this one to simulate "Missing"
      }

      String status = 'active';
      DateTime expiryDate = now.add(const Duration(days: 365));
      DateTime issueDate = now.subtract(const Duration(days: 30));

      if (index == 2) {
        // Expiring Soon (in 30 days)
        status = 'active';
        expiryDate = now.add(const Duration(days: 30));
      } else if (index == 3) {
        // Expired (30 days ago)
        status = 'expired';
        expiryDate = now.subtract(const Duration(days: 30));
        issueDate = now.subtract(const Duration(days: 395));
      }

      final userLicenseRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_licenses')
          .doc(licenseId); // Use license ID as doc ID for simplicity

      batch.set(userLicenseRef, {
        'license_id': licenseId,
        'license_name': licenseName,
        'status': status,
        'issue_date': Timestamp.fromDate(issueDate),
        'expiry_date': Timestamp.fromDate(expiryDate),
        'uploaded_at': FieldValue.serverTimestamp(),
        'document_url': 'https://example.com/test_doc.pdf',
        'notes': 'Seeded test data',
      });

      debugPrint('  set $licenseId to $status');
      index++;
    }

    await batch.commit();
    debugPrint('✅ User test data seeded successfully!');
  }

  // Clear all compliance data (for testing)
  Future<void> clearAllData() async {
    debugPrint('🗑️  Clearing all compliance data...');

    try {
      final states = await _firestore.collection('compliance_data').get();

      for (var stateDoc in states.docs) {
        await _deleteCollection(stateDoc.reference);
      }

      debugPrint('✅ All data cleared!');
    } catch (e) {
      debugPrint('❌ Failed to clear data: $e');
      rethrow;
    }
  }

  Future<void> _deleteCollection(DocumentReference docRef) async {
    final collections = ['cities'];
    for (var collection in collections) {
      final snapshot = await docRef.collection(collection).get();
      for (var doc in snapshot.docs) {
        await _deleteCollection(doc.reference);
        await doc.reference.delete();
      }
    }
  }
}
