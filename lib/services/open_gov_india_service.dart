import '../config/api_config.dart';
import 'base_api_service.dart';

/// Model for regulatory update
class RegulatoryUpdate {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime publishedDate;
  final DateTime effectiveDate;
  final String source;
  final String? url;
  final List<String> affectedSectors;

  RegulatoryUpdate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.publishedDate,
    required this.effectiveDate,
    required this.source,
    this.url,
    required this.affectedSectors,
  });

  factory RegulatoryUpdate.fromJson(Map<String, dynamic> json) {
    return RegulatoryUpdate(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      publishedDate: DateTime.parse(json['published_date']),
      effectiveDate: DateTime.parse(json['effective_date']),
      source: json['source'] ?? '',
      url: json['url'],
      affectedSectors: List<String>.from(json['affected_sectors'] ?? []),
    );
  }
}

/// Model for license fee schedule
class LicenseFeeSchedule {
  final String licenseType;
  final String state;
  final double applicationFee;
  final double renewalFee;
  final double lateFee;
  final String currency;
  final DateTime lastUpdated;

  LicenseFeeSchedule({
    required this.licenseType,
    required this.state,
    required this.applicationFee,
    required this.renewalFee,
    required this.lateFee,
    this.currency = 'INR',
    required this.lastUpdated,
  });

  factory LicenseFeeSchedule.fromJson(Map<String, dynamic> json) {
    return LicenseFeeSchedule(
      licenseType: json['license_type'] ?? '',
      state: json['state'] ?? '',
      applicationFee: (json['application_fee'] ?? 0).toDouble(),
      renewalFee: (json['renewal_fee'] ?? 0).toDouble(),
      lateFee: (json['late_fee'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

/// Service for Open Government India API
class OpenGovIndiaService extends BaseApiService {
  OpenGovIndiaService()
      : super(
          baseUrl: ApiConfig.openGovIndiaBaseUrl,
          defaultHeaders: {
            'api-key': ApiConfig.openGovIndiaKey,
          },
        );

  /// Get regulatory updates
  Future<List<RegulatoryUpdate>> getRegulatoryUpdates({
    String? category,
    DateTime? since,
    int limit = 20,
  }) async {
    if (!ApiConfig.enableOpenGovIndia || !ApiConfig.hasOpenGovIndiaKey) {
      // Return empty list if API is not configured
      return [];
    }

    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };

      if (category != null) {
        queryParams['category'] = category;
      }

      if (since != null) {
        queryParams['since'] = since.toIso8601String();
      }

      final response = await get(
        '/regulatory-updates',
        queryParameters: queryParams,
        useCache: true,
        cacheDuration: const Duration(hours: 6),
      );

      final List<dynamic> updates = response['data'] ?? [];
      return updates.map((json) => RegulatoryUpdate.fromJson(json)).toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Get license fee schedule
  Future<LicenseFeeSchedule?> getLicenseFeeSchedule({
    required String licenseType,
    required String state,
  }) async {
    if (!ApiConfig.enableOpenGovIndia || !ApiConfig.hasOpenGovIndiaKey) {
      return null;
    }

    try {
      final response = await get(
        '/license-fees',
        queryParameters: {
          'license_type': licenseType,
          'state': state,
        },
        useCache: true,
        cacheDuration: const Duration(days: 30), // Fee schedules change rarely
      );

      return LicenseFeeSchedule.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get compliance deadlines
  Future<List<Map<String, dynamic>>> getComplianceDeadlines({
    required String licenseType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!ApiConfig.enableOpenGovIndia || !ApiConfig.hasOpenGovIndiaKey) {
      return [];
    }

    try {
      final queryParams = <String, dynamic>{
        'license_type': licenseType,
      };

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await get(
        '/compliance-deadlines',
        queryParameters: queryParams,
        useCache: true,
        cacheDuration: const Duration(hours: 12),
      );

      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Check if API is available
  static bool get isAvailable =>
      ApiConfig.enableOpenGovIndia && ApiConfig.hasOpenGovIndiaKey;
}
