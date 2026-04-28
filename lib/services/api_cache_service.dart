import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for caching API responses
class ApiCacheService {
  static const String _cachePrefix = 'api_cache_';

  /// Get cached data
  Future<Map<String, dynamic>?> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson == null) return null;

      final cacheData = jsonDecode(cachedJson) as Map<String, dynamic>;
      final expiryTime = DateTime.parse(cacheData['expiry'] as String);

      // Check if cache has expired
      if (DateTime.now().isAfter(expiryTime)) {
        await prefs.remove(cacheKey);
        return null;
      }

      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Cache read error: $e');
      return null;
    }
  }

  /// Set cached data with TTL
  Future<void> set(
    String key,
    Map<String, dynamic> data,
    Duration duration,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final expiryTime = DateTime.now().add(duration);

      final cacheData = {
        'data': data,
        'expiry': expiryTime.toIso8601String(),
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      debugPrint('✅ Cached: $key (expires: ${duration.inMinutes}m)');
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  /// Clear all cached data
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }

      debugPrint('🗑️ Cleared all API cache');
    } catch (e) {
      debugPrint('Cache clear error: $e');
    }
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      await prefs.remove(cacheKey);
    } catch (e) {
      debugPrint('Cache remove error: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, int>> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int totalCached = 0;
      int expiredCount = 0;

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          totalCached++;
          final cachedJson = prefs.getString(key);
          if (cachedJson != null) {
            final cacheData = jsonDecode(cachedJson) as Map<String, dynamic>;
            final expiryTime = DateTime.parse(cacheData['expiry'] as String);
            if (DateTime.now().isAfter(expiryTime)) {
              expiredCount++;
            }
          }
        }
      }

      return {
        'total': totalCached,
        'expired': expiredCount,
        'valid': totalCached - expiredCount,
      };
    } catch (e) {
      debugPrint('Cache stats error: $e');
      return {'total': 0, 'expired': 0, 'valid': 0};
    }
  }
}
