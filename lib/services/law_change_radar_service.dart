import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'government_portal_service.dart';
import 'open_gov_india_service.dart';

class LawChangeRadarService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GovernmentPortalService _portalService = GovernmentPortalService();
  final OpenGovIndiaService _openGovService = OpenGovIndiaService();

  List<Map<String, dynamic>> _lawUpdates = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get lawUpdates => _lawUpdates;
  bool get isLoading => _isLoading;

  /// Fetch law updates relevant to user's location and business
  Future<void> fetchRelevantUpdates({
    required String state,
    required String city,
    required String businessType,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch from Firestore (admin-approved updates)
      final firestoreUpdates = await _fetchFromFirestore(
        state: state,
        city: city,
        businessType: businessType,
      );

      _lawUpdates = List.from(firestoreUpdates);

      // Fetch from Open Gov India API if available
      if (OpenGovIndiaService.isAvailable) {
        try {
          final apiUpdates = await _fetchFromApi(category: businessType);
          _lawUpdates.addAll(apiUpdates);

          // Sort merged list by date
          _lawUpdates.sort((a, b) {
            final dateA =
                (a['published_date'] as Timestamp?)?.toDate() ?? DateTime.now();
            final dateB =
                (b['published_date'] as Timestamp?)?.toDate() ?? DateTime.now();
            return dateB.compareTo(dateA);
          });
        } catch (e) {
          debugPrint('Failed to fetch from Open Gov API: $e');
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching law updates: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch admin-approved law updates from Firestore
  Future<List<Map<String, dynamic>>> _fetchFromFirestore({
    required String state,
    required String city,
    required String businessType,
  }) async {
    debugPrint(
        '🔍 Fetching law updates for: state=$state, city=$city, businessType=$businessType');

    // Query all law_updates (seeded data doesn't have status field)
    final query = await _firestore
        .collection('law_updates')
        .orderBy('published_date', descending: true)
        .limit(50)
        .get();

    debugPrint('📊 Found ${query.docs.length} total law updates');

    final updates = query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();

    // Client-side filtering for state and business type
    final filtered = updates.where((update) {
      // State filter - check if states array contains user's state or "All India"
      final states = update['states'] as List?;
      if (states != null) {
        final statesLower =
            states.map((s) => s.toString().toLowerCase()).toList();
        if (!statesLower.contains(state.toLowerCase()) &&
            !statesLower.contains('all india')) {
          return false;
        }
      }

      // Business type filter
      final businessTypes = update['business_types'] as List?;
      if (businessTypes != null && !businessTypes.contains(businessType)) {
        return false;
      }

      return true;
    }).toList();

    debugPrint('✅ Filtered to ${filtered.length} relevant updates');
    return filtered;
  }

  /// Fetch updates from Open Gov India API
  Future<List<Map<String, dynamic>>> _fetchFromApi({String? category}) async {
    final updates = await _openGovService.getRegulatoryUpdates(
      category: category,
      limit: 10,
    );

    return updates
        .map((u) => {
              'id': 'api_${u.id}',
              'title': u.title,
              'summary': u.description,
              'source': u.source,
              'published_date': Timestamp.fromDate(u.publishedDate),
              'severity': 'medium', // Default
              'impact': 'Compliance Update',
              'url': u.url,
              'is_api_data': true,
            })
        .toList();
  }

  /// Background job: Scrape government portals for new updates
  /// This should be run as a Cloud Function periodically
  Future<void> scrapeAndStoreUpdates() async {
    try {
      // Scrape eGazette
      final gazetteUpdates = await _portalService.fetchGazetteUpdates();

      // Store as pending updates for admin review
      for (var update in gazetteUpdates) {
        await _firestore.collection('law_updates').add({
          ...update,
          'status': 'pending_review',
          'source': 'egazette_scraper',
          'created_at': FieldValue.serverTimestamp(),
          'state': _extractState(update['title']),
          'business_types': _extractBusinessTypes(update['title']),
        });
      }

      debugPrint('Scraped ${gazetteUpdates.length} updates for admin review');
    } catch (e) {
      debugPrint('Error scraping updates: $e');
    }
  }

  /// Admin function: Approve pending update
  Future<void> approveUpdate({
    required String updateId,
    required String state,
    String? city,
    required List<String> businessTypes,
    required DateTime effectiveDate,
  }) async {
    await _firestore.collection('law_updates').doc(updateId).update({
      'status': 'approved',
      'state': state,
      'city': city,
      'business_types': businessTypes,
      'effective_date': Timestamp.fromDate(effectiveDate),
      'approved_at': FieldValue.serverTimestamp(),
    });
  }

  /// Admin function: Reject pending update
  Future<void> rejectUpdate(String updateId, String reason) async {
    await _firestore.collection('law_updates').doc(updateId).update({
      'status': 'rejected',
      'rejection_reason': reason,
      'rejected_at': FieldValue.serverTimestamp(),
    });
  }

  /// Admin function: Manually add law update
  Future<void> addManualUpdate({
    required String title,
    required String description,
    required String state,
    String? city,
    required List<String> businessTypes,
    required DateTime effectiveDate,
    required String sourceUrl,
  }) async {
    await _firestore.collection('law_updates').add({
      'title': title,
      'description': description,
      'state': state,
      'city': city,
      'business_types': businessTypes,
      'effective_date': Timestamp.fromDate(effectiveDate),
      'source_url': sourceUrl,
      'status': 'approved',
      'source': 'manual_entry',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Stream law updates for real-time notifications
  Stream<List<Map<String, dynamic>>> watchUpdates({
    required String state,
    required String city,
    required String businessType,
  }) {
    return _firestore
        .collection('law_updates')
        .where('state', isEqualTo: state)
        .where('status', isEqualTo: 'approved')
        .where('effective_date', isGreaterThan: Timestamp.now())
        .orderBy('effective_date')
        .snapshots()
        .map((snapshot) {
      final updates = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Filter by city and business type
      return updates.where((update) {
        final updateCity = update['city'] as String?;
        if (updateCity != null && updateCity != city) {
          return false;
        }

        final businessTypes = update['business_types'] as List?;
        if (businessTypes != null && !businessTypes.contains(businessType)) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  /// Extract state from update title (basic NLP)
  String _extractState(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('karnataka')) return 'karnataka';
    if (lowerTitle.contains('maharashtra')) return 'maharashtra';
    if (lowerTitle.contains('delhi')) return 'delhi';

    return 'unknown';
  }

  /// Extract business types from update title (basic NLP)
  List<String> _extractBusinessTypes(String title) {
    final lowerTitle = title.toLowerCase();
    final types = <String>[];

    if (lowerTitle.contains('food') || lowerTitle.contains('fssai')) {
      types.add('food_beverage');
    }
    if (lowerTitle.contains('retail') || lowerTitle.contains('shop')) {
      types.add('retail_shop');
    }
    if (lowerTitle.contains('manufacturing') ||
        lowerTitle.contains('factory')) {
      types.add('manufacturing');
    }
    if (lowerTitle.contains('service')) {
      types.add('service_provider');
    }

    // If no specific type found, apply to all
    if (types.isEmpty) {
      types.addAll([
        'retail_shop',
        'food_beverage',
        'service_provider',
        'manufacturing',
      ]);
    }

    return types;
  }
}
