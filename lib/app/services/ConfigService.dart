import 'dart:async';

import 'package:flutter/foundation.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  bool _initialized = false;
  bool _isInMaintenanceMode = false;

  // Timer untuk refresh berkala (dummy, tidak digunakan manual)
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
      debugPrint('Initializing Config Service (manual mode, no Firebase)...');

      // Custom/manual assignment
      // _devUrl = 'https://infoev.id/api';
      // _baseUrl = 'https://infoev.id';
      // _prodUrl = 'https://infoev.id/api';
      _devUrl = 'https://infoev.mazkama.web.id/api';
      _baseUrl = 'https://infoev.mazkama.web.id';
      _prodUrl = 'https://infoev.mazkama.web.id/api';
      _isInMaintenanceMode = false;

      // Validasi nilai yang dibutuhkan
      if (_devUrl.isEmpty || _baseUrl.isEmpty || _prodUrl.isEmpty) {
        debugPrint('❌ Required values missing. Entering maintenance mode.');
        _isInMaintenanceMode = true;
        return false;
      }

      if (_isInMaintenanceMode) {
        debugPrint('⚠️ Maintenance mode ENABLED (manual config).');
        return false;
      }

      _initialized = true;
      debugPrint('✅ Config initialized successfully (manual mode).');
      return true;
    } catch (e) {
      _isInMaintenanceMode = true;
      debugPrint('❌ Exception during config initialization: $e');
      return false;
    }
  }

  // Dummy for compatibility, does nothing in manual mode
  Future<bool> refreshConfig() async {
    debugPrint('Manual config mode: refreshConfig() does nothing.');
    return true;
  }

  void dispose() {
    _configRefreshTimer?.cancel();
  }

  void debugConfig() {
    debugPrint('======== CONFIG DEBUG (MANUAL MODE) ========');
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