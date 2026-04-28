import 'package:flutter/material.dart';
import '../../services/api_setu_service.dart';
import '../../theme/app_theme.dart';

class GSTValidationScreen extends StatefulWidget {
  const GSTValidationScreen({super.key});

  @override
  State<GSTValidationScreen> createState() => _GSTValidationScreenState();
}

class _GSTValidationScreenState extends State<GSTValidationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gstController = TextEditingController();

  bool _isLoading = false;
  bool _isVerified = false;
  String? _legalName;
  String? _tradeName;
  String? _errorMessage;

  final _apiSetuService = ApiSetuService();

  @override
  void dispose() {
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _verifyGST() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiSetuService.validateGST(_gstController.text);

      if (response != null && response.isValid) {
        setState(() {
          _isVerified = true;
          _legalName = response.legalName;
          _tradeName = response.tradeName;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ GST Verified Successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid GST Number or Business Inactive';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Verification failed. Please check your internet or try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if API verification is possible
    final canVerify = ApiSetuService.isAvailable;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify GST Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Business Verification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                canVerify
                    ? 'Verify your business using your GSTIN'
                    : 'Enter your business GSTIN details',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _gstController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'GSTIN',
                  hintText: '27AAPFU0939F1ZV',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.business),
                  suffixIcon: _isVerified
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter GSTIN';
                  }
                  if (value.length != 15) {
                    return 'GSTIN must be 15 characters';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (_isVerified) {
                    setState(() {
                      _isVerified = false;
                      _legalName = null;
                      _tradeName = null;
                    });
                  }
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (canVerify && !_isVerified)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyGST,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify GSTIN'),
                  ),
                ),
              if (_isVerified) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Legal Name', _legalName ?? '-'),
                      const Divider(height: 24),
                      _buildDetailRow('Trade Name', _tradeName ?? '-'),
                      const Divider(height: 24),
                      _buildDetailRow('Status', 'Active'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isVerified ? AppTheme.primaryBlue : Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                      _isVerified ? 'Confirm Business Details' : 'Continue'),
                ),
              ),
              if (!canVerify) ...[
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Verification service currently unavailable.\nYou can update these details later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
