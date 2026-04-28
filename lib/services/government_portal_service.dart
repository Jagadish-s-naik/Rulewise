import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for fetching live data from government portals
/// Uses web scraping for portals without APIs
class GovernmentPortalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Government portal URLs
  static const String indiaCodeUrl = 'https://www.indiacode.nic.in';
  static const String eGazetteUrl = 'https://egazette.nic.in';
  static const String bbmpUrl = 'https://bbmp.gov.in';
  static const String bmcUrl = 'https://portal.mcgm.gov.in';
  static const String fssaiUrl = 'https://www.fssai.gov.in';
  static const String gstUrl = 'https://www.gst.gov.in';

  /// Fetch latest law updates from eGazette
  /// This should be run periodically (Cloud Function)
  Future<List<Map<String, dynamic>>> fetchGazetteUpdates() async {
    try {
      final response = await http.get(Uri.parse(eGazetteUrl));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final updates = <Map<String, dynamic>>[];

        // Parse gazette notifications
        // Note: Actual parsing logic depends on website structure
        final notifications = document.querySelectorAll('.notification-item');

        for (var notification in notifications) {
          final title = notification.querySelector('.title')?.text ?? '';
          final date = notification.querySelector('.date')?.text ?? '';
          final link =
              notification.querySelector('a')?.attributes['href'] ?? '';

          if (title.isNotEmpty) {
            updates.add({
              'title': title,
              'date': date,
              'source_url': '$eGazetteUrl$link',
              'source': 'eGazette',
              'fetched_at': FieldValue.serverTimestamp(),
            });
          }
        }

        return updates;
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching gazette updates: $e');
      return [];
    }
  }

  /// Fetch FSSAI fee updates
  Future<Map<String, dynamic>?> fetchFSSAIFees() async {
    try {
      final response = await http.get(Uri.parse('$fssaiUrl/licensing'));

      if (response.statusCode == 200) {
        // Parse fee structure
        // This is a simplified example - actual implementation depends on website
        return {
          'basic_registration': 100,
          'state_license': 2000,
          'central_license': 7500,
          'last_updated': FieldValue.serverTimestamp(),
          'source_url': '$fssaiUrl/licensing',
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching FSSAI fees: $e');
      return null;
    }
  }

  /// Fetch municipal notifications for a specific city
  Future<List<Map<String, dynamic>>> fetchMunicipalNotifications(
    String city,
  ) async {
    String portalUrl;

    switch (city.toLowerCase()) {
      case 'bengaluru':
        portalUrl = bbmpUrl;
        break;
      case 'mumbai':
        portalUrl = bmcUrl;
        break;
      default:
        return [];
    }

    try {
      final response = await http.get(Uri.parse('$portalUrl/notifications'));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final notifications = <Map<String, dynamic>>[];

        // Parse notifications
        final items = document.querySelectorAll('.notification');

        for (var item in items) {
          final title = item.querySelector('.title')?.text ?? '';
          final date = item.querySelector('.date')?.text ?? '';

          notifications.add({
            'title': title,
            'date': date,
            'city': city,
            'source_url': portalUrl,
            'fetched_at': FieldValue.serverTimestamp(),
          });
        }

        return notifications;
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching municipal notifications: $e');
      return [];
    }
  }

  /// Verify and update license fee from official portal
  Future<int?> verifyLicenseFee({
    required String licenseType,
    required String city,
  }) async {
    // This would fetch live fee from the appropriate portal
    // For now, returns null to use cached Firestore data
    // In production, implement specific scrapers for each license type

    try {
      // Example: For trade license in Bengaluru
      if (licenseType == 'trade_license' && city == 'bengaluru') {
        final response = await http.get(
          Uri.parse('$bbmpUrl/trade-license-fees'),
        );

        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          // Parse fee from table/list
          final feeText = document.querySelector('.fee-amount')?.text ?? '';
          final fee = int.tryParse(feeText.replaceAll(RegExp(r'[^0-9]'), ''));
          return fee;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error verifying license fee: $e');
      return null;
    }
  }

  /// Store fetched updates in Firestore for admin review
  Future<void> storePendingUpdate(Map<String, dynamic> update) async {
    await _firestore.collection('pending_law_updates').add({
      ...update,
      'status': 'pending_review',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get GST threshold information
  Future<Map<String, dynamic>?> fetchGSTThresholds() async {
    try {
      // GST portal doesn't have a public API
      // This would need to be manually updated or scraped
      // For now, return verified thresholds
      return {
        'registration_threshold': 4000000, // ₹40 lakhs
        'composition_threshold': 15000000, // ₹1.5 crore
        'last_verified': DateTime.now(),
        'source_url': gstUrl,
      };
    } catch (e) {
      debugPrint('Error fetching GST thresholds: $e');
      return null;
    }
  }
}
