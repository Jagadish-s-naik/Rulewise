import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_license_service.dart';
import '../../models/user_license_model.dart';
import 'document_upload_screen.dart'; // Added import

class DocumentVaultScreen extends StatelessWidget {
  const DocumentVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title:
            const Text('Document Vault', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentUploadScreen()),
              );
            },
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<UserLicenseService>(
        builder: (context, service, _) {
          final licenses = service.userLicenses;

          if (licenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off_rounded,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No documents found',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => service.loadUserLicenses(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: licenses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final license = licenses[index];
                return _DocumentCard(license: license);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final UserLicenseModel license;

  const _DocumentCard({required this.license});

  @override
  Widget build(BuildContext context) {
    // Icons based on file type (mock logic for now, using PDF icon usually)
    const icon = Icons.picture_as_pdf_rounded;
    const color = Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  license.licenseName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  license.documentUrl != null
                      ? 'Uploaded on ${license.updatedAt.day}/${license.updatedAt.month}/${license.updatedAt.year}'
                      : 'No document uploaded',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          if (license.documentUrl != null)
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.blue),
              onPressed: () {
                // Pending: Implement download
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download started...')));
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.upload_rounded, color: Colors.orange),
              tooltip: 'Upload Document',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select file to upload...')));
              },
            ),
        ],
      ),
    );
  }
}
