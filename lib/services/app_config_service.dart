import 'package:shared_preferences/shared_preferences.dart';

class AiGenerationSettings {
  const AiGenerationSettings({
    required this.backendUrl,
    required this.useAiIfAvailable,
    required this.disableLocalFallbackForAiTests,
  });

  final String backendUrl;
  final bool useAiIfAvailable;
  final bool disableLocalFallbackForAiTests;

  bool get hasBackendUrl => backendUrl.trim().isNotEmpty;
}

class AppConfigService {
  static const defaultBackendUrl =
      'https://preventia-backend-gjhg.onrender.com/api/generate-document';
  static const defaultBackendHealthUrl =
      'https://preventia-backend-gjhg.onrender.com/health';

  static const _backendUrlKey = 'ai_backend_url';
  static const _useAiIfAvailableKey = 'ai_use_if_available';
  static const _disableLocalFallbackForAiTestsKey =
      'ai_disable_local_fallback_for_tests';
  static const selectedLocaleKey = 'selected_locale';

  Future<AiGenerationSettings> loadAiSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final storedBackendUrl = preferences.getString(_backendUrlKey);
    final backendUrl = _effectiveBackendUrl(storedBackendUrl);
    if (backendUrl != storedBackendUrl) {
      await preferences.setString(_backendUrlKey, backendUrl);
    }

    return AiGenerationSettings(
      backendUrl: backendUrl,
      useAiIfAvailable: preferences.getBool(_useAiIfAvailableKey) ?? false,
      disableLocalFallbackForAiTests:
          preferences.getBool(_disableLocalFallbackForAiTestsKey) ?? false,
    );
  }

  Future<void> saveAiSettings(AiGenerationSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_backendUrlKey, settings.backendUrl.trim());
    await preferences.setBool(_useAiIfAvailableKey, settings.useAiIfAvailable);
    await preferences.setBool(
      _disableLocalFallbackForAiTestsKey,
      settings.disableLocalFallbackForAiTests,
    );
  }

  Future<void> resetBackendUrlToDefault() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_backendUrlKey, defaultBackendUrl);
  }

  Future<String> loadSelectedLocaleCode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(selectedLocaleKey) ?? 'fr';
  }

  Future<void> saveSelectedLocaleCode(String localeCode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(selectedLocaleKey, localeCode);
  }

  static bool shouldResetBackendUrl(String? backendUrl) {
    final trimmed = backendUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return true;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return true;
    }

    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1') {
      return true;
    }
    if (host.endsWith('trycloudflare.com')) {
      return true;
    }

    final parts = host.split('.');
    if (parts.length != 4) {
      return false;
    }

    final octets = parts.map(int.tryParse).toList();
    if (octets.any((octet) => octet == null || octet < 0 || octet > 255)) {
      return false;
    }

    final first = octets[0]!;
    final second = octets[1]!;
    return first == 10 ||
        first == 192 && second == 168 ||
        first == 172 && second >= 16 && second <= 31;
  }

  static String _effectiveBackendUrl(String? backendUrl) {
    if (shouldResetBackendUrl(backendUrl)) {
      return defaultBackendUrl;
    }
    return backendUrl!.trim();
  }
}
