import 'package:flutter/material.dart';
import '../../models/license_model.dart';

class DocumentPreparationGuide extends StatelessWidget {
  final LicenseModel license;

  const DocumentPreparationGuide({
    super.key,
    required this.license,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Guide'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Preparation for ${license.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Required Documents
            const Text(
              'Required Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...license.requiredDocuments.map((doc) {
              return _buildDocumentCard(doc);
            }),

            const SizedBox(height: 24),

            // Common Mistakes
            const Text(
              'Common Mistakes to Avoid',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildMistakeCard(
              'Unclear Photocopies',
              'Ensure all documents are clear, legible, and properly scanned',
              Icons.warning_amber,
            ),
            _buildMistakeCard(
              'Missing Signatures',
              'All documents must be signed where required',
              Icons.edit,
            ),
            _buildMistakeCard(
              'Expired Documents',
              'Check validity dates of all supporting documents',
              Icons.event_busy,
            ),
            _buildMistakeCard(
              'Incorrect Format',
              'Follow the specified format for each document',
              Icons.format_align_left,
            ),

            const SizedBox(height: 24),

            // Tips for Approval
            const Text(
              'Tips for Quick Approval',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

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
                  _buildTip('Submit all documents in one go'),
                  _buildTip('Use high-quality scans (300 DPI minimum)'),
                  _buildTip('Organize documents in the required order'),
                  _buildTip('Keep original documents for verification'),
                  _buildTip('Double-check all information before submission'),
                  _buildTip('Follow up within 7 days of submission'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Document Checklist
            const Text(
              'Pre-Submission Checklist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

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
                  _buildChecklistItem('All documents collected'),
                  _buildChecklistItem('Documents are clear and legible'),
                  _buildChecklistItem('All signatures in place'),
                  _buildChecklistItem('Dates are current'),
                  _buildChecklistItem('Information matches across documents'),
                  _buildChecklistItem('Application form filled correctly'),
                  _buildChecklistItem('Fee payment ready'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Help Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      const Text(
                        'Need Help?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contact helpline: ${license.helpline}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Department: ${license.department}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[900],
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

  Widget _buildDocumentCard(String document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.description, color: Colors.blue[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                document,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakeCard(String title, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.red[700], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
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

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_box_outline_blank,
              size: 18, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
