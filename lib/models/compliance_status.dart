import 'package:cloud_firestore/cloud_firestore.dart';
import 'license_model.dart';

class ComplianceStatus {
  final LicenseModel license;
  final Map<String, dynamic>? userLicenseData;

  ComplianceStatus({
    required this.license,
    this.userLicenseData,
  });

  String get userStatus {
    if (userLicenseData == null) {
      return 'not_acquired';
    }
    return userLicenseData!['status'] ?? 'not_acquired';
  }

  DateTime? get expiryDate {
    if (userLicenseData == null) {
      return null;
    }
    final timestamp = userLicenseData!['expiry_date'];
    if (timestamp == null) {
      return null;
    }
    return (timestamp as Timestamp).toDate();
  }

  int? get daysToExpiry {
    if (expiryDate == null) {
      return null;
    }
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  bool get isExpired {
    if (daysToExpiry == null) {
      return false;
    }
    return daysToExpiry! < 0;
  }

  bool get isExpiringSoon {
    if (daysToExpiry == null) {
      return false;
    }
    return daysToExpiry! < 60 && daysToExpiry! >= 0;
  }

  String get statusBadge {
    if (isExpired) {
      return 'Expired';
    }
    if (isExpiringSoon) {
      return 'Due Soon';
    }
    if (userStatus == 'active') {
      return 'Active';
    }
    if (userStatus == 'pending') {
      return 'Pending';
    }
    return 'Missing';
  }
}
