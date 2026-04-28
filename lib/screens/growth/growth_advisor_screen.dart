import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/business_growth_advisor_service.dart';
import '../../services/profile_service.dart';
import '../../services/compliance_service.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_plan.dart';
import '../subscription/subscription_upgrade_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class GrowthAdvisorScreen extends StatefulWidget {
  const GrowthAdvisorScreen({super.key});

  @override
  State<GrowthAdvisorScreen> createState() => _GrowthAdvisorScreenState();
}

class _GrowthAdvisorScreenState extends State<GrowthAdvisorScreen> {
  final BusinessGrowthAdvisorService _advisorService =
      BusinessGrowthAdvisorService();
  final TextEditingController _turnoverController = TextEditingController();
  final TextEditingController _employeeController = TextEditingController();

  bool _isLoading = false;
  bool _hasAccess = false;
  GrowthAdvisory? _advisory;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    final subscriptionService = context.read<SubscriptionService>();
    setState(() {
      _hasAccess =
          subscriptionService.canAccess(SubscriptionFeature.growthAdvisor);
    });
  }

  Future<void> _analyzeGrowth() async {
    final turnover = double.tryParse(_turnoverController.text);
    final employees = int.tryParse(_employeeController.text);

    if (turnover == null || employees == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileService = context.read<ProfileService>();
      final complianceService = context.read<ComplianceService>();
      final profile = profileService.currentProfile;

      if (profile != null) {
        final advisory = await _advisorService.analyzeGrowth(
          userId: 'user_id', // Get from auth
          currentTurnover: turnover,
          employeeCount: employees,
          currentCity: profile.city,
          currentState: profile.state,
          businessType: profile.businessType,
          currentLicenses: complianceService.applicableLicenses,
        );

        setState(() => _advisory = advisory);
      }
    } catch (e) {
      debugPrint('Error analyzing growth: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Growth Advisor'),
      ),
      body: !_hasAccess ? _buildLockedView() : _buildAdvisorContent(),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Business Growth Advisor',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Get compliance warnings as your business grows and discover opportunities',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionUpgradeScreen(),
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

  Widget _buildAdvisorContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Input Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter Your Business Metrics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _turnoverController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Annual Turnover (₹)',
                    hintText: 'e.g., 3500000',
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _employeeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Number of Employees',
                    hintText: 'e.g., 8',
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _analyzeGrowth,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.analytics),
                    label: const Text('Analyze Growth'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_advisory != null) ...[
          const SizedBox(height: 24),

          // Overall Risk Level
          _buildRiskLevelCard(),

          const SizedBox(height: 16),

          // Warnings
          if (_advisory!.warnings.isNotEmpty) ...[
            const Text(
              'Compliance Warnings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._advisory!.warnings.map(_buildWarningCard),
          ],

          // Opportunities
          if (_advisory!.opportunities.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Growth Opportunities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._advisory!.opportunities.map(_buildOpportunityCard),
          ],
        ],
      ],
    );
  }

  Widget _buildRiskLevelCard() {
    final severity = _advisory!.overallRiskLevel;
    Color color;
    String label;
    IconData icon;

    switch (severity) {
      case WarningSeverity.critical:
        color = Colors.red;
        label = 'CRITICAL';
        icon = Icons.error;
        break;
      case WarningSeverity.high:
        color = Colors.orange;
        label = 'HIGH';
        icon = Icons.warning;
        break;
      case WarningSeverity.medium:
        color = Colors.yellow.shade700;
        label = 'MEDIUM';
        icon = Icons.info;
        break;
      case WarningSeverity.low:
        color = Colors.green;
        label = 'LOW';
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Growth Risk: $label',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_advisory!.warnings.length} warnings, ${_advisory!.opportunities.length} opportunities',
                  style: TextStyle(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(ComplianceWarning warning) {
    Color color;
    switch (warning.severity) {
      case WarningSeverity.critical:
        color = Colors.red;
        break;
      case WarningSeverity.high:
        color = Colors.orange;
        break;
      case WarningSeverity.medium:
        color = Colors.yellow.shade700;
        break;
      case WarningSeverity.low:
        color = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    warning.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(warning.description),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  '${warning.daysToComply} days',
                  Icons.schedule,
                  color,
                ),
                const SizedBox(width: 8),
                if (warning.estimatedCost > 0)
                  _buildInfoChip(
                    '₹${warning.estimatedCost}',
                    Icons.currency_rupee,
                    color,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpportunityCard(ComplianceOpportunity opportunity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    opportunity.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(opportunity.description),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.savings,
                          size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Save ₹${opportunity.estimatedSavings.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(opportunity.actionUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Learn More'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _turnoverController.dispose();
    _employeeController.dispose();
    super.dispose();
  }
}
