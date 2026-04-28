import 'package:cloud_firestore/cloud_firestore.dart';

/// User's acquired license with verification and tracking
class UserLicenseModel {
  final String id;
  final String licenseId; // Reference to compliance_data license
  final String licenseName; // Cached for display
  final String licenseNumber;
  final String issuingAuthority;
  final DateTime issueDate;
  final DateTime expiryDate;
  final LicenseStatus status;
  final String? documentUrl; // Firebase Storage URL
  final bool userVerified;
  final bool renewalAlertsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserLicenseModel({
    required this.id,
    required this.licenseId,
    required this.licenseName,
    required this.licenseNumber,
    required this.issuingAuthority,
    required this.issueDate,
    required this.expiryDate,
    required this.status,
    this.documentUrl,
    required this.userVerified,
    required this.renewalAlertsEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate days until expiry
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  /// Check if license is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// Check if license is expiring soon (within 30 days)
  bool get isExpiringSoon => daysUntilExpiry <= 30 && daysUntilExpiry > 0;

  /// Get current status based on expiry date
  LicenseStatus get currentStatus {
    if (isExpired) return LicenseStatus.expired;
    if (isExpiringSoon) return LicenseStatus.expiringSoon;
    return LicenseStatus.active;
  }

  factory UserLicenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // Safe cast

    // Helper to safe parse Date
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserLicenseModel(
      id: doc.id,
      licenseId: data['license_id']?.toString() ?? '',
      licenseName: data['license_name']?.toString() ?? 'Unknown License',
      licenseNumber: data['license_number']?.toString() ?? '',
      issuingAuthority: data['issuing_authority']?.toString() ?? '',
      issueDate: parseDate(data['issue_date']),
      expiryDate: parseDate(data['expiry_date']),
      status: LicenseStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            (data['status']?.toString() ?? 'active'),
        orElse: () => LicenseStatus.active,
      ),
      documentUrl: data['document_url']?.toString(),
      userVerified: data['user_verified'] ?? false,
      renewalAlertsEnabled: data['renewal_alerts_enabled'] ?? true,
      createdAt: parseDate(data['created_at']),
      updatedAt: parseDate(data['updated_at']),
    );
  }

  /// Alternative constructor from ID and data map (for emergency cache)
  factory UserLicenseModel.fromMap(String id, Map<String, dynamic> data) {
    return UserLicenseModel(
      id: id,
      licenseId: data['license_id'] ?? '',
      licenseName: data['license_name'] ?? '',
      licenseNumber: data['license_number'] ?? '',
      issuingAuthority: data['issuing_authority'] ?? '',
      issueDate: (data['issue_date'] as Timestamp).toDate(),
      expiryDate: (data['expiry_date'] as Timestamp).toDate(),
      status: LicenseStatus.values.firstWhere(
        (e) => e.toString() == 'LicenseStatus.${data['status']}',
        orElse: () => LicenseStatus.active,
      ),
      documentUrl: data['document_url'],
      userVerified: data['user_verified'] ?? false,
      renewalAlertsEnabled: data['renewal_alerts_enabled'] ?? true,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'license_id': licenseId,
      'license_name': licenseName,
      'license_number': licenseNumber,
      'issuing_authority': issuingAuthority,
      'issue_date': Timestamp.fromDate(issueDate),
      'expiry_date': Timestamp.fromDate(expiryDate),
      'status': status.toString().split('.').last,
      'document_url': documentUrl,
      'user_verified': userVerified,
      'renewal_alerts_enabled': renewalAlertsEnabled,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Alias for toFirestore (for compatibility)
  Map<String, dynamic> toMap() => toFirestore();

  /// Create a copy with updated fields
  UserLicenseModel copyWith({
    String? licenseNumber,
    String? issuingAuthority,
    DateTime? issueDate,
    DateTime? expiryDate,
    LicenseStatus? status,
    String? documentUrl,
    bool? userVerified,
    bool? renewalAlertsEnabled,
  }) {
    return UserLicenseModel(
      id: id,
      licenseId: licenseId,
      licenseName: licenseName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      documentUrl: documentUrl ?? this.documentUrl,
      userVerified: userVerified ?? this.userVerified,
      renewalAlertsEnabled: renewalAlertsEnabled ?? this.renewalAlertsEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// License status enum
enum LicenseStatus {
  active,
  expired,
  expiringSoon,
  renewalInProgress,
}

/// Extension for status display
extension LicenseStatusExtension on LicenseStatus {
  String get displayName {
    switch (this) {
      case LicenseStatus.active:
        return 'Active';
      case LicenseStatus.expired:
        return 'Expired';
      case LicenseStatus.expiringSoon:
        return 'Expiring Soon';
      case LicenseStatus.renewalInProgress:
        return 'Renewal in Progress';
    }
  }

  String get badgeColor {
    switch (this) {
      case LicenseStatus.active:
        return 'green';
      case LicenseStatus.expired:
        return 'red';
      case LicenseStatus.expiringSoon:
        return 'orange';
      case LicenseStatus.renewalInProgress:
        return 'blue';
    }
  }
}
