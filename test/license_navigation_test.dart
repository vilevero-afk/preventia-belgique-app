import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preventia_belgique_app/main.dart';
import 'package:preventia_belgique_app/models/license_status.dart';
import 'package:preventia_belgique_app/screens/home_screen.dart';
import 'package:preventia_belgique_app/screens/license_screen.dart';
import 'package:preventia_belgique_app/services/app_config_service.dart';
import 'package:preventia_belgique_app/services/app_locale_controller.dart';
import 'package:preventia_belgique_app/services/license_service.dart';

LicenseStatus status({bool active = true, bool expired = false}) =>
    LicenseStatus.fromJson({
      'email': 'user@example.com',
      'license': {
        'isActive': active,
        'licenseType': 'primary',
        'billingCycle': 'monthly',
        'price': 79,
        'endDate': expired ? '2020-01-01' : '2099-01-01',
        'activatedDevices': 1,
        'maxDevices': 3,
        'monthlySimpleDocumentsLimit': 50,
        'monthlyRiskAnalysisLimit': 10,
      },
    });

class _LicenseService extends LicenseService {
  _LicenseService(this.status, {this.token});
  LicenseStatus status;
  LicenseStatus? nextStatus;
  String? token;
  int loginCalls = 0;
  int refreshCalls = 0;
  int logoutCalls = 0;

  @override
  Future<bool> hasActiveSession() async => token != null && status.isActive;
  @override
  Future<LicenseStatus?> getCachedLicenseStatus() async =>
      token == null ? null : status;
  @override
  Future<bool> getRememberMe() async => false;
  @override
  Future<String?> getSavedEmail() async => null;
  @override
  Future<String?> getAuthToken() async => token;
  @override
  Future<LicenseStatus?> getCurrentLicenseStatus({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      refreshCalls++;
      if (nextStatus != null) {
        status = nextStatus!;
        nextStatus = null;
      }
    }
    return token == null ? null : status;
  }

  @override
  Future<LicenseStatus> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    loginCalls++;
    token = 'test-session';
    return status;
  }

  @override
  Future<void> logoutThisDevice({bool localOnly = false}) async {
    logoutCalls++;
    token = null;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openApp(WidgetTester tester, _LicenseService service) async {
    final locale = AppLocaleController(AppConfigService());
    await locale.load();
    await tester.pumpWidget(
      PreventiaBelgiqueApp(localeController: locale, licenseService: service),
    );
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.enterText(find.byType(TextField).last, 'test-password');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'connexion active ouvre directement l’accueil sans écran licence',
    (tester) async {
      final service = _LicenseService(status());
      await openApp(tester, service);
      await login(tester);
      expect(service.loginCalls, 1);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LicenseScreen), findsNothing);
      expect(find.text('Licence active'), findsNothing);
      expect(find.text('Continuer vers l’application'), findsNothing);
      expect(
        Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
        isFalse,
      );
    },
  );

  testWidgets('session active au démarrage ouvre directement l’accueil', (
    tester,
  ) async {
    await openApp(tester, _LicenseService(status(), token: 'test'));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LicenseScreen), findsNothing);
  });

  testWidgets(
    'le menu donne accès aux quatre actions et aux détails de licence',
    (tester) async {
      await openApp(tester, _LicenseService(status(), token: 'test'));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      for (final item in [
        'Abonnement / Licence',
        'Actualiser la licence',
        'Gérer mon abonnement',
        'Déconnecter cet appareil',
      ]) {
        expect(find.text(item).hitTestable(), findsOneWidget);
      }
      await tester.tap(find.text('Abonnement / Licence'));
      await tester.pumpAndSettle();
      expect(find.byType(LicenseScreen), findsOneWidget);
      for (final field in [
        'Adresse e-mail',
        'Type de licence',
        'Cycle',
        'Prix',
        'Date d’expiration',
        'Appareils utilisés',
        'Documents simples',
        'Analyses de risques',
      ]) {
        expect(find.text(field), findsOneWidget);
      }
      expect(find.text('Continuer vers l’application'), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  for (final expired in [false, true]) {
    testWidgets(
      'connexion avec licence ${expired ? 'expirée' : 'inactive'} bloque l’accueil',
      (tester) async {
        await openApp(
          tester,
          _LicenseService(status(active: expired, expired: expired)),
        );
        await login(tester);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.byType(LicenseScreen), findsOneWidget);
        expect(
          find.text(expired ? 'Licence expirée' : 'Licence inactive'),
          findsWidgets,
        );
        expect(find.text('Continuer vers l’application'), findsNothing);
      },
    );
  }

  testWidgets('une session déjà connectée mais expirée reste bloquée', (
    tester,
  ) async {
    await openApp(
      tester,
      _LicenseService(status(expired: true), token: 'test'),
    );
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Licence expirée'), findsOneWidget);
  });

  testWidgets(
    'actualiser utilise la logique existante et bloque une licence devenue invalide',
    (tester) async {
      final service = _LicenseService(status(), token: 'test');
      await openApp(tester, service);
      service.nextStatus = status(active: false);
      await chooseMenu(tester, 'Actualiser la licence');
      expect(service.refreshCalls, greaterThanOrEqualTo(1));
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Licence inactive'), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(LicenseScreen))).canPop(),
        isFalse,
      );
      service.nextStatus = status();
      await tester.tap(find.text('Actualiser'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'déconnecter réutilise la confirmation et supprime l’accès par retour',
    (tester) async {
      final service = _LicenseService(status(), token: 'test');
      await openApp(tester, service);
      await chooseMenu(tester, 'Déconnecter cet appareil');
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Déconnecter cet appareil'),
      );
      await tester.pumpAndSettle();
      expect(service.logoutCalls, 1);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Se connecter'), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(LicenseScreen))).canPop(),
        isFalse,
      );
    },
  );
}
