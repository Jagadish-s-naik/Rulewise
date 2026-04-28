import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/license_model.dart';
import '../../models/user_license_model.dart';
import '../../services/user_license_service.dart';

class EditLicenseScreen extends StatefulWidget {
  final LicenseModel license;
  final UserLicenseModel userLicense;

  const EditLicenseScreen({
    super.key,
    required this.license,
    required this.userLicense,
  });

  @override
  State<EditLicenseScreen> createState() => _EditLicenseScreenState();
}

class _EditLicenseScreenState extends State<EditLicenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _licenseNumberController;
  late TextEditingController _issuingAuthorityController;

  late DateTime _issueDate;
  late DateTime _expiryDate;
  String? _documentPath;
  String? _documentUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _licenseNumberController =
        TextEditingController(text: widget.userLicense.licenseNumber);
    _issuingAuthorityController =
        TextEditingController(text: widget.userLicense.issuingAuthority);
    _issueDate = widget.userLicense.issueDate;
    _expiryDate = widget.userLicense.expiryDate;
    _documentUrl = widget.userLicense.documentUrl;
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _issuingAuthorityController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _documentPath = result.files.first.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadDocument() async {
    if (_documentPath == null) return _documentUrl;

    setState(() => _isUploading = true);

    try {
      final file = File(_documentPath!);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${widget.license.id}';
      final storageRef =
          FirebaseStorage.instance.ref().child('user_licenses').child(fileName);

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _documentUrl = downloadUrl;
        _isUploading = false;
      });

      return downloadUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return _documentUrl;
    }
  }

  Future<void> _saveLicense() async {
    if (!_formKey.currentState!.validate()) return;

    final userLicenseService = context.read<UserLicenseService>();
    setState(() => _isSaving = true);

    try {
      // Upload new document if selected
      String? documentUrl = _documentUrl;
      if (_documentPath != null) {
        documentUrl = await _uploadDocument();
      }

      // Update license
      final updatedLicense = widget.userLicense.copyWith(
        licenseNumber: _licenseNumberController.text.trim(),
        issuingAuthority: _issuingAuthorityController.text.trim(),
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        documentUrl: documentUrl,
      );

      if (!mounted) return;
      await userLicenseService.updateLicense(updatedLicense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('License updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating license: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit License'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // License Info
              Text(
                widget.license.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Document Upload
              const Text(
                'Update Document (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _isUploading ? null : _pickDocument,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: _documentPath != null ? Colors.green[50] : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _documentPath != null
                            ? Icons.check_circle
                            : Icons.upload_file,
                        color:
                            _documentPath != null ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _documentPath != null
                                  ? 'New document selected'
                                  : _documentUrl != null
                                      ? 'Current document'
                                      : 'Tap to upload new document',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color:
                                    _documentPath != null ? Colors.green : null,
                              ),
                            ),
                            if (_documentPath != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _documentPath!.split('/').last,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_isUploading)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Form Fields
              TextFormField(
                controller: _licenseNumberController,
                decoration: InputDecoration(
                  labelText: 'License Number *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'License number is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _issuingAuthorityController,
                decoration: InputDecoration(
                  labelText: 'Issuing Authority *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Issuing authority is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Issue Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _issueDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _issueDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Issue Date *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                      '${_issueDate.day}/${_issueDate.month}/${_issueDate.year}'),
                ),
              ),

              const SizedBox(height: 16),

              // Expiry Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _expiryDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry Date *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.event),
                  ),
                  child: Text(
                      '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}'),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving || _isUploading ? null : _saveLicense,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update License',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
