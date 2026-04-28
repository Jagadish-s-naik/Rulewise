import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_plan.dart';
import '../subscription/subscription_upgrade_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class LawChangeRadarScreen extends StatefulWidget {
  const LawChangeRadarScreen({super.key});

  @override
  State<LawChangeRadarScreen> createState() => _LawChangeRadarScreenState();
}

class _LawChangeRadarScreenState extends State<LawChangeRadarScreen> {
  bool _isLoading = true;
  bool _hasAccess = false;
  List<Map<String, dynamic>> _lawUpdates = [];
  String? _filterState;
  String? _filterCity;

  @override
  void initState() {
    super.initState();
    _loadRadarData();
  }

  Future<void> _loadRadarData() async {
    setState(() => _isLoading = true);

    try {
      final subscriptionService = context.read<SubscriptionService>();
      _hasAccess =
          subscriptionService.canAccess(SubscriptionFeature.lawChangeRadar);

      if (_hasAccess) {
        final profileService = context.read<ProfileService>();
        final profile = profileService.currentProfile;

        if (profile != null) {
          _filterState = profile.state;
          _filterCity = profile.city;

          // Fetch law updates from Firestore
          await _fetchLawUpdates();
        }
      }
    } catch (e) {
      debugPrint('Error loading radar data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLawUpdates() async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('law_updates')
          .orderBy('published_date', descending: true)
          .limit(50);

      // Filter by state if available
      if (_filterState != null && _filterState!.isNotEmpty) {
        query = query.where('states', arrayContains: _filterState);
      }

      final snapshot = await query.get();
      setState(() {
        _lawUpdates = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching law updates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Law Change Radar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRadarData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
              ? _buildLockedView()
              : _buildRadarContent(),
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
              'Get real-time alerts about law changes affecting your business',
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

  Widget _buildRadarContent() {
    if (_lawUpdates.isEmpty) {
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
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadRadarData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRadarData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lawUpdates.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildRadarHeader();
          }
          return _buildRadarCard(_lawUpdates[index - 1]);
        },
      ),
    );
  }

  Widget _buildRadarHeader() {
    return Card(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radar, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Active Monitoring',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tracking ${_lawUpdates.length} law changes for ${_filterCity ?? 'your location'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarCard(Map<String, dynamic> update) {
    final title = update['title'] ?? 'Law Update';
    final description = update['description'] ?? '';
    final effectiveDate = update['effective_date'] != null
        ? (update['effective_date'] as Timestamp).toDate()
        : null;
    final publishedDate = update['published_date'] != null
        ? (update['published_date'] as Timestamp).toDate()
        : null;
    final sourceUrl = update['source_url'] ?? '';
    final businessTypes = update['business_types'] as List? ?? [];
    final impact = update['impact'] ?? 'medium';
    final states = update['states'] as List? ?? [];

    // Determine impact color
    Color impactColor;
    IconData impactIcon;
    switch (impact.toString().toLowerCase()) {
      case 'high':
        impactColor = Colors.red;
        impactIcon = Icons.warning;
        break;
      case 'medium':
        impactColor = Colors.orange;
        impactIcon = Icons.info;
        break;
      case 'low':
        impactColor = Colors.blue;
        impactIcon = Icons.info_outline;
        break;
      default:
        impactColor = Colors.grey;
        impactIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showUpdateDetails(update),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with impact indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: impactColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(impactIcon, color: impactColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${impact.toString().toUpperCase()} IMPACT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: impactColor,
                          ),
                        ),
                        if (publishedDate != null)
                          Text(
                            DateFormat('MMM d, y').format(publishedDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (effectiveDate != null &&
                      effectiveDate.isAfter(DateTime.now()))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Effective ${DateFormat('MMM d').format(effectiveDate)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // States
              if (states.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: states.take(3).map((state) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Text(
                        state.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 12),

              // Business Types
              if (businessTypes.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: businessTypes.take(3).map((type) {
                    return Chip(
                      label: Text(
                        type.toString().replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.blue.shade50,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  if (sourceUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(sourceUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Official Source'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateDetails(Map<String, dynamic> update) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                update['title'] ?? 'Law Update',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                update['description'] ?? '',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              if (update['source_url'] != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(update['source_url']);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View Official Notification'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Law Updates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Filters are automatically applied based on your profile'),
            const SizedBox(height: 16),
            if (_filterState != null)
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('State'),
                subtitle: Text(_filterState!),
              ),
            if (_filterCity != null)
              ListTile(
                leading: const Icon(Icons.location_city),
                title: const Text('City'),
                subtitle: Text(_filterCity!),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
