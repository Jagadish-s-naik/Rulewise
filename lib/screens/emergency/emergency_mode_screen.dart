import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/emergency_mode_service.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_plan.dart';
import '../subscription/subscription_upgrade_screen.dart';

class EmergencyModeScreen extends StatefulWidget {
  const EmergencyModeScreen({super.key});

  @override
  State<EmergencyModeScreen> createState() => _EmergencyModeScreenState();
}

class _EmergencyModeScreenState extends State<EmergencyModeScreen> {
  final EmergencyModeService _emergencyService = EmergencyModeService();
  bool _isLoading = true;
  bool _hasAccess = false;
  Map<String, dynamic>? _legalRights;
  List<Map<String, dynamic>> _penalties = [];
  Map<String, dynamic>? _checklist;
  List<Map<String, dynamic>> _cachedLicenses = [];

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    setState(() => _isLoading = true);

    try {
      // Check access
      final subscriptionService = context.read<SubscriptionService>();
      _hasAccess =
          subscriptionService.canAccess(SubscriptionFeature.emergencyMode);

      if (_hasAccess) {
        // Load all emergency data
        _legalRights = await _emergencyService.getLegalRights();
        _penalties = await _emergencyService.getPenaltyReference();
        _checklist = await _emergencyService.getInspectionChecklist();
        _cachedLicenses = await _emergencyService.getCachedLicenses();
      }
    } catch (e) {
      debugPrint('Error loading emergency data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Mode'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmergencyData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
              ? _buildLockedView()
              : _buildEmergencyContent(),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Emergency Mode',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Offline access to legal rights, penalties, and inspection checklist',
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

  Widget _buildEmergencyContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Warning Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Inspector Visit? Stay calm. Know your rights.',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Legal Rights Section
        if (_legalRights != null) _buildLegalRightsCard(),

        const SizedBox(height: 16),

        // Cached Licenses
        _buildCachedLicensesCard(),

        const SizedBox(height: 16),

        // Penalty Reference
        if (_penalties.isNotEmpty) _buildPenaltyReferenceCard(),

        const SizedBox(height: 16),

        // Inspection Checklist
        if (_checklist != null) _buildChecklistCard(),
      ],
    );
  }

  Widget _buildLegalRightsCard() {
    final rights = (_legalRights!['rights'] as List?)?.cast<dynamic>() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _legalRights!['title'] ?? 'Your Legal Rights',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...rights.map((right) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          right.toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
            if (_legalRights!['source'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Source: ${_legalRights!['source']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedLicensesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.offline_pin, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Your Licenses (Offline)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cachedLicenses.isEmpty)
              const Text('No licenses cached. Connect to internet to sync.')
            else
              ..._cachedLicenses.map((license) => ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(license['license_name'] ?? 'License'),
                    subtitle: Text('No: ${license['license_number'] ?? 'N/A'}'),
                    trailing: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildPenaltyReferenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.money_off, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Penalty Reference',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._penalties.map((penalty) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        penalty['violation'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        penalty['penalty'] ?? '',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      const Divider(),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard() {
    final categories = (_checklist!['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _checklist!['title'] ?? 'Inspection Checklist',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...categories.map((category) {
              final items = category['items'] as List? ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_box_outline_blank, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.toString())),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
