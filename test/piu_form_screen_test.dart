import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preventia_belgique_app/l10n/generated/app_localizations.dart';
import 'package:preventia_belgique_app/models/document_form_data.dart';
import 'package:preventia_belgique_app/screens/piu_form_screen.dart';
import 'package:preventia_belgique_app/services/ai_document_service.dart';
import 'package:preventia_belgique_app/services/app_config_service.dart';
import 'package:preventia_belgique_app/services/app_locale_controller.dart';
import 'package:preventia_belgique_app/services/license_service.dart';

void main() {
  test('PIU payload contains its document type and default scenarios', () {
    final data = buildPiuFormData(
      textValues: const {'companyName': 'PreventIA', 'siteName': 'Bruxelles'},
      choiceValues: const {'visitors': 'Oui'},
      emergencyScenarios: piuDefaultScenarios,
      availablePlans: const {'Plan d’évacuation disponible'},
    );
    final payload = data.toJson();

    expect(payload['documentType'], piuDocumentType);
    expect(payload['emergencyScenarios'], isA<List<dynamic>>());
    expect(
      payload['emergencyScenarios'],
      contains('Intrusion dangereuse / AMOK'),
    );
    expect(payload['availablePlans'], ['Plan d’évacuation disponible']);
  });

  test(
    'existing AI service sends the PIU payload to generation endpoint',
    () async {
      Map<String, dynamic>? requestPayload;
      final service = AiDocumentService(
        licenseService: _PiuLicenseService(),
        client: MockClient((request) async {
          requestPayload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'success': true, 'document': '# Projet PIU'}),
            200,
          );
        }),
      );
      final data = buildPiuFormData(
        textValues: const {'companyName': 'PreventIA'},
        choiceValues: const {},
        emergencyScenarios: piuDefaultScenarios,
        availablePlans: const {},
      );

      await service.generateDocument(
        backendUrl: AppConfigService.defaultBackendUrl,
        data: data,
        languageCode: 'fr',
        languageLabel: 'Français',
      );

      expect(requestPayload?['documentType'], piuDocumentType);
      expect(
        (requestPayload?['formData']
            as Map<String, dynamic>)['emergencyScenarios'],
        contains('Accident corporel ou malaise'),
      );
    },
  );

  testWidgets('PIU screen exists and Generate uses the existing form data', (
    tester,
  ) async {
    DocumentFormData? generatedData;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PiuFormScreen(onGenerate: (data) async => generatedData = data),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan Interne d’Urgence — PIU'), findsOneWidget);
    expect(find.text('Étape 1 / 8'), findsOneWidget);
    expect(find.text('Identification du site'), findsOneWidget);
    expect(find.byType(Stepper), findsNothing);

    for (var step = 1; step < 8; step += 1) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Générer le PIU'));
    await tester.pumpAndSettle();

    expect(generatedData?.documentType, piuDocumentType);
    expect(
      generatedData?.extraFields['emergencyScenarios'],
      contains('Incendie'),
    );
  });

  testWidgets('PIU generation ignores a second click while pending', (
    tester,
  ) async {
    final pendingGeneration = Completer<void>();
    var generationCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PiuFormScreen(
          onGenerate: (_) async {
            generationCalls += 1;
            await pendingGeneration.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var step = 1; step < 8; step += 1) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    final generate = tester
        .widget<FilledButton>(find.byKey(const ValueKey('piu_generate')))
        .onPressed!;

    generate();
    generate();
    await tester.pump();
    await tester.pump();

    expect(generationCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    pendingGeneration.complete();
    await tester.pumpAndSettle();
    expect(generationCalls, 1);
  });

  testWidgets('PIU back and home controls leave without a dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppLocaleScope(
        controller: AppLocaleController(AppConfigService()),
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PiuFormScreen(),
                  ),
                ),
                child: const Text('Ouvrir le PIU'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir le PIU'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Ouvrir le PIU'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('Ouvrir le PIU'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler et revenir à l’accueil'));
    await tester.pumpAndSettle();
    expect(find.text('PreventIA Belgique'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Plan Interne d’Urgence — PIU'),
      400,
    );
    await tester.tap(find.text('Plan Interne d’Urgence — PIU'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Accueil'));
    await tester.pumpAndSettle();
    expect(find.text('PreventIA Belgique'), findsOneWidget);
  });
}

class _PiuLicenseService extends LicenseService {
  @override
  Future<String?> getLicenseKey() async => null;

  @override
  Future<String?> getAuthToken() async => null;

  @override
  Future<String> getOrCreateDeviceId() async => 'piu-test-device';
}
