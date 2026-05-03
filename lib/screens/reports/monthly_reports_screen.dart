import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/report_generation_service.dart';
import '../../services/profile_service.dart';
import '../../services/compliance_service.dart';
import '../../services/user_license_service.dart';
import '../../services/subscription_service.dart';
import '../../services/auth_service.dart';
import '../../models/subscription_plan.dart';
import '../subscription/premium_promo_screen.dart'; // Added
import 'package:rulewise/utils/url_helper.dart';

import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class MonthlyReportsScreen extends StatefulWidget {
  const MonthlyReportsScreen({super.key});

  @override
  State<MonthlyReportsScreen> createState() => _MonthlyReportsScreenState();
}

class _MonthlyReportsScreenState extends State<MonthlyReportsScreen> {
  final ReportGenerationService _reportService = ReportGenerationService();
  bool _isGenerating = false;
  bool _hasAccess = false;
  String? _lastReportFirebaseUrl;
  String? _lastReportLocalPath;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    final subscriptionService = context.read<SubscriptionService>();
    setState(() {
      _hasAccess =
          subscriptionService.canAccess(SubscriptionFeature.monthlyReports);
    });
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final profileService = context.read<ProfileService>();
      final complianceService = context.read<ComplianceService>();
      final userLicenseService = context.read<UserLicenseService>();

      final profile = profileService.currentProfile;
      final userLicenses = userLicenseService.userLicenses;
      final applicableLicenses = complianceService.applicableLicenses;
      final metrics =
          complianceService.calculateComplianceMetrics(userLicenses);
      final riskProfile = complianceService.calculateRiskProfile(userLicenses);

      if (profile == null) {
        throw Exception('Profile not found');
      }

      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.uid ?? 'unknown_user';

      final reportResult = await _reportService.generateMonthlyReport(
        userId: userId,
        userName: profile.businessName,
        businessName: profile.businessName,
        city: profile.city,
        state: profile.state,
        applicableLicenses: applicableLicenses,
        userLicenses: userLicenses,
        metrics: metrics,
        riskProfile: riskProfile,
      );

      setState(() {
        _lastReportFirebaseUrl = reportResult['firebase_url'];
        _lastReportLocalPath = reportResult['local_path'];
        _isGenerating = false;
      });

      if (mounted) {
        final message = _lastReportLocalPath != null
            ? '✅ Report saved to device!'
            : '✅ Report generated (cloud only)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            action: _lastReportLocalPath != null
                ? SnackBarAction(
                    label: 'OPEN',
                    textColor: Colors.white,
                    onPressed: _openLocalReport,
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openLocalReport() async {
    if (_lastReportLocalPath == null) return;

    try {
      final result = await OpenFile.open(_lastReportLocalPath!);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open PDF: ${result.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openCloudReport() async {
    if (_lastReportFirebaseUrl == null) return;
    await openUrl(_lastReportFirebaseUrl!);
  }

  Future<void> _shareReport() async {
    if (_lastReportLocalPath == null) return;

    try {
      await Share.shareXFiles(
        [XFile(_lastReportLocalPath!)],
        subject: 'RuleWise Compliance Report',
        text: 'Here is my compliance report from RuleWise',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reports'),
      ),
      body: !_hasAccess ? _buildLockedView() : _buildReportsContent(),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Monthly Compliance Reports',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Get detailed PDF reports with live government data every month',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PremiumPromoScreen(
                      featureName: "Monthly Reports",
                      benefit: "Automated Executive Summary",
                      description:
                          "Get detailed PDF reports with live government data every month.",
                      icon: Icons.picture_as_pdf,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade to Business Shield'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Monthly Compliance Report',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Generate a comprehensive PDF report with:\n• Live government data\n• Compliance status\n• Risk analysis\n• Upcoming deadlines\n• Recommended actions',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateReport,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Report'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),

          if (_lastReportLocalPath != null ||
              _lastReportFirebaseUrl != null) ...[
            const SizedBox(height: 24),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Report Ready',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_lastReportLocalPath != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.phone_android, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saved on device',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastReportLocalPath!.split('/').last,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openLocalReport,
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: const Text('Open'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _shareReport,
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_lastReportLocalPath == null &&
                        _lastReportFirebaseUrl != null) ...[
                      const Text(
                        'Saved to cloud only',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openCloudReport,
                        icon: const Icon(Icons.cloud_download, size: 18),
                        label: const Text('Download from Cloud'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'PDFs are saved to your device\'s Download folder for offline access',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
