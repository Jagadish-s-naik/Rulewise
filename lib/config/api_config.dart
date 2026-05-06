// Configuration centralized for security and compile-time injection
class ApiConfig {
  // Firebase Configuration (Injected via --dart-define)
  static const String firebaseWebApiKey =
      String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const String firebaseAndroidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const String firebaseWindowsApiKey =
      String.fromEnvironment('FIREBASE_WINDOWS_API_KEY');

  // Groq AI Configuration
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Razorpay Configuration
  static const String razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');
  static const bool enableRazorpayMock =
      bool.fromEnvironment('ENABLE_RAZORPAY_MOCK', defaultValue: true);

  // API Setu Configuration
  static const String apiSetuKey = String.fromEnvironment('API_SETU_KEY');
  static const String apiSetuBaseUrl =
      String.fromEnvironment('API_SETU_BASE_URL', defaultValue: 'https://apisetu.gov.in/api');
  static const bool enableApiSetu =
      bool.fromEnvironment('ENABLE_API_SETU', defaultValue: false);

  // Open Government India Configuration
  static const String openGovIndiaKey =
      String.fromEnvironment('OPEN_GOV_INDIA_KEY');
  static const String openGovIndiaBaseUrl =
      String.fromEnvironment('OPEN_GOV_INDIA_BASE_URL', defaultValue: 'https://api.data.gov.in');
  static const bool enableOpenGovIndia =
      bool.fromEnvironment('ENABLE_OPEN_GOV_INDIA', defaultValue: false);

  // Razorpay IFSC Configuration
  static const String razorpayIfscBaseUrl =
      String.fromEnvironment('RAZORPAY_IFSC_BASE_URL', defaultValue: 'https://ifsc.razorpay.com');

  // Mutual Fund API Configuration
  static const String mutualFundBaseUrl =
      String.fromEnvironment('MUTUAL_FUND_BASE_URL', defaultValue: 'https://api.mfapi.in');
  static const bool enableMutualFund =
      bool.fromEnvironment('ENABLE_MUTUAL_FUND', defaultValue: false);

  // Tax Data API Configuration
  static const String taxDataApiKey = String.fromEnvironment('TAX_DATA_API_KEY');
  static const String taxDataBaseUrl =
      String.fromEnvironment('TAX_DATA_BASE_URL', defaultValue: 'https://api.apilayer.com/tax_data');
  static const bool enableTaxData =
      bool.fromEnvironment('ENABLE_TAX_DATA', defaultValue: false);

  // VAT Validation API Configuration
  static const String vatValidationApiKey =
      String.fromEnvironment('VAT_VALIDATION_API_KEY');
  static const String vatValidationBaseUrl =
      String.fromEnvironment('VAT_VALIDATION_BASE_URL', defaultValue: 'https://vat.abstractapi.com/v1');
  static const bool enableVatValidation =
      bool.fromEnvironment('ENABLE_VAT_VALIDATION', defaultValue: false);


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
