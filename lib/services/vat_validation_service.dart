import '../config/api_config.dart';
import 'base_api_service.dart';

/// Model for VAT validation response
class VATValidationResponse {
  final String vatNumber;
  final bool isValid;
  final String companyName;
  final String companyAddress;
  final String country;
  final String countryCode;
  final bool isActive;

  VATValidationResponse({
    required this.vatNumber,
    required this.isValid,
    required this.companyName,
    required this.companyAddress,
    required this.country,
    required this.countryCode,
    required this.isActive,
  });

  factory VATValidationResponse.fromJson(Map<String, dynamic> json) {
    return VATValidationResponse(
      vatNumber: json['vat_number'] ?? '',
      isValid: json['valid'] == true,
      companyName: json['company_name'] ?? '',
      companyAddress: json['company_address'] ?? '',
      country: json['country'] ?? '',
      countryCode: json['country_code'] ?? '',
      isActive: json['active'] == true,
    );
  }
}

/// Service for VAT Validation API (Paid Service)
class VATValidationService extends BaseApiService {
  VATValidationService()
      : super(
          baseUrl: ApiConfig.vatValidationBaseUrl,
          defaultHeaders: {
            'api_key': ApiConfig.vatValidationApiKey,
          },
        );

  /// Validate VAT/GST number
  Future<VATValidationResponse?> validateVAT(String vatNumber) async {
    if (!ApiConfig.enableVatValidation || !ApiConfig.hasVatValidationKey) {
      return null;
    }

    try {
      final response = await get(
        '/validate',
        queryParameters: {'vat_number': vatNumber},
        useCache: true,
        cacheDuration: const Duration(days: 7),
      );

      return VATValidationResponse.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Validate Indian GST number (wrapper for consistency)
  Future<VATValidationResponse?> validateGSTNumber(String gstNumber) async {
    return await validateVAT(gstNumber);
  }

  /// Verify vendor compliance status
  Future<bool> verifyVendorCompliance(String vatNumber) async {
    final result = await validateVAT(vatNumber);
    return result?.isValid == true && result?.isActive == true;
  }

  /// Check if API is available
  static bool get isAvailable =>
      ApiConfig.enableVatValidation && ApiConfig.hasVatValidationKey;
}
