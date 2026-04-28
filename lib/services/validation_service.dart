import 'package:flutter/foundation.dart';

/// Validation service for Aadhaar, PAN, and other compliance validations
class ValidationService extends ChangeNotifier {
  /// Validate Aadhaar number using Verhoeff algorithm
  bool validateAadhaar(String aadhaar) {
    // Remove spaces and dashes
    final cleaned = aadhaar.replaceAll(RegExp(r'[\s-]'), '');

    // Check length
    if (cleaned.length != 12) return false;

    // Check if all digits
    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) return false;

    // Verhoeff algorithm check
    return _verhoeffCheck(cleaned);
  }

  /// Verhoeff algorithm implementation for Aadhaar validation
  bool _verhoeffCheck(String num) {
    // Multiplication table
    const d = [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
      [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
      [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
      [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
      [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
      [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
      [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
      [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
      [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
    ];

    // Permutation table
    const p = [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
      [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
      [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
      [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
      [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
      [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
      [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
    ];

    int c = 0;
    final reversedNum = num.split('').reversed.toList();

    for (int i = 0; i < reversedNum.length; i++) {
      c = d[c][p[(i % 8)][int.parse(reversedNum[i])]];
    }

    return c == 0;
  }

  /// Validate PAN number format
  bool validatePAN(String pan) {
    // PAN format: AAAAA9999A
    // 5 letters, 4 digits, 1 letter
    final regex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    return regex.hasMatch(pan.toUpperCase());
  }

  /// Get Aadhaar validation error message
  String? getAadhaarError(String aadhaar) {
    final cleaned = aadhaar.replaceAll(RegExp(r'[\s-]'), '');

    if (cleaned.isEmpty) {
      return 'Aadhaar number is required';
    }

    if (cleaned.length != 12) {
      return 'Aadhaar must be 12 digits';
    }

    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return 'Aadhaar must contain only digits';
    }

    if (!_verhoeffCheck(cleaned)) {
      return 'Invalid Aadhaar number';
    }

    return null;
  }

  /// Get PAN validation error message
  String? getPANError(String pan) {
    if (pan.isEmpty) {
      return 'PAN is required';
    }

    if (pan.length != 10) {
      return 'PAN must be 10 characters';
    }

    if (!validatePAN(pan)) {
      return 'Invalid PAN format (e.g., ABCDE1234F)';
    }

    return null;
  }

  /// Format Aadhaar for display (XXXX XXXX XXXX)
  String formatAadhaar(String aadhaar) {
    final cleaned = aadhaar.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length != 12) return aadhaar;

    return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 8)} ${cleaned.substring(8, 12)}';
  }

  /// Mask Aadhaar for privacy (XXXX XXXX 1234)
  String maskAadhaar(String aadhaar) {
    final cleaned = aadhaar.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length != 12) return aadhaar;

    return 'XXXX XXXX ${cleaned.substring(8, 12)}';
  }

  /// Validate business name
  String? validateBusinessName(String name) {
    if (name.trim().isEmpty) {
      return 'Business name is required';
    }

    if (name.trim().length < 3) {
      return 'Business name must be at least 3 characters';
    }

    return null;
  }

  /// Validate phone number (Indian format)
  String? validatePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');

    if (cleaned.isEmpty) {
      return 'Phone number is required';
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Invalid Indian phone number';
    }

    return null;
  }

  /// Validate email
  String? validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Email is required';
    }

    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!regex.hasMatch(email)) {
      return 'Invalid email address';
    }

    return null;
  }
}
