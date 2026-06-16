import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preventia_belgique_app/models/license_status.dart';
import 'package:preventia_belgique_app/services/license_service.dart';

void main() {
  group('LicenseService', () {
    test('generates the local deviceId only once', () async {
      final storage = _MemoryLicenseStorage();
      final service = LicenseService(storage: storage);

      final first = await service.getOrCreateDeviceId();
      final second = await service.getOrCreateDeviceId();

      expect(first, isNotEmpty);
      expect(second, first);
    });

    test('parses LicenseStatus from backend JSON', () {
      final status = LicenseStatus.fromJson({
        'license': {
          'plan': 'Entreprise',
          'companyName': 'PreventIA Test',
          'endDate': '2026-12-31T00:00:00.000Z',
          'maxDevices': 5,
          'activatedDevices': 2,
          'monthlySimpleDocumentsLimit': 100,
          'monthlyRiskAnalysisLimit': 20,
          'usedSimpleDocumentsThisMonth': 7,
          'usedRiskAnalysisThisMonth': 3,
          'allowedFeatures': ['risk_analysis', 'simple_documents'],
          'isActive': true,
        },
      });

      expect(status.plan, 'Entreprise');
      expect(status.companyName, 'PreventIA Test');
      expect(status.maxDevices, 5);
      expect(status.activatedDevices, 2);
      expect(status.monthlySimpleDocumentsLimit, 100);
      expect(status.monthlyRiskAnalysisLimit, 20);
      expect(status.usedSimpleDocumentsThisMonth, 7);
      expect(status.usedRiskAnalysisThisMonth, 3);
      expect(status.allowedFeatures, contains('risk_analysis'));
      expect(status.isActive, isTrue);
    });

    test(
      'activate sends device metadata and persists license status',
      () async {
        Uri? requestedUri;
        Map<String, dynamic>? payload;
        final storage = _MemoryLicenseStorage();
        await storage.write(key: 'license_device_id', value: 'device-test');
        final service = LicenseService(
          storage: storage,
          client: MockClient((request) async {
            requestedUri = request.url;
            payload = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'success': true,
                'license': {
                  'plan': 'Entreprise',
                  'companyName': 'PreventIA Test',
                  'endDate': '2026-12-31T00:00:00.000Z',
                  'maxDevices': 5,
                  'activatedDevices': 1,
                  'monthlySimpleDocumentsLimit': 100,
                  'monthlyRiskAnalysisLimit': 20,
                  'usedSimpleDocumentsThisMonth': 0,
                  'usedRiskAnalysisThisMonth': 0,
                  'allowedFeatures': ['simple_documents'],
                  'isActive': true,
                },
              }),
              200,
            );
          }),
        );

        final status = await service.activateLicense(' LIC-TEST-123456 ');

        expect(
          requestedUri,
          Uri.parse(
            'https://preventia-backend-gjhg.onrender.com/api/licenses/activate',
          ),
        );
        expect(payload?['licenseKey'], 'LIC-TEST-123456');
        expect(payload?['deviceId'], 'device-test');
        expect(payload?['deviceName'], isA<String>());
        expect(payload?['platform'], isA<String>());
        expect(payload?['appVersion'], isA<String>());
        expect(status.isActive, isTrue);
        expect(await storage.read(key: 'license_key'), 'LIC-TEST-123456');
        expect(await storage.read(key: 'license_cached_status'), isNotNull);
      },
    );

    test('activate throws backend error message on failed response', () async {
      final service = LicenseService(
        storage: _MemoryLicenseStorage(),
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({'success': false, 'error': 'Licence inconnue'}),
            200,
          );
        }),
      );

      expect(
        () => service.activateLicense('LIC-UNKNOWN'),
        throwsA(
          isA<LicenseException>().having(
            (error) => error.message,
            'message',
            'Licence inconnue',
          ),
        ),
      );
    });

    test('refresh status calls status endpoint and updates cache', () async {
      Uri? requestedUri;
      Map<String, dynamic>? payload;
      final storage = _MemoryLicenseStorage();
      await storage.write(key: 'license_key', value: 'LIC-TEST');
      await storage.write(key: 'license_device_id', value: 'device-test');
      final service = LicenseService(
        storage: storage,
        client: MockClient((request) async {
          requestedUri = request.url;
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'license': {'companyName': 'PreventIA Test', 'isActive': true},
            }),
            200,
          );
        }),
      );

      final status = await service.refreshLicenseStatus();

      expect(
        requestedUri,
        Uri.parse(
          'https://preventia-backend-gjhg.onrender.com/api/licenses/status',
        ),
      );
      expect(payload?['licenseKey'], 'LIC-TEST');
      expect(payload?['deviceId'], 'device-test');
      expect(status.companyName, 'PreventIA Test');
      expect(await storage.read(key: 'license_cached_status'), isNotNull);
    });

    test('deactivate calls backend and clears local license', () async {
      Uri? requestedUri;
      Map<String, dynamic>? payload;
      final storage = _MemoryLicenseStorage();
      await storage.write(key: 'license_key', value: 'LIC-TEST');
      await storage.write(key: 'license_device_id', value: 'device-test');
      await storage.write(key: 'license_cached_status', value: '{}');
      final service = LicenseService(
        storage: storage,
        client: MockClient((request) async {
          requestedUri = request.url;
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'success': true}), 200);
        }),
      );

      await service.deactivateThisDevice();

      expect(
        requestedUri,
        Uri.parse(
          'https://preventia-backend-gjhg.onrender.com/api/licenses/deactivate-device',
        ),
      );
      expect(payload?['licenseKey'], 'LIC-TEST');
      expect(payload?['deviceId'], 'device-test');
      expect(await storage.read(key: 'license_key'), isNull);
      expect(await storage.read(key: 'license_cached_status'), isNull);
    });

    test('maps macOS Keychain entitlement failures to a clear error', () async {
      final service = LicenseService(storage: _FailingLicenseStorage());

      expect(
        () => service.getLicenseKey(),
        throwsA(
          isA<LicenseException>().having(
            (error) => error.message,
            'message',
            'Le stockage sécurisé macOS n’est pas disponible. Vérifiez les entitlements Keychain.',
          ),
        ),
      );
    });

    test('validate-generation sends licenseKey and deviceId', () async {
      Map<String, dynamic>? payload;
      final storage = _MemoryLicenseStorage();
      await storage.write(key: 'license_key', value: 'LIC-TEST');
      await storage.write(key: 'license_device_id', value: 'device-test');
      final service = LicenseService(
        storage: storage,
        client: MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'success': true}), 200);
        }),
      );

      final allowed = await service.canGenerateDocument(
        'Analyse de risques générale',
      );

      expect(allowed, isTrue);
      expect(payload?['licenseKey'], 'LIC-TEST');
      expect(payload?['deviceId'], 'device-test');
      expect(payload?['documentType'], 'Analyse de risques générale');
    });

    test('login stores auth token, email and license status', () async {
      Uri? requestedUri;
      Map<String, dynamic>? payload;
      final storage = _MemoryLicenseStorage();
      await storage.write(key: 'deviceId', value: 'device-test');
      final service = LicenseService(
        storage: storage,
        client: MockClient((request) async {
          requestedUri = request.url;
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'authToken': 'token-test',
              'email': 'user@example.com',
              'license': {
                'licenseType': 'primary',
                'billingCycle': 'monthly',
                'price': 79,
                'isActive': true,
              },
            }),
            200,
          );
        }),
      );

      final status = await service.login(' user@example.com ', 'secret');

      expect(
        requestedUri,
        Uri.parse('https://preventia-backend-gjhg.onrender.com/api/auth/login'),
      );
      expect(payload?['email'], 'user@example.com');
      expect(payload?['password'], 'secret');
      expect(payload?['deviceId'], 'device-test');
      expect(status.email, 'user@example.com');
      expect(status.licenseType, 'primary');
      expect(status.billingCycle, 'monthly');
      expect(status.price, 79);
      expect(await storage.read(key: 'authToken'), 'token-test');
      expect(await storage.read(key: 'email'), 'user@example.com');
      expect(await storage.read(key: 'cachedLicenseStatus'), isNotNull);
    });

    test('validate-generation uses auth endpoint and bearer token', () async {
      Uri? requestedUri;
      Map<String, dynamic>? payload;
      String? authorization;
      final storage = _MemoryLicenseStorage();
      await storage.write(key: 'authToken', value: 'token-test');
      await storage.write(key: 'deviceId', value: 'device-test');
      final service = LicenseService(
        storage: storage,
        client: MockClient((request) async {
          requestedUri = request.url;
          authorization = request.headers['Authorization'];
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'allowed': true}), 200);
        }),
      );

      final allowed = await service.validateGeneration(
        'Analyse de risques générale',
      );

      expect(allowed, isTrue);
      expect(
        requestedUri,
        Uri.parse(
          'https://preventia-backend-gjhg.onrender.com/api/auth/validate-generation',
        ),
      );
      expect(authorization, 'Bearer token-test');
      expect(payload?['deviceId'], 'device-test');
      expect(payload?['documentType'], 'Analyse de risques générale');
    });
  });
}

class _FailingLicenseStorage implements LicenseStorage {
  @override
  Future<String?> read({required String key}) async {
    throw PlatformException(
      code: 'Unexpected security result code',
      message: "A required entitlement isn't present. Code: -34018",
    );
  }

  @override
  Future<void> write({required String key, required String value}) async {
    throw PlatformException(
      code: 'Unexpected security result code',
      message: "A required entitlement isn't present. Code: -34018",
    );
  }

  @override
  Future<void> delete({required String key}) async {
    throw PlatformException(
      code: 'Unexpected security result code',
      message: "A required entitlement isn't present. Code: -34018",
    );
  }
}

class _MemoryLicenseStorage implements LicenseStorage {
  final _values = <String, String>{};

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }
}
