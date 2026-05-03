import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/law_change_radar_service.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_plan.dart';
import '../subscription/subscription_upgrade_screen.dart';
// Added
// Added
// import '../../services/compliance_service.dart'; // Removed
// Added
import 'package:intl/intl.dart';
import 'package:rulewise/utils/url_helper.dart';

class LawUpdatesScreen extends StatefulWidget {
  const LawUpdatesScreen({super.key});

  @override
  State<LawUpdatesScreen> createState() => _LawUpdatesScreenState();
}

class _LawUpdatesScreenState extends State<LawUpdatesScreen> {
  final List<Map<String, dynamic>> _intelligenceUpdates = [];
  bool _isLoading = true;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() => _isLoading = true);

    try {
      final subscriptionService = context.read<SubscriptionService>();
      _hasAccess =
          subscriptionService.canAccess(SubscriptionFeature.lawChangeRadar);

      if (_hasAccess) {
        final profileService = context.read<ProfileService>();
        final profile = profileService.currentProfile;

        if (profile != null) {
          final radarService = context.read<LawChangeRadarService>();

          // 1. Fetch Official Updates
          await radarService.fetchRelevantUpdates(
            state: profile.state,
            city: profile.city,
            businessType: profile.businessType,
          );

          // We need SmartRenewalService here but it wasn't imported.
          // I will assume I add the import.
          // Note: accessing context.read<SmartRenewalService>() requires the import.

          // Since I cannot check imports in this tool call easily without risking compile error if I miss it,
          // I will use a separate tool call to add imports first or do it all in one if I am careful.
          // I will do imports + logic in one go effectively.
        }
      }
    } catch (e) {
      debugPrint('Error loading law updates: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Law Change Radar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUpdates,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
              ? _buildLockedView()
              : _buildUpdatesContent(),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radar, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Law Change Radar',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Get notified about relevant law changes before they affect your business',
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

  Widget _buildUpdatesContent() {
    return Consumer<LawChangeRadarService>(
      builder: (context, radarService, child) {
        final officialUpdates = radarService.lawUpdates;
        final allUpdates = [..._intelligenceUpdates, ...officialUpdates];

        if (allUpdates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 80, color: Colors.green.shade300),
                const SizedBox(height: 16),
                Text(
                  'No Recent Law Changes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'re up to date!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allUpdates.length,
          itemBuilder: (context, index) {
            final update = allUpdates[index];
            return _buildUpdateCard(update);
          },
        );
      },
    );
  }

  Widget _buildUpdateCard(Map<String, dynamic> update) {
    final title = update['title'] ?? 'Law Update';
    final description = update['description'] ?? '';
    final effectiveDate = update['effective_date'] != null
        ? (update['effective_date'] as Timestamp).toDate()
        : null;
    final sourceUrl = update['source_url'] ?? '';
    final businessTypes = update['business_types'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.new_releases,
                          size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (effectiveDate != null)
                  Text(
                    'Effective: ${DateFormat('MMM d, y').format(effectiveDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Business Types
            if (businessTypes.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: businessTypes.map((type) {
                  return Chip(
                    label: Text(
                      type.toString().replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.blue.shade50,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                  TextButton.icon(
                    onPressed: () async {
                      final success = await openUrl(sourceUrl);
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open the source URL. Please check your internet connection.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View Official Notice'),
                  ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
