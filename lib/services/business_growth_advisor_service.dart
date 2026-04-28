import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/license_model.dart';
import 'government_portal_service.dart';

class BusinessGrowthAdvisorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GovernmentPortalService _portalService = GovernmentPortalService();

  /// Analyze growth and predict compliance needs
  Future<GrowthAdvisory> analyzeGrowth({
    required String userId,
    required double currentTurnover,
    required int employeeCount,
    required String currentCity,
    required String currentState,
    required String businessType,
    required List<LicenseModel> currentLicenses,
    String? expandingToCity,
  }) async {
    final warnings = <ComplianceWarning>[];
    final opportunities = <ComplianceOpportunity>[];

    // Check turnover thresholds
    await _checkTurnoverThresholds(
      currentTurnover: currentTurnover,
      currentLicenses: currentLicenses,
      warnings: warnings,
    );

    // Check employee count thresholds
    _checkEmployeeThresholds(
      employeeCount: employeeCount,
      currentLicenses: currentLicenses,
      warnings: warnings,
    );

    // Check expansion compliance
    if (expandingToCity != null) {
      await _checkExpansionCompliance(
        expandingToCity: expandingToCity,
        currentState: currentState,
        businessType: businessType,
        warnings: warnings,
      );
    }

    // Identify growth opportunities (benefits, subsidies)
    await _identifyOpportunities(
      turnover: currentTurnover,
      employeeCount: employeeCount,
      businessType: businessType,
      opportunities: opportunities,
    );

    return GrowthAdvisory(
      warnings: warnings,
      opportunities: opportunities,
      overallRiskLevel: _calculateGrowthRisk(warnings),
    );
  }

  /// Check turnover-based compliance thresholds
  Future<void> _checkTurnoverThresholds({
    required double currentTurnover,
    required List<LicenseModel> currentLicenses,
    required List<ComplianceWarning> warnings,
  }) async {
    // Fetch live GST thresholds
    final gstData = await _portalService.fetchGSTThresholds();
    final gstThreshold = gstData?['registration_threshold'] ?? 4000000;

    // GST Registration
    if (currentTurnover >= gstThreshold * 0.8) {
      final hasGST = currentLicenses.any((l) => l.id.contains('gst'));

      if (!hasGST) {
        if (currentTurnover >= gstThreshold) {
          warnings.add(ComplianceWarning(
            title: 'GST Registration MANDATORY',
            description: 'Your turnover (₹${_formatAmount(currentTurnover)}) '
                'exceeds ₹${_formatAmount(gstThreshold)}. '
                'GST registration is legally required.',
            severity: WarningSeverity.critical,
            daysToComply: 30,
            estimatedCost: 0,
          ));
        } else {
          warnings.add(ComplianceWarning(
            title: 'Approaching GST Threshold',
            description:
                'You are at ${((currentTurnover / gstThreshold) * 100).round()}% '
                'of GST threshold. Plan registration in advance.',
            severity: WarningSeverity.medium,
            daysToComply: 90,
            estimatedCost: 0,
          ));
        }
      }
    }

    // Professional Tax (varies by state)
    if (currentTurnover >= 250000) {
      final hasPT =
          currentLicenses.any((l) => l.name.contains('Professional Tax'));

      if (!hasPT) {
        warnings.add(ComplianceWarning(
          title: 'Professional Tax Registration',
          description:
              'Businesses with turnover > ₹2.5L typically need PT registration',
          severity: WarningSeverity.medium,
          daysToComply: 60,
          estimatedCost: 2500,
        ));
      }
    }
  }

  /// Check employee count thresholds
  void _checkEmployeeThresholds({
    required int employeeCount,
    required List<LicenseModel> currentLicenses,
    required List<ComplianceWarning> warnings,
  }) {
    // EPFO (10+ employees)
    if (employeeCount >= 10) {
      final hasEPFO = currentLicenses
          .any((l) => l.name.contains('EPFO') || l.name.contains('PF'));

      if (!hasEPFO) {
        warnings.add(ComplianceWarning(
          title: 'EPFO Registration Required',
          description: 'Businesses with 10+ employees must register with EPFO',
          severity: WarningSeverity.high,
          daysToComply: 30,
          estimatedCost: 0,
        ));
      }
    }

    // Factory License (20+ employees in manufacturing)
    if (employeeCount >= 20) {
      final hasFactory = currentLicenses.any((l) => l.name.contains('Factory'));

      if (!hasFactory) {
        warnings.add(ComplianceWarning(
          title: 'Factory License May Be Required',
          description:
              'If in manufacturing, 20+ employees triggers Factory Act',
          severity: WarningSeverity.medium,
          daysToComply: 60,
          estimatedCost: 8000,
        ));
      }
    }
  }

  /// Check compliance for city expansion
  Future<void> _checkExpansionCompliance({
    required String expandingToCity,
    required String currentState,
    required String businessType,
    required List<ComplianceWarning> warnings,
  }) async {
    // Fetch applicable licenses for new city
    final newCityLicenses = await _firestore
        .collection('compliance_data')
        .doc(currentState)
        .collection('cities')
        .doc(expandingToCity)
        .collection('business_types')
        .doc(businessType)
        .collection('licenses')
        .get();

    if (newCityLicenses.docs.isNotEmpty) {
      warnings.add(ComplianceWarning(
        title: 'New City Compliance Required',
        description:
            '${newCityLicenses.docs.length} new licenses needed in $expandingToCity',
        severity: WarningSeverity.high,
        daysToComply: 90,
        estimatedCost: newCityLicenses.docs
            .map((doc) => doc.data()['fee'] as int? ?? 0)
            .reduce((a, b) => a + b),
      ));
    }
  }

  /// Identify growth opportunities
  Future<void> _identifyOpportunities({
    required double turnover,
    required int employeeCount,
    required String businessType,
    required List<ComplianceOpportunity> opportunities,
  }) async {
    // MSME Registration benefits
    if (turnover < 50000000) {
      // < 5 crore
      opportunities.add(ComplianceOpportunity(
        title: 'MSME Registration Benefits',
        description:
            'Register as MSME to get tax benefits, subsidies, and easier loans',
        estimatedSavings: turnover * 0.02, // 2% estimated savings
        actionUrl: 'https://udyamregistration.gov.in',
      ));
    }

    // Startup India benefits
    if (turnover < 100000000) {
      // < 10 crore
      opportunities.add(ComplianceOpportunity(
        title: 'Startup India Recognition',
        description: 'Get tax exemptions and faster approvals',
        estimatedSavings: 50000,
        actionUrl: 'https://www.startupindia.gov.in',
      ));
    }
  }

  WarningSeverity _calculateGrowthRisk(List<ComplianceWarning> warnings) {
    if (warnings.any((w) => w.severity == WarningSeverity.critical)) {
      return WarningSeverity.critical;
    } else if (warnings.any((w) => w.severity == WarningSeverity.high)) {
      return WarningSeverity.high;
    } else if (warnings.isNotEmpty) {
      return WarningSeverity.medium;
    }
    return WarningSeverity.low;
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    }
    return amount.toStringAsFixed(0);
  }
}

enum WarningSeverity {
  low,
  medium,
  high,
  critical,
}

class ComplianceWarning {
  final String title;
  final String description;
  final WarningSeverity severity;
  final int daysToComply;
  final int estimatedCost;

  ComplianceWarning({
    required this.title,
    required this.description,
    required this.severity,
    required this.daysToComply,
    required this.estimatedCost,
  });
}

class ComplianceOpportunity {
  final String title;
  final String description;
  final double estimatedSavings;
  final String actionUrl;

  ComplianceOpportunity({
    required this.title,
    required this.description,
    required this.estimatedSavings,
    required this.actionUrl,
  });
}

class GrowthAdvisory {
  final List<ComplianceWarning> warnings;
  final List<ComplianceOpportunity> opportunities;
  final WarningSeverity overallRiskLevel;

  GrowthAdvisory({
    required this.warnings,
    required this.opportunities,
    required this.overallRiskLevel,
  });
}
