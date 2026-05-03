import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/compliance_service.dart';
import '../../../services/user_license_service.dart';
import '../../../services/subscription_service.dart';
import '../../../models/risk_profile.dart';
import '../../../models/subscription_plan.dart';
import '../../subscription/premium_promo_screen.dart'; // Added
import 'dart:ui'; // For ImageFilter

class RiskMonitorWidget extends StatelessWidget {
  const RiskMonitorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final isLocked =
        !subscriptionService.canAccess(SubscriptionFeature.riskMonitor);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // The actual content (always built, but blurred if locked)
            _buildContent(context),

            // Lock Overlay
            if (isLocked)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.lock,
                              size: 24, color: Colors.blue),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Premium Feature',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upgrade to see Real-Time Risk',
                          style: TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PremiumPromoScreen(
                                  featureName: "Risk Monitor",
                                  benefit:
                                      "Spot Risks Before They Become Fines",
                                  description:
                                      "Real-time monitoring of your compliance status across all licenses.",
                                  icon: Icons.analytics_outlined,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Upgrade Now',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer2<ComplianceService, UserLicenseService>(
      builder: (context, complianceService, userLicenseService, child) {
        final riskProfile = complianceService
            .calculateRiskProfile(userLicenseService.userLicenses);

        final color = _getRiskColor(riskProfile.level);
        final label = _getRiskLabel(riskProfile.level);

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Risk Monitor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Score Indicator (Linear Progress for simplicity)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: riskProfile.overallScore / 100,
                    backgroundColor: Colors.grey[200],
                    color: color,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${riskProfile.overallScore.round()}/100 Safe',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Risk Factors
              if (riskProfile.riskFactors.isNotEmpty) ...[
                const Text(
                  'Critical Factors:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...riskProfile.riskFactors.take(3).map((factor) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color:
                                factor.isCritical ? Colors.red : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              factor.description,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
              ] else
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('No critical risk factors detected.'),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return Colors.green;
      case RiskLevel.warning:
        return Colors.orange;
      case RiskLevel.highRisk:
        return Colors.red;
    }
  }

  String _getRiskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.warning:
        return 'Warning';
      case RiskLevel.highRisk:
        return 'High Risk';
    }
  }
}
