import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class AppTokenService {
  static const _deviceIdKey = 'device_id';
  static const _appKeyKey = 'app_key';
  static const _appKeyExpiryKey = 'app_key_expiry';

  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final Uuid _uuid = Uuid();
  final String _backendUrl;

  AppTokenService(this._backendUrl);

  /// Get device id or create new one and save
  Future<String> getDeviceId() async {
    String? deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
    return deviceId;
  }

  /// Get app key if available
  Future<String?> getAppKey() async {
    return await _storage.read(key: _appKeyKey);
  }

  /// Save app key
  Future<void> saveAppKey(String appKey) async {
    await _storage.write(key: _appKeyKey, value: appKey);

    // Simpan waktu kedaluwarsa (7 hari dari sekarang)
    final expiryDate = DateTime.now().add(const Duration(days: 7));
    await _storage.write(
      key: _appKeyExpiryKey,
      value: expiryDate.toIso8601String(),
    );
  }

  /// Delete app key (e.g. logout or revoke)
  Future<void> deleteAppKey() async {
    await _storage.delete(key: _appKeyKey);
  }

  Future<bool> isAppKeyValid() async {
    final expiryString = await _storage.read(key: _appKeyExpiryKey);
    if (expiryString == null) return false;

    final expiryDate = DateTime.tryParse(expiryString);
    if (expiryDate == null) return false;

    return DateTime.now().isBefore(expiryDate);
  }

  /// Request new app key from backend (app-handshake)
  Future<String?> fetchNewAppKey({required String platform}) async {
    final deviceId = await getDeviceId();

    final response = await http.post(
      Uri.parse('$_backendUrl/app-handshake'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId, 'platform': platform}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final appKey = data['app_key'] as String;
      await saveAppKey(appKey);
      return appKey;
    } else {
      // Handle error, bisa throw atau return null
      return null;
    }
  }

  /// Initialize app key, get existing or fetch new
  Future<String?> initialize({required String platform}) async {
    String? appKey = await getAppKey();

    if (appKey == null) {
      // Belum punya token, fetch baru
      appKey = await fetchNewAppKey(platform: platform);
    } else {
      // Punya token, cek apakah masih valid
      final isValid = await isAppKeyValid();
      if (!isValid) {
        // Jika tidak valid, fetch token baru
        appKey = await fetchNewAppKey(platform: platform);
      }
    }

    return appKey;
  }
}
