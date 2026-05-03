import 'package:flutter/material.dart';

import '../../utils/url_helper.dart';
import '../../models/license_model.dart';
import 'document_preparation_guide.dart';

class LicenseApplicationWizard extends StatefulWidget {
  final LicenseModel license;

  const LicenseApplicationWizard({
    super.key,
    required this.license,
  });

  @override
  State<LicenseApplicationWizard> createState() =>
      _LicenseApplicationWizardState();
}

class _LicenseApplicationWizardState extends State<LicenseApplicationWizard> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Guide'),
        elevation: 0,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 5) {
            setState(() => _currentStep++);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        onStepTapped: (step) => setState(() => _currentStep = step),
        steps: [
          // Step 1: Why Required
          Step(
            title: const Text('Why This License?'),
            content: _buildWhyRequiredStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),

          // Step 2: Fee Information
          Step(
            title: const Text('Fee Details'),
            content: _buildFeeStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),

          // Step 3: Required Documents
          Step(
            title: const Text('Required Documents'),
            content: _buildDocumentsStep(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),

          // Step 4: Application Steps
          Step(
            title: const Text('How to Apply'),
            content: _buildApplicationStepsContent(),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),

          // Step 5: Processing Timeline
          Step(
            title: const Text('Timeline'),
            content: _buildTimelineStep(),
            isActive: _currentStep >= 4,
            state: _currentStep > 4 ? StepState.complete : StepState.indexed,
          ),

          // Step 6: Apply Online
          Step(
            title: const Text('Apply Now'),
            content: _buildApplyStep(),
            isActive: _currentStep >= 5,
            state: StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildWhyRequiredStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This license is required for:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Text(
          widget.license.whyRequired.isNotEmpty
              ? widget.license.whyRequired
              : 'Operating your business legally',
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.license.isMandatory
                      ? 'This is a MANDATORY license'
                      : 'This license is recommended for your business type',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Application Fee:',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '₹${widget.license.fee}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.refresh, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Renewal: ${widget.license.renewalCycle}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Methods:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Online payment via government portal'),
              Text('• Demand Draft'),
              Text('• Cash (at designated counters)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prepare these documents:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...widget.license.requiredDocuments.map((doc) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(doc, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreparationGuide(
                    license: widget.license,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.description),
            label: const Text('View Document Guide'),
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationStepsContent() {
    // Convert ApplicationStep objects to simple strings for display
    final List<String> stepDescriptions;

    if (widget.license.applicationSteps.isNotEmpty) {
      stepDescriptions = widget.license.applicationSteps
          .map((step) => step.description)
          .toList();
    } else {
      stepDescriptions = [
        'Visit the official portal',
        'Fill the application form',
        'Upload required documents',
        'Pay the application fee',
        'Submit and note application number',
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Follow these steps:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...stepDescriptions.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimelineStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, size: 24, color: Colors.blue[700]),
            const SizedBox(width: 12),
            Text(
              widget.license.processingTime,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips for faster processing:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Submit all documents correctly'),
              Text('• Ensure documents are clear and legible'),
              Text('• Follow up regularly'),
              Text('• Keep application number handy'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.phone, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Helpline: ${widget.license.helpline}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApplyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ready to apply?',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        const SizedBox(height: 12),
        const Text(
          'Click the button below to visit the official application portal.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _openApplicationUrl(),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Apply Online'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You will be redirected to the official government portal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openApplicationUrl() async {
    await openUrl(widget.license.applicationUrl);
  }
}
