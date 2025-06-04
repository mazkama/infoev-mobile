import 'package:flutter/material.dart';
import 'package:infoev/app/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Testing CacheService...');
  
  // Test basic cache functionality
  await testBasicCache();
  
  // Test cache expiration
  await testCacheExpiration();
  
  // Test cache statistics
  await testCacheStatistics();
  
  print('All tests completed!');
}

Future<void> testBasicCache() async {
  print('\n=== Testing Basic Cache ===');
  
  // Test saving and loading data
  final testData = {'id': 1, 'name': 'Test Vehicle', 'brand': 'Test Brand'};
  await CacheService.saveToCache('test_key', testData);
  
  final loadedData = await CacheService.loadFromCache('test_key');
  print('Saved data: $testData');
  print('Loaded data: $loadedData');
  
  // Test cache validity
  final isValid = await CacheService.isCacheValid('test_key');
  print('Cache is valid: $isValid');
}

Future<void> testCacheExpiration() async {
  print('\n=== Testing Cache Expiration ===');
  
  // Save data with short expiration
  await CacheService.saveToCache(
    'short_cache', 
    {'test': 'data'}, 
    duration: Duration(seconds: 1)
  );
  
  print('Saved short-lived cache');
  
  // Check validity immediately
  bool isValid = await CacheService.isCacheValid('short_cache');
  print('Cache valid immediately: $isValid');
  
  // Wait and check again
  await Future.delayed(Duration(seconds: 2));
  isValid = await CacheService.isCacheValid('short_cache');
  print('Cache valid after 2 seconds: $isValid');
}

Future<void> testCacheStatistics() async {
  print('\n=== Testing Cache Statistics ===');
  
  final stats = await CacheService.getCacheStatistics();
  print('Cache statistics: $stats');
  
  // Test cache cleanup
  await CacheService.cleanExpiredCache();
  print('Cleaned expired cache');
  
  final statsAfterCleanup = await CacheService.getCacheStatistics();
  print('Cache statistics after cleanup: $statsAfterCleanup');
}
