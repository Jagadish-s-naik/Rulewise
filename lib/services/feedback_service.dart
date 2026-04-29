import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitFeedback({
    required String type,
    required String message,
    required double rating,
  }) async {
    final user = _auth.currentUser;
    final userId = user?.uid ?? 'anonymous';

    await _firestore.collection('feedback').add({
      'userId': userId,
      'type': type,
      'message': message,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
      'appVersion': '1.0.0', // Could be dynamic from package_info
      'status': 'new',
    });
  }
}
