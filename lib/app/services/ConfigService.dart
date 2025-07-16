import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  bool _initialized = false;
  bool _isInMaintenanceMode = false;

  // Timer untuk refresh berkala
  Timer? _configRefreshTimer;

  // Cache untuk nilai konfigurasi
  String _devUrl = '';
  String _baseUrl = '';
  String _prodUrl = '';

  // Getters
  bool get isInMaintenanceMode => _isInMaintenanceMode;
  String get devUrl => _devUrl;
  String get baseUrl => _baseUrl;
  String get prodUrl => _prodUrl;

  Future<bool> initialize() async {
    if (_initialized) return !_isInMaintenanceMode;

    try {
      debugPrint('Initializing Config Service with Firebase Remote Config...');

      // Set default values
      await _remoteConfig.setDefaults({
        'dev_url': 'https://infoev.mazkama.web.id/api',
        'base_url': 'https://infoev.mazkama.web.id', // Updated default value
        'prod_url':
            'https://infoev.mazkama.web.id/api', // Updated default value
        'maintenance_mode': false,
      });

      // For first launch, use development settings with no fetch interval
      // to ensure we get fresh values
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval:
              Duration.zero, // Force fresh fetch on first launch
        ),
      );

      // Two-step fetch and activate for better control
      debugPrint('📥 Fetching remote config on first launch...');
      await _remoteConfig.fetch();

      debugPrint('📤 Activating fetched config...');
      final bool updated = await _remoteConfig.activate();

      debugPrint(
        updated
            ? '📢 Remote config values updated during initialization'
            : 'ℹ️ Using cached or default config values',
      );

      // Parse configuration
      _updateConfigFromRemote();

      // Now reset to normal fetch settings for future updates
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );

      // Set up periodic refresh
      _configRefreshTimer = Timer.periodic(const Duration(minutes: 15), (
        _,
      ) async {
        debugPrint('🔄 Periodic config refresh...');
        bool updated = await _remoteConfig.fetchAndActivate();
        if (updated) {
          debugPrint('📢 Remote config updated from periodic refresh');
          _updateConfigFromRemote();
        }
      });

      // Validasi nilai yang dibutuhkan
      if (_devUrl.isEmpty || _baseUrl.isEmpty || _prodUrl.isEmpty) {
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
      debugPrint('❌ Exception during config initialization: $e');
      return false;
    }
  }

  void _updateConfigFromRemote() {
    bool previousMaintenanceMode = _isInMaintenanceMode;

    // Add detailed debugging for maintenance mode
    debugPrint(
      'Raw maintenance_mode value: ${_remoteConfig.getValue('maintenance_mode')}',
    );
    debugPrint(
      'maintenance_mode source: ${_remoteConfig.getValue('maintenance_mode').source}',
    );

    _devUrl = _remoteConfig.getString('dev_url');
    _baseUrl = _remoteConfig.getString('base_url');
    _prodUrl = _remoteConfig.getString('prod_url');
    _isInMaintenanceMode = _remoteConfig.getBool('maintenance_mode');

    // Jika maintenance mode berubah dari false ke true,
    // navigasi ke halaman maintenance
    if (!previousMaintenanceMode && _isInMaintenanceMode) {
      Future.delayed(const Duration(milliseconds: 500), () {
        debugPrint('⚠️ Navigating to maintenance page due to config update');
        Get.offAllNamed('/maintenance');
      });
    }

    // Log perubahan
    debugPrint('Remote Config updated:');
    debugPrint(
      'dev_url: $_devUrl (source: ${_remoteConfig.getValue('dev_url').source})',
    );
    debugPrint(
      'base_url: $_baseUrl (source: ${_remoteConfig.getValue('base_url').source})',
    );
    debugPrint(
      'prod_url: $_prodUrl (source: ${_remoteConfig.getValue('prod_url').source})',
    );
    debugPrint(
      'maintenance_mode: $_isInMaintenanceMode (source: ${_remoteConfig.getValue('maintenance_mode').source})',
    );
  }

  Future<bool> refreshConfig() async {
    try {
      debugPrint('🔄 Refreshing Config...');

      // Temporarily disable caching to force a fresh fetch
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: Duration.zero, // Force fetch
        ),
      );

      // Fetch konfigurasi terbaru secara manual (with separate steps for better debugging)
      debugPrint('📥 Fetching latest remote config...');
      await _remoteConfig.fetch();

      debugPrint('📤 Activating fetched config...');
      bool updated = await _remoteConfig.activate();

      if (updated) {
        debugPrint('📢 Remote config values updated');
      } else {
        debugPrint('ℹ️ No new config values fetched');
      }

      // Print raw values for debugging
      debugPrint(
        'Raw maintenance_mode value: ${_remoteConfig.getValue('maintenance_mode')}',
      );

      // Update nilai konfigurasi
      _updateConfigFromRemote();

      // Reset fetch interval to normal
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );

      if (_devUrl.isEmpty || _baseUrl.isEmpty || _prodUrl.isEmpty) {
        debugPrint(
          '❌ Missing required values after refresh. Entering maintenance mode.',
        );
        _isInMaintenanceMode = true;
        return false;
      }

      if (_isInMaintenanceMode) {
        debugPrint('⚠️ Maintenance mode ENABLED after refresh.');
        return false;
      }

      _initialized = true;
      debugPrint('✅ Config refreshed successfully: API = $_devUrl');

      // Restart aplikasi untuk menerapkan perubahan
      Future.delayed(const Duration(milliseconds: 500), () {
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

  void dispose() {
    _configRefreshTimer?.cancel();
  }

  void debugConfig() {
    debugPrint('======== CONFIG DEBUG (REMOTE CONFIG) ========');
    debugPrint('Status: ${_initialized ? 'INITIALIZED' : 'NOT INITIALIZED'}');
    debugPrint('Maintenance Mode: $_isInMaintenanceMode');
    debugPrint(
      'Auto Refresh: ${_configRefreshTimer != null ? 'ACTIVE' : 'INACTIVE'}',
    );

    debugPrint('--- PARAMETER VALUES ---');
    debugPrint('dev_url: $_devUrl');
    debugPrint('base_url: $_baseUrl');
    debugPrint('prod_url: $_prodUrl');
    debugPrint('maintenance_mode: $_isInMaintenanceMode');
    debugPrint('=========================================');
  }
}
