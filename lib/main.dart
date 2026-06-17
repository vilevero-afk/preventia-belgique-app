import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/generated/app_localizations.dart';
import 'screens/license_screen.dart';
import 'services/app_config_service.dart';
import 'services/app_locale_controller.dart';
import 'services/license_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = AppLocaleController(AppConfigService());
  await localeController.load();
  runApp(PreventiaBelgiqueApp(localeController: localeController));
}

class PreventiaBelgiqueApp extends StatelessWidget {
  PreventiaBelgiqueApp({
    required this.localeController,
    LicenseService? licenseService,
    super.key,
  }) : licenseService = licenseService ?? LicenseService();

  final AppLocaleController localeController;
  final LicenseService licenseService;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0F766E);
    const secondary = Color(0xFF123A5A);
    const background = Color(0xFFF4FAF8);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFE6F1EF),
    );

    return AppLocaleScope(
      controller: localeController,
      child: AnimatedBuilder(
        animation: localeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'PreventIA Belgique',
            debugShowCheckedModeBanner: false,
            locale: localeController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: colorScheme,
              scaffoldBackgroundColor: background,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: secondary,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: secondary,
                  side: const BorderSide(color: Color(0xFF9BBDB8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: secondary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC9DCD8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primary, width: 1.5),
                ),
                floatingLabelStyle: const TextStyle(color: primary),
              ),
            ),
            home: _StartupGate(licenseService: licenseService),
          );
        },
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.licenseService});

  final LicenseService licenseService;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool? _hasActiveSession;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasActiveSession = await widget.licenseService.hasActiveSession();
    if (!mounted) {
      return;
    }
    setState(() => _hasActiveSession = hasActiveSession);
  }

  void _openHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSession = _hasActiveSession;
    if (hasActiveSession == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (hasActiveSession) {
      return const HomeScreen();
    }
    return LicenseScreen(onContinue: _openHome);
  }
}
