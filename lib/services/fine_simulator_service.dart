import '../models/license_model.dart';
import '../models/user_license_model.dart';

class FineSimulatorService {
  /// Calculate potential fine for a missing or expired license
  FineCalculation calculateFine({
    required LicenseModel license,
    UserLicenseModel? userLicense,
  }) {
    if (userLicense == null) {
      // License is missing
      return _calculateMissingLicenseFine(license);
    } else if (userLicense.isExpired) {
      // License is expired
      final daysExpired =
          DateTime.now().difference(userLicense.expiryDate).inDays;
      return _calculateExpiredLicenseFine(license, daysExpired);
    } else {
      // License is active
      return FineCalculation(
        fineAmount: 0,
        legalConsequence: 'License is active. No penalty.',
        riskProbability: 0.0,
        recommendation: 'Keep monitoring expiry date.',
      );
    }
  }

  /// Calculate fine for missing license
  FineCalculation _calculateMissingLicenseFine(LicenseModel license) {
    // Base fine for operating without license
    final baseFine = license.fee * 2; // Typically 2x the license fee
    final penaltyPerMonth = license.penaltyPerMonth;

    // Assume 3 months of operation without license (average)
    final estimatedFine = baseFine + (penaltyPerMonth * 3);

    String consequence;
    double riskProbability;

    if (license.isMandatory) {
      consequence = '''
SEVERE CONSEQUENCES:
• Business closure notice
• Court summons possible
• Criminal liability under relevant act
• Cannot operate legally until obtained
• May face inspection raid
''';
      riskProbability = 0.85; // High probability for mandatory licenses
    } else {
      consequence = '''
MODERATE CONSEQUENCES:
• Warning notice from department
• Penalty payment required
• Compliance notice issued
• May affect future license applications
''';
      riskProbability = 0.45; // Moderate probability
    }

    return FineCalculation(
      fineAmount: estimatedFine.toDouble(),
      legalConsequence: consequence,
      riskProbability: riskProbability,
      recommendation: license.isMandatory
          ? 'URGENT: Apply immediately to avoid legal action'
          : 'Recommended: Apply within 30 days',
    );
  }

  /// Calculate fine for expired license
  FineCalculation _calculateExpiredLicenseFine(
    LicenseModel license,
    int daysExpired,
  ) {
    final monthsExpired = (daysExpired / 30).ceil();
    final penaltyAmount = license.penaltyPerMonth * monthsExpired;

    // Check if within grace period
    final isWithinGrace = daysExpired <= license.gracePeriodDays;

    String consequence;
    double riskProbability;

    if (isWithinGrace) {
      consequence = '''
GRACE PERIOD ACTIVE:
• Warning notice may be issued
• Penalty waived if renewed immediately
• No legal action yet
• Grace period ends in ${license.gracePeriodDays - daysExpired} days
''';
      riskProbability = 0.25;
    } else if (daysExpired <= 90) {
      consequence = '''
BEYOND GRACE PERIOD:
• Penalty: ₹${penaltyAmount.toStringAsFixed(0)}
• Compliance notice issued
• Renewal required immediately
• May face inspection
• Late fee applicable
''';
      riskProbability = 0.60;
    } else {
      consequence = '''
CRITICAL VIOLATION:
• Heavy penalty: ₹${penaltyAmount.toStringAsFixed(0)}
• Business closure notice likely
• Court summons possible
• Criminal liability under ${license.department} act
• Immediate renewal mandatory
• May require fresh application
''';
      riskProbability = 0.90;
    }

    return FineCalculation(
      fineAmount: penaltyAmount.toDouble(),
       legalConsequence: consequence,
       riskProbability: riskProbability,
       recommendation: isWithinGrace
           ? 'Renew within grace period to avoid penalty'
           : 'URGENT: Renew immediately to minimize penalties',
       daysExpired: daysExpired,
       gracePeriodExpired: !isWithinGrace,
     );
   }

   /// Simulate fine for multiple missing licenses
  MultiLicenseFineCalculation calculateMultipleFines({
    required List<LicenseModel> applicableLicenses,
    required List<UserLicenseModel> userLicenses,
  }) {
    final userLicenseMap = {for (var ul in userLicenses) ul.licenseId: ul};
    final calculations = <FineCalculation>[];
    double totalFine = 0;
    int criticalViolations = 0;

    for (var license in applicableLicenses) {
      final userLicense = userLicenseMap[license.id];
      final calc = calculateFine(license: license, userLicense: userLicense);

      if (calc.fineAmount > 0) {
        calculations.add(calc);
        totalFine += calc.fineAmount;

        if (calc.riskProbability >= 0.7) {
          criticalViolations++;
        }
      }
    }

    return MultiLicenseFineCalculation(
      individualCalculations: calculations,
      totalEstimatedFine: totalFine,
      criticalViolations: criticalViolations,
      overallRisk: _calculateOverallRisk(calculations),
    );
  }

  double _calculateOverallRisk(List<FineCalculation> calculations) {
    if (calculations.isEmpty) return 0.0;

    final avgRisk =
        calculations.map((c) => c.riskProbability).reduce((a, b) => a + b) /
            calculations.length;

    // Increase risk if multiple violations
    final multiplier = 1 + (calculations.length * 0.1);
    return (avgRisk * multiplier).clamp(0.0, 1.0);
  }
}

class FineCalculation {
  final double fineAmount;
  final String legalConsequence;
  final double riskProbability; // 0.0 to 1.0
  final String recommendation;
  final int? daysExpired;
  final bool? gracePeriodExpired;

  FineCalculation({
    required this.fineAmount,
    required this.legalConsequence,
    required this.riskProbability,
    required this.recommendation,
    this.daysExpired,
    this.gracePeriodExpired,
  });
}

class MultiLicenseFineCalculation {
  final List<FineCalculation> individualCalculations;
  final double totalEstimatedFine;
  final int criticalViolations;
  final double overallRisk;

  MultiLicenseFineCalculation({
    required this.individualCalculations,
    required this.totalEstimatedFine,
    required this.criticalViolations,
    required this.overallRisk,
  });
}
