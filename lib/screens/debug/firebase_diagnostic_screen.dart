import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';

/// Diagnostic screen to check Firebase and subscription status
/// Add this to your app to debug subscription issues
class FirebaseDiagnosticScreen extends StatefulWidget {
  const FirebaseDiagnosticScreen({super.key});

  @override
  State<FirebaseDiagnosticScreen> createState() =>
      _FirebaseDiagnosticScreenState();
}

class _FirebaseDiagnosticScreenState extends State<FirebaseDiagnosticScreen> {
  Map<String, dynamic>? _firestoreData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFirestoreData();
  }

  Future<void> _loadFirestoreData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'User document does not exist in Firestore';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _firestoreData = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final subscriptionService = context.watch<SubscriptionService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Diagnostic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFirestoreData,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Authentication Status
          _buildSection(
            'Authentication Status',
            [
              _buildRow(
                  'Logged In', authService.isAuthenticated ? '✅ Yes' : '❌ No'),
              _buildRow('User Email', authService.currentUser?.email ?? 'N/A'),
              _buildRow('User ID', authService.currentUser?.uid ?? 'N/A'),
            ],
          ),

          const SizedBox(height: 24),

          // Subscription Service Status
          _buildSection(
            'Subscription Service',
            [
              _buildRow(
                  'Testing Mode',
                  SubscriptionService.testingMode
                      ? '🧪 ENABLED'
                      : '✅ Disabled'),
              _buildRow('Current Tier', subscriptionService.currentTier.name),
              _buildRow('AI Queries Used',
                  '${subscriptionService.aiQueriesUsedThisWeek}'),
              _buildRow('AI Queries Remaining',
                  '${subscriptionService.aiQueriesRemaining}'),
              _buildRow('Trial Active',
                  subscriptionService.isTrialActive ? '✅ Yes' : '❌ No'),
            ],
          ),

          const SizedBox(height: 24),

          // Firestore Data
          _buildSection(
            'Firestore Data',
            _isLoading
                ? [const Center(child: CircularProgressIndicator())]
                : _error != null
                    ? [
                        Text('❌ Error: $_error',
                            style: const TextStyle(color: Colors.red))
                      ]
                    : _firestoreData == null
                        ? [const Text('No data loaded')]
                        : [
                            _buildRow(
                                'subscription_tier',
                                _firestoreData!['subscription_tier'] ??
                                    'NOT SET'),
                            _buildRow('is_premium',
                                '${_firestoreData!['is_premium'] ?? false}'),
                            _buildRow('ai_queries_this_week',
                                '${_firestoreData!['ai_queries_this_week'] ?? 0}'),
                            _buildRow('has_used_trial',
                                '${_firestoreData!['has_used_trial'] ?? false}'),
                            _buildRow('Document Exists', '✅ Yes'),
                          ],
          ),

          const SizedBox(height: 24),

          // Test Actions
          _buildSection(
            'Test Actions',
            [
              ElevatedButton(
                onPressed: () async {
                  try {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ No user logged in')),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .update({
                      'subscription_tier': 'protection',
                      'is_premium': true,
                      'subscription_updated_at': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('✅ Manually set tier to Protection')),
                    );

                    await _loadFirestoreData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Error: $e')),
                    );
                  }
                },
                child: const Text('🧪 Test: Set Protection Tier'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ No user logged in')),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .update({
                      'subscription_tier': 'businessShield',
                      'is_premium': true,
                      'subscription_updated_at': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('✅ Manually set tier to BusinessShield')),
                    );

                    await _loadFirestoreData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Error: $e')),
                    );
                  }
                },
                child: const Text('🧪 Test: Set BusinessShield Tier'),
              ),
              const SizedBox(height: 8),
               ElevatedButton(
                 onPressed: () async {
                   // Force reload subscription
                   await context.read<SubscriptionService>().init();
                   await _loadFirestoreData();
                   if (!mounted) return;
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('🔄 Reloaded subscription')),
                   );
                 },
                 child: const Text('🔄 Reload Subscription'),
               ),
            ],
          ),

          const SizedBox(height: 24),

          // Recommendations
          _buildSection(
            'Recommendations',
            [
              if (!authService.isAuthenticated)
                const Text(
                  '❌ NOT LOGGED IN: You must be logged in for subscriptions to work.',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              if (authService.isAuthenticated && _firestoreData == null)
                const Text(
                  '❌ NO FIRESTORE DOCUMENT: Create user document in Firestore.',
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              if (SubscriptionService.testingMode)
                const Text(
                  '🧪 TESTING MODE ENABLED: Subscription upgrades won\'t persist. Set testingMode = false in subscription_service.dart',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              if (authService.isAuthenticated &&
                  _firestoreData != null &&
                  !SubscriptionService.testingMode)
                const Text(
                  '✅ ALL GOOD: Firebase is configured correctly. Subscription upgrades should work.',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
