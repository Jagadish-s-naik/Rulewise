import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Quick test screen to seed sample data for testing the dashboard
class TestDataSeederScreen extends StatefulWidget {
  const TestDataSeederScreen({super.key});

  @override
  State<TestDataSeederScreen> createState() => _TestDataSeederScreenState();
}

class _TestDataSeederScreenState extends State<TestDataSeederScreen> {
  bool _isSeeding = false;
  String _status = '';

  Future<void> _seedTestData() async {
    setState(() {
      _isSeeding = true;
      _status = 'Starting...';
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final firestore = FirebaseFirestore.instance;

      // 1. Update user profile
      setState(() => _status = 'Updating user profile...');
      await firestore.collection('users').doc(userId).set({
        'business_name': 'Test Retail Shop',
        'business_type': 'retail_shop',
        'location': {
          'state': 'karnataka',
          'city': 'bengaluru',
        },
        'aadhaar': '123456789012',
        'aadhaar_verified': true,
        'pan': 'ABCDE1234F',
        'pan_verified': true,
        'profile_completed': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Add sample licenses to compliance_data
      setState(() => _status = 'Adding sample licenses...');

      final licensesRef = firestore
          .collection('compliance_data')
          .doc('karnataka')
          .collection('cities')
          .doc('bengaluru')
          .collection('business_types')
          .doc('retail_shop')
          .collection('licenses');

      // Trade License
      await licensesRef.doc('trade_license').set({
        'name': 'Trade License',
        'official_name': 'Shop and Establishment License',
        'department': 'BBMP (Bruhat Bengaluru Mahanagara Palike)',
        'description': 'Mandatory license for all retail shops in Bengaluru',
        'fee': 500,
        'renewal_cycle': 'Yearly',
        'penalty_per_month': 100,
        'grace_period_days': 30,
        'application_url': 'https://bbmp.gov.in/trade-license',
        'helpline': '080-22660000',
        'required_documents': [
          'Business registration proof',
          'Owner ID proof',
          'Property documents',
          'NOC from owner',
        ],
        'processing_time': '15-30 days',
        'is_mandatory': true,
        'source_url': 'https://bbmp.gov.in',
        'last_verified': FieldValue.serverTimestamp(),
        'verification_notes': 'Verified from BBMP official website',
        'why_required': 'Required by Karnataka Shops and Establishments Act',
      });

      // GST Registration
      await licensesRef.doc('gst').set({
        'name': 'GST Registration',
        'official_name': 'Goods and Services Tax Registration',
        'department': 'GST Department, Government of India',
        'description': 'Mandatory for businesses with turnover > ₹40 lakhs',
        'fee': 0,
        'renewal_cycle': 'Yearly',
        'penalty_per_month': 200,
        'grace_period_days': 15,
        'application_url': 'https://www.gst.gov.in',
        'helpline': '1800-103-4786',
        'required_documents': [
          'PAN card',
          'Aadhaar card',
          'Business registration',
          'Bank account details',
        ],
        'processing_time': '7-15 days',
        'is_mandatory': true,
        'source_url': 'https://www.gst.gov.in',
        'last_verified': FieldValue.serverTimestamp(),
        'verification_notes': 'Verified from GST portal',
        'why_required': 'Required by GST Act 2017',
      });

      // Fire Safety NOC
      await licensesRef.doc('fire_noc').set({
        'name': 'Fire Safety NOC',
        'official_name': 'Fire and Emergency Services NOC',
        'department': 'Karnataka Fire and Emergency Services',
        'description': 'Required for shops with area > 500 sq ft',
        'fee': 1000,
        'renewal_cycle': 'Yearly',
        'penalty_per_month': 150,
        'grace_period_days': 30,
        'application_url': 'https://ksfes.karnataka.gov.in',
        'helpline': '080-22868444',
        'required_documents': [
          'Building plan',
          'Fire safety equipment list',
          'Inspection report',
        ],
        'processing_time': '30-45 days',
        'is_mandatory': false,
        'source_url': 'https://ksfes.karnataka.gov.in',
        'last_verified': FieldValue.serverTimestamp(),
        'verification_notes': 'Verified from Fire Department website',
        'why_required': 'Required for public safety compliance',
      });

      // 3. Add one user license (active)
      setState(() => _status = 'Adding user licenses...');
      await firestore
          .collection('users')
          .doc(userId)
          .collection('user_licenses')
          .add({
        'license_id': 'trade_license',
        'license_name': 'Trade License',
        'license_number': 'TL/2024/12345',
        'issuing_authority': 'BBMP',
        'issue_date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'expiry_date': Timestamp.fromDate(DateTime(2025, 1, 1)),
        'status': 'active',
        'user_verified': true,
        'renewal_alerts_enabled': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSeeding = false;
        _status =
            '✅ Test data seeded successfully!\n\nYou now have:\n- 3 applicable licenses\n- 1 active license\n- Complete profile\n\nGo back and check the dashboard!';
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: const Text(
              'Test data has been seeded.\n\nGo back to the dashboard to see your compliance status!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to dashboard
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSeeding = false;
        _status = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Data Seeder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.science,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Seed Test Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will create sample licenses and user data for testing the dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (_status.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSeeding ? null : _seedTestData,
                child: _isSeeding
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Seed Test Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
