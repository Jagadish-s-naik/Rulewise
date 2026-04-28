import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Quick test widget to check Firebase status
/// Add this to your app temporarily to debug
class QuickFirebaseTest extends StatelessWidget {
  const QuickFirebaseTest({super.key});

  Future<Map<String, dynamic>> _runTest() async {
    final results = <String, dynamic>{};

    try {
      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      results['authenticated'] = user != null;
      results['email'] = user?.email ?? 'NOT LOGGED IN';
      results['uid'] = user?.uid ?? 'N/A';

      if (user != null) {
        // Check Firestore document
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          results['document_exists'] = doc.exists;

          if (doc.exists) {
            final data = doc.data();
            results['subscription_tier'] =
                data?['subscription_tier'] ?? 'MISSING';
            results['is_premium'] = data?['is_premium'] ?? false;
            results['has_all_fields'] =
                data?.containsKey('subscription_tier') ?? false;
          }
        } catch (e) {
          results['firestore_error'] = e.toString();
        }
      }
    } catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Quick Test')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _runTest(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildResult('Authenticated', results['authenticated'] == true),
              _buildResult('Email', results['email']),
              _buildResult('UID', results['uid']),
              if (results.containsKey('document_exists'))
                _buildResult(
                  'Firestore Doc Exists',
                  results['document_exists'],
                ),
              if (results.containsKey('subscription_tier'))
                _buildResult('Subscription Tier', results['subscription_tier']),
              if (results.containsKey('is_premium'))
                _buildResult('Is Premium', results['is_premium']),
              if (results.containsKey('has_all_fields'))
                _buildResult('Has All Fields', results['has_all_fields']),
              if (results.containsKey('firestore_error'))
                _buildResult(
                  'Firestore Error',
                  results['firestore_error'],
                  isError: true,
                ),
              if (results.containsKey('error'))
                _buildResult('Error', results['error'], isError: true),

              const SizedBox(height: 24),

              // Diagnosis
              Card(
                color: _getDiagnosisColor(results),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _getDiagnosis(results),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResult(String label, dynamic value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                color: isError ? Colors.red : null,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDiagnosisColor(Map<String, dynamic> results) {
    if (results['authenticated'] != true) return Colors.red;
    if (results['document_exists'] != true) return Colors.orange;
    if (results['subscription_tier'] == 'MISSING') return Colors.orange;
    return Colors.green;
  }

  String _getDiagnosis(Map<String, dynamic> results) {
    if (results['authenticated'] != true) {
      return '❌ NOT LOGGED IN\n\nYou must log in first for subscriptions to work.';
    }

    if (results['document_exists'] != true) {
      return '❌ NO FIRESTORE DOCUMENT\n\nUser document doesn\'t exist. This happens if you signed up before the fix was applied.';
    }

    if (results['subscription_tier'] == 'MISSING') {
      return '⚠️ MISSING SUBSCRIPTION FIELD\n\nDocument exists but subscription_tier field is missing. Sign up with a new account or manually add the field.';
    }

    return '✅ ALL GOOD!\n\nFirebase is configured correctly. Subscription upgrades should work.';
  }
}
