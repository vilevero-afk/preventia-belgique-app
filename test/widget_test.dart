import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/main.dart';
import 'package:preventia_belgique_app/screens/document_form_screen.dart';
import 'package:preventia_belgique_app/services/app_config_service.dart';
import 'package:preventia_belgique_app/services/app_locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('PreventIA home screen is displayed', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final localeController = AppLocaleController(AppConfigService());
    await localeController.load();

    await tester.pumpWidget(
      PreventiaBelgiqueApp(localeController: localeController),
    );

    expect(find.text('PreventIA Belgique'), findsOneWidget);
    expect(
      find.text('Assistant de prévention et bien-être au travail'),
      findsOneWidget,
    );
    expect(find.text('Nouveau document'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('Mentions et limites'), findsOneWidget);

    expect(find.text('0'), findsNothing);
  });

  testWidgets('Dutch complete example fills the form in Dutch', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'selected_locale': 'nl'});
    final localeController = AppLocaleController(AppConfigService());
    await localeController.load();

    await tester.pumpWidget(
      PreventiaBelgiqueApp(localeController: localeController),
    );

    await tester.tap(find.text('Nieuw document'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Algemene risicoanalyse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invullen met een volledig voorbeeld'));
    await tester.pumpAndSettle();

    expect(
      find.text('Gemeentebestuur van Verviers – Technische dienst'),
      findsOneWidget,
    );
    expect(
      find.text('Interne preventieadviseur – ontwerp aan te vullen'),
      findsOneWidget,
    );
  });

  test('complete examples share the same internal field keys', () {
    final french = getCompleteExampleData('fr');
    final dutch = getCompleteExampleData('nl');
    final english = getCompleteExampleData('en');
    final german = getCompleteExampleData('de');

    expect(english.keys.toSet(), french.keys.toSet());
    expect(german.keys.toSet(), french.keys.toSet());
    expect(dutch.keys.toSet(), french.keys.toSet());
    expect(english['youngWorkers'], 'Not communicated / to be checked.');
    expect(german['youngWorkers'], 'Nicht mitgeteilt / zu prüfen.');
  });

  testWidgets('English complete example fills the form in English', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'selected_locale': 'en'});
    final localeController = AppLocaleController(AppConfigService());
    await localeController.load();

    await tester.pumpWidget(
      PreventiaBelgiqueApp(localeController: localeController),
    );

    await tester.tap(find.text('New document'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('General risk assessment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fill with a complete example'));
    await tester.pumpAndSettle();

    expect(
      find.text('Municipal Administration of Verviers – Technical Department'),
      findsOneWidget,
    );
    expect(
      find.text('Internal prevention advisor – draft to be completed'),
      findsOneWidget,
    );
  });

  testWidgets('German complete example fills the form in German', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'selected_locale': 'de'});
    final localeController = AppLocaleController(AppConfigService());
    await localeController.load();

    await tester.pumpWidget(
      PreventiaBelgiqueApp(localeController: localeController),
    );

    await tester.tap(find.text('Neues Dokument'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allgemeine Risikoanalyse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mit vollständigem Beispiel ausfüllen'));
    await tester.pumpAndSettle();

    expect(
      find.text('Gemeindeverwaltung Verviers – Technischer Dienst'),
      findsOneWidget,
    );
    expect(
      find.text('Interner Präventionsberater – Entwurf zu vervollständigen'),
      findsOneWidget,
    );
  });
}
