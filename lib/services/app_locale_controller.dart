import 'package:flutter/material.dart';

import 'app_config_service.dart';

class AppLocaleController extends ChangeNotifier {
  AppLocaleController(this._configService);

  final AppConfigService _configService;
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  Future<void> load() async {
    final code = await _configService.loadSelectedLocaleCode();
    _locale = Locale(_supportedCodeOrFrench(code));
  }

  Future<void> setLocaleCode(String code) async {
    final normalized = _supportedCodeOrFrench(code);
    if (_locale.languageCode == normalized) {
      await _configService.saveSelectedLocaleCode(normalized);
      return;
    }

    _locale = Locale(normalized);
    notifyListeners();
    await _configService.saveSelectedLocaleCode(normalized);
  }

  static String languageLabel(String code) {
    return switch (_supportedCodeOrFrench(code)) {
      'nl' => 'Nederlands',
      'en' => 'English',
      'de' => 'Deutsch',
      _ => 'Français',
    };
  }

  static String _supportedCodeOrFrench(String code) {
    return switch (code) {
      'fr' || 'nl' || 'en' || 'de' => code,
      _ => 'fr',
    };
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    required AppLocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope not found in widget tree.');
    return scope!.notifier!;
  }
}
