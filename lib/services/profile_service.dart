import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Profile service for managing user profile and completion status
class ProfileService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;

  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  /// Get current profile as UserProfile model
  UserProfile? get currentProfile {
    if (_userProfile == null) return null;

    return UserProfile(
      businessName: _userProfile!['business_name'] ?? '',
      city: _userProfile!['location']?['city'] ?? '',
      state: _userProfile!['location']?['state'] ?? '',
      businessType: _userProfile!['business_type'] ?? '',
    );
  }

  /// Load user profile from Firestore
  Future<void> loadUserProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _userProfile = doc.data();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if profile is complete
  bool isProfileComplete() {
    if (_userProfile == null) return false;

    return _userProfile!['aadhaar_verified'] == true &&
        _userProfile!['pan_verified'] == true &&
        (_userProfile!['business_name'] ?? '').toString().isNotEmpty &&
        (_userProfile!['business_type'] ?? '').toString().isNotEmpty &&
        (_userProfile!['location']?['state'] ?? '').toString().isNotEmpty &&
        (_userProfile!['location']?['city'] ?? '').toString().isNotEmpty;
  }

  /// Get profile completion percentage
  double getCompletionPercentage() {
    if (_userProfile == null) return 0.0;

    int completed = 0;
    const int total = 6;

    if (_userProfile!['aadhaar_verified'] == true) completed++;
    if (_userProfile!['pan_verified'] == true) completed++;
    if ((_userProfile!['business_name'] ?? '').toString().isNotEmpty) {
      completed++;
    }
    if ((_userProfile!['business_type'] ?? '').toString().isNotEmpty) {
      completed++;
    }
    if ((_userProfile!['location']?['state'] ?? '').toString().isNotEmpty) {
      completed++;
    }
    if ((_userProfile!['location']?['city'] ?? '').toString().isNotEmpty) {
      completed++;
    }

    return (completed / total) * 100;
  }

  /// Get list of missing fields
  List<String> getMissingFields() {
    if (_userProfile == null) {
      return [
        'Aadhaar verification',
        'PAN verification',
        'Business name',
        'Business type',
        'State',
        'City',
      ];
    }

    final missing = <String>[];

    if (_userProfile!['aadhaar_verified'] != true) {
      missing.add('Aadhaar verification');
    }
    if (_userProfile!['pan_verified'] != true) {
      missing.add('PAN verification');
    }
    if ((_userProfile!['business_name'] ?? '').toString().isEmpty) {
      missing.add('Business name');
    }
    if ((_userProfile!['business_type'] ?? '').toString().isEmpty) {
      missing.add('Business type');
    }
    if ((_userProfile!['location']?['state'] ?? '').toString().isEmpty) {
      missing.add('State');
    }
    if ((_userProfile!['location']?['city'] ?? '').toString().isEmpty) {
      missing.add('City');
    }

    return missing;
  }

  /// Update Aadhaar verification status
  Future<void> updateAadhaarVerification(String aadhaar, bool verified) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'aadhaar': aadhaar,
        'aadhaar_verified': verified,
        'updated_at': FieldValue.serverTimestamp(),
      });

      _userProfile?['aadhaar'] = aadhaar;
      _userProfile?['aadhaar_verified'] = verified;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating Aadhaar: $e');
      rethrow;
    }
  }

  /// Update PAN verification status
  Future<void> updatePANVerification(String pan, bool verified) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'pan': pan,
        'pan_verified': verified,
        'updated_at': FieldValue.serverTimestamp(),
      });

      _userProfile?['pan'] = pan;
      _userProfile?['pan_verified'] = verified;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating PAN: $e');
      rethrow;
    }
  }

  /// Update business information
  Future<void> updateBusinessInfo({
    String? businessName,
    String? businessType,
    String? state,
    String? city,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (businessName != null) updates['business_name'] = businessName;
      if (businessType != null) updates['business_type'] = businessType;

      if (state != null || city != null) {
        updates['location'] = {
          'state': state ?? _userProfile?['location']?['state'] ?? '',
          'city': city ?? _userProfile?['location']?['city'] ?? '',
        };
      }

      await _firestore.collection('users').doc(userId).update(updates);

      // Update local profile
      if (businessName != null) _userProfile?['business_name'] = businessName;
      if (businessType != null) _userProfile?['business_type'] = businessType;
      if (state != null || city != null) {
        _userProfile?['location'] = {
          'state': state ?? _userProfile?['location']?['state'] ?? '',
          'city': city ?? _userProfile?['location']?['city'] ?? '',
        };
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating business info: $e');
      rethrow;
    }
  }
}

/// Simple user profile model
class UserProfile {
  final String businessName;
  final String city;
  final String state;
  final String businessType;

  UserProfile({
    required this.businessName,
    required this.city,
    required this.state,
    required this.businessType,
  });
}
