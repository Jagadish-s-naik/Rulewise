import '../config/api_config.dart';
import 'base_api_service.dart';

/// Model for GST rate information
class GSTRateInfo {
  final String hsn;
  final String description;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final String category;

  GSTRateInfo({
    required this.hsn,
    required this.description,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.category,
  });

  double get totalGST => cgst + sgst;

  factory GSTRateInfo.fromJson(Map<String, dynamic> json) {
    return GSTRateInfo(
      hsn: json['hsn'] ?? '',
      description: json['description'] ?? '',
      cgst: (json['cgst'] ?? 0).toDouble(),
      sgst: (json['sgst'] ?? 0).toDouble(),
      igst: (json['igst'] ?? 0).toDouble(),
      cess: (json['cess'] ?? 0).toDouble(),
      category: json['category'] ?? '',
    );
  }
}

/// Model for tax calculation
class TaxCalculation {
  final double baseAmount;
  final double taxAmount;
  final double totalAmount;
  final Map<String, double> breakdown;

  TaxCalculation({
    required this.baseAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.breakdown,
  });

  factory TaxCalculation.fromJson(Map<String, dynamic> json) {
    return TaxCalculation(
      baseAmount: (json['base_amount'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      breakdown: Map<String, double>.from(json['breakdown'] ?? {}),
    );
  }
}

/// Service for Tax Data API (Paid Service)
class TaxDataService extends BaseApiService {
  TaxDataService()
      : super(
          baseUrl: ApiConfig.taxDataBaseUrl,
          defaultHeaders: {
            'apikey': ApiConfig.taxDataApiKey,
          },
        );

  /// Get GST rate for HSN code
  Future<GSTRateInfo?> getGSTRate(String hsnCode) async {
    if (!ApiConfig.enableTaxData || !ApiConfig.hasTaxDataKey) {
      return null;
    }

    try {
      final response = await get(
        '/gst-rates',
        queryParameters: {'hsn': hsnCode},
        useCache: true,
        cacheDuration:
            const Duration(days: 30), // GST rates change infrequently
      );

      return GSTRateInfo.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Calculate tax for given amount
  Future<TaxCalculation?> calculateTax({
    required double amount,
    required String taxType, // 'GST', 'INCOME_TAX', etc.
    Map<String, dynamic>? additionalParams,
  }) async {
    if (!ApiConfig.enableTaxData || !ApiConfig.hasTaxDataKey) {
      return null;
    }

    try {
      final queryParams = <String, dynamic>{
        'amount': amount,
        'tax_type': taxType,
      };

      if (additionalParams != null) {
        queryParams.addAll(additionalParams);
      }

      final response = await get(
        '/calculate',
        queryParameters: queryParams,
        useCache: false, // Don't cache calculations
      );

      return TaxCalculation.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get tax filing deadlines
  Future<List<Map<String, dynamic>>> getFilingDeadlines({
    required String taxType,
    required int year,
  }) async {
    if (!ApiConfig.enableTaxData || !ApiConfig.hasTaxDataKey) {
      return [];
    }

    try {
      final response = await get(
        '/filing-deadlines',
        queryParameters: {
          'tax_type': taxType,
          'year': year,
        },
        useCache: true,
        cacheDuration: const Duration(days: 90),
      );

      return List<Map<String, dynamic>>.from(response['deadlines'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Check if API is available
  static bool get isAvailable =>
      ApiConfig.enableTaxData && ApiConfig.hasTaxDataKey;
}
