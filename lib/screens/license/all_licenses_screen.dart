import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/compliance_service.dart';
import '../../services/user_license_service.dart';
import '../../services/profile_service.dart'; // Added missing import
import '../../models/license_model.dart';
import '../../models/user_license_model.dart';
import '../license/license_details_screen.dart';

class AllLicensesScreen extends StatefulWidget {
  const AllLicensesScreen({super.key});

  @override
  State<AllLicensesScreen> createState() => _AllLicensesScreenState();
}

class _AllLicensesScreenState extends State<AllLicensesScreen> {
  String _searchQuery = '';
  String _filterBy = 'All'; // All, Acquired, Not Acquired, Mandatory

  List<LicenseModel> get _licenses =>
      context.read<ComplianceService>().applicableLicenses;
  List<UserLicenseModel> get _userLicenses =>
      context.watch<UserLicenseService>().userLicenses;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure we have data
      final compliance = context.read<ComplianceService>();
      final profile = context.read<ProfileService>().userProfile;

      if (compliance.applicableLicenses.isEmpty) {
        // Fetch with defaults if needed
        compliance.fetchApplicableLicenses(
          state: profile?['location']?['state'] ?? 'Karnataka',
          city: profile?['location']?['city'] ?? 'Bangalore',
          businessType: profile?['business_type'] ?? 'Retail',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use watch to rebuild when data changes
    final complianceService = context.watch<ComplianceService>();
    final licenses = complianceService.applicableLicenses;

    final filteredLicenses = _getFilteredLicenses(licenses);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Licenses'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search licenses...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    _buildFilterChip('Acquired'),
                    _buildFilterChip('Not Acquired'),
                    _buildFilterChip('Mandatory'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: filteredLicenses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredLicenses.length,
              itemBuilder: (context, index) {
                final license = filteredLicenses[index];
                final userLicense = _userLicenses.firstWhere(
                  (ul) => ul.licenseId == license.id,
                  orElse: () => UserLicenseModel(
                    id: '',
                    licenseId: license.id,
                    licenseName: license.name,
                    licenseNumber: '',
                    issuingAuthority: '',
                    issueDate: DateTime.now(),
                    expiryDate: DateTime.now(),
                    status: LicenseStatus.active,
                    userVerified: false,
                    renewalAlertsEnabled: false,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );

                final hasLicense = userLicense.licenseNumber.isNotEmpty;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasLicense ? Colors.green[50] : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasLicense
                            ? Icons.check_circle
                            : Icons.article_outlined,
                        color: hasLicense ? Colors.green : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    title: Text(
                      license.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(license.department),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '₹${license.fee}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (license.isMandatory)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50], // Lighter red
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red[100]!),
                                ),
                                child: Text(
                                  'MANDATORY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (hasLicense) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(userLicense.status)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _getStatusColor(userLicense.status)
                                        .withValues(
                                            alpha: 0.2), // Fixed deprecated
                                  ),
                                ),
                                child: Text(
                                  userLicense.status.displayName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getStatusColor(userLicense.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LicenseDetailsScreen(
                            license: license,
                            userLicense: hasLicense ? userLicense : null,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterBy == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterBy = label);
        },
      ),
    );
  }

  List<LicenseModel> _getFilteredLicenses(List<LicenseModel> allLicenses) {
    var licenses = allLicenses;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      licenses = licenses.where((license) {
        return license.name.toLowerCase().contains(_searchQuery) ||
            license.department.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply category filter
    switch (_filterBy) {
      case 'Acquired':
        licenses = licenses.where((license) {
          return _userLicenses.any((ul) => // Use getter
              ul.licenseId == license.id && ul.licenseNumber.isNotEmpty);
        }).toList();
        break;
      case 'Not Acquired':
        licenses = licenses.where((license) {
          return !_userLicenses.any((ul) => // Use getter
              ul.licenseId == license.id && ul.licenseNumber.isNotEmpty);
        }).toList();
        break;
      case 'Mandatory':
        licenses = licenses.where((license) => license.isMandatory).toList();
        break;
    }

    return licenses;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No licenses found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return Colors.green;
      case LicenseStatus.expiringSoon:
        return Colors.orange;
      case LicenseStatus.expired:
        return Colors.red;
      case LicenseStatus.renewalInProgress:
        return Colors.blue;
    }
  }
}
