import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/license_status.dart';
import 'app_config_service.dart';

abstract class LicenseStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class SecureLicenseStorage implements LicenseStorage {
  SecureLicenseStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _fallbackPrefix = 'debug_license_storage_';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (error) {
      if (!_isMacOsKeychainEntitlementError(error)) {
        rethrow;
      }
      if (!_canUseDebugMacOsFallback) {
        throw const LicenseException(_macOsKeychainEntitlementMessage);
      }
      debugPrint(
        'Secure storage unavailable on debug macOS, using SharedPreferences fallback for $key.',
      );
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString(_fallbackPrefix + key);
    }
  }

  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (error) {
      if (!_isMacOsKeychainEntitlementError(error)) {
        rethrow;
      }
      if (!_canUseDebugMacOsFallback) {
        throw const LicenseException(_macOsKeychainEntitlementMessage);
      }
      debugPrint(
        'Secure storage unavailable on debug macOS, using SharedPreferences fallback for $key.',
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_fallbackPrefix + key, value);
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (error) {
      if (!_isMacOsKeychainEntitlementError(error)) {
        rethrow;
      }
      if (!_canUseDebugMacOsFallback) {
        throw const LicenseException(_macOsKeychainEntitlementMessage);
      }
      debugPrint(
        'Secure storage unavailable on debug macOS, using SharedPreferences fallback for $key.',
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_fallbackPrefix + key);
    }
  }

  static bool get _canUseDebugMacOsFallback {
    return kDebugMode &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}

class LicenseException implements Exception {
  const LicenseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LicenseService {
  LicenseService({
    http.Client? client,
    LicenseStorage? storage,
    String? backendUrl,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? SecureLicenseStorage(),
       _backendUrl = backendUrl ?? AppConfigService.defaultBackendUrl;

  static const _licenseKeyStorageKey = 'license_key';
  static const _deviceIdStorageKey = 'license_device_id';
  static const _cachedStatusStorageKey = 'license_cached_status';
  static const _authTokenStorageKey = 'authToken';
  static const _emailStorageKey = 'email';
  static const _authDeviceIdStorageKey = 'deviceId';
  static const _authCachedStatusStorageKey = 'cachedLicenseStatus';

  final http.Client _client;
  final LicenseStorage _storage;
  final String _backendUrl;

  Future<String> getOrCreateDeviceId() async {
    final existing =
        await _readStorage(_authDeviceIdStorageKey) ??
        await _readStorage(_deviceIdStorageKey);
    if (existing != null && existing.trim().isNotEmpty) {
      await _writeStorage(_authDeviceIdStorageKey, existing.trim());
      return existing.trim();
    }
    final deviceId = const Uuid().v4();
    await _writeStorage(_authDeviceIdStorageKey, deviceId);
    await _writeStorage(_deviceIdStorageKey, deviceId);
    return deviceId;
  }

  Future<String?> getAuthToken() async {
    final value = await _readStorage(_authTokenStorageKey);
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<String?> getEmail() async {
    final value = await _readStorage(_emailStorageKey);
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<String?> getLicenseKey() async {
    final value = await _readStorage(_licenseKeyStorageKey);
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> saveLicenseKey(String key) {
    return _writeStorage(_licenseKeyStorageKey, key.trim());
  }

  Future<void> clearLicense() async {
    await _deleteStorage(_licenseKeyStorageKey);
    await _deleteStorage(_cachedStatusStorageKey);
  }

  Future<void> clearSession() async {
    await _deleteStorage(_authTokenStorageKey);
    await _deleteStorage(_emailStorageKey);
    await _deleteStorage(_authCachedStatusStorageKey);
  }

  Future<LicenseStatus> login(String email, String password) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const LicenseException('Connexion requise.');
    }
    final deviceId = await getOrCreateDeviceId();
    final decoded = await _postJson('/api/auth/login', {
      'email': normalizedEmail,
      'password': password,
      'deviceId': deviceId,
      'deviceName': _deviceName(),
      'platform': _platformName(),
      'appVersion': _appVersion(),
    });
    final token = _tokenFrom(decoded);
    if (token == null) {
      throw const LicenseException('Réponse de connexion invalide.');
    }
    await _writeStorage(_authTokenStorageKey, token);
    await _writeStorage(_emailStorageKey, normalizedEmail);
    final status = LicenseStatus.fromJson({
      ...decoded,
      'email': decoded['email'] ?? normalizedEmail,
    });
    await _cacheStatus(status);
    return status;
  }

  Future<LicenseStatus> activateLicense(String licenseKey) async {
    final normalizedKey = licenseKey.trim();
    if (normalizedKey.isEmpty) {
      throw const LicenseException('Clé de licence manquante.');
    }
    final deviceId = await getOrCreateDeviceId();
    final status = await _postForStatus('/api/licenses/activate', {
      'licenseKey': normalizedKey,
      'deviceId': deviceId,
      'deviceName': _deviceName(),
      'platform': _platformName(),
      'appVersion': _appVersion(),
    }, requireSuccess: true);
    await saveLicenseKey(normalizedKey);
    await _cacheStatus(status);
    return status;
  }

  Future<LicenseStatus> getLicenseStatus() async {
    final token = await getAuthToken();
    if (token != null) {
      return getCurrentLicenseStatus();
    }
    final licenseKey = await getLicenseKey();
    if (licenseKey == null) {
      return await _readCachedStatus() ?? LicenseStatus.inactive();
    }
    try {
      final status = await _postForStatus('/api/licenses/status', {
        'licenseKey': licenseKey,
        'deviceId': await getOrCreateDeviceId(),
      });
      await _cacheStatus(status);
      return status;
    } on Object catch (error) {
      debugPrint('License status unavailable: $error');
      return await _readCachedStatus() ?? LicenseStatus.inactive();
    }
  }

  Future<LicenseStatus> refreshLicenseStatus() async {
    final token = await getAuthToken();
    if (token != null) {
      return getCurrentLicenseStatus(forceRefresh: true);
    }
    final licenseKey = await getLicenseKey();
    if (licenseKey == null) {
      return LicenseStatus.inactive();
    }
    final status = await _postForStatus('/api/licenses/status', {
      'licenseKey': licenseKey,
      'deviceId': await getOrCreateDeviceId(),
    });
    await _cacheStatus(status);
    return status;
  }

  Future<void> deactivateThisDevice() async {
    await logoutThisDevice();
  }

  Future<void> logoutThisDevice() async {
    final token = await getAuthToken();
    if (token != null) {
      await _postJson('/api/auth/logout-device', {
        'deviceId': await getOrCreateDeviceId(),
      }, authToken: token);
      await clearSession();
      return;
    }
    final licenseKey = await getLicenseKey();
    if (licenseKey != null) {
      await _postJson('/api/licenses/deactivate-device', {
        'licenseKey': licenseKey,
        'deviceId': await getOrCreateDeviceId(),
      });
    }
    await clearLicense();
  }

  Future<LicenseStatus> getCurrentLicenseStatus({
    bool forceRefresh = false,
  }) async {
    final token = await getAuthToken();
    if (token == null) {
      if (forceRefresh) {
        return refreshLicenseStatus();
      }
      return getLicenseStatus();
    }
    if (!forceRefresh) {
      final cached = await _readCachedStatus();
      if (cached != null) {
        return cached;
      }
    }
    try {
      final decoded = await _getJson('/api/auth/me', authToken: token);
      final email = await getEmail();
      final status = LicenseStatus.fromJson({
        ...decoded,
        if (email != null) 'email': decoded['email'] ?? email,
      });
      await _cacheStatus(status);
      return status;
    } on Object catch (error) {
      debugPrint('License status unavailable: $error');
      return await _readCachedStatus() ?? LicenseStatus.inactive();
    }
  }

  Future<bool> canGenerateDocument(String documentType) {
    return validateGeneration(documentType);
  }

  Future<bool> validateGeneration(String documentType) async {
    final token = await getAuthToken();
    final licenseKey = await getLicenseKey();
    if (token == null && licenseKey == null) {
      return true;
    }
    try {
      final decoded = token != null
          ? await _postJson('/api/auth/validate-generation', {
              'deviceId': await getOrCreateDeviceId(),
              'documentType': documentType,
              'licenseKey': ?licenseKey,
            }, authToken: token)
          : await _postJson('/api/licenses/validate-generation', {
              'licenseKey': licenseKey,
              'deviceId': await getOrCreateDeviceId(),
              'documentType': documentType,
            });
      final allowed =
          decoded['allowed'] == true ||
          decoded['canGenerate'] == true ||
          decoded['success'] == true;
      if (!allowed) {
        throw LicenseException(
          _messageFrom(decoded) ??
              'Votre abonnement ne permet pas ce document.',
        );
      }
      if (decoded['license'] is Map<String, dynamic> ||
          decoded['status'] is Map<String, dynamic>) {
        await _cacheStatus(LicenseStatus.fromJson(decoded));
      }
      return true;
    } on LicenseException {
      rethrow;
    } on Object catch (error) {
      debugPrint('License generation validation unavailable: $error');
      return true;
    }
  }

  Future<LicenseStatus> _postForStatus(
    String path,
    Map<String, dynamic> payload, {
    bool requireSuccess = false,
  }) async {
    final decoded = await _postJson(path, payload);
    if (decoded['success'] == false) {
      throw LicenseException(_messageFrom(decoded) ?? 'Licence invalide.');
    }
    if (requireSuccess && decoded['success'] != true) {
      throw const LicenseException('Réponse licence invalide.');
    }
    return LicenseStatus.fromJson(decoded);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload, {
    String? authToken,
  }) async {
    final uri = _licenseUri(path);
    debugPrint('License endpoint called: $uri');
    debugPrint('License deviceId used: ${payload['deviceId'] ?? '-'}');
    if (payload['licenseKey'] is String) {
      debugPrint(
        'License key used: ${_maskedLicenseKey(payload['licenseKey'] as String)}',
      );
    }
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(payload),
    );
    debugPrint('License HTTP status code: ${response.statusCode}');
    debugPrint('License backend response body: ${response.body}');
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const LicenseException('Réponse licence invalide.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LicenseException(
        _messageFrom(decoded) ?? 'Service de licence indisponible.',
      );
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    required String authToken,
  }) async {
    final uri = _licenseUri(path);
    debugPrint('License endpoint called: $uri');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );
    debugPrint('License HTTP status code: ${response.statusCode}');
    debugPrint('License backend response body: ${response.body}');
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const LicenseException('Réponse licence invalide.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LicenseException(
        _messageFrom(decoded) ?? 'Service de licence indisponible.',
      );
    }
    return decoded;
  }

  Uri _licenseUri(String path) {
    final source = Uri.parse(_backendUrl.trim());
    return source.replace(path: path, query: null, fragment: null);
  }

  static String _deviceName() {
    return 'PreventIA ${_platformName()}';
  }

  static String _platformName() {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform.name;
  }

  static String _appVersion() {
    return const String.fromEnvironment('APP_VERSION', defaultValue: 'unknown');
  }

  static String _maskedLicenseKey(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 10) {
      final visibleLength = trimmed.length < 6 ? trimmed.length : 6;
      return '${trimmed.substring(0, visibleLength)}****';
    }
    return '${trimmed.substring(0, 6)}****${trimmed.substring(trimmed.length - 4)}';
  }

  Future<void> _cacheStatus(LicenseStatus status) {
    final encoded = jsonEncode(status.toJson());
    return Future.wait([
      _writeStorage(_cachedStatusStorageKey, encoded),
      _writeStorage(_authCachedStatusStorageKey, encoded),
    ]).then((_) {});
  }

  Future<LicenseStatus?> _readCachedStatus() async {
    final raw =
        await _readStorage(_authCachedStatusStorageKey) ??
        await _readStorage(_cachedStatusStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return LicenseStatus.fromJson(decoded);
    } on Object {
      return null;
    }
  }

  Future<String?> _readStorage(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (error) {
      final readableError = _readableStorageException(error);
      if (readableError != null) {
        throw readableError;
      }
      rethrow;
    }
  }

  Future<void> _writeStorage(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (error) {
      final readableError = _readableStorageException(error);
      if (readableError != null) {
        throw readableError;
      }
      rethrow;
    }
  }

  Future<void> _deleteStorage(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (error) {
      final readableError = _readableStorageException(error);
      if (readableError != null) {
        throw readableError;
      }
      rethrow;
    }
  }

  static LicenseException? _readableStorageException(PlatformException error) {
    if (_isMacOsKeychainEntitlementError(error)) {
      return const LicenseException(_macOsKeychainEntitlementMessage);
    }
    return null;
  }

  static String? _messageFrom(Map<String, dynamic> decoded) {
    final value = decoded['error'] ?? decoded['message'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is Map<String, dynamic>) {
      final message = value['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }

  static String? _tokenFrom(Map<String, dynamic> decoded) {
    final value =
        decoded['authToken'] ??
        decoded['token'] ??
        decoded['accessToken'] ??
        decoded['jwt'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}

const _macOsKeychainEntitlementMessage =
    'Le stockage sécurisé macOS n’est pas disponible. Vérifiez les entitlements Keychain.';

bool _isMacOsKeychainEntitlementError(PlatformException error) {
  final details = error.details?.toString() ?? '';
  final message = error.message ?? '';
  return error.code == '-34018' ||
      message.contains('-34018') ||
      details.contains('-34018');
}
