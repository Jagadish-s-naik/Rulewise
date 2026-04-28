import 'package:flutter/material.dart';
import '../../services/ifsc_validation_service.dart';
import '../../theme/app_theme.dart';

class BankVerificationScreen extends StatefulWidget {
  const BankVerificationScreen({super.key});

  @override
  State<BankVerificationScreen> createState() => _BankVerificationScreenState();
}

class _BankVerificationScreenState extends State<BankVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ifscController = TextEditingController();
  final _accountController = TextEditingController();

  bool _isLoading = false;
  bool _isVerified = false;
  IFSCDetails? _bankDetails;
  String? _errorMessage;

  final _ifscService = IFSCValidationService();

  @override
  void dispose() {
    _ifscController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _verifyIFSC() async {
    // Basic format check
    if (_ifscController.text.length != 11) {
      setState(() {
        _errorMessage = 'IFSC Account must be 11 characters';
        _bankDetails = null;
        _isVerified = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isVerified = false;
      _bankDetails = null;
    });

    try {
      final details = await _ifscService.validateIFSC(_ifscController.text);

      if (!mounted) return;

      if (details != null) {
        setState(() {
          _bankDetails = details;
          _isVerified = true;
        });
        FocusScope.of(context).unfocus();
      } else {
        setState(() {
          _errorMessage = 'Invalid IFSC Code. Bank not found.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Validation failed. Please check the code.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _saveBankDetails() {
    if (!_formKey.currentState!.validate()) return;

    // Here you would save to ProfileService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Bank Details Saved (Simulation)'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Verification'),
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
                'Verify Bank Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter IFSC code to verify bank details',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // IFSC Input
              TextFormField(
                controller: _ifscController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'IFSC Code',
                  hintText: 'SBIN0001234',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.account_balance),
                  suffixIcon: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                    onPressed: _verifyIFSC,
                  ),
                ),
                onChanged: (val) {
                  if (_isVerified) {
                    setState(() {
                      _isVerified = false;
                      _bankDetails = null;
                    });
                  }
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 24),

              // Bank Details Card
              if (_bankDetails != null) ...[
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
                          const Icon(Icons.verified, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _bankDetails!.bank,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailRow('Branch', _bankDetails!.branch),
                      const SizedBox(height: 8),
                      _buildDetailRow('City', _bankDetails!.city),
                      const SizedBox(height: 8),
                      _buildDetailRow('State', _bankDetails!.state),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildSupportBadge('UPI', _bankDetails!.upi),
                          const SizedBox(width: 8),
                          _buildSupportBadge('IMPS', _bankDetails!.imps),
                          const SizedBox(width: 8),
                          _buildSupportBadge('NEFT', _bankDetails!.neft),
                          const SizedBox(width: 8),
                          _buildSupportBadge('RTGS', _bankDetails!.rtgs),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Account Number (Only if verified)
              if (_isVerified) ...[
                TextFormField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter account number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveBankDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Bank Details'),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportBadge(String label, bool supported) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: supported ? Colors.green[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: supported ? Colors.green[800] : Colors.grey[600],
        ),
      ),
    );
  }
}
