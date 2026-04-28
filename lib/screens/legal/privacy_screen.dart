import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RuleWise Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: January 2026',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Information We Collect',
              'We collect the following information:\n'
                  '• Email address and authentication details\n'
                  '• Business information (name, type, location)\n'
                  '• License and permit information you provide\n'
                  '• Usage data and analytics',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'Your information is used to:\n'
                  '• Provide personalized compliance recommendations\n'
                  '• Send renewal reminders and notifications\n'
                  '• Improve our service and user experience\n'
                  '• Analyze usage patterns and trends',
            ),
            _buildSection(
              '3. Data Storage and Security',
              'Your data is stored securely using Firebase services with industry-standard encryption. We implement appropriate security measures to protect your information.',
            ),
            _buildSection(
              '4. Aadhaar and PAN Handling',
              'We do NOT store your Aadhaar or PAN numbers in plain text. Only verification status is saved. We use these solely for identity verification purposes.',
            ),
            _buildSection(
              '5. Data Sharing',
              'We do not sell, trade, or rent your personal information to third parties. We may share anonymized, aggregated data for research purposes.',
            ),
            _buildSection(
              '6. Third-Party Services',
              'We use the following third-party services:\n'
                  '• Firebase (Google) for authentication and database\n'
                  '• Groq API for AI assistance\n'
                  'These services have their own privacy policies.',
            ),
            _buildSection(
              '7. Cookies and Tracking',
              'We use local storage and analytics to improve user experience. You can disable these in your device settings.',
            ),
            _buildSection(
              '8. Your Rights',
              'You have the right to:\n'
                  '• Access your personal data\n'
                  '• Request data correction or deletion\n'
                  '• Opt-out of notifications\n'
                  '• Export your data',
            ),
            _buildSection(
              '9. Data Retention',
              'We retain your data as long as your account is active. You can request account deletion at any time.',
            ),
            _buildSection(
              '10. Children\'s Privacy',
              'RuleWise is not intended for users under 18. We do not knowingly collect information from children.',
            ),
            _buildSection(
              '11. Changes to Privacy Policy',
              'We may update this policy periodically. Continued use after changes constitutes acceptance.',
            ),
            _buildSection(
              '12. Contact Us',
              'For privacy concerns or data requests, contact us through the app support section.',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      const Text(
                        'Your Privacy Matters',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We are committed to protecting your privacy and handling your data responsibly. Your trust is important to us.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[900],
                      height: 1.5,
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

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
