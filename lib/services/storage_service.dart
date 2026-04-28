import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  // Explicitly using the bucket from google-services.json / firebase_options.dart
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://rulewise-4ec59.firebasestorage.app',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads a file to the user's secure folder in Firebase Storage
  /// Returns the download URL
  Future<String?> uploadDocument({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File does not exist at local path: $filePath');
      }

      // Read bytes to safely handle Scoped Storage on Android
      // This bypasses 'putFile' permission issues by reading into memory first
      final bytes = await file.readAsBytes();
      debugPrint('📂 Reading file: ${bytes.lengthInBytes} bytes');

      // Create a secure path: users/{userId}/documents/{timestamp}_{fileName}
      final ref = _storage
          .ref()
          .child('users')
          .child(user.uid)
          .child('documents')
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      // Upload raw bytes with metadata
      final metadata = SettableMetadata(
        contentType: 'application/octet-stream',
        customMetadata: {'originalName': fileName},
      );

      final uploadTask = ref.putData(bytes, metadata);

      // Wait for completion
      final snapshot = await uploadTask;
      debugPrint('✅ Upload success. Size: ${snapshot.totalBytes}');

      // Get URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('🔗 Cloud URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file to Cloud: $e');
      rethrow;
    }
  }

  /// Deletes a file from storage
  Future<void> deleteDocument(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
}
