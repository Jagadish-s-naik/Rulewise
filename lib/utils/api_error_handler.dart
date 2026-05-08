import 'package:http/http.dart' as http;

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  ApiException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status: $statusCode)';
    }
    return 'ApiException: $message';
  }
}

/// Centralized API error handling
class ApiErrorHandler {
  static ApiException handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }

    final errorString = error.toString().toLowerCase();
    
    // Check for network connectivity errors in a cross-platform way
    if (errorString.contains('socketexception') || 
        errorString.contains('failed host lookup') ||
        errorString.contains('connection failed')) {
      return ApiException(
        'No internet connection. Please check your network and try again.',
      );
    }

    if (error is http.ClientException) {
      return ApiException(
        'Network error. Please try again later.',
      );
    }

    if (error is FormatException) {
      return ApiException(
        'Invalid response format from server.',
      );
    }

    if (error.toString().contains('TimeoutException')) {
      return ApiException(
        'Request timed out. Please try again.',
      );
    }

    // Generic error
    return ApiException(
      'An unexpected error occurred: ${error.toString()}',
    );
  }

  /// Get user-friendly error message
  static String getUserMessage(ApiException exception) {
    if (exception.statusCode != null) {
      switch (exception.statusCode!) {
        case 400:
          return 'Invalid request. Please check your input.';
        case 401:
          return 'Authentication failed. Please check your API key.';
        case 403:
          return 'Access denied. You don\'t have permission for this operation.';
        case 404:
          return 'Resource not found.';
        case 429:
          return 'Too many requests. Please try again later.';
        case 500:
        case 502:
        case 503:
          return 'Server error. Please try again later.';
        default:
          return exception.message;
      }
    }

    return exception.message;
  }
}
