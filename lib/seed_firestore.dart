// ignore_for_file: avoid_print
// Run this file to seed Firestore data
// dart run lib/seed_firestore.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  print('🌱 Starting Firestore seeding...\n');

  // Initialize Firebase
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  try {
    // Seed law updates
    print('📜 Seeding law updates...');
    await _seedLawUpdates(firestore);

    // Seed penalties
    print('\n⚖️  Seeding penalties...');
    await _seedPenalties(firestore);

    // Seed legal resources
    print('\n📚 Seeding legal resources...');
    await _seedLegalResources(firestore);

    print('\n✅ All data seeded successfully!');
  } catch (e) {
    print('\n❌ Error: $e');
  }
}

Future<void> _seedLawUpdates(FirebaseFirestore firestore) async {
  final updates = [
    {
      'title': 'FSSAI License Fee Revision 2024',
      'description':
          'Ministry of Health revises FSSAI license fees for all categories. New fee structure effective from April 1, 2024.',
      'published_date': Timestamp.now(),
      'effective_date': Timestamp.fromDate(DateTime(2024, 4, 1)),
      'states': ['All India'],
      'business_types': ['food_beverage', 'retail_shop'],
      'impact': 'high',
      'source_url': 'https://www.fssai.gov.in',
    },
    {
      'title': 'GST Rate Changes for Restaurants',
      'description':
          'GST Council revises tax rates for restaurant services. AC restaurants now at 18%, non-AC at 12%.',
      'published_date':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
      'effective_date': Timestamp.fromDate(DateTime(2024, 2, 1)),
      'states': ['All India'],
      'business_types': ['food_beverage'],
      'impact': 'high',
      'source_url': 'https://www.gst.gov.in',
    },
    {
      'title': 'Shop Act Amendment - Karnataka',
      'description':
          'Karnataka amends Shop and Establishment Act. All shops must now register online. Penalty for non-compliance increased to ₹10,000.',
      'published_date':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
      'effective_date': Timestamp.fromDate(DateTime(2024, 3, 1)),
      'states': ['Karnataka'],
      'business_types': ['retail_shop', 'service_provider'],
      'impact': 'medium',
      'source_url': 'https://labour.karnataka.gov.in',
    },
    {
      'title': 'Fire Safety NOC Mandatory',
      'description':
          'Maharashtra Fire Department makes Fire Safety NOC mandatory for all commercial establishments above 500 sq ft.',
      'published_date':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 15))),
      'effective_date': Timestamp.fromDate(DateTime(2024, 6, 30)),
      'states': ['Maharashtra'],
      'business_types': ['retail_shop', 'food_beverage', 'service_provider'],
      'impact': 'high',
      'source_url': 'https://mahafireservice.gov.in',
    },
    {
      'title': 'Trade License Renewal Extended',
      'description':
          'Delhi Municipal Corporation extends trade license renewal period by 3 months. No late fees till March 31, 2024.',
      'published_date':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      'effective_date': Timestamp.fromDate(DateTime(2024, 3, 31)),
      'states': ['Delhi'],
      'business_types': ['retail_shop', 'food_beverage', 'service_provider'],
      'impact': 'medium',
      'source_url': 'https://mcdonline.gov.in',
    },
  ];

  for (var update in updates) {
    await firestore.collection('law_updates').add(update);
    print('  ✓ ${update['title']}');
  }
}

Future<void> _seedPenalties(FirebaseFirestore firestore) async {
  final penalties = [
    {
      'violation': 'Operating without valid FSSAI license',
      'penalty': '₹25,000 fine or imprisonment up to 6 months',
      'law_reference': 'Food Safety and Standards Act 2006, Section 59',
    },
    {
      'violation': 'Operating without Trade License',
      'penalty': '₹10,000 fine and possible business closure',
      'law_reference': 'Shop and Establishment Act, Section 7',
    },
    {
      'violation': 'Non-payment of Professional Tax',
      'penalty': '₹5,000 fine plus 2% interest per month',
      'law_reference': 'Professional Tax Act, Section 12',
    },
    {
      'violation': 'Expired Fire Safety NOC',
      'penalty': '₹50,000 fine and immediate closure order',
      'law_reference': 'Fire Safety Act, Section 15',
    },
    {
      'violation': 'Non-compliance with Labour Laws',
      'penalty': '₹20,000 fine per violation',
      'law_reference': 'Labour Welfare Act, Section 25',
    },
  ];

  for (var penalty in penalties) {
    await firestore.collection('penalty_reference').add(penalty);
    print('  ✓ ${penalty['violation']}');
  }
}

Future<void> _seedLegalResources(FirebaseFirestore firestore) async {
  await firestore.collection('legal_resources').doc('legal_rights').set({
    'title': 'Your Legal Rights During Inspection',
    'source': 'Constitution of India, Article 19 & 21',
    'rights': [
      'Inspector must show valid ID and authorization letter',
      'You have right to ask for inspection notice (except emergency)',
      'You can request presence of witness during inspection',
      'Inspector cannot seize documents without proper procedure',
      'You have right to take photographs of inspection process',
      'Inspector must provide inspection report copy',
      'You can refuse entry if inspector has no valid authorization',
      'You have right to legal representation during inspection',
    ],
  });
  print('  ✓ Legal rights');

  await firestore
      .collection('legal_resources')
      .doc('inspection_checklist')
      .set({
    'title': 'Quick Inspection Checklist',
    'categories': [
      {
        'name': 'Documentation',
        'items': [
          'Original license certificates (FSSAI, Trade, etc.)',
          'Renewal receipts and payment proofs',
          'Employee health certificates',
          'Fire safety NOC',
          'Pollution clearance certificate',
        ],
      },
      {
        'name': 'Hygiene & Safety',
        'items': [
          'Clean and sanitized premises',
          'Proper waste disposal system',
          'Fire extinguishers in working condition',
          'First aid kit available',
        ],
      },
      {
        'name': 'Employee Records',
        'items': [
          'Employee attendance register',
          'Salary payment records',
          'EPF and ESI compliance documents',
        ],
      },
    ],
  });
  print('  ✓ Inspection checklist');
}
