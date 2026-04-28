import '../config/api_config.dart';
import 'base_api_service.dart';

/// Model for IFSC details
class IFSCDetails {
  final String ifsc;
  final String bank;
  final String branch;
  final String address;
  final String city;
  final String district;
  final String state;
  final String? contact;
  final bool rtgs;
  final bool neft;
  final bool imps;
  final bool upi;

  IFSCDetails({
    required this.ifsc,
    required this.bank,
    required this.branch,
    required this.address,
    required this.city,
    required this.district,
    required this.state,
    this.contact,
    required this.rtgs,
    required this.neft,
    required this.imps,
    required this.upi,
  });

  factory IFSCDetails.fromJson(Map<String, dynamic> json) {
    return IFSCDetails(
      ifsc: json['IFSC'] ?? '',
      bank: json['BANK'] ?? '',
      branch: json['BRANCH'] ?? '',
      address: json['ADDRESS'] ?? '',
      city: json['CITY'] ?? '',
      district: json['DISTRICT'] ?? '',
      state: json['STATE'] ?? '',
      contact: json['CONTACT'],
      rtgs: json['RTGS'] == true,
      neft: json['NEFT'] == true,
      imps: json['IMPS'] == true,
      upi: json['UPI'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'IFSC': ifsc,
      'BANK': bank,
      'BRANCH': branch,
      'ADDRESS': address,
      'CITY': city,
      'DISTRICT': district,
      'STATE': state,
      'CONTACT': contact,
      'RTGS': rtgs,
      'NEFT': neft,
      'IMPS': imps,
      'UPI': upi,
    };
  }
}

/// Service for validating IFSC codes using Razorpay API
class IFSCValidationService extends BaseApiService {
  IFSCValidationService()
      : super(
          baseUrl: ApiConfig.razorpayIfscBaseUrl,
        );

  /// Validate IFSC code and get bank details
  /// Returns null if IFSC is invalid
  Future<IFSCDetails?> validateIFSC(String ifscCode) async {
    try {
      // Validate format first
      if (!_isValidIFSCFormat(ifscCode)) {
        throw Exception('Invalid IFSC code format');
      }

      final response = await get(
        ifscCode.toUpperCase(),
        useCache: true,
        cacheDuration: const Duration(days: 30), // IFSC data rarely changes
      );

      return IFSCDetails.fromJson(response);
    } catch (e) {
      // IFSC not found or invalid
      return null;
    }
  }

  /// Validate IFSC format (11 characters: 4 letters + 7 alphanumeric)
  bool _isValidIFSCFormat(String ifsc) {
    if (ifsc.length != 11) return false;

    final regex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    return regex.hasMatch(ifsc.toUpperCase());
  }

  /// Get bank name from IFSC code
  Future<String?> getBankName(String ifscCode) async {
    final details = await validateIFSC(ifscCode);
    return details?.bank;
  }

  /// Get branch name from IFSC code
  Future<String?> getBranchName(String ifscCode) async {
    final details = await validateIFSC(ifscCode);
    return details?.branch;
  }

  /// Check if IFSC supports specific payment method
  Future<bool> supportsPaymentMethod(
    String ifscCode,
    String method, // 'RTGS', 'NEFT', 'IMPS', 'UPI'
  ) async {
    final details = await validateIFSC(ifscCode);
    if (details == null) return false;

    switch (method.toUpperCase()) {
      case 'RTGS':
        return details.rtgs;
      case 'NEFT':
        return details.neft;
      case 'IMPS':
        return details.imps;
      case 'UPI':
        return details.upi;
      default:
        return false;
    }
  }
}
