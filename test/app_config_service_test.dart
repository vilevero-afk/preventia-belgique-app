import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/services/app_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppConfigService backend URL', () {
    test('uses Render backend by default', () async {
      SharedPreferences.setMockInitialValues({});

      final settings = await AppConfigService().loadAiSettings();

      expect(settings.backendUrl, AppConfigService.defaultBackendUrl);
      expect(settings.disableLocalFallbackForAiTests, isFalse);
    });

    test('migrates local and Cloudflare URLs to Render backend', () async {
      for (final oldUrl in [
        'http://localhost:3000/api/generate-document',
        'http://127.0.0.1:3000/api/generate-document',
        'http://192.168.1.12:3000/api/generate-document',
        'https://abc.trycloudflare.com/api/generate-document',
      ]) {
        SharedPreferences.setMockInitialValues({'ai_backend_url': oldUrl});

        final settings = await AppConfigService().loadAiSettings();

        expect(settings.backendUrl, AppConfigService.defaultBackendUrl);
      }
    });

    test('keeps custom HTTPS backend URL', () async {
      const customUrl = 'https://backend.example.com/api/generate-document';
      SharedPreferences.setMockInitialValues({'ai_backend_url': customUrl});

      final settings = await AppConfigService().loadAiSettings();

      expect(settings.backendUrl, customUrl);
    });
  });
}
