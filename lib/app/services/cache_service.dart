import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CacheService {
  static const Duration defaultCacheDuration = Duration(hours: 12);
  static const Duration longCacheDuration = Duration(days: 1);
  static const Duration shortCacheDuration = Duration(hours: 6);

  // Cache keys
  static const String _keyNewNews = 'cache_new_news';
  static const String _keyPopularVehicles = 'cache_popular_vehicles';
  static const String _keyNewVehicles = 'cache_new_vehicles';
  static const String _keyBrandList = 'cache_brand_list';
  static const String _keyVehicleTypes = 'cache_vehicle_types';
  static const String _keyChargerStations = 'cache_charger_stations';
  static const String _keyUserFavorites = 'cache_user_favorites';

  // Generic cache save method
  static Future<void> saveToCache(
    String key,
    dynamic data, {
    Duration? duration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'expiry': DateTime.now()
            .add(duration ?? defaultCacheDuration)
            .toIso8601String(),
      };
      
      await prefs.setString(key, json.encode(cacheData));
      
      if (kDebugMode) {
        print('[CacheService] Saved data to cache: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CacheService] Error saving to cache: $e');
      }
    }
  }

  // Generic cache load method
  static Future<T?> loadFromCache<T>(
    String key,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);

      if (cached == null) return null;

      final cacheData = json.decode(cached);
      final expiryTime = DateTime.parse(cacheData['expiry']);

      // Check if cache is still valid
      if (DateTime.now().isAfter(expiryTime)) {
        await prefs.remove(key);
        if (kDebugMode) {
          print('[CacheService] Cache expired and removed: $key');
        }
        return null;
      }

      final data = cacheData['data'];
      if (kDebugMode) {
        print('[CacheService] Loaded data from cache: $key');
      }
      
      return fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('[CacheService] Error loading from cache: $e');
      }
      return null;
    }
  }

  // Load list from cache
  static Future<List<T>?> loadListFromCache<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);

      if (cached == null) return null;

      final cacheData = json.decode(cached);
      final expiryTime = DateTime.parse(cacheData['expiry']);

      // Check if cache is still valid
      if (DateTime.now().isAfter(expiryTime)) {
        await prefs.remove(key);
        if (kDebugMode) {
          print('[CacheService] Cache expired and removed: $key');
        }
        return null;
      }

      final data = cacheData['data'] as List;
      if (kDebugMode) {
        print('[CacheService] Loaded list from cache: $key (${data.length} items)');
      }
      
      return data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('[CacheService] Error loading list from cache: $e');
      }
      return null;
    }
  }

  // Check if cache exists and is valid
  static Future<bool> isCacheValid(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);

      if (cached == null) return false;

      final cacheData = json.decode(cached);
      final expiryTime = DateTime.parse(cacheData['expiry']);

      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      return false;
    }
  }

  // Clear specific cache
  static Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      if (kDebugMode) {
        print('[CacheService] Cleared cache: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CacheService] Error clearing cache: $e');
      }
    }
  }

  // Clear all cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_'));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      if (kDebugMode) {
        print('[CacheService] Cleared all cache (${keys.length} keys)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CacheService] Error clearing all cache: $e');
      }
    }
  }

  // Get cache size (approximate)
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_'));
      
      int totalSize = 0;
      int validCacheCount = 0;
      int expiredCacheCount = 0;

      for (final key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          totalSize += value.length;
          
          try {
            final cacheData = json.decode(value);
            final expiryTime = DateTime.parse(cacheData['expiry']);
            
            if (DateTime.now().isBefore(expiryTime)) {
              validCacheCount++;
            } else {
              expiredCacheCount++;
            }
          } catch (e) {
            expiredCacheCount++;
          }
        }
      }

      return {
        'totalKeys': keys.length,
        'validCacheCount': validCacheCount,
        'expiredCacheCount': expiredCacheCount,
        'approximateSize': totalSize,
        'approximateSizeKB': (totalSize / 1024).round(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('[CacheService] Error getting cache info: $e');
      }
      return {
        'totalKeys': 0,
        'validCacheCount': 0,
        'expiredCacheCount': 0,
        'approximateSize': 0,
        'approximateSizeKB': 0,
      };
    }
  }

  // Clean expired cache
  static Future<void> cleanExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_'));
      int cleanedCount = 0;

      for (final key in keys) {
        final cached = prefs.getString(key);
        if (cached != null) {
          try {
            final cacheData = json.decode(cached);
            final expiryTime = DateTime.parse(cacheData['expiry']);

            if (DateTime.now().isAfter(expiryTime)) {
              await prefs.remove(key);
              cleanedCount++;
            }
          } catch (e) {
            // If we can't parse the cache data, remove it
            await prefs.remove(key);
            cleanedCount++;
          }
        }
      }

      if (kDebugMode) {
        print('[CacheService] Cleaned $cleanedCount expired cache entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CacheService] Error cleaning expired cache: $e');
      }
    }
  }

  // Preload critical data
  static Future<void> preloadCriticalData() async {
    if (kDebugMode) {
      print('[CacheService] Starting critical data preload...');
    }

    // Check which critical data is missing and needs to be fetched
    final criticalCaches = [
      _keyPopularVehicles,
      _keyNewVehicles,
      _keyNewNews,
      _keyBrandList,
    ];

    for (final key in criticalCaches) {
      if (!(await isCacheValid(key))) {
        if (kDebugMode) {
          print('[CacheService] Critical cache missing: $key');
        }
        // Cache is invalid/missing for critical data
        // The respective controllers will handle fetching and caching
      }
    }
  }

  // Cache keys for easy access
  static const String newNewsKey = _keyNewNews; 
  static const String popularVehiclesKey = _keyPopularVehicles;
  static const String newVehiclesKey = _keyNewVehicles;
  static const String brandListKey = _keyBrandList;
  static const String vehicleTypesKey = _keyVehicleTypes;
  static const String chargerStationsKey = _keyChargerStations;
  static const String userFavoritesKey = _keyUserFavorites;
}
