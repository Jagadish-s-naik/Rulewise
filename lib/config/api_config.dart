import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // API Setu Configuration
  static String get apiSetuKey => dotenv.env['API_SETU_KEY'] ?? '';
  static String get apiSetuBaseUrl =>
      dotenv.env['API_SETU_BASE_URL'] ?? 'https://apisetu.gov.in/api';
  static bool get enableApiSetu =>
      dotenv.env['ENABLE_API_SETU']?.toLowerCase() == 'true';

  // Open Government India Configuration
  static String get openGovIndiaKey => dotenv.env['OPEN_GOV_INDIA_KEY'] ?? '';
  static String get openGovIndiaBaseUrl =>
      dotenv.env['OPEN_GOV_INDIA_BASE_URL'] ?? 'https://api.data.gov.in';
  static bool get enableOpenGovIndia =>
      dotenv.env['ENABLE_OPEN_GOV_INDIA']?.toLowerCase() == 'true';

  // Razorpay IFSC Configuration
  static String get razorpayIfscBaseUrl =>
      dotenv.env['RAZORPAY_IFSC_BASE_URL'] ?? 'https://ifsc.razorpay.com';

  // Mutual Fund API Configuration
  static String get mutualFundBaseUrl =>
      dotenv.env['MUTUAL_FUND_BASE_URL'] ?? 'https://api.mfapi.in';
  static bool get enableMutualFund =>
      dotenv.env['ENABLE_MUTUAL_FUND']?.toLowerCase() == 'true';

  // Tax Data API Configuration
  static String get taxDataApiKey => dotenv.env['TAX_DATA_API_KEY'] ?? '';
  static String get taxDataBaseUrl =>
      dotenv.env['TAX_DATA_BASE_URL'] ?? 'https://api.apilayer.com/tax_data';
  static bool get enableTaxData =>
      dotenv.env['ENABLE_TAX_DATA']?.toLowerCase() == 'true';

  // VAT Validation API Configuration
  static String get vatValidationApiKey =>
      dotenv.env['VAT_VALIDATION_API_KEY'] ?? '';
  static String get vatValidationBaseUrl =>
      dotenv.env['VAT_VALIDATION_BASE_URL'] ?? 'https://vat.abstractapi.com/v1';
  static bool get enableVatValidation =>
      dotenv.env['ENABLE_VAT_VALIDATION']?.toLowerCase() == 'true';

  // Validation helpers
  static bool get hasApiSetuKey => apiSetuKey.isNotEmpty;
  static bool get hasOpenGovIndiaKey => openGovIndiaKey.isNotEmpty;
  static bool get hasTaxDataKey => taxDataApiKey.isNotEmpty;
  static bool get hasVatValidationKey => vatValidationApiKey.isNotEmpty;

  // Check if any paid APIs are enabled
  static bool get hasPaidApisEnabled => enableTaxData || enableVatValidation;

  // Get list of enabled APIs
  static List<String> get enabledApis {
    final List<String> enabled = [];
    if (enableApiSetu) {
      enabled.add('API Setu');
    }
    if (enableOpenGovIndia) {
      enabled.add('Open Government India');
    }
    if (enableMutualFund) {
      enabled.add('Mutual Fund');
    }
    if (enableTaxData) {
      enabled.add('Tax Data');
    }
    if (enableVatValidation) {
      enabled.add('VAT Validation');
    }
    return enabled;
  }
}
