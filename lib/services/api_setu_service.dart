import '../config/api_config.dart';
import 'base_api_service.dart';

/// Model for GST validation response
class GSTValidationResponse {
  final String gstin;
  final String legalName;
  final String tradeName;
  final String status;
  final String registrationDate;
  final String taxpayerType;
  final String constitutionOfBusiness;
  final String stateJurisdiction;
  final String centerJurisdiction;
  final String principalPlaceOfBusiness;
  final bool isValid;

  GSTValidationResponse({
    required this.gstin,
    required this.legalName,
    required this.tradeName,
    required this.status,
    required this.registrationDate,
    required this.taxpayerType,
    required this.constitutionOfBusiness,
    required this.stateJurisdiction,
    required this.centerJurisdiction,
    required this.principalPlaceOfBusiness,
    required this.isValid,
  });

  factory GSTValidationResponse.fromJson(Map<String, dynamic> json) {
    return GSTValidationResponse(
      gstin: json['gstin'] ?? '',
      legalName: json['legalName'] ?? '',
      tradeName: json['tradeName'] ?? '',
      status: json['status'] ?? '',
      registrationDate: json['registrationDate'] ?? '',
      taxpayerType: json['taxpayerType'] ?? '',
      constitutionOfBusiness: json['constitutionOfBusiness'] ?? '',
      stateJurisdiction: json['stateJurisdiction'] ?? '',
      centerJurisdiction: json['centerJurisdiction'] ?? '',
      principalPlaceOfBusiness: json['principalPlaceOfBusiness'] ?? '',
      isValid: json['status']?.toLowerCase() == 'active',
    );
  }
}

/// Model for PAN validation response
class PANValidationResponse {
  final String pan;
  final String name;
  final String category;
  final bool isValid;

  PANValidationResponse({
    required this.pan,
    required this.name,
    required this.category,
    required this.isValid,
  });

  factory PANValidationResponse.fromJson(Map<String, dynamic> json) {
    return PANValidationResponse(
      pan: json['pan'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      isValid: json['valid'] == true,
    );
  }
}

/// Service for API Setu integrations (Government APIs)
class ApiSetuService extends BaseApiService {
  ApiSetuService()
      : super(
          baseUrl: ApiConfig.apiSetuBaseUrl,
          defaultHeaders: {
            'X-API-Key': ApiConfig.apiSetuKey,
          },
        );

  /// Validate GST number
  Future<GSTValidationResponse?> validateGST(String gstNumber) async {
    if (!ApiConfig.enableApiSetu || !ApiConfig.hasApiSetuKey) {
      throw Exception('API Setu is not configured');
    }

    try {
      // Validate format first
      if (!_isValidGSTFormat(gstNumber)) {
        throw Exception('Invalid GST number format');
      }

      final response = await get(
        '/gst/verify',
        queryParameters: {'gstin': gstNumber.toUpperCase()},
        useCache: true,
        cacheDuration: const Duration(days: 7),
      );

      return GSTValidationResponse.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Validate PAN number (requires user consent)
  Future<PANValidationResponse?> validatePAN(String panNumber) async {
    if (!ApiConfig.enableApiSetu || !ApiConfig.hasApiSetuKey) {
      throw Exception('API Setu is not configured');
    }

    try {
      // Validate format first
      if (!_isValidPANFormat(panNumber)) {
        throw Exception('Invalid PAN number format');
      }

      final response = await get(
        '/pan/verify',
        queryParameters: {'pan': panNumber.toUpperCase()},
        useCache: true,
        cacheDuration: const Duration(days: 30),
      );

      return PANValidationResponse.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Verify business registration
  Future<Map<String, dynamic>?> verifyBusinessRegistration(
    String registrationNumber,
  ) async {
    if (!ApiConfig.enableApiSetu || !ApiConfig.hasApiSetuKey) {
      throw Exception('API Setu is not configured');
    }

    try {
      final response = await get(
        '/business/verify',
        queryParameters: {'registration_number': registrationNumber},
        useCache: true,
        cacheDuration: const Duration(days: 7),
      );

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Validate GST format (15 characters)
  bool _isValidGSTFormat(String gst) {
    if (gst.length != 15) return false;
    final regex =
        RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    return regex.hasMatch(gst.toUpperCase());
  }

  /// Validate PAN format (10 characters)
  bool _isValidPANFormat(String pan) {
    if (pan.length != 10) return false;
    final regex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    return regex.hasMatch(pan.toUpperCase());
  }

  /// Check if API Setu is available
  static bool get isAvailable =>
      ApiConfig.enableApiSetu && ApiConfig.hasApiSetuKey;
}
