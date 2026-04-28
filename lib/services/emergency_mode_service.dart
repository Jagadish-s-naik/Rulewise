import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_license_model.dart';

class EmergencyModeService {
  static const String _emergencyBox = 'emergency_cache';
  static const String _licensesKey = 'cached_licenses';
  static const String _legalRightsKey = 'legal_rights';
  static const String _penaltiesKey = 'penalty_reference';
  static const String _checklistKey = 'inspection_checklist';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize emergency cache on app start
  Future<void> initializeCache(String userId) async {
    try {
      final box = await Hive.openBox(_emergencyBox);

      // Fetch and cache user licenses
      final userLicenses = await _fetchUserLicenses(userId);
      await box.put(_licensesKey, userLicenses.map((l) => l.toMap()).toList());

      // Fetch and cache legal rights
      final legalRights = await _fetchLegalRights();
      await box.put(_legalRightsKey, legalRights);

      // Fetch and cache penalty reference
      final penalties = await _fetchPenaltyReference();
      await box.put(_penaltiesKey, penalties);

      // Fetch and cache inspection checklist
      final checklist = await _fetchInspectionChecklist();
      await box.put(_checklistKey, checklist);

      debugPrint('Emergency cache initialized successfully');
    } catch (e) {
      debugPrint('Error initializing emergency cache: $e');
    }
  }

  /// Get cached licenses (works offline)
  Future<List<Map<String, dynamic>>> getCachedLicenses() async {
    final box = await Hive.openBox(_emergencyBox);
    final cached = box.get(_licensesKey);

    if (cached is List) {
      return List<Map<String, dynamic>>.from(
        cached.map((item) => Map<String, dynamic>.from(item)),
      );
    }

    return [];
  }

  /// Get legal rights text (works offline)
  Future<Map<String, dynamic>> getLegalRights() async {
    // Try Firestore first
    try {
      debugPrint('🔍 Loading legal rights from Firestore...');
      final doc = await _firestore
          .collection('legal_resources')
          .doc('legal_rights')
          .get();

      if (doc.exists && doc.data() != null) {
        debugPrint('✅ Loaded legal rights from Firestore');
        return doc.data()!;
      }
    } catch (e) {
      debugPrint('⚠️ Firestore failed, trying cache: $e');
    }

    // Fallback to cache
    final box = await Hive.openBox(_emergencyBox);
    final cached = box.get(_legalRightsKey);

    if (cached is Map) {
      debugPrint('✅ Loaded legal rights from cache');
      return Map<String, dynamic>.from(cached);
    }

    debugPrint('⚠️ Using default legal rights');
    return {
      'title': 'Your Legal Rights During Inspection',
      'rights': [
        'Inspector must show valid ID and authorization',
        'You have right to ask for inspection notice',
        'You can request presence of witness',
        'Inspector cannot seize documents without proper procedure',
        'You have right to take photographs of inspection',
      ],
    };
  }

  /// Get penalty reference (works offline)
  Future<List<Map<String, dynamic>>> getPenaltyReference() async {
    // Try Firestore first
    try {
      debugPrint('🔍 Loading penalties from Firestore...');
      final snapshot = await _firestore.collection('penalty_reference').get();

      if (snapshot.docs.isNotEmpty) {
        debugPrint('✅ Loaded ${snapshot.docs.length} penalties from Firestore');
        return snapshot.docs.map((doc) => doc.data()).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Firestore failed, trying cache: $e');
    }

    // Fallback to cache
    final box = await Hive.openBox(_emergencyBox);
    final cached = box.get(_penaltiesKey);

    if (cached is List) {
      debugPrint('✅ Loaded penalties from cache');
      return List<Map<String, dynamic>>.from(
        cached.map((item) => Map<String, dynamic>.from(item)),
      );
    }

    debugPrint('⚠️ Using empty penalty list');
    return [];
  }

  /// Get inspection checklist (works offline)
  Future<Map<String, dynamic>> getInspectionChecklist() async {
    // Try Firestore first
    try {
      debugPrint('🔍 Loading checklist from Firestore...');
      final doc = await _firestore
          .collection('legal_resources')
          .doc('inspection_checklist')
          .get();

      if (doc.exists && doc.data() != null) {
        debugPrint('✅ Loaded checklist from Firestore');
        return doc.data()!;
      }
    } catch (e) {
      debugPrint('⚠️ Firestore failed, trying cache: $e');
    }

    // Fallback to cache
    final box = await Hive.openBox(_emergencyBox);
    final cached = box.get(_checklistKey);

    if (cached is Map) {
      debugPrint('✅ Loaded checklist from cache');
      return Map<String, dynamic>.from(cached);
    }

    debugPrint('⚠️ Using default checklist');
    return {
      'title': 'Quick Inspection Checklist',
      'items': [
        'All licenses displayed prominently',
        'License copies available',
        'Fire safety equipment accessible',
        'Employee records up to date',
        'Hygiene standards maintained (if applicable)',
      ],
    };
  }

  /// Fetch user licenses from Firestore
  Future<List<UserLicenseModel>> _fetchUserLicenses(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_licenses')
        .get();

    return snapshot.docs
        .map((doc) => UserLicenseModel.fromFirestore(doc))
        .toList();
  }

  /// Fetch legal rights from Firestore
  Future<Map<String, dynamic>> _fetchLegalRights() async {
    try {
      debugPrint('🔍 Fetching legal rights from Firestore...');
      // Try seeded document ID first
      final doc = await _firestore
          .collection('legal_resources')
          .doc('legal_rights')
          .get();

      if (doc.exists) {
        debugPrint('✅ Found legal_rights document');
        return doc.data() ?? {};
      }

      debugPrint('⚠️ legal_rights document not found');
    } catch (e) {
      debugPrint('❌ Error fetching legal rights: $e');
    }

    // Fallback to default rights
    return {
      'title': 'Your Legal Rights During Inspection',
      'rights': [
        'Inspector must show valid ID and authorization letter',
        'You have right to ask for advance notice (except surprise inspections)',
        'You can request presence of witness during inspection',
        'Inspector cannot seize documents without proper seizure memo',
        'You have right to take photographs/videos of inspection process',
        'You can request copy of inspection report',
        'Right to legal representation if required',
      ],
      'source': 'Based on Indian Administrative Law',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Fetch penalty reference from Firestore
  Future<List<Map<String, dynamic>>> _fetchPenaltyReference() async {
    try {
      debugPrint('🔍 Fetching penalty reference from Firestore...');
      // Don't use orderBy since seeded data doesn't have severity field
      final snapshot = await _firestore.collection('penalty_reference').get();

      debugPrint('✅ Found ${snapshot.docs.length} penalties');
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Error fetching penalty reference: $e');
    }

    // Fallback to common penalties
    return [
      {
        'violation': 'Operating without Trade License',
        'penalty': 'Up to ₹10,000 + closure notice',
        'severity': 'high',
      },
      {
        'violation': 'Expired FSSAI License',
        'penalty': '₹25,000 for first offense',
        'severity': 'high',
      },
      {
        'violation': 'No Fire NOC',
        'penalty': '₹5,000 - ₹50,000',
        'severity': 'medium',
      },
      {
        'violation': 'Shops & Establishment violation',
        'penalty': '₹2,000 - ₹20,000',
        'severity': 'medium',
      },
    ];
  }

  /// Fetch inspection checklist from Firestore
  Future<Map<String, dynamic>> _fetchInspectionChecklist() async {
    try {
      final doc = await _firestore
          .collection('legal_resources')
          .doc('inspection_checklist')
          .get();

      if (doc.exists) {
        return doc.data() ?? {};
      }
    } catch (e) {
      debugPrint('Error fetching checklist: $e');
    }

    // Fallback checklist
    return {
      'title': 'Quick Inspection Checklist',
      'categories': [
        {
          'name': 'Documents',
          'items': [
            'All licenses displayed at prominent location',
            'License copies available for verification',
            'Employee records up to date',
            'Tax payment receipts',
          ],
        },
        {
          'name': 'Safety',
          'items': [
            'Fire extinguishers accessible and serviced',
            'Emergency exits clearly marked',
            'First aid kit available',
          ],
        },
        {
          'name': 'Hygiene (if applicable)',
          'items': [
            'Food handler medical certificates',
            'Pest control records',
            'Waste disposal system',
          ],
        },
      ],
    };
  }

  /// Check if emergency mode access is available
  Future<bool> hasEmergencyAccess(String userId) async {
    // Check subscription or microtransaction
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) return false;

    final data = userDoc.data()!;

    // Business Shield or Enterprise tier
    final tier = data['subscription_tier'] as String?;
    if (tier == 'business_shield' || tier == 'enterprise') {
      return true;
    }

    // Check microtransaction
    final microtransactions = data['microtransactions'] as Map?;
    if (microtransactions != null) {
      final emergencyAccess = microtransactions['emergency_mode_24h'];
      if (emergencyAccess != null) {
        final expiresAt =
            (emergencyAccess['expiresAt'] as Timestamp?)?.toDate();
        if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
          return true;
        }
      }
    }

    return false;
  }
}
