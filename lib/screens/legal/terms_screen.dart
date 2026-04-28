import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RuleWise Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using RuleWise, you accept and agree to be bound by the terms and provision of this agreement.',
            ),
            _buildSection(
              '2. Use of Service',
              'RuleWise provides information and guidance on business compliance requirements. The service is provided "as is" without warranties of any kind.',
            ),
            _buildSection(
              '3. Information Accuracy',
              'While we strive to provide accurate and up-to-date information, we do not guarantee the accuracy, completeness, or reliability of any information provided through the service.',
            ),
            _buildSection(
              '4. User Responsibilities',
              'You are solely responsible for:\n'
                  '• Verifying all compliance requirements with official government sources\n'
                  '• Maintaining accurate records of your licenses and permits\n'
                  '• Ensuring compliance with all applicable laws and regulations\n'
                  '• Renewing licenses before expiry dates',
            ),
            _buildSection(
              '5. No Legal Advice',
              'RuleWise does not provide legal advice. The information provided is for general guidance only. Consult with qualified legal professionals for specific advice.',
            ),
            _buildSection(
              '6. Data Collection',
              'We collect and process personal data as described in our Privacy Policy. By using RuleWise, you consent to such processing.',
            ),
            _buildSection(
              '7. Third-Party Sources',
              'Information is sourced from publicly available government websites. We are not responsible for the accuracy of third-party data.',
            ),
            _buildSection(
              '8. Limitation of Liability',
              'RuleWise and its creators shall not be liable for any direct, indirect, incidental, consequential, or punitive damages arising from your use of the service.',
            ),
            _buildSection(
              '9. Changes to Terms',
              'We reserve the right to modify these terms at any time. Continued use of the service constitutes acceptance of modified terms.',
            ),
            _buildSection(
              '10. Contact',
              'For questions about these terms, please contact us through the app support section.',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      const Text(
                        'Important Notice',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'By using RuleWise, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[900],
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
