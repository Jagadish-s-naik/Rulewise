import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/license_model.dart';
import '../models/user_license_model.dart';
import '../models/compliance_metrics.dart';
import '../models/risk_profile.dart';
import 'government_portal_service.dart';

class ReportGenerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GovernmentPortalService _portalService = GovernmentPortalService();

  /// Generate monthly compliance report for a user
  /// Includes LIVE government data verification
  /// Returns Map with 'firebase_url' and 'local_path'
  Future<Map<String, String?>> generateMonthlyReport({
    required String userId,
    required String userName,
    required String businessName,
    required String city,
    required String state,
    required List<LicenseModel> applicableLicenses,
    required List<UserLicenseModel> userLicenses,
    required ComplianceMetrics metrics,
    required RiskProfile riskProfile,
  }) async {
    try {
      final pdf = pw.Document();

      // Fetch LIVE government data for verification
      final liveGazetteUpdates = await _portalService.fetchGazetteUpdates();

      // Generate report pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            // Header
            _buildHeader(businessName, city, state),
            pw.SizedBox(height: 20),

            // Executive Summary
            _buildExecutiveSummary(metrics, riskProfile),
            pw.SizedBox(height: 20),

            // License Status Breakdown
            _buildLicenseStatus(metrics),
            pw.SizedBox(height: 20),

            // Missing Licenses with Fees
            _buildMissingLicenses(applicableLicenses, userLicenses),
            pw.SizedBox(height: 20),

            // Upcoming Renewals (90 days)
            _buildUpcomingRenewals(userLicenses),
            pw.SizedBox(height: 20),

            // Potential Penalties
            _buildPotentialPenalties(applicableLicenses, userLicenses),
            pw.SizedBox(height: 20),

            // Recent Law Updates (from live data)
            if (liveGazetteUpdates.isNotEmpty)
              _buildLawUpdates(liveGazetteUpdates),

            // Footer
            pw.SizedBox(height: 30),
            _buildFooter(),
          ],
        ),
      );

      // Save PDF to temporary file
      final output = await getTemporaryDirectory();
      final fileName =
          'RuleWise_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      debugPrint('📄 PDF generated in temp: ${file.path}');

      // Save to device storage FIRST (priority)
      final localPath = await _saveToDevice(file, fileName);
      debugPrint('💾 Local save result: $localPath');

      // Try to upload to Firebase Storage (optional, don't fail if it errors)
      String? downloadUrl;
      try {
        debugPrint('☁️ Attempting Firebase upload...');
        final storageRef = _storage.ref().child('reports/$userId/$fileName');
        await storageRef.putFile(file);
        downloadUrl = await storageRef.getDownloadURL();
        debugPrint('✅ Firebase upload successful: $downloadUrl');
      } catch (storageError) {
        debugPrint(
            '⚠️ Firebase upload failed (continuing anyway): $storageError');
        // Continue execution - local save is what matters
      }

      // Try to store report metadata in Firestore (optional)
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('reports')
            .add({
          'generated_at': FieldValue.serverTimestamp(),
          'period': DateTime.now().toIso8601String().substring(0, 7), // YYYY-MM
          'compliance_score': riskProfile.overallScore,
          'pdf_url': downloadUrl,
          'local_path': localPath,
          'metrics': {
            'total_required': metrics.totalRequired,
            'active': metrics.active,
            'expired': metrics.expired,
            'expiring_soon': metrics.expiringSoon,
            'not_acquired': metrics.notAcquired,
          },
        });
        debugPrint('✅ Report metadata saved to Firestore');
      } catch (firestoreError) {
        debugPrint(
            '⚠️ Firestore metadata save failed (continuing anyway): $firestoreError');
      }

      // Clean up temp file
      try {
        await file.delete();
        debugPrint('🗑️ Temp file cleaned up');
      } catch (e) {
        debugPrint('⚠️ Could not delete temp file: $e');
      }

      return {
        'firebase_url': downloadUrl,
        'local_path': localPath,
      };
    } catch (e) {
      debugPrint('Error generating report: $e');
      return {
        'firebase_url': null,
        'local_path': null,
      };
    }
  }

  pw.Widget _buildHeader(String businessName, String city, String state) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Monthly Compliance Health Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Business: $businessName'),
        pw.Text('Location: $city, $state'),
        pw.Text('Generated: ${DateTime.now().toString().substring(0, 10)}'),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildExecutiveSummary(
    ComplianceMetrics metrics,
    RiskProfile riskProfile,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Executive Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Overall Compliance Score:'),
            pw.Text(
              '${riskProfile.overallScore.round()}%',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: _getPdfColor(riskProfile.level),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Risk Level:'),
            pw.Text(
              _getRiskLabel(riskProfile.level),
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: _getPdfColor(riskProfile.level),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildLicenseStatus(ComplianceMetrics metrics) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'License Status Breakdown',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Status',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Count',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Total Required')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${metrics.totalRequired}')),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Active')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${metrics.active}')),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Expiring Soon')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${metrics.expiringSoon}')),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Expired')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${metrics.expired}')),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Not Acquired')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${metrics.notAcquired}')),
            ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMissingLicenses(
    List<LicenseModel> applicableLicenses,
    List<UserLicenseModel> userLicenses,
  ) {
    final userLicenseIds = userLicenses.map((ul) => ul.licenseId).toSet();
    final missingLicenses = applicableLicenses
        .where((license) => !userLicenseIds.contains(license.id))
        .toList();

    if (missingLicenses.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Missing Licenses (Action Required)',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...missingLicenses.map((license) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text('• ${license.name}')),
                  pw.Text('₹${license.fee}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            )),
      ],
    );
  }

  pw.Widget _buildUpcomingRenewals(List<UserLicenseModel> userLicenses) {
    final now = DateTime.now();
    final upcomingRenewals = userLicenses
        .where((ul) =>
            ul.expiryDate.isAfter(now) &&
            ul.expiryDate.difference(now).inDays <= 90)
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    if (upcomingRenewals.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Upcoming Renewals (Next 90 Days)',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...upcomingRenewals.map((ul) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text('• License #${ul.licenseNumber}')),
                  pw.Text(
                    'Due: ${ul.expiryDate.toString().substring(0, 10)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  pw.Widget _buildPotentialPenalties(
    List<LicenseModel> applicableLicenses,
    List<UserLicenseModel> userLicenses,
  ) {
    double totalPenalty = 0;
    final userLicenseMap = {for (var ul in userLicenses) ul.licenseId: ul};

    for (var license in applicableLicenses) {
      final userLicense = userLicenseMap[license.id];
      if (userLicense != null && userLicense.isExpired) {
        final monthsExpired =
            (DateTime.now().difference(userLicense.expiryDate).inDays / 30)
                .ceil();
        totalPenalty += license.penaltyPerMonth * monthsExpired;
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Potential Penalties',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Estimated Total:'),
            pw.Text(
              '₹${totalPenalty.toStringAsFixed(0)}',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: totalPenalty > 0 ? PdfColors.red : PdfColors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildLawUpdates(List<Map<String, dynamic>> updates) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent Law Updates',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...updates.take(5).map((update) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text('• ${update['title']}'),
            )),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.Text(
          'This report is generated based on official government notifications and verified compliance data.',
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'RuleWise - Compliance Protection Assistant',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  PdfColor _getPdfColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return PdfColors.green;
      case RiskLevel.warning:
        return PdfColors.orange;
      case RiskLevel.highRisk:
        return PdfColors.red;
    }
  }

  String _getRiskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return 'SAFE';
      case RiskLevel.warning:
        return 'WARNING';
      case RiskLevel.highRisk:
        return 'HIGH RISK';
    }
  }

  /// Save PDF to device storage (Downloads folder)
  Future<String?> _saveToDevice(File tempFile, String fileName) async {
    try {
      debugPrint('💾 Starting _saveToDevice for: $fileName');

      // Request storage permission
      if (Platform.isAndroid) {
        debugPrint('📱 Android detected, requesting storage permissions...');
        final status = await Permission.storage.request();
        debugPrint('📱 Storage permission status: $status');

        if (!status.isGranted) {
          // Try with manageExternalStorage for Android 11+
          debugPrint('📱 Trying manageExternalStorage permission...');
          final manageStatus = await Permission.manageExternalStorage.request();
          debugPrint(
              '📱 ManageExternalStorage permission status: $manageStatus');

          if (!manageStatus.isGranted) {
            debugPrint('❌ Storage permission denied');
            return null;
          }
        }
        debugPrint('✅ Storage permissions granted');
      }

      // Get appropriate directory based on platform
      Directory? directory;
      if (Platform.isAndroid) {
        // For Android, use Downloads directory
        debugPrint('📁 Creating Android Downloads directory...');
        directory = Directory('/storage/emulated/0/Download/RuleWise');
        if (!await directory.exists()) {
          debugPrint('📁 Directory does not exist, creating...');
          await directory.create(recursive: true);
          debugPrint('✅ Directory created: ${directory.path}');
        } else {
          debugPrint('✅ Directory already exists: ${directory.path}');
        }
      } else if (Platform.isIOS) {
        // For iOS, use Documents directory
        debugPrint('📁 Getting iOS Documents directory...');
        directory = await getApplicationDocumentsDirectory();
        debugPrint('✅ iOS directory: ${directory.path}');
      }

      if (directory == null) {
        debugPrint('❌ Could not get storage directory');
        return null;
      }

      // Copy file to permanent location
      final permanentPath = '${directory.path}/$fileName';
      debugPrint('📋 Copying file to: $permanentPath');
      await tempFile.copy(permanentPath);

      debugPrint('✅ PDF saved successfully to: $permanentPath');
      return permanentPath;
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving PDF to device: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
