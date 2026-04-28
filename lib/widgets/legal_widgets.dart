import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DisclaimerWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const DisclaimerWidget({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? Colors.orange[700];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: displayColor!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: displayColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: displayColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: displayColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SourceAttributionWidget extends StatelessWidget {
  final String sourceUrl;
  final DateTime? lastVerified;
  final String? verificationNotes;

  const SourceAttributionWidget({
    super.key,
    required this.sourceUrl,
    this.lastVerified,
    this.verificationNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Data Source',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                // Add https:// if URL doesn't have a scheme
                String formattedUrl = sourceUrl;
                if (!sourceUrl.startsWith('http://') &&
                    !sourceUrl.startsWith('https://')) {
                  formattedUrl = 'https://$sourceUrl';
                }

                final uri = Uri.parse(formattedUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                sourceUrl,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (lastVerified != null) ...[
              const SizedBox(height: 6),
              Text(
                'Last verified: ${_formatDate(lastVerified!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (verificationNotes != null) ...[
              const SizedBox(height: 6),
              Text(
                verificationNotes!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class LegalDisclaimers {
  static const String general =
      'Information provided is for guidance only. Please verify all details on official government portals before taking action.';

  static const String aiAssistant =
      'AI responses are generated based on available data and may not be 100% accurate. Always verify critical information independently.';

  static const String compliance =
      'RuleWise helps you track compliance requirements but does not guarantee completeness. You are responsible for ensuring full legal compliance.';

  static const String dataAccuracy =
      'We strive to provide accurate information but cannot guarantee the accuracy of third-party data. Always cross-check with official sources.';

  static const String noLegalAdvice =
      'This app does not provide legal advice. Consult with a qualified professional for specific legal guidance.';

  static const String userResponsibility =
      'Users are solely responsible for verifying license requirements and maintaining compliance with all applicable laws.';
}
