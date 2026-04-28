import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility screen to seed Firestore data
/// This should be run ONCE to populate the database
class FirestoreSeederScreen extends StatefulWidget {
  const FirestoreSeederScreen({super.key});

  @override
  State<FirestoreSeederScreen> createState() => _FirestoreSeederScreenState();
}

class _FirestoreSeederScreenState extends State<FirestoreSeederScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSeeding = false;
  String _status = 'Ready to seed data';
  int _progress = 0;
  int _total = 0;

  Future<void> _seedAllData() async {
    setState(() {
      _isSeeding = true;
      _status = 'Starting data seeding...';
      _progress = 0;
      _total = 27; // 15 law updates + 10 penalties + 2 legal resources
    });

    try {
      await _seedLawUpdates();
      await _seedPenaltyReference();
      await _seedLegalResources();

      setState(() {
        _status = '✅ All data seeded successfully!';
        _isSeeding = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Firestore data seeded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isSeeding = false;
      });
    }
  }

  Future<void> _seedLawUpdates() async {
    setState(() => _status = 'Seeding law updates...');

    final lawUpdates = [
      {
        'title': 'FSSAI License Fee Revision 2024',
        'description':
            'Ministry of Health revises FSSAI license fees for all categories. New fee structure effective from April 1, 2024. Basic license fee increased from ₹100 to ₹200 per year.',
        'published_date': Timestamp.now(),
        'effective_date': Timestamp.fromDate(DateTime(2024, 4, 1)),
        'states': ['All India'],
        'business_types': ['food_beverage', 'retail_shop'],
        'impact': 'high',
        'source_url': 'https://www.fssai.gov.in/notifications',
      },
      {
        'title': 'GST Rate Changes for Restaurants',
        'description':
            'GST Council revises tax rates for restaurant services. AC restaurants now at 18%, non-AC at 12%. Effective from February 2024.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 5))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 2, 1)),
        'states': ['All India'],
        'business_types': ['food_beverage'],
        'impact': 'high',
        'source_url': 'https://www.gst.gov.in',
      },
      {
        'title': 'Shop and Establishment Act Amendment - Karnataka',
        'description':
            'Karnataka amends Shop and Establishment Act. All shops must now register online. Penalty for non-compliance increased to ₹10,000.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 10))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 3, 1)),
        'states': ['Karnataka'],
        'business_types': ['retail_shop', 'service_provider'],
        'impact': 'medium',
        'source_url': 'https://labour.karnataka.gov.in',
      },
      {
        'title': 'Fire Safety NOC Mandatory',
        'description':
            'Maharashtra Fire Department makes Fire Safety NOC mandatory for all commercial establishments above 500 sq ft. Deadline: June 30, 2024.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 15))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 6, 30)),
        'states': ['Maharashtra'],
        'business_types': ['retail_shop', 'food_beverage', 'service_provider'],
        'impact': 'high',
        'source_url': 'https://mahafireservice.gov.in',
      },
      {
        'title': 'Trade License Renewal Extended',
        'description':
            'Delhi Municipal Corporation extends trade license renewal period by 3 months. New deadline: March 31, 2024. No late fees till then.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 3))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 3, 31)),
        'states': ['Delhi'],
        'business_types': ['retail_shop', 'food_beverage', 'service_provider'],
        'impact': 'medium',
        'source_url': 'https://mcdonline.gov.in',
      },
      {
        'title': 'Professional Tax Slab Revision',
        'description':
            'Tamil Nadu revises professional tax slabs. New maximum limit ₹2,500 per year. Applicable from April 2024.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 20))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 4, 1)),
        'states': ['Tamil Nadu'],
        'business_types': [
          'retail_shop',
          'food_beverage',
          'service_provider',
          'manufacturing'
        ],
        'impact': 'medium',
        'source_url': 'https://tnprofessionaltax.gov.in',
      },
      {
        'title': 'Labour Welfare Fund Increase',
        'description':
            'Gujarat increases Labour Welfare Fund contribution to ₹40 per employee per year. Employers must pay by March 31, 2024.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 7))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 3, 31)),
        'states': ['Gujarat'],
        'business_types': ['manufacturing', 'service_provider'],
        'impact': 'low',
        'source_url': 'https://labour.gujarat.gov.in',
      },
      {
        'title': 'Plastic Ban Enforcement',
        'description':
            'Maharashtra strengthens plastic ban enforcement. Single-use plastic items banned. Penalty: ₹25,000 for first offense.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 12))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 2, 15)),
        'states': ['Maharashtra'],
        'business_types': ['retail_shop', 'food_beverage'],
        'impact': 'high',
        'source_url': 'https://mpcb.gov.in',
      },
      {
        'title': 'Health License Fee Reduced',
        'description':
            'Bangalore Municipal Corporation reduces health trade license renewal fee by 20%. New fee: ₹400 per year.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 25))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'states': ['Karnataka'],
        'business_types': ['food_beverage'],
        'impact': 'low',
        'source_url': 'https://bbmp.gov.in',
      },
      {
        'title': 'Mandatory License Display',
        'description':
            'All India - All businesses must display license numbers prominently at entrance. Non-compliance penalty: ₹5,000.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 30))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 5, 1)),
        'states': ['All India'],
        'business_types': [
          'retail_shop',
          'food_beverage',
          'service_provider',
          'manufacturing'
        ],
        'impact': 'medium',
        'source_url': 'https://msme.gov.in',
      },
      {
        'title': 'EPF Contribution Unchanged',
        'description':
            'EPFO announces no change in EPF contribution rate. Remains at 12% for employees and employers. Effective FY 2024-25.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 8))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 4, 1)),
        'states': ['All India'],
        'business_types': [
          'retail_shop',
          'food_beverage',
          'service_provider',
          'manufacturing'
        ],
        'impact': 'low',
        'source_url': 'https://www.epfindia.gov.in',
      },
      {
        'title': 'Food Safety Training Mandatory',
        'description':
            'FSSAI makes food safety training mandatory for all food handlers. Certificate must be obtained by June 2024. Training fee: ₹500.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 18))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 6, 30)),
        'states': ['All India'],
        'business_types': ['food_beverage'],
        'impact': 'high',
        'source_url': 'https://foscos.fssai.gov.in',
      },
      {
        'title': 'Minimum Wage Revision - UP',
        'description':
            'UP government revises minimum wages. Unskilled: ₹10,500/month, Skilled: ₹12,000/month. Effective from March 2024.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 14))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 3, 1)),
        'states': ['Uttar Pradesh'],
        'business_types': [
          'retail_shop',
          'food_beverage',
          'service_provider',
          'manufacturing'
        ],
        'impact': 'high',
        'source_url': 'https://uplabour.gov.in',
      },
      {
        'title': 'Digital Payment Incentive',
        'description':
            'Government extends digital payment incentive for small businesses. 1% cashback on UPI transactions above ₹100. Valid till Dec 2024.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 4))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 12, 31)),
        'states': ['All India'],
        'business_types': ['retail_shop', 'food_beverage', 'service_provider'],
        'impact': 'low',
        'source_url': 'https://digitalindia.gov.in',
      },
      {
        'title': 'Environmental Clearance Required',
        'description':
            'New environmental clearance norms for manufacturing units. All units must obtain NOC from Pollution Control Board. Deadline: May 2024.',
        'published_date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 22))),
        'effective_date': Timestamp.fromDate(DateTime(2024, 5, 31)),
        'states': ['All India'],
        'business_types': ['manufacturing'],
        'impact': 'high',
        'source_url': 'https://cpcb.nic.in',
      },
    ];

    for (var update in lawUpdates) {
      await _firestore.collection('law_updates').add(update);
      setState(() {
        _progress++;
        _status = 'Seeded law update: ${update['title']}';
      });
    }
  }

  Future<void> _seedPenaltyReference() async {
    setState(() => _status = 'Seeding penalty reference...');

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
        'penalty': '₹5,000 fine plus 2% interest per month on dues',
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
      {
        'violation': 'GST Non-filing or Late Filing',
        'penalty': '₹10,000 or 10% of tax due (whichever is higher)',
        'law_reference': 'GST Act 2017, Section 47',
      },
      {
        'violation': 'Environmental Violations',
        'penalty': '₹1,00,000 fine and possible imprisonment',
        'law_reference': 'Environment Protection Act 1986, Section 15',
      },
      {
        'violation': 'Non-display of License Numbers',
        'penalty': '₹5,000 fine for first offense, ₹10,000 for repeat',
        'law_reference': 'MSME Act, Section 18',
      },
      {
        'violation': 'Violation of Plastic Ban',
        'penalty': '₹25,000 fine and confiscation of plastic items',
        'law_reference': 'Plastic Waste Management Rules 2016',
      },
      {
        'violation': 'Non-payment of Minimum Wages',
        'penalty': '₹50,000 fine and compensation to employees',
        'law_reference': 'Minimum Wages Act 1948, Section 22',
      },
    ];

    for (var penalty in penalties) {
      await _firestore.collection('penalty_reference').add(penalty);
      setState(() {
        _progress++;
        _status = 'Seeded penalty: ${penalty['violation']}';
      });
    }
  }

  Future<void> _seedLegalResources() async {
    setState(() => _status = 'Seeding legal resources...');

    // Legal Rights
    await _firestore.collection('legal_resources').doc('legal_rights').set({
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

    setState(() {
      _progress++;
      _status = 'Seeded legal rights';
    });

    // Inspection Checklist
    await _firestore
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
            'GST registration certificate',
            'Professional tax enrollment',
          ],
        },
        {
          'name': 'Hygiene & Safety',
          'items': [
            'Clean and sanitized premises',
            'Proper waste disposal system',
            'Fire extinguishers in working condition',
            'First aid kit available',
            'Adequate lighting and ventilation',
            'Pest control records',
          ],
        },
        {
          'name': 'Employee Records',
          'items': [
            'Employee attendance register',
            'Salary payment records',
            'EPF and ESI compliance documents',
            'Leave records',
            'Appointment letters',
          ],
        },
        {
          'name': 'Food Safety (if applicable)',
          'items': [
            'Food handler medical certificates',
            'Temperature logs for refrigeration',
            'Supplier invoices and bills',
            'Water quality test reports',
            'Cleaning and sanitization logs',
          ],
        },
        {
          'name': 'Display Requirements',
          'items': [
            'License numbers displayed at entrance',
            'Price list displayed prominently',
            'No smoking signage',
            'Emergency exit signs',
            'Business hours displayed',
          ],
        },
      ],
    });

    setState(() {
      _progress++;
      _status = 'Seeded inspection checklist';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Data Seeder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seed Firestore Data',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will populate your Firestore database with:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text('• 15 law updates'),
            const Text('• 10 penalty references'),
            const Text('• Legal rights and inspection checklist'),
            const SizedBox(height: 32),
            if (_isSeeding) ...[
              LinearProgressIndicator(
                value: _total > 0 ? _progress / _total : 0,
              ),
              const SizedBox(height: 16),
              Text(
                '$_progress / $_total items',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              _status,
              style: TextStyle(
                color: _status.startsWith('✅')
                    ? Colors.green
                    : _status.startsWith('❌')
                        ? Colors.red
                        : Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSeeding ? null : _seedAllData,
                child: _isSeeding
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Seeding...'),
                        ],
                      )
                    : const Text('Seed Data Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
