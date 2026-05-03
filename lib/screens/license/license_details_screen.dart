import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/url_helper.dart';
import '../../models/license_model.dart';
import '../../models/user_license_model.dart';
import '../../services/user_license_service.dart';

import 'edit_license_screen.dart';
import 'license_application_wizard.dart';

class LicenseDetailsScreen extends StatelessWidget {
  final LicenseModel license;
  final UserLicenseModel? userLicense;

  const LicenseDetailsScreen({
    super.key,
    required this.license,
    this.userLicense,
  });

  @override
  Widget build(BuildContext context) {
    final hasLicense = userLicense != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('License Details'),
        elevation: 0,
        actions: [
          if (hasLicense)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditLicenseScreen(
                      license: license,
                      userLicense: userLicense!,
                    ),
                  ),
                );
              },
              tooltip: 'Edit License',
            ),
          if (hasLicense)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context),
              tooltip: 'Delete License',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // License Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      license.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      license.officialName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (hasLicense) ...[
                      const SizedBox(height: 16),
                      _buildStatusBadge(userLicense!.currentStatus),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // User License Details (if acquired)
            if (hasLicense) ...[
              _buildSectionTitle('Your License'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'License Number',
                        userLicense!.licenseNumber,
                        Icons.badge,
                      ),
                      const Divider(),
                      _buildDetailRow(
                        'Issuing Authority',
                        userLicense!.issuingAuthority,
                        Icons.business,
                      ),
                      const Divider(),
                      _buildDetailRow(
                        'Issue Date',
                        _formatDate(userLicense!.issueDate),
                        Icons.calendar_today,
                      ),
                      const Divider(),
                      _buildDetailRow(
                        'Expiry Date',
                        _formatDate(userLicense!.expiryDate),
                        Icons.event,
                      ),
                      if (userLicense!.isExpiringSoon ||
                          userLicense!.isExpired) ...[
                        const Divider(),
                        _buildDetailRow(
                          'Days Until Expiry',
                          '${userLicense!.daysUntilExpiry} days',
                          Icons.warning_amber,
                          valueColor: userLicense!.isExpired
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ],
                      if (userLicense!.documentUrl != null) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.attach_file),
                          title: const Text('Document'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => _openDocument(userLicense!.documentUrl!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // License Information
            _buildSectionTitle('License Information'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Department',
                      license.department,
                      Icons.account_balance,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Fee',
                      '₹${license.fee}',
                      Icons.currency_rupee,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Renewal Cycle',
                      license.renewalCycle,
                      Icons.refresh,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Processing Time',
                      license.processingTime,
                      Icons.access_time,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Helpline',
                      license.helpline,
                      Icons.phone,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Mandatory',
                      license.isMandatory ? 'Yes' : 'No',
                      Icons.info,
                      valueColor:
                          license.isMandatory ? Colors.red : Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Required Documents
            _buildSectionTitle('Required Documents'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: license.requiredDocuments.map((doc) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(doc)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Application Wizard Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LicenseApplicationWizard(
                        license: license,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.assistant),
                label: const Text('Application Guide'),
              ),
            ),

            const SizedBox(height: 12),

            // Application Link
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _openUrl(license.applicationUrl),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Apply Online'),
              ),
            ),

            const SizedBox(height: 16),

            // Verification Info
            if (license.sourceUrl.isNotEmpty) ...[
              _buildSectionTitle('Data Verification'),
              const SizedBox(height: 12),
              Card(
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue[100]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified,
                              size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Verified Government Source',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This information was verified from the official department website on ${_formatDate(license.lastVerified)}.',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _openUrl(license.sourceUrl),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Source',
                              style: TextStyle(
                                color: Colors.blue[800],
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_outward,
                                size: 14, color: Colors.blue[800]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(label),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: valueColor,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LicenseStatus status) {
    Color badgeColor;
    String badgeText;

    switch (status) {
      case LicenseStatus.active:
        badgeColor = Colors.green;
        badgeText = 'Active';
        break;
      case LicenseStatus.expiringSoon:
        badgeColor = Colors.orange;
        badgeText = 'Expiring Soon';
        break;
      case LicenseStatus.expired:
        badgeColor = Colors.red;
        badgeText = 'Expired';
        break;
      case LicenseStatus.renewalInProgress:
        badgeColor = Colors.blue;
        badgeText = 'Renewal in Progress';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _openUrl(String url) async {
    await openUrl(url);
  }

  Future<void> _openDocument(String url) async {
    await openUrl(url);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete License'),
        content: const Text(
          'Are you sure you want to delete this license? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<UserLicenseService>().deleteLicense(userLicense!.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('License deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return to dashboard
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting license: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
