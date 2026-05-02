import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/compliance_service.dart';
import '../../services/user_license_service.dart';
import '../../models/license_model.dart';
import 'package:intl/intl.dart';

class AddLicenseScreen extends StatefulWidget {
  final LicenseModel? requiredLicense;

  const AddLicenseScreen({super.key, this.requiredLicense});

  @override
  State<AddLicenseScreen> createState() => _AddLicenseScreenState();
}

class _AddLicenseScreenState extends State<AddLicenseScreen> {
  // Step 1: Selection
  LicenseModel? _selectedLicense;

  // Step 2: Form Details
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _authorityController =
      TextEditingController(); // Pre-filled but editable
  DateTime? _issueDate;
  DateTime? _expiryDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.requiredLicense != null) {
      _selectLicense(widget.requiredLicense!);
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _authorityController.dispose();
    super.dispose();
  }

  void _selectLicense(LicenseModel license) {
    setState(() {
      _selectedLicense = license;
      // Pre-fill authority if available
      _authorityController.text = license.department;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isExpiry) async {
    final initialDate = isExpiry
        ? DateTime.now().add(const Duration(days: 365))
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _issueDate = picked;
        }
      });
    }
  }

  Future<void> _saveLicense() async {
    if (_selectedLicense == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_issueDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<UserLicenseService>().addLicense(
            license: _selectedLicense!,
            licenseNumber: _numberController.text.trim(),
            issuingAuthority: _authorityController.text.trim(),
            issueDate: _issueDate!,
            expiryDate: _expiryDate!,
            // content: Pending upload
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('License added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_selectedLicense == null ? 'Select License' : 'Add Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedLicense == null
              ? _buildSelectionList()
              : _buildForm(),
    );
  }

  Widget _buildSelectionList() {
    return Consumer2<ComplianceService, UserLicenseService>(
      builder: (context, complianceService, userLicenseService, child) {
        final applicable = complianceService.applicableLicenses;
        final existingIds =
            userLicenseService.userLicenses.map((l) => l.licenseId).toSet();

        // Filter out licenses that are already added
        // Or maybe show them as "Added"?
        // Let's just show available ones for now.
        final available =
            applicable; // .where((l) => !existingIds.contains(l.id)).toList();

        if (available.isEmpty) {
          return const Center(
            child: Text(
                'No applicable licenses found.\nPlease check your profile settings.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: available.length,
          itemBuilder: (context, index) {
            final license = available[index];
            final isAdded = existingIds.contains(license.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isAdded ? Colors.green[100] : Colors.blue[100],
                  child: Icon(isAdded ? Icons.check : Icons.description,
                      color: isAdded ? Colors.green : Colors.blue),
                ),
                title: Text(license.name),
                subtitle: Text(license.department),
                trailing: isAdded
                    ? const Text('Added', style: TextStyle(color: Colors.green))
                    : const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: isAdded ? null : () => _selectLicense(license),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              _selectedLicense!.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Issuing Authority: ${_selectedLicense!.department}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Divider(height: 32),

            // License Number
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'License Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Authority (Editable)
            TextFormField(
              controller: _authorityController,
              decoration: const InputDecoration(
                labelText: 'Issuing Authority',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _buildDateInput(
                    label: 'Issue Date',
                    value: _issueDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateInput(
                    label: 'Expiry Date',
                    value: _expiryDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Buttons
            ElevatedButton(
              onPressed: _saveLicense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save License'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _selectedLicense = null),
              child: const Text('Back to Selection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInput({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value == null ? 'Select' : DateFormat('dd/MM/yyyy').format(value),
        ),
      ),
    );
  }
}
