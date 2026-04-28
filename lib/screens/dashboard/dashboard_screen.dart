import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/compliance_service.dart';
import '../../screens/subscription/premium_promo_screen.dart'; // Added
import '../../services/user_license_service.dart';
import '../../services/profile_service.dart';
import '../../services/notification_service.dart';
import '../../services/subscription_service.dart'; // Added
import '../../models/compliance_metrics.dart';
import '../../models/user_license_model.dart';
import '../../models/subscription_plan.dart';

// Screens
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/ai/ai_assistant_screen.dart';
import '../../screens/license/add_license_screen.dart';
import '../../screens/emergency/emergency_mode_screen.dart';
import '../../screens/law_updates/law_updates_screen.dart';
import '../../screens/fine_simulator/fine_simulator_screen.dart';
import '../../screens/growth/growth_advisor_screen.dart';
import '../../screens/timeline/compliance_timeline_screen.dart'; // Added
import '../../screens/renewal/smart_renewal_screen.dart';

// Widgets
import '../../screens/license/document_upload_screen.dart';

// Dashboard Widgets
import 'widgets/premium_risk_gauge.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/risk_monitor_widget.dart';
import 'widgets/compliance_alerts_widget.dart';
import 'widgets/tax_calculator_widget.dart';
import 'widgets/financial_insights_widget.dart';
import '../../widgets/metric_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final profileService = context.read<ProfileService>();
      final complianceService = context.read<ComplianceService>();
      final userLicenseService = context.read<UserLicenseService>();

      // Load all data
      await Future.wait([
        profileService.loadUserProfile(),
        userLicenseService.loadUserLicenses(),
      ]);

      // Fetch applicable licenses (Use defaults if profile incomplete to show Catalog)
      final state =
          profileService.userProfile?['location']?['state'] ?? 'Karnataka';
      final city =
          profileService.userProfile?['location']?['city'] ?? 'Bangalore';
      final businessType =
          profileService.userProfile?['business_type'] ?? 'Retail';

      await complianceService.fetchApplicableLicenses(
        state: state,
        city: city,
        businessType: businessType,
      );

      // Update metrics
      await complianceService.getComplianceStatus();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: No Scaffold here because MainScreen provides the structure
    // We just return the body content

    final profileService = context.watch<ProfileService>();
    final userName = profileService.userProfile?['name'] ?? 'User';

    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: Consumer3<ComplianceService, UserLicenseService,
                  NotificationService>(
                builder: (context, complianceService, userLicenseService,
                    notificationService, _) {
                  final metrics = complianceService.metrics ??
                      ComplianceMetrics(
                        totalRequired: 0,
                        active: 0,
                        expired: 0,
                        expiringSoon: 0,
                        notAcquired: 0,
                      );
                  final userLicenses = userLicenseService.userLicenses;

                  // Find expiring soon licenses for the gauge
                  final expiringCount = userLicenses
                      .where((l) => l.isExpiringSoon || l.isExpired)
                      .length;

                  // Calculate min days for gauge
                  int minDays = 30;
                  if (expiringCount > 0) {
                    final sorted = userLicenses
                        .where((l) => l.isExpiringSoon || l.isExpired)
                        .toList()
                      ..sort((a, b) =>
                          a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
                    if (sorted.isNotEmpty) {
                      minDays = sorted.first.daysUntilExpiry;
                      // Handle negative (expired) by showing 0 or "Overdue"
                      if (minDays < 0) minDays = 0;
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 16),
                      // 1. Header
                      _buildHeader(
                          context, userName, notificationService.unreadCount),

                      const SizedBox(height: 24),

                      // 2. Risk Gauge
                      PremiumRiskGauge(
                        score: metrics.complianceScore / 100, // 0.0 to 1.0
                        expiringCount: expiringCount,
                        daysToExpiry: minDays,
                      ),

                      const SizedBox(height: 24),

                      // Commercial/Premium Risk Monitor (Restored)
                      const RiskMonitorWidget(),

                      const SizedBox(height: 24),

                      // Compliance Alerts Widget
                      const ComplianceAlertsWidget(),

                      const SizedBox(height: 24),

                      // Financial Insights & Tax Calculator
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            return const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: FinancialInsightsWidget(),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TaxCalculatorWidget(),
                                ),
                              ],
                            );
                          } else {
                            return const Column(
                              children: [
                                TaxCalculatorWidget(),
                                SizedBox(height: 24),
                                FinancialInsightsWidget(),
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 32),

                      // 3. Quick Actions
                      QuickActionGrid(
                        onEmergencyTap: () {
                          _tryAccessFeature(
                            context,
                            SubscriptionFeature.emergencyMode,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const EmergencyModeScreen())),
                          );
                        },
                        onAiTap: () {
                          // AI Screen handles its own quota, so we just navigate
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AIAssistantScreen()));
                        },
                        onAddLicenseTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddLicenseScreen()));
                        },
                        onUploadDocTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const DocumentUploadScreen()));
                        },
                      ),

                      const SizedBox(height: 32),

                      // 4. Deadlines / Upcoming (Horizontal List)
                      _buildUpcomingDeadlines(userLicenses),

                      const SizedBox(height: 32),

                      // 5. Overview Stats (Grid)
                      const Text(
                        'Overview',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          MetricCard(
                            icon: Icons.assignment_rounded,
                            label: 'Total Licenses',
                            value: '${metrics.totalRequired}',
                            color: Colors.blue,
                          ),
                          MetricCard(
                            icon: Icons.check_circle_rounded,
                            label: 'Active',
                            value: '${metrics.active}',
                            color: Colors.green,
                          ),
                          MetricCard(
                            icon: Icons.warning_amber_rounded,
                            label: 'Expiring Soon',
                            value: '${metrics.expiringSoon}',
                            color: Colors.orange,
                          ),
                          MetricCard(
                            icon: Icons.error_outline_rounded,
                            label: 'Expired',
                            value: '${metrics.expired}',
                            color: Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 6. Tools & Resources (List of other features)
                      _buildToolsSection(context),

                      const SizedBox(height: 48), // Bottom padding
                    ],
                  );
                },
              ),
            ),
    );
  }

  /// Helper to check access and show upgrade prompt if needed
  void _tryAccessFeature(
      BuildContext context, String feature, VoidCallback onGranted) {
    final subscriptionService =
        Provider.of<SubscriptionService>(context, listen: false);

    if (subscriptionService.canAccess(feature)) {
      onGranted();
    } else {
      _showUpgradeDialog(context, feature);
    }
  }

  void _showUpgradeDialog(BuildContext context, String feature) {
    // Navigate to dedicated Promo Screen
    String benefit = "Unlock advanced compliance tools.";
    String description =
        "Get access to premium features to secure your business.";
    IconData icon = Icons.lock;

    switch (feature) {
      case SubscriptionFeature.riskMonitor:
        benefit = "Spot Risks Before They Become Fines";
        description =
            "Real-time monitoring of your compliance status across all licenses.";
        icon = Icons.analytics_outlined;
        break;
      case SubscriptionFeature.growthAdvisor:
        benefit = "Expert Strategy for Expansion";
        description =
            "AI-powered insights to help you grow your business safely.";
        icon = Icons.trending_up;
        break;
      case SubscriptionFeature.emergencyMode:
        benefit = "Instant Crisis Management";
        description =
            "Step-by-step guidance to handle raids and legal emergencies.";
        icon = Icons.emergency_outlined;
        break;
      case SubscriptionFeature.lawChangeRadar:
        benefit = "Stay Ahead of Legal Changes";
        description =
            "Get instant alerts when laws affect your specific business type.";
        icon = Icons.radar;
        break;
      case SubscriptionFeature.fineSimulator:
        benefit = "Calculate Your Risk";
        description =
            "Simulate potential fines based on your current compliance status.";
        icon = Icons.gavel;
        break;
      case SubscriptionFeature.timelineView:
        benefit = "Visual Compliance Roadmap";
        description =
            "See your entire year of compliance deadlines at a glance.";
        icon = Icons.timeline;
        break;
      case SubscriptionFeature.renewalAutomation:
        benefit = "Automated Renewal Tracking";
        description =
            "Never miss a deadline with intelligent renewal automation.";
        icon = Icons.autorenew;
        break;
      default:
        benefit = "Upgrade to unlock this feature";
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumPromoScreen(
          featureName: feature
              .split('_')
              .map((word) =>
                  "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}")
              .join(' '),
          benefit: benefit,
          description: description,
          icon: icon,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName, int unreadCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s your compliance overview',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()));
              },
              icon: const Icon(Icons.notifications_outlined, size: 28),
              color: const Color(0xFF1E293B),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingDeadlines(List<UserLicenseModel> licenses) {
    final expiring =
        licenses.where((l) => l.isExpiringSoon || l.isExpired).toList();

    // Sort by soonest
    expiring.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    // Take top 3
    final displayList = expiring.take(3).toList();

    if (displayList.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Deadlines',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                _tryAccessFeature(
                  context,
                  SubscriptionFeature.renewalAutomation,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SmartRenewalScreen())),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...displayList.map((license) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (license.isExpired ? Colors.red : Colors.orange)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: license.isExpired ? Colors.red : Colors.orange,
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // Simple formatting for now
                          'Expires: ${license.expiryDate.day}/${license.expiryDate.month}/${license.expiryDate.year}',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (license.isExpired)
                    _buildTag('Overdue', Colors.red)
                  else
                    _buildTag('Urgent', Colors.orange),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More Tools',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.timeline_rounded, color: Colors.orange),
                  title: const Text('Compliance Timeline'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _tryAccessFeature(
                    context,
                    SubscriptionFeature.timelineView,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ComplianceTimelineScreen())),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.autorenew_rounded, color: Colors.blue),
                  title: const Text('Smart Renewal'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _tryAccessFeature(
                    context,
                    SubscriptionFeature.renewalAutomation,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SmartRenewalScreen())),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.calculate_rounded, color: Colors.purple),
                  title: const Text('Fine Simulator'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _tryAccessFeature(
                    context,
                    SubscriptionFeature.fineSimulator,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FineSimulatorScreen())),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.radar_rounded, color: Colors.blue),
                  title: const Text('Law Change Radar'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _tryAccessFeature(
                    context,
                    SubscriptionFeature.lawChangeRadar,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LawUpdatesScreen())),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.trending_up_rounded,
                      color: Colors.green),
                  title: const Text('Growth Advisor'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _tryAccessFeature(
                    context,
                    SubscriptionFeature.growthAdvisor,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GrowthAdvisorScreen())),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} // End of class
