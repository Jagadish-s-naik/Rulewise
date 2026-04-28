import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/profile_service.dart';
import '../../../services/compliance_service.dart';
import '../../../services/user_license_service.dart';
import '../../../models/risk_profile.dart';
import 'package:intl/intl.dart';

class ExecutiveSummaryPanel extends StatelessWidget {
  const ExecutiveSummaryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProfileService, ComplianceService, UserLicenseService>(
      builder: (context, profileService, complianceService, userLicenseService,
          child) {
        final profile = profileService.currentProfile;
        final userLicenses = userLicenseService.userLicenses;
        final riskProfile =
            complianceService.calculateRiskProfile(userLicenses);

        // Find nearest deadline
        final sortedLicenses = [...userLicenses]
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        final nearestDeadline =
            sortedLicenses.isNotEmpty ? sortedLicenses.first.expiryDate : null;

        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Name & City
                Row(
                  children: [
                    const Icon(Icons.business, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.businessName ?? 'Your Business',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${profile?.city ?? 'City'}, ${profile?.state ?? 'State'}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Metrics Row
                Row(
                  children: [
                    // Compliance Score
                    Expanded(
                      child: _buildMetric(
                        icon: Icons.check_circle_outline,
                        label: 'Compliance Score',
                        value: '${riskProfile.overallScore.round()}%',
                        color: _getRiskColor(riskProfile.level),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Nearest Deadline
                    Expanded(
                      child: _buildMetric(
                        icon: Icons.event,
                        label: 'Nearest Deadline',
                        value: nearestDeadline != null
                            ? _formatDeadline(nearestDeadline)
                            : 'None',
                        color: nearestDeadline != null &&
                                nearestDeadline
                                        .difference(DateTime.now())
                                        .inDays <
                                    30
                            ? Colors.orange
                            : Colors.white,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Risk Indicator
                    _buildRiskIndicator(riskProfile.level),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskIndicator(RiskLevel level) {
    final color = _getRiskColor(level);
    final label = _getRiskLabel(level);
    final icon = _getRiskIcon(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return Colors.greenAccent;
      case RiskLevel.warning:
        return Colors.orangeAccent;
      case RiskLevel.highRisk:
        return Colors.redAccent;
    }
  }

  String _getRiskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return 'SAFE';
      case RiskLevel.warning:
        return 'WARNING';
      case RiskLevel.highRisk:
        return 'HIGH RISK';
    }
  }

  IconData _getRiskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return Icons.shield_outlined;
      case RiskLevel.warning:
        return Icons.warning_amber_rounded;
      case RiskLevel.highRisk:
        return Icons.error_outline;
    }
  }

  String _formatDeadline(DateTime deadline) {
    final daysUntil = deadline.difference(DateTime.now()).inDays;

    if (daysUntil < 0) {
      return 'Overdue';
    } else if (daysUntil == 0) {
      return 'Today';
    } else if (daysUntil == 1) {
      return 'Tomorrow';
    } else if (daysUntil < 30) {
      return '$daysUntil days';
    } else {
      return DateFormat('MMM d').format(deadline);
    }
  }
}
