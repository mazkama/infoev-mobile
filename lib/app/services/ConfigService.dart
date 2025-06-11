import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;
  bool _isInMaintenanceMode = false;
  
  // Stream untuk konfigurasi
  Stream<DocumentSnapshot>? _configStream;
  StreamSubscription? _configSubscription;
  
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
      debugPrint('Initializing Config Service with Firestore...');
      
      // Fetch konfigurasi awal
      final docSnapshot = await _firestore
          .collection('config')
          .doc('app_config')
          .get();
          
      if (!docSnapshot.exists) {
        debugPrint('❌ Config document does not exist!');
        _isInMaintenanceMode = true;
        return false;
      }
      
      // Parse konfigurasi
      final data = docSnapshot.data() as Map<String, dynamic>;
      _updateConfigFromData(data);
      
      // Set up listener untuk perubahan real-time
      _configStream = _firestore
          .collection('config')
          .doc('app_config')
          .snapshots();
          
      _configSubscription = _configStream!.listen(
        (DocumentSnapshot snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;
            debugPrint('📢 Received real-time config update!');
            
            // Update nilai konfigurasi
            _updateConfigFromData(data);
            
            // Cek jika mode maintenance berubah
            if (_isInMaintenanceMode) {
              debugPrint('⚠️ Maintenance mode ENABLED in real-time update.');
              Get.offAllNamed('/maintenance');
            }
          }
        },
        onError: (error) {
          debugPrint('❌ Error in config stream: $error');
        }
      );

      // Validasi nilai yang dibutuhkan
      if (_devUrl.isEmpty || _baseUrl.isEmpty || _prodUrl.isEmpty) {
        debugPrint('❌ Required values missing. Entering maintenance mode.');
        _isInMaintenanceMode = true;
        return false;
      }

      if (_isInMaintenanceMode) {
        debugPrint('⚠️ Maintenance mode ENABLED from Firestore.');
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
  
  void _updateConfigFromData(Map<String, dynamic> data) {
    _devUrl = data['dev_url'] ?? '';
    _baseUrl = data['base_url'] ?? '';
    _prodUrl = data['prod_url'] ?? '';
    
    // Update maintenance mode
    bool previousMaintenanceMode = _isInMaintenanceMode;
    _isInMaintenanceMode = data['maintenance_mode'] ?? false;
    
    // Jika maintenance mode berubah dari false ke true,
    // navigasi ke halaman maintenance
    if (!previousMaintenanceMode && _isInMaintenanceMode) {
      Future.delayed(Duration(milliseconds: 500), () {
        debugPrint('⚠️ Navigating to maintenance page due to real-time update');
        Get.offAllNamed('/maintenance');
      });
    }
    
    // Log perubahan
    debugPrint('Config updated:');
    debugPrint('dev_url: $_devUrl');
    debugPrint('base_url: $_baseUrl');
    debugPrint('prod_url: $_prodUrl');
    debugPrint('maintenance_mode: $_isInMaintenanceMode');
  }

  Future<bool> refreshConfig() async {
    try {
      debugPrint('🔄 Refreshing Config...');
      
      // Fetch konfigurasi terbaru secara manual
      final docSnapshot = await _firestore
          .collection('config')
          .doc('app_config')
          .get();
          
      if (!docSnapshot.exists) {
        debugPrint('❌ Config document does not exist!');
        _isInMaintenanceMode = true;
        return false;
      }
      
      // Parse konfigurasi
      final data = docSnapshot.data() as Map<String, dynamic>;
      _updateConfigFromData(data);
      
      if (_devUrl.isEmpty || _baseUrl.isEmpty || _prodUrl.isEmpty) {
        debugPrint('❌ Missing required values after refresh. Entering maintenance mode.');
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
  
  void dispose() {
    _configSubscription?.cancel();
  }

  void debugConfig() {
    debugPrint('======== CONFIG DEBUG (FIRESTORE) ========');
    debugPrint('Status: ${_initialized ? 'INITIALIZED' : 'NOT INITIALIZED'}');
    debugPrint('Maintenance Mode: $_isInMaintenanceMode');
    debugPrint('Stream Active: ${_configSubscription != null}');

    debugPrint('--- PARAMETER VALUES ---');
    debugPrint('dev_url: $_devUrl');
    debugPrint('base_url: $_baseUrl');
    debugPrint('prod_url: $_prodUrl');
    debugPrint('maintenance_mode: $_isInMaintenanceMode');
    debugPrint('=========================================');
  }
}
