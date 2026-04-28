/// Compliance metrics for dashboard display
class ComplianceMetrics {
  final int totalRequired;
  final int active;
  final int expired;
  final int expiringSoon;
  final int notAcquired;
  final double complianceScore;

  ComplianceMetrics({
    required this.totalRequired,
    required this.active,
    required this.expired,
    required this.expiringSoon,
    required this.notAcquired,
    double? overrideScore,
  }) : complianceScore = overrideScore ??
            (totalRequired > 0 ? (active / totalRequired) * 100 : 0.0);

  /// Get compliance status message
  String get statusMessage {
    if (complianceScore >= 90) {
      return 'Excellent compliance!';
    } else if (complianceScore >= 70) {
      return 'Good compliance';
    } else if (complianceScore >= 50) {
      return 'Needs improvement';
    } else {
      return 'Critical - Action required';
    }
  }

  /// Get status color
  String get statusColor {
    if (complianceScore >= 90) return 'green';
    if (complianceScore >= 70) return 'blue';
    if (complianceScore >= 50) return 'orange';
    return 'red';
  }

  /// Check if user has critical compliance issues
  bool get hasCriticalIssues => expired > 0 || expiringSoon > 0;

  /// Get priority action message
  String? get priorityAction {
    if (expired > 0) {
      return '$expired license(s) expired - Renew immediately';
    } else if (expiringSoon > 0) {
      return '$expiringSoon license(s) expiring soon - Plan renewal';
    } else if (notAcquired > 0) {
      return '$notAcquired required license(s) missing - Apply now';
    }
    return null;
  }
}
