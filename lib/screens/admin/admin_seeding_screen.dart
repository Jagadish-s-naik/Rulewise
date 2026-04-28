import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_seeding_service.dart';

class AdminSeedingScreen extends StatefulWidget {
  const AdminSeedingScreen({super.key});

  @override
  State<AdminSeedingScreen> createState() => _AdminSeedingScreenState();
}

class _AdminSeedingScreenState extends State<AdminSeedingScreen> {
  final _seedingService = FirestoreSeedingService();
  bool _isSeeding = false;
  String _status = 'Ready to seed Firestore database';

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
      _status = 'Seeding in progress...';
    });

    try {
      await _seedingService.seedAllData();
      setState(() {
        _status = '✅ Seeding completed successfully!';
        _isSeeding = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database seeded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ Seeding failed: $e';
        _isSeeding = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seeding failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seedUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to seed user data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSeeding = true;
      _status = 'Creating test licenses for you...';
    });

    try {
      await _seedingService.seedUserScenario(user.uid);
      setState(() {
        _status = '✅ Test user data created!';
        _isSeeding = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User Profile & Licenses seeded! Go to Dashboard.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ User seeding failed: $e';
        _isSeeding = false;
      });
    }
  }

  Future<void> _clearDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Database?'),
        content: const Text('This will delete all compliance data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSeeding = true;
      _status = 'Clearing database...';
    });

    try {
      await _seedingService.clearAllData();
      setState(() {
        _status = '✅ Database cleared!';
        _isSeeding = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Clear failed: $e';
        _isSeeding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Database Seeding'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 24),
            const Text(
              'Firestore Database Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Populate the database with government compliance data',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_status),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isSeeding)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: _seedDatabase,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Seed Master DB (First time)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _seedUserData,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Seed Test User Data (For Me)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _clearDatabase,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear Database'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  foregroundColor: Colors.red,
                ),
              ),
            ],
            const Spacer(),
            const Text(
              'ℹ️ This will populate Firestore with:\n'
              '• Karnataka (Bengaluru, Mysuru, Mangaluru)\n'
              '• Maharashtra (Mumbai, Pune, Nagpur)\n'
              '• Delhi (New Delhi, South Delhi)\n'
              '• 4 business types per city\n'
              '• 3-5 licenses per business type',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
