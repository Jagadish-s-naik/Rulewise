import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageDiagnosticScreen extends StatefulWidget {
  const StorageDiagnosticScreen({super.key});

  @override
  State<StorageDiagnosticScreen> createState() =>
      _StorageDiagnosticScreenState();
}

class _StorageDiagnosticScreenState extends State<StorageDiagnosticScreen> {
  final List<String> _logs = [];
  bool _isRunning = false;

  void _log(String message) {
    setState(() {
      _logs.add(
          '${DateTime.now().toIso8601String().substring(11, 19)} $message');
    });
    debugPrint('[StorageDiag] $message');
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _logs.clear();
      _isRunning = true;
    });

    try {
      _log('🚀 Starting Diagnostic...');

      // 1. Check Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User NOT authenticated');
      }
      _log('✅ Auth OK: ${user.uid}');

      // 2. Check Bucket
      final storage = FirebaseStorage.instance;
      _log('ℹ️ Bucket: ${storage.bucket}');

      // 3. Prepare Test Data
      final data = Uint8List.fromList('Hello World Diagnostic'.codeUnits);
      final fileName = 'diag_${DateTime.now().millisecondsSinceEpoch}.txt';
      final ref = storage.ref().child('users/${user.uid}/test/$fileName');

      _log('📂 Target: ${ref.fullPath}');

      // 4. Upload
      _log('⏳ Uploading ${data.length} bytes...');
      final task =
          ref.putData(data, SettableMetadata(contentType: 'text/plain'));

      final snapshot = await task;
      _log('✅ Upload Finished. State: ${snapshot.state}');
      _log('📊 Bytes Transferred: ${snapshot.bytesTransferred}');

      // 5. Get URL
      _log('⏳ Getting Download URL...');
      final url = await ref.getDownloadURL();
      _log('✅ URL Retrieved: $url');

      _log('🎉 DIAGNOSTIC SUCCESS! Storage is working.');
    } catch (e) {
      _log('❌ ERROR: $e');
      if (e is FirebaseException) {
        _log('Code: ${e.code}');
        _log('Message: ${e.message}');
      }
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storage Diagnostic')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runDiagnostic,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Test'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isError = log.contains('❌') || log.contains('ERROR');
                final isSuccess = log.contains('✅') || log.contains('🎉');
                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                   color: isError
                       ? Colors.red.withValues(alpha: 0.1)
                       : isSuccess
                           ? Colors.green.withValues(alpha: 0.1)
                           : null,
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isError ? Colors.red : Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
