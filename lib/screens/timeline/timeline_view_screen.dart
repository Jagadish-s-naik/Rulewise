import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_license_service.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_plan.dart';
import '../subscription/subscription_upgrade_screen.dart';
import '../../models/user_license_model.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

class TimelineViewScreen extends StatefulWidget {
  const TimelineViewScreen({super.key});

  @override
  State<TimelineViewScreen> createState() => _TimelineViewScreenState();
}

class _TimelineViewScreenState extends State<TimelineViewScreen> {
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    final subscriptionService = context.read<SubscriptionService>();
    setState(() {
      _hasAccess =
          subscriptionService.canAccess(SubscriptionFeature.timelineView);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Timeline'),
      ),
      body: !_hasAccess ? _buildLockedView() : _buildTimelineContent(),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Compliance Timeline',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Visualize your compliance journey - past, present, and future',
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

  Widget _buildTimelineContent() {
    return Consumer<UserLicenseService>(
      builder: (context, licenseService, child) {
        final licenses = licenseService.userLicenses;

        if (licenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No Licenses Yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Add your first license to see the timeline'),
              ],
            ),
          );
        }

        // Sort licenses by issue date
        final sortedLicenses = [...licenses]
          ..sort((a, b) => a.issueDate.compareTo(b.issueDate));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Text(
              'Your Compliance Journey',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${licenses.length} licenses tracked',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),

            // Timeline
            ...sortedLicenses.asMap().entries.map((entry) {
              final index = entry.key;
              final license = entry.value;
              final isFirst = index == 0;
              final isLast = index == sortedLicenses.length - 1;

              return _buildTimelineItem(
                license: license,
                isFirst: isFirst,
                isLast: isLast,
              );
            }),

            // Future prediction
            _buildFuturePrediction(sortedLicenses),
          ],
        );
      },
    );
  }

  Widget _buildTimelineItem({
    required UserLicenseModel license,
    required bool isFirst,
    required bool isLast,
  }) {
    final isExpired = license.isExpired;
    final isExpiringSoon = license.isExpiringSoon;

    Color indicatorColor;
    IconData icon;

    if (isExpired) {
      indicatorColor = Colors.red;
      icon = Icons.error;
    } else if (isExpiringSoon) {
      indicatorColor = Colors.orange;
      icon = Icons.warning;
    } else {
      indicatorColor = Colors.green;
      icon = Icons.check_circle;
    }

    return TimelineTile(
      isFirst: isFirst,
      isLast: false,
      beforeLineStyle: LineStyle(
        color: Colors.grey.shade300,
        thickness: 2,
      ),
      indicatorStyle: IndicatorStyle(
        width: 40,
        color: indicatorColor,
        iconStyle: IconStyle(
          iconData: icon,
          color: Colors.white,
        ),
      ),
      endChild: Card(
        margin: const EdgeInsets.only(left: 16, bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // License Name
              Text(
                license.licenseName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // License Number
              Text(
                'No: ${license.licenseNumber}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 12),

              // Dates
              Row(
                children: [
                  _buildDateChip(
                    'Issued',
                    license.issueDate,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildDateChip(
                    'Expires',
                    license.expiryDate,
                    isExpired
                        ? Colors.red
                        : isExpiringSoon
                            ? Colors.orange
                            : Colors.green,
                  ),
                ],
              ),

              // Status
              if (isExpired || isExpiringSoon) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isExpired ? Colors.red.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpired ? Icons.error : Icons.warning,
                        size: 16,
                        color: isExpired ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isExpired ? 'EXPIRED' : 'EXPIRING SOON',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.red : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, DateTime date, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            DateFormat('MMM d, y').format(date),
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturePrediction(List<UserLicenseModel> licenses) {
    // Find next renewal
    final now = DateTime.now();
    final upcomingRenewals = licenses
        .where((l) => l.expiryDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    if (upcomingRenewals.isEmpty) {
      return const SizedBox.shrink();
    }

    final nextRenewal = upcomingRenewals.first;

    return TimelineTile(
      isFirst: false,
      isLast: true,
      beforeLineStyle: LineStyle(
        color: Colors.grey.shade300,
        thickness: 2,
      ),
      indicatorStyle: IndicatorStyle(
        width: 40,
        color: Colors.blue.shade300,
        iconStyle: IconStyle(
          iconData: Icons.schedule,
          color: Colors.white,
        ),
      ),
      endChild: Card(
        margin: const EdgeInsets.only(left: 16, bottom: 16),
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Next Milestone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${nextRenewal.licenseName} renewal',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Due: ${DateFormat('MMMM d, y').format(nextRenewal.expiryDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${nextRenewal.daysUntilExpiry} days remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
