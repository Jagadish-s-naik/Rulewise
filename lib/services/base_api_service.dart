import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/api_error_handler.dart';
import 'api_cache_service.dart';

/// Base class for all API services
/// Provides common functionality for HTTP requests, caching, and error handling
abstract class BaseApiService {
  final String baseUrl;
  final Map<String, String>? defaultHeaders;
  final ApiCacheService _cacheService = ApiCacheService();

  BaseApiService({
    required this.baseUrl,
    this.defaultHeaders,
  });

  /// GET request with caching support
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool useCache = true,
    Duration cacheDuration = const Duration(hours: 1),
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final cacheKey = uri.toString();

      // Check cache first
      if (useCache) {
        final cachedData = await _cacheService.get(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Cache hit for: $endpoint');
          return cachedData;
        }
      }

      debugPrint('🌐 GET: $uri');

      final response = await http
          .get(
            uri,
            headers: _mergeHeaders(headers),
          )
          .timeout(const Duration(seconds: 30));

      final data = _handleResponse(response);

      // Cache successful response
      if (useCache) {
        await _cacheService.set(cacheKey, data, cacheDuration);
      }

      return data;
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      debugPrint('🌐 POST: $uri');

      final response = await http
          .post(
            uri,
            headers: _mergeHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      debugPrint('🌐 PUT: $uri');

      final response = await http
          .put(
            uri,
            headers: _mergeHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParameters) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$baseUrl$path';

    if (queryParameters != null && queryParameters.isNotEmpty) {
      return Uri.parse(url).replace(
        queryParameters: queryParameters
            .map((key, value) => MapEntry(key, value.toString())),
      );
    }

    return Uri.parse(url);
  }

  /// Merge default headers with request-specific headers
  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    final merged = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (defaultHeaders != null) {
      merged.addAll(defaultHeaders!);
    }

    if (headers != null) {
      merged.addAll(headers);
    }

    return merged;
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('📡 Response: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }

      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ApiException(
          'Failed to parse response',
          statusCode: response.statusCode,
        );
      }
    } else {
      throw ApiException(
        'Request failed with status ${response.statusCode}',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  /// Clear cache for this service
  Future<void> clearCache() async {
    await _cacheService.clear();
  }
}
