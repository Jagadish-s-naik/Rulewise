import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/smart_renewal_service.dart';
import '../../services/user_license_service.dart';
import '../../services/compliance_service.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_service.dart';
import '../../models/user_license_model.dart';
import '../../models/subscription_plan.dart';
import '../../models/renewal_automation_model.dart';
import '../../theme/app_theme.dart';
import '../subscription/premium_promo_screen.dart';
import 'package:intl/intl.dart';

class SmartRenewalScreen extends StatefulWidget {
  const SmartRenewalScreen({super.key});

  @override
  State<SmartRenewalScreen> createState() => _SmartRenewalScreenState();
}

class _SmartRenewalScreenState extends State<SmartRenewalScreen> {
  final SmartRenewalService _renewalService = SmartRenewalService();
  Map<String, RenewalIntelligence> _renewalData = {};
  final Map<String, RenewalAutomation?> _automationStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRenewalData();
  }

  Future<void> _loadRenewalData() async {
    setState(() => _isLoading = true);

    try {
      final userLicenseService = context.read<UserLicenseService>();
      final complianceService = context.read<ComplianceService>();
      final profileService = context.read<ProfileService>();

      final userLicenses = userLicenseService.userLicenses;
      final applicableLicenses = complianceService.applicableLicenses;
      final profile = profileService.currentProfile;

      final Map<String, RenewalIntelligence> data = {};

      final Set<String> existingLicenseIds =
          userLicenses.map((u) => u.licenseId).toSet();

      // 1. Analyze Existing Licenses
      for (var userLicense in userLicenses) {
        final applicableLicense = applicableLicenses.firstWhere(
            (l) => l.id == userLicense.licenseId,
            orElse: () => applicableLicenses.first);

        final intelligence = await _renewalService.analyzeRenewal(
          license: applicableLicense,
          userLicense: userLicense,
          city: profile?.city ?? '',
        );
        data[userLicense.id] = intelligence;
      }

      // 2. Analyze Missing (Projected) Licenses
      for (var license in applicableLicenses) {
        if (!existingLicenseIds.contains(license.id)) {
          // Create "Projected" Intelligence for Gap Analysis
          final projected = RenewalIntelligence(
            license: license,
            userLicense: UserLicenseModel(
              id: 'virtual_${license.id}',
              licenseId: license.id,
              licenseName: license.name,
              licenseNumber: 'NOT_ACQUIRED',
              issuingAuthority: license.department,
              issueDate: DateTime.now(),
              expiryDate:
                  DateTime.now().add(const Duration(days: 365)), // Projected
              status: LicenseStatus.active,
              documentUrl: null,
              userVerified: false,
              renewalAlertsEnabled: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )..copyWith(
                status: LicenseStatus
                    .expiringSoon), // Hack not needed, handled by UI logic
            currentFee: license.fee,
            feeChanged: false,
            feeIncrease: 0,
            documentChanges: [],
            optimalRenewalDate: DateTime.now().add(const Duration(days: 330)),
            daysUntilExpiry: 365,
            urgency: RenewalUrgency.planned,
            recommendation:
                'Future Obligation: Costs ₹${license.fee}/${license.renewalCycle}. Apply now to start compliance.',
          );
          data['virtual_${license.id}'] = projected;
        }
      }

      setState(() {
        _renewalData = data;
        _isLoading = false;
      });

      // Load automation status for each license
      await _loadAutomationStatus();
    } catch (e) {
      debugPrint('Error loading renewal data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAutomationStatus() async {
    for (var licenseId in _renewalData.keys) {
      final status = await _renewalService.getAutomationStatus(licenseId);
      setState(() {
        _automationStatus[licenseId] = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Renewal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRenewalData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildRenewalContent(),
    );
  }

  Widget _buildRenewalContent() {
    if (_renewalData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No Licenses to Renew',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Add licenses to see renewal intelligence'),
          ],
        ),
      );
    }

     final activeItems = _renewalData.values
         .where((i) => i.userLicense.licenseNumber != 'NOT_ACQUIRED')
         .toList();
     final projectedItems = _renewalData.values
         .where((i) => i.userLicense.licenseNumber == 'NOT_ACQUIRED')
         .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeItems.isNotEmpty) ...[
          const Text('Active Renewals',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ...activeItems.map((i) => _buildRenewalCard(i.userLicense, i)),
          const SizedBox(height: 24),
        ],
        if (projectedItems.isNotEmpty) ...[
          const Text('Projected Obligations',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blueGrey)),
          const SizedBox(height: 4),
          const Text('Based on your business profile',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ...projectedItems.map(
              (i) => _buildRenewalCard(i.userLicense, i, isProjected: true)),
        ],
      ],
    );
  }

  Widget _buildRenewalCard(
      UserLicenseModel license, RenewalIntelligence intelligence,
      {bool isProjected = false}) {
    final daysUntilExpiry = license.daysUntilExpiry;
    final isExpired = license.isExpired;
    final isUrgent = isExpired || license.isExpiringSoon;
    final statusColor = isExpired 
        ? AppTheme.dangerRed 
        : (isUrgent ? AppTheme.warningOrange : AppTheme.primaryBlue);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // License Name & Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isProjected ? AppTheme.primaryBlue : (isExpired ? AppTheme.dangerRed : Colors.purple))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isProjected ? Icons.add_moderator : (isExpired ? Icons.warning_rounded : Icons.verified_user),
                  color: isProjected ? AppTheme.primaryBlue : (isExpired ? AppTheme.dangerRed : Colors.purple),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      license.licenseName,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isUrgent && !isProjected)
                      Text(
                        isExpired ? 'Action Required Immediately' : 'Urgent Attention Needed',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (isProjected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PROJECTED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),

          // Automation Toggle (Premium Feature)
          if (!isProjected) ...[
            const SizedBox(height: 16),
            _buildAutomationToggle(license),
          ],

          const SizedBox(height: 20),

          // Expiry / Cycle Info with Icons
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIMELINE',
                      style: AppTheme.lightTheme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isProjected
                          ? '${intelligence.license.renewalCycle} Cycle'
                          : DateFormat('MMM d, y').format(license.expiryDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS',
                      style: AppTheme.lightTheme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isProjected
                          ? 'Not Acquired'
                          : '$daysUntilExpiry days left',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fee Change Alert (Styled)
          if (intelligence.feeChanged)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fee Revision Detected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Old: ₹${intelligence.currentFee} → New: ₹${intelligence.liveFee ?? intelligence.currentFee}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Recommendation Box (Premium)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isExpired ? Icons.report_problem_rounded : Icons.auto_awesome,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    intelligence.recommendation,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to renewal flow
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isExpired ? AppTheme.dangerRed : AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: Icon(isProjected ? Icons.add_circle_outline : Icons.refresh,
                  size: 18),
              label: Text(
                isProjected ? 'Plan Application' : (isExpired ? 'Renew Immediately' : 'Start Renewal'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationToggle(UserLicenseModel license) {
    final subscriptionService = context.watch<SubscriptionService>();
    final canAutomate =
        subscriptionService.canAccess(SubscriptionFeature.renewalAutomation);
    final automation = _automationStatus[license.id];
    final isEnabled = automation?.enabled ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: canAutomate
            ? AppTheme.accentGreen.withValues(alpha: 0.05)
            : AppTheme.textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canAutomate
              ? AppTheme.accentGreen.withValues(alpha: 0.2)
              : AppTheme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            canAutomate ? Icons.auto_awesome : Icons.lock_outline,
            color: canAutomate ? AppTheme.accentGreen : AppTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canAutomate
                      ? 'Smart Automation'
                      : 'Smart Automation (Premium)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: canAutomate
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                if (canAutomate && isEnabled)
                  const Text(
                    'Auto-reminders active',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.accentGreen,
                    ),
                  ),
              ],
            ),
          ),
          if (canAutomate)
            Switch(
              value: isEnabled,
              onChanged: (value) => _toggleAutomation(license, value),
              activeThumbColor: AppTheme.accentGreen,
            )
          else
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PremiumPromoScreen(
                      featureName: 'Smart Renewal Automation',
                      benefit: 'Never Miss a Renewal Deadline',
                      description:
                          'Automated reminders, document prep alerts, and optimal renewal timing.',
                      icon: Icons.auto_awesome,
                    ),
                  ),
                );
              },
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleAutomation(UserLicenseModel license, bool enabled) async {
    try {
      if (enabled) {
        await _renewalService.enableAutomation(license.id, license);
      } else {
        await _renewalService.disableAutomation(license.id);
      }

      // Reload automation status
      final status = await _renewalService.getAutomationStatus(license.id);
      setState(() {
        _automationStatus[license.id] = status;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? '✅ Automation enabled for ${license.licenseName}'
                  : '❌ Automation disabled for ${license.licenseName}',
            ),
            backgroundColor: enabled ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
