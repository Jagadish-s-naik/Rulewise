import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/fine_simulator_service.dart';
import '../../services/compliance_service.dart';
import '../../services/user_license_service.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_plan.dart';
import '../subscription/subscription_upgrade_screen.dart';

class FineSimulatorScreen extends StatefulWidget {
  const FineSimulatorScreen({super.key});

  @override
  State<FineSimulatorScreen> createState() => _FineSimulatorScreenState();
}

class _FineSimulatorScreenState extends State<FineSimulatorScreen> {
  final FineSimulatorService _simulatorService = FineSimulatorService();
  bool _isLoading = true;
  bool _hasAccess = false;
  MultiLicenseFineCalculation? _calculation;

  @override
  void initState() {
    super.initState();
    _calculateFines();
  }

  Future<void> _calculateFines() async {
    setState(() => _isLoading = true);

    try {
      final subscriptionService = context.read<SubscriptionService>();
      _hasAccess =
          subscriptionService.canAccess(SubscriptionFeature.fineSimulator);

      if (_hasAccess) {
        final complianceService = context.read<ComplianceService>();
        final userLicenseService = context.read<UserLicenseService>();

        final applicableLicenses = complianceService.applicableLicenses;
        final userLicenses = userLicenseService.userLicenses;

        _calculation = _simulatorService.calculateMultipleFines(
          applicableLicenses: applicableLicenses,
          userLicenses: userLicenses,
        );
      }
    } catch (e) {
      debugPrint('Error calculating fines: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fine Simulator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calculateFines,
            tooltip: 'Recalculate',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
              ? _buildLockedView()
              : _buildSimulatorContent(),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate_outlined,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Fine Simulator',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Calculate potential fines and legal consequences for missing or expired licenses',
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
              label: const Text('Upgrade to Protection Plan'),
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

  Widget _buildSimulatorContent() {
    if (_calculation == null || _calculation!.individualCalculations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 80, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text(
              'No Violations Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'All licenses are active!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        _buildSummaryCard(),

        const SizedBox(height: 16),

        // Risk Level Indicator
        _buildRiskIndicator(),

        const SizedBox(height: 24),

        // Individual Violations
        Text(
          'Potential Violations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),

        ..._calculation!.individualCalculations.map(_buildViolationCard),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Estimated Fine',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '₹${_calculation!.totalEstimatedFine.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Critical Violations: ${_calculation!.criticalViolations}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Overall Risk: ${(_calculation!.overallRisk * 100).round()}%',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskIndicator() {
    final risk = _calculation!.overallRisk;
    Color color;
    String label;
    IconData icon;

    if (risk >= 0.7) {
      color = Colors.red;
      label = 'HIGH RISK';
      icon = Icons.error;
    } else if (risk >= 0.4) {
      color = Colors.orange;
      label = 'MEDIUM RISK';
      icon = Icons.warning;
    } else {
      color = Colors.yellow.shade700;
      label = 'LOW RISK';
      icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Probability of inspection action: ${(risk * 100).round()}%',
                  style: TextStyle(color: color, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationCard(FineCalculation calc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fine Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Fine',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '₹${calc.fineAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Risk Probability
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: calc.riskProbability,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      calc.riskProbability >= 0.7
                          ? Colors.red
                          : calc.riskProbability >= 0.4
                              ? Colors.orange
                              : Colors.yellow.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(calc.riskProbability * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Legal Consequence
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legal Consequences:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    calc.legalConsequence,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recommendation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      calc.recommendation,
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
