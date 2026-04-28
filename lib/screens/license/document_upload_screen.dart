import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/user_license_service.dart';
import '../../services/storage_service.dart';
import '../../services/ocr_service.dart';
import '../../models/extracted_data_model.dart';
import '../../services/subscription_service.dart'; // Added
import '../../screens/subscription/subscription_upgrade_screen.dart'; // Added
import '../../models/subscription_plan.dart'; // Required for extension methods

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final StorageService _storageService = StorageService();
  final OCRService _ocrService = OCRService(); // OCR Service

  bool _isUploading = false;
  bool _isScanning = false;
  bool _uploadComplete = false;

  String? _fileName;
  String? _filePath;
  String _statusMessage = 'Select a document to upload';
  Color _statusColor = Colors.grey;

  // Extracted Data
  ExtractedDataModel? _extractedData;
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  DateTime? _selectedExpiryDate;

  @override
  void dispose() {
    _ocrService.dispose();
    _licenseNumberController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument({bool scan = false}) async {
    // 1. Check Storage Limit
    final subscriptionService = context.read<SubscriptionService>();
    final userLicenseService = context.read<UserLicenseService>();
    final currentCount = userLicenseService.userLicenses.length;
    final maxDocs = subscriptionService.currentTier.maxDocuments;

    if (currentCount >= maxDocs) {
      _showStorageFullDialog();
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'], // OCR supports images best
      );

      if (result != null) {
        setState(() {
          _isUploading = false;
          _uploadComplete = false;
          _extractedData = null;
          _statusMessage = 'Document Selected';
          _statusColor = Colors.blue;
          _fileName = result.files.single.name;
          _filePath = result.files.single.path;
        });

        if (scan && _filePath != null) {
          await _performOCR(File(_filePath!));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _performOCR(File imageFile) async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning with AI...';
      _statusColor = Colors.purple;
    });

    try {
      final data = await _ocrService.scanImage(imageFile);

      if (mounted) {
        setState(() {
          _extractedData = data;
          _isScanning = false;
          _statusMessage = data.hasData
              ? 'Data Extracted Successfully!'
              : 'Scan Complete (No clear data found)';
          _statusColor = data.hasData ? Colors.green : Colors.orange;

          // Auto-fill form
          if (data.licenseNumber != null) {
            _licenseNumberController.text = data.licenseNumber!;
          }
          if (data.expiryDate != null) {
            _selectedExpiryDate = data.expiryDate;
            _expiryDateController.text =
                DateFormat('dd/MM/yyyy').format(data.expiryDate!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Scan Failed: $e';
          _statusColor = Colors.red;
        });
      }
    }
  }

  Future<void> _saveToVault() async {
    if (_filePath == null || _fileName == null) return;

    // Validate Input
    if (_licenseNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter/verify License Number')),
      );
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _statusMessage = 'Uploading to Secure Cloud...';
      });

      // 1. Upload to Firebase Storage
      final downloadUrl = await _storageService.uploadDocument(
        filePath: _filePath!,
        fileName: _fileName!,
      );

      if (downloadUrl == null) throw Exception('Upload returned no URL');

      if (!mounted) return;

      // 2. Save Metadata to Firestore
      await context.read<UserLicenseService>().addUserLicense(
            licenseId: 'doc_${DateTime.now().millisecondsSinceEpoch}',
            licenseNumber: _licenseNumberController.text.trim(),
            issueDate: _extractedData?.issueDate ?? DateTime.now(),
            expiryDate: _selectedExpiryDate ??
                DateTime.now().add(const Duration(days: 365)),
            documentUrl: downloadUrl,
          );

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadComplete = true;
          _statusMessage = 'Upload Complete';
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document & Data Saved to Vault')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save document: $e')),
        );
        setState(() {
          _isUploading = false;
          _statusMessage = 'Upload Failed. Try again.';
          _statusColor = Colors.red;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Upload')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload Area
            InkWell(
              onTap: _isUploading || _isScanning
                  ? null
                  : () => _pickDocument(scan: true),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isScanning)
                      const CircularProgressIndicator(color: Colors.purple)
                    else
                      Icon(
                        _uploadComplete
                            ? Icons.check_circle
                            : (_extractedData != null
                                ? Icons.document_scanner
                                : Icons.add_a_photo_outlined),
                        size: 64,
                        color: _statusColor,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _fileName ?? 'Tap to Scan License',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                          color: _statusColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // AI Badge
            if (_extractedData != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI extracted data with ${(_extractedData!.confidence * 100).toInt()}% confidence',
                        style:
                            const TextStyle(color: Colors.purple, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Form Fields
            TextField(
              controller: _licenseNumberController,
              decoration: const InputDecoration(
                labelText: 'License Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expiryDateController,
              readOnly: true,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedExpiryDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2050),
                );
                if (picked != null) {
                  setState(() {
                    _selectedExpiryDate = picked;
                    _expiryDateController.text =
                        DateFormat('dd/MM/yyyy').format(picked);
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Expiry Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton.icon(
              onPressed: _isUploading || _isScanning ? null : _saveToVault,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isUploading ? 'Saving...' : 'Save to Vault'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStorageFullDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Storage Full'),
          ],
        ),
        content: const Text(
            'You have reached the document limit for your current plan.\n\nUpgrade to Protection or Business Shield for more storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SubscriptionUpgradeScreen()),
              );
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}
