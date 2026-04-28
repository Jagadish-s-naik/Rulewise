import 'package:flutter/material.dart';
import '../../services/emergency_data_seeder.dart';

class DataSeedingScreen extends StatefulWidget {
  const DataSeedingScreen({super.key});

  @override
  State<DataSeedingScreen> createState() => _DataSeedingScreenState();
}

class _DataSeedingScreenState extends State<DataSeedingScreen> {
  final EmergencyDataSeeder _seeder = EmergencyDataSeeder();
  bool _isSeeding = false;
  String _status = '';

  Future<void> _seedAllData() async {
    setState(() {
      _isSeeding = true;
      _status = 'Seeding data...';
    });

    try {
      await _seeder.seedAll();
      setState(() {
        _status =
            '✅ All data seeded successfully!\n\nYou can now:\n- View law updates in Law Change Radar\n- See legal rights in Emergency Mode\n- Check inspection checklist\n- View penalty references';
        _isSeeding = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isSeeding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Test Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_upload,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Seed Test Data',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will add:\n• 5 Law Updates\n• Legal Rights\n• Inspection Checklist\n• Penalty References',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSeeding ? null : _seedAllData,
                child: _isSeeding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Seed Data Now'),
              ),
            ),
            const SizedBox(height: 24),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('✅')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _status.contains('✅') ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.contains('✅')
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
