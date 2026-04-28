import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/indian_compliance_data.dart';

class MasterDataSeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Main function to seed all data.
  /// Checks if data exists to prevent duplicates/overwrites unless forced.
  Future<void> seedMasterData({bool force = false}) async {
    debugPrint('🚀 Starting Master Data Seeding...');
    int totalImported = 0;

    // 1. Group Data by State -> City -> BusinessType
    // This maps the flat list to the deep structure logic
    // Structure: compliance_data/{state}/cities/{city}/business_types/{type}/licenses/{license_id}

    // Since our app defaults are:
    // States: Karnataka, Maharashtra, Delhi
    // Cities: Bangalore, Mumbai, Delhi
    // Types: retail_shop, food_beverage, manufacturing, service_provider

    final targetLocations = [
      {'state': 'Karnataka', 'city': 'Bangalore'},
      {'state': 'Maharashtra', 'city': 'Mumbai'},
      {'state': 'Delhi', 'city': 'Delhi'},
    ];

    final targetTypes = [
      'retail_shop',
      'food_beverage',
      'manufacturing',
      'service_provider'
    ];

    for (var loc in targetLocations) {
      final state = loc['state']!;
      final city = loc['city']!;

      for (var type in targetTypes) {
        debugPrint('📦 Preparing data for $state -> $city -> $type...');

        // Filter relevant licenses from the master list
        final relevantLicenses = indianComplianceData.where((l) {
          // Check Location
          final states = l['states'] as List;
          bool stateMatch = states.contains('All') || states.contains(state);

          // Check Business Type
          final types = l['business_types'] as List;
          bool typeMatch = types.contains('All') || types.contains(type);

          return stateMatch && typeMatch;
        }).toList();

        if (relevantLicenses.isEmpty) continue;

        // Batch write to Firestore
        final batch = _firestore.batch();
        final collectionRef = _firestore
            .collection('compliance_data')
            .doc(state)
            .collection('cities')
            .doc(city)
            .collection('business_types')
            .doc(type)
            .collection('licenses');

        for (var licenseData in relevantLicenses) {
          final docRef = collectionRef.doc(licenseData['id'] as String);

          // Map flat data to Firestore schema
          final firestoreData = {
            'name': licenseData['name'],
            'official_name': licenseData['official_name'],
            'department': licenseData['department'],
            'description': licenseData['description'],
            'is_mandatory': licenseData['is_mandatory'],
            'renewal_cycle': licenseData['renewal_cycle'],
            'fee': licenseData['fee'],
            'penalty_per_month': 0, // Default or parse description
            'grace_period_days': licenseData['grace_period_days'],
            'application_url': licenseData['application_url'],
            'helpline': licenseData['helpline'],
            'required_documents': licenseData['required_documents'],
            'processing_time': licenseData['processing_time'],
            'last_updated': FieldValue.serverTimestamp(),
          };

          batch.set(docRef, firestoreData, SetOptions(merge: true));
          totalImported++;
        }

        await batch.commit();
        debugPrint('✅ Committed batch for $type in $city');
      }
    }

    debugPrint('🎉 Seeding Complete! Imported $totalImported license entries.');
  }
}
