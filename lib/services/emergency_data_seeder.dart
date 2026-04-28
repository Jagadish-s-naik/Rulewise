import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class EmergencyDataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed real law updates for testing
  Future<void> seedLawUpdates() async {
    final updates = [
      {
        'title': 'FSSAI License Renewal Process Updated',
        'description':
            'New online renewal process introduced for FSSAI licenses. All renewals must be done through FoSCoS portal with digital signatures.',
        'effective_date': DateTime(2026, 2, 1),
        'source_url': 'https://www.fssai.gov.in',
        'business_types': ['food_beverage', 'restaurant', 'cafe'],
        'state': 'karnataka',
        'city': 'bengaluru',
        'status': 'approved',
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'title': 'GST Annual Return Filing Deadline Extended',
        'description':
            'GSTR-9 annual return filing deadline extended to March 31, 2026. Late fees waived for businesses with turnover below ₹2 crore.',
        'effective_date': DateTime(2026, 3, 31),
        'source_url': 'https://www.gst.gov.in',
        'business_types': ['retail', 'food_beverage', 'services'],
        'state': 'all',
        'city': 'all',
        'status': 'approved',
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Karnataka Shops and Establishments Act Amendment',
        'description':
            'New provisions for women employees working night shifts. Mandatory transportation and security measures required.',
        'effective_date': DateTime(2026, 1, 15),
        'source_url': 'https://labour.karnataka.gov.in',
        'business_types': ['retail', 'services', 'manufacturing'],
        'state': 'karnataka',
        'city': 'all',
        'status': 'approved',
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Trade License Fee Revision - BBMP',
        'description':
            'Bengaluru municipal corporation revised trade license fees. 15% increase for commercial establishments above 1000 sq ft.',
        'effective_date': DateTime(2026, 4, 1),
        'source_url': 'https://bbmp.gov.in',
        'business_types': ['retail', 'food_beverage', 'services'],
        'state': 'karnataka',
        'city': 'bengaluru',
        'status': 'approved',
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Professional Tax Payment Mode Updated',
        'description':
            'Karnataka Professional Tax now accepts UPI payments. Offline payment counters to be phased out by June 2026.',
        'effective_date': DateTime(2026, 6, 1),
        'source_url': 'https://karnatakatax.gov.in',
        'business_types': ['all'],
        'state': 'karnataka',
        'city': 'all',
        'status': 'approved',
        'created_at': FieldValue.serverTimestamp(),
      },
    ];

    for (var update in updates) {
      await _firestore.collection('law_updates').add(update);
    }

    debugPrint('✅ Seeded ${updates.length} law updates');
  }

  /// Seed legal rights for emergency mode
  Future<void> seedLegalRights() async {
    await _firestore
        .collection('legal_resources')
        .doc('inspection_rights')
        .set({
      'title': 'Your Legal Rights During Inspection',
      'rights': [
        'Inspector must show valid ID and authorization letter',
        'You have right to ask for advance notice (except surprise inspections)',
        'You can request presence of witness during inspection',
        'Inspector cannot seize documents without proper seizure memo',
        'You have right to take photographs/videos of inspection process',
        'You can request copy of inspection report within 7 days',
        'Right to legal representation if required',
        'Inspector must provide reasons for any adverse findings',
      ],
      'source':
          'Based on Indian Administrative Law and Right to Fair Administrative Action',
      'last_updated': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Seeded legal rights');
  }

  /// Seed inspection checklist
  Future<void> seedInspectionChecklist() async {
    await _firestore
        .collection('legal_resources')
        .doc('inspection_checklist')
        .set({
      'title': 'Quick Inspection Checklist',
      'categories': [
        {
          'name': 'Before Inspector Arrives',
          'items': [
            'Keep all license documents ready and accessible',
            'Ensure premises are clean and organized',
            'Brief staff about inspection procedures',
            'Keep contact details of legal advisor handy',
          ],
        },
        {
          'name': 'During Inspection',
          'items': [
            'Verify inspector\'s ID and authorization',
            'Accompany inspector throughout premises',
            'Take notes of inspector\'s observations',
            'Request clarification for any unclear points',
            'Do not sign any document without reading',
          ],
        },
        {
          'name': 'Documents to Keep Ready',
          'items': [
            'Trade License (original + photocopy)',
            'FSSAI License (if applicable)',
            'GST Registration Certificate',
            'Professional Tax enrollment',
            'Fire Safety Certificate',
            'Building plan approval',
          ],
        },
        {
          'name': 'After Inspection',
          'items': [
            'Request copy of inspection report',
            'Note down inspector\'s observations',
            'Address any deficiencies immediately',
            'Keep record of corrective actions taken',
            'Follow up on compliance timeline',
          ],
        },
      ],
      'last_updated': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Seeded inspection checklist');
  }

  /// Seed penalty reference
  Future<void> seedPenaltyReference() async {
    final penalties = [
      {
        'license_type': 'Trade License',
        'violation': 'Operating without valid license',
        'penalty': '₹10,000 - ₹50,000 fine + possible closure',
        'severity': 'critical',
      },
      {
        'license_type': 'FSSAI License',
        'violation': 'Food business without FSSAI registration',
        'penalty': '₹25,000 fine for first offense',
        'severity': 'critical',
      },
      {
        'license_type': 'Professional Tax',
        'violation': 'Non-payment of professional tax',
        'penalty': '₹1,000 per month + 1.25% interest per month',
        'severity': 'high',
      },
      {
        'license_type': 'GST',
        'violation': 'Late filing of GST returns',
        'penalty': '₹50 per day (max ₹5,000)',
        'severity': 'medium',
      },
      {
        'license_type': 'Shops & Establishments',
        'violation': 'Non-registration under Act',
        'penalty': '₹5,000 - ₹10,000 fine',
        'severity': 'high',
      },
    ];

    for (var penalty in penalties) {
      await _firestore.collection('penalty_reference').add(penalty);
    }

    debugPrint('✅ Seeded ${penalties.length} penalty references');
  }

  /// Seed all emergency data
  Future<void> seedAll() async {
    try {
      await seedLawUpdates();
      await seedLegalRights();
      await seedInspectionChecklist();
      await seedPenaltyReference();
      debugPrint('🎉 All emergency data seeded successfully!');
    } catch (e) {
      debugPrint('❌ Error seeding data: $e');
      rethrow;
    }
  }
}
