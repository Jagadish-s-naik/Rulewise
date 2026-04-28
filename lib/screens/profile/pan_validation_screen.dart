import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/validation_service.dart';
import '../../services/profile_service.dart';

class PANValidationScreen extends StatefulWidget {
  const PANValidationScreen({super.key});

  @override
  State<PANValidationScreen> createState() => _PANValidationScreenState();
}

class _PANValidationScreenState extends State<PANValidationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();
  bool _isVerifying = false;
  bool? _isValid;

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  Future<void> _verifyPAN() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _isValid = null;
    });

    final validationService = context.read<ValidationService>();
    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    final isValid = validationService.validatePAN(_panController.text);

    setState(() {
      _isVerifying = false;
      _isValid = isValid;
    });

    if (isValid) {
      // Save to profile
      final profileService = context.read<ProfileService>();
      await profileService.updatePANVerification(
        _panController.text.toUpperCase(),
        true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PAN verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid PAN format. Please check and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final validationService = context.watch<ValidationService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify PAN'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'PAN is required for GST and tax-related licenses. Your data is secure.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Enter Your PAN Number',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'This helps us identify tax-related compliance requirements for your business.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 24),

              // PAN Input
              TextFormField(
                controller: _panController,
                keyboardType: TextInputType.text,
                maxLength: 10,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'PAN Number',
                  hintText: 'ABCDE1234F',
                  prefixIcon: const Icon(Icons.badge),
                  suffixIcon: _isValid != null
                      ? Icon(
                          _isValid! ? Icons.check_circle : Icons.error,
                          color: _isValid! ? Colors.green : Colors.red,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '',
                ),
                onChanged: (value) {
                  setState(() {
                    _isValid = null;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your PAN number';
                  }
                  return validationService.getPANError(value);
                },
              ),

              const SizedBox(height: 16),

              // Validation Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Format: AAAAA9999A',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        const Text(
                          '5 letters, 4 digits, 1 letter',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyPAN,
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify PAN',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Skip for now'),
                ),
              ),

              const SizedBox(height: 24),

              // Privacy Note
              Text(
                'Privacy Note: We do not store your PAN in plain text. Only a verification status is saved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom formatter to convert to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
