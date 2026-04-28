import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/validation_service.dart';
import '../../services/profile_service.dart';

class AadhaarValidationScreen extends StatefulWidget {
  const AadhaarValidationScreen({super.key});

  @override
  State<AadhaarValidationScreen> createState() =>
      _AadhaarValidationScreenState();
}

class _AadhaarValidationScreenState extends State<AadhaarValidationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  bool _isVerifying = false;
  bool? _isValid;

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _verifyAadhaar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _isValid = null;
    });

    final validationService = context.read<ValidationService>();
    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    final isValid = validationService.validateAadhaar(_aadhaarController.text);

    setState(() {
      _isVerifying = false;
      _isValid = isValid;
    });

    if (isValid) {
      // Save to profile
      final profileService = context.read<ProfileService>();
      await profileService.updateAadhaarVerification(
        _aadhaarController.text,
        true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aadhaar verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to next step (PAN validation)
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Invalid Aadhaar number. Please check and try again.'),
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
        title: const Text('Verify Aadhaar'),
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
                        'We use Aadhaar only for identity verification. Your data is secure and never shared.',
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
                'Enter Your Aadhaar Number',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'This helps us verify your identity and provide personalized compliance information.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 24),

              // Aadhaar Input
              TextFormField(
                controller: _aadhaarController,
                keyboardType: TextInputType.number,
                maxLength: 12,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Aadhaar Number',
                  hintText: 'XXXX XXXX XXXX',
                  prefixIcon: const Icon(Icons.credit_card),
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
                    return 'Please enter your Aadhaar number';
                  }
                  return validationService.getAadhaarError(value);
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
                          'Must be exactly 12 digits',
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
                          'Validated using Verhoeff algorithm',
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
                  onPressed: _isVerifying ? null : _verifyAadhaar,
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify Aadhaar',
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
                'Privacy Note: We do not store your Aadhaar number in plain text. Only a verification status is saved.',
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
