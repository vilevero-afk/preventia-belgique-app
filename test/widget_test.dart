import 'package:flutter/material.dart';
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
    expect(find.text('Analyse de risques'), findsOneWidget);
    expect(find.text('Documents de prévention'), findsOneWidget);
    expect(find.text('Nouveau document'), findsNothing);
    expect(find.text('Plan annuel d’action'), findsOneWidget);
    expect(find.text('Plan global de prévention sur 5 ans'), findsOneWidget);
    expect(find.text('Rapport de visite sécurité'), findsOneWidget);
    expect(find.text('Fiche de poste'), findsOneWidget);
    expect(find.text('Fiche d’instruction sécurité'), findsOneWidget);
    expect(find.text('Rapport d’accident ou d’incident'), findsOneWidget);
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

    await tester.tap(find.text('Risicoanalyse'));
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

    await tester.tap(find.text('Risk assessment'));
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

    await tester.tap(find.text('Gefährdungsbeurteilung'));
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

  testWidgets('form section headers use readable styling and visible states', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'selected_locale': 'de'});
    final localeController = AppLocaleController(AppConfigService());
    await localeController.load();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      PreventiaBelgiqueApp(localeController: localeController),
    );

    await tester.tap(find.text('Gefährdungsbeurteilung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allgemeine Risikoanalyse'));
    await tester.pumpAndSettle();

    final sectionTitle = find.text('A. Identifikation des Dokuments');
    expect(sectionTitle, findsOneWidget);

    final titleText = tester.widget<Text>(sectionTitle);
    expect(titleText.softWrap, isTrue);
    expect(titleText.style?.color, const Color(0xFF143C3A));
    expect(titleText.style?.fontSize, 15.5);
    expect(titleText.style?.fontWeight, FontWeight.w700);

    Card sectionCard() {
      return tester.widget<Card>(
        find.ancestor(of: sectionTitle, matching: find.byType(Card)).first,
      );
    }

    expect(sectionCard().color, const Color(0xFFF1FAF7));

    await tester.tap(sectionTitle);
    await tester.pumpAndSettle();

    expect(sectionCard().color, Colors.white);
  });
}
