import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  late final FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;
  bool _isInMaintenanceMode = false;

  // Getter status maintenance
  bool get isInMaintenanceMode => _isInMaintenanceMode;

  // Getter konfigurasi remote
  String get apiUrl => _remoteConfig.getString('api_url');
  String get baseUrl => _remoteConfig.getString('base_url');
  String get prodUrl => _remoteConfig.getString('prod_url');

  Future<bool> initialize() async {
    if (_initialized) return !_isInMaintenanceMode;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: const Duration(seconds: 0), // Bisa diganti ke 1 jam untuk production
      ));

      await _remoteConfig.setDefaults({
        'api_url': '',
        'base_url': '',
        'prod_url': '',
        'maintenance_mode': false,
      });

      await _remoteConfig.fetchAndActivate().then((activated) {
        debugPrint('Remote Config fetched & activated: $activated');
      });

      // Ambil nilai maintenance setelah activation
      _isInMaintenanceMode = _remoteConfig.getBool('maintenance_mode');

      // Validasi nilai yang dibutuhkan
      if (_remoteConfig.getString('api_url').isEmpty ||
          _remoteConfig.getString('base_url').isEmpty ||
          _remoteConfig.getString('prod_url').isEmpty) {
        debugPrint('❌ Required values missing. Entering maintenance mode.');
        _isInMaintenanceMode = true;
        return false;
      }

      if (_isInMaintenanceMode) {
        debugPrint('⚠️ Maintenance mode ENABLED from Remote Config.');
        return false;
      }

      _initialized = true;
      debugPrint('✅ Config initialized successfully.');
      return true;
    } catch (e) {
      _isInMaintenanceMode = true;
      debugPrint('❌ Exception during Remote Config initialization: $e');
      return false;
    }
  }

  Future<bool> refreshConfig() async {
    try {
      debugPrint('🔄 Refreshing Remote Config...');
      await _remoteConfig.fetchAndActivate().then((activated) {
        debugPrint('Remote Config refreshed. Activated: $activated');
      });

      _isInMaintenanceMode = _remoteConfig.getBool('maintenance_mode');

      if (_remoteConfig.getString('api_url').isEmpty ||
          _remoteConfig.getString('base_url').isEmpty ||
          _remoteConfig.getString('prod_url').isEmpty) {
        debugPrint('❌ Missing required values after refresh. Entering maintenance mode.');
        _isInMaintenanceMode = true;
        return false;
      }

      if (_isInMaintenanceMode) {
        debugPrint('⚠️ Maintenance mode ENABLED after refresh.');
        return false;
      }

      _initialized = true;
      debugPrint('✅ Config refreshed successfully: API = $apiUrl');

      Future.delayed(Duration(milliseconds: 500), () {
        debugPrint('🚀 Restarting app...');
        Get.offAllNamed('/splash');
      });

      return true;
    } catch (e) {
      _isInMaintenanceMode = true;
      debugPrint('❌ Exception during config refresh: $e');
      return false;
    }
  }

  void debugConfig() {
    debugPrint('======== REMOTE CONFIG DEBUG ========');
    debugPrint('Status: ${_initialized ? 'INITIALIZED' : 'NOT INITIALIZED'}');
    debugPrint('Maintenance Mode: $_isInMaintenanceMode');

    try {
      debugPrint('Last Fetch Status: ${_remoteConfig.lastFetchStatus.name}');
      debugPrint('Last Fetch Time: ${_remoteConfig.lastFetchTime}');
      debugPrint('Fetch Timeout: ${_remoteConfig.settings.fetchTimeout}');
      debugPrint('Min Fetch Interval: ${_remoteConfig.settings.minimumFetchInterval}');

      debugPrint('--- PARAMETER VALUES ---');
      debugPrint('api_url: $apiUrl');
      debugPrint('base_url: $baseUrl');
      debugPrint('prod_url: $prodUrl');
      debugPrint('maintenance_mode: $_isInMaintenanceMode');

      final allParams = _remoteConfig.getAll();
      debugPrint('--- ALL PARAMETERS ---');
      allParams.forEach((key, value) {
        debugPrint('$key: ${value.asString()} (source: ${value.source.name})');
      });
    } catch (e) {
      debugPrint('❌ Error getting debug config: $e');
    }

    debugPrint('====================================');
  }
}
