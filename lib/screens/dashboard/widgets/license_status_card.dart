import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/license_model.dart';
import '../../../models/user_license_model.dart';
import '../../license/add_license_screen.dart';
import '../../license/license_details_screen.dart';

class LicenseStatusCard extends StatelessWidget {
  final LicenseModel license;
  final UserLicenseModel? userLicense;

  const LicenseStatusCard({
    super.key,
    required this.license,
    this.userLicense,
  });

  @override
  Widget build(BuildContext context) {
    final hasLicense =
        userLicense != null && userLicense!.licenseNumber.isNotEmpty;
    final status = hasLicense ? userLicense!.currentStatus : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LicenseDetailsScreen(
                license: license,
                userLicense: userLicense,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          license.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          license.department,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),

              const SizedBox(height: 12),

              // License Details or Action
              if (hasLicense) ...[
                _buildLicenseDetails(),
              ] else ...[
                _buildApplySection(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LicenseStatus? status) {
    if (status == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Not Acquired',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      );
    }

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
        badgeText = 'Renewing';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildLicenseDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.badge, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'License: ${userLicense!.licenseNumber}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Expires: ${_formatDate(userLicense!.expiryDate)}',
              style: const TextStyle(fontSize: 14),
            ),
            if (userLicense!.isExpiringSoon || userLicense!.isExpired) ...[
              const SizedBox(width: 8),
              Text(
                '(${userLicense!.daysUntilExpiry} days)',
                style: TextStyle(
                  fontSize: 12,
                  color: userLicense!.isExpired ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildApplySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Fee: ₹${license.fee}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 16),
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              license.processingTime,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Primary Action: Apply Online
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () =>
                _openApplicationUrl(context, license.applicationUrl),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Apply Online'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Secondary Action: I Have This License
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddLicenseScreen(requiredLicense: license),
                ),
              );
              // Reload dashboard if license was added
              if (result == true) {
                // Trigger parent widget refresh
              }
            },
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('I Have This License'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openApplicationUrl(BuildContext context, String url) async {
    try {
      // Add https:// if URL doesn't have a scheme
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }

      final uri = Uri.parse(formattedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open: $formattedUrl'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
