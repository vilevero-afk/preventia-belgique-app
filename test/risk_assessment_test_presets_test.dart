import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/data/risk_assessment_test_presets.dart';
import 'package:preventia_belgique_app/l10n/generated/app_localizations.dart';
import 'package:preventia_belgique_app/models/document_type.dart';
import 'package:preventia_belgique_app/screens/document_form_screen.dart';
import 'package:preventia_belgique_app/services/preventia_company_project_service.dart';
import 'package:preventia_belgique_app/utils/risk_assessment_test_preset_filler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SPGE risk-assessment presets', () {
    const requiredDocumentTypes = [
      'Analyse de risques générale',
      'Analyse de risques incendie',
      'Analyse de risques — Installations électriques BT/HT',
      'Analyse de risques — Ascenseur',
      'Analyse de risques ergonomie / postes écran',
      'Analyse de risques manutention / archives',
      'Analyse de risques nettoyage / produits chimiques',
      'Analyse de risques entreprises extérieures',
      'Analyse de risques circulation interne / chutes',
      'Analyse de risques psychosociaux / accueil public',
    ];

    for (final documentType in requiredDocumentTypes) {
      test('provides common data for $documentType', () {
        final preset = getRiskAssessmentTestPreset(documentType);

        expect(preset['companyName'], 'SPGE');
        expect(preset['siteName'], 'Site administratif de Verviers');
        expect(preset['address'], 'Rue des Écoles 12');
        expect(preset['preventionAdvisor'], 'Vincent Legrand');
        expect(preset['siteContact'], 'Sophie Martin');
        expect(preset['riskProfile'], 'modéré');
        expect(preset['language'], 'fr');
        expect(preset['scenario'], isNotEmpty);
        expect(preset['existingMeasures'], isNotEmpty);
        expect(preset['pointsToCheck'], isNotEmpty);
        expect(preset['plannedMeasures'], isNotEmpty);
        expect(preset['paaPgpLinks'], isNotEmpty);
        expect(preset['diuLinks'], isNotEmpty);
        expect(preset['piuLinks'], isNotEmpty);
        expect(preset['additionalContext'], contains('SCÉNARIO TEST SPGE'));
        expect(preset['additionalContext'], contains('RISQUES IDENTIFIÉS'));
        expect(preset['additionalContext'], contains('PREUVES À OBTENIR'));
      });
    }

    test(
      'provides a distinct complete preset for every registered analysis',
      () {
        final scenarios = <String>{};
        for (final type in documentTypes.where((type) => type.isRiskAnalysis)) {
          final preset = getRiskAssessmentTestPreset(type.label);
          expect(preset['companyName'], 'SPGE', reason: type.label);
          expect(preset['siteName'], isNotEmpty, reason: type.label);
          for (final key in const [
            'scenario',
            'exposedPersons',
            'concernedAreas',
            'mainRisks',
            'existingMeasures',
            'pointsToCheck',
            'plannedMeasures',
            'priority',
            'responsible',
            'deadline',
            'evidenceToCollect',
            'paaPgpLinks',
            'diuLinks',
            'piuLinks',
          ]) {
            if (type.id == 'fire_risk_analysis' && key == 'mainRisks') {
              expect(preset['fireRisks'], isNotEmpty, reason: type.label);
            } else {
              expect(preset[key], isNotEmpty, reason: '${type.label}: $key');
            }
          }
          scenarios.add(preset['scenario'] as String);
        }
        expect(
          scenarios,
          hasLength(documentTypes.where((type) => type.isRiskAnalysis).length),
        );
      },
    );

    test('contains the specialized electrical and elevator data', () {
      final electrical = getRiskAssessmentTestPreset(
        'Analyse de risques — Installations électriques BT/HT',
      );
      final elevator = getRiskAssessmentTestPreset(
        'Analyse de risques — Ascenseur',
      );

      expect(electrical['analysisStage'], 'Exploitation');
      expect(electrical['hasMainLowVoltagePanel'], 'Oui');
      expect(
        electrical['additionalContext'],
        allOf(contains('PV RGIE'), contains('LIENS PIU')),
      );
      expect(elevator['owner'], 'SPGE');
      expect(elevator['personsCapacity'], '8 personnes');
      expect(
        elevator['additionalContext'],
        allOf(contains('Kone'), contains('communication bidirectionnelle')),
      );
    });

    test('detects document types by meaningful words and accents', () {
      expect(
        RiskAssessmentTestPresets.forDocumentType(
          'Contrôle des installations BASSE TENSION',
        )['scenario'],
        contains('armoires électriques'),
      );
      expect(
        RiskAssessmentTestPresets.forDocumentType(
          'Évaluation ASCENSEUR du bâtiment',
        )['scenario'],
        contains('ascenseur est utilisé quotidiennement'),
      );
      expect(
        RiskAssessmentTestPresets.forDocumentType(
          'Analyse de risques entreprises extérieures',
        )['scenario'],
        contains('Plusieurs entreprises interviennent'),
      );
    });
  });

  test('filler maps aliases and ignores missing preset fields', () {
    final controllers = {
      'companyController': TextEditingController(),
      'siteConcerned': TextEditingController(),
      'additionalInformation': TextEditingController(),
      'lifecycleStage': TextEditingController(),
      'documentReference': TextEditingController(text: 'AR-2026-001'),
      'unrelatedField': TextEditingController(text: 'Conserver'),
    };
    addTearDown(() {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    });

    fillRiskAssessmentControllers(
      controllers: controllers,
      preset: {
        'companyName': 'SPGE',
        'siteName': 'Site administratif de Verviers',
        'additionalContext': 'Contexte SPGE',
        'analysisStage': 'Exploitation.',
        'ignored': 'Sans contrôleur',
      },
    );

    expect(controllers['companyController']!.text, 'SPGE');
    expect(
      controllers['siteConcerned']!.text,
      'Site administratif de Verviers',
    );
    expect(controllers['additionalInformation']!.text, 'Contexte SPGE');
    expect(controllers['lifecycleStage']!.text, 'Exploitation.');
    expect(controllers['documentReference']!.text, 'AR-2026-001');
    expect(controllers['unrelatedField']!.text, 'Conserver');
  });

  test('filler maps every specialized electrical and elevator alias', () {
    final electricalControllers = {
      'lifecycleStage': TextEditingController(),
      'lowVoltageCabinetPresent': TextEditingController(),
      'mainLowVoltageSwitchboardPresent': TextEditingController(),
      'approvedBodyOpenRemarks': TextEditingController(),
      'additionalContext': TextEditingController(),
    };
    final elevatorControllers = {
      'personCapacity': TextEditingController(),
      'lastPeriodicInspectionDate': TextEditingController(),
      'modernizationWorkCompleted': TextEditingController(),
      'openWork': TextEditingController(),
      'additionalContext': TextEditingController(),
    };
    addTearDown(() {
      for (final controller in [
        ...electricalControllers.values,
        ...elevatorControllers.values,
      ]) {
        controller.dispose();
      }
    });

    fillRiskAssessmentControllers(
      controllers: electricalControllers,
      preset: RiskAssessmentTestPresets.forDocumentType(
        'Analyse de risques — Installations électriques BT/HT',
      ),
    );
    fillRiskAssessmentControllers(
      controllers: elevatorControllers,
      preset: RiskAssessmentTestPresets.forDocumentType(
        'Analyse de risques — Ascenseur',
      ),
    );

    expect(electricalControllers['lifecycleStage']!.text, 'Exploitation');
    expect(
      electricalControllers['mainLowVoltageSwitchboardPresent']!.text,
      'Oui',
    );
    expect(
      electricalControllers['additionalContext']!.text,
      contains('DONNÉES SPÉCIFIQUES INSTALLATIONS ÉLECTRIQUES BT/HT'),
    );
    expect(elevatorControllers['personCapacity']!.text, '8 personnes');
    expect(elevatorControllers['openWork']!.text, 'À vérifier');
    expect(
      elevatorControllers['additionalContext']!.text,
      contains('DONNÉES SPÉCIFIQUES ASCENSEUR'),
    );
  });

  testWidgets('fills the form and confirms before replacing existing data', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1200, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: DocumentFormScreen(documentType: 'Analyse de risques générale'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Remplir avec scénario test SPGE'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fill-spge-test-preset')));
    await tester.pump();
    expect(
      await PreventiaCompanyProjectService().getProjects(migrateLegacy: false),
      isEmpty,
    );
    expect(_fieldValue(tester, 'Nom de la société / entreprise'), 'SPGE');
    expect(
      _fieldValue(tester, 'Adresse complète du site'),
      'Rue des Écoles 12',
    );
    expect(_fieldValue(tester, 'Conseiller en prévention'), 'Vincent Legrand');
    expect(
      _fieldValue(tester, 'Personne de contact sur site'),
      'Sophie Martin',
    );
    expect(
      _fieldValue(tester, 'Site concerné'),
      'Site administratif de Verviers',
    );
    final renderedFields = tester
        .widgetList<TextFormField>(
          find.byType(TextFormField, skipOffstage: false),
        )
        .toList();
    // The document reference is generated independently and is intentionally
    // never overwritten by a test scenario.
    for (var index = 1; index < renderedFields.length; index++) {
      final field = renderedFields[index];
      expect(
        field.controller?.text.trim(),
        isNotEmpty,
        reason: 'Le champ disponible n°$index doit être prérempli.',
      );
    }

    await tester.tap(find.byKey(const ValueKey('fill-spge-test-preset')));
    await tester.pumpAndSettle();
    expect(
      find.text('Remplacer les données actuelles par le scénario test SPGE ?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'Nom de la société / entreprise'), 'SPGE');
  });

  testWidgets('blocks risk generation when companyName is missing', (
    tester,
  ) async {
    await _pumpRiskForm(tester);
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Veuillez compléter les informations générales obligatoires avant de générer l’analyse.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('blocks risk generation when address is missing', (tester) async {
    await _pumpRiskForm(tester);
    await tester.tap(find.byKey(const ValueKey('fill-spge-test-preset')));
    await tester.pumpAndSettle();
    await tester.enterText(_fieldFinder('Adresse complète du site'), '');
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Veuillez compléter les informations générales obligatoires avant de générer l’analyse.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('blocks risk generation when preventionAdvisor is missing', (
    tester,
  ) async {
    await _pumpRiskForm(tester);
    await tester.tap(find.byKey(const ValueKey('fill-spge-test-preset')));
    await tester.pumpAndSettle();
    await tester.enterText(_fieldFinder('Conseiller en prévention'), '');
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Veuillez compléter les informations générales obligatoires avant de générer l’analyse.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('blocks risk generation when riskProfile is missing', (
    tester,
  ) async {
    await _pumpRiskForm(tester);
    await tester.enterText(
      _fieldFinder('Nom de la société / entreprise'),
      'SPGE',
    );
    await tester.enterText(
      _fieldFinder('Site / bâtiment concerné'),
      'Site administratif de Verviers',
    );
    await tester.enterText(
      _fieldFinder('Adresse complète du site'),
      'Rue des Écoles 12',
    );
    await tester.enterText(_fieldFinder('Code postal'), '4800');
    await tester.enterText(_fieldFinder('Ville'), 'Verviers');
    await tester.enterText(
      _fieldFinder('Personne de contact sur site'),
      'Sophie Martin',
    );
    await tester.enterText(
      _fieldFinder('Conseiller en prévention'),
      'Vincent Legrand',
    );
    await tester.enterText(
      _fieldFinder('Activité du site'),
      'Bureaux administratifs',
    );
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('Veuillez sélectionner le profil de risque de l’entreprise.'),
      findsOneWidget,
    );
  });
}

String _fieldValue(WidgetTester tester, String label) {
  final values = tester
      .widgetList<TextFormField>(_fieldMatches(label))
      .map((field) => field.controller?.text ?? '')
      .toList();
  return values.firstWhere(
    (value) => value.trim().isNotEmpty,
    orElse: () => '',
  );
}

Finder _fieldMatches(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

Finder _fieldFinder(String label) => _fieldMatches(label).last;

Future<void> _tapGenerate(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
  final button = find
      .ancestor(
        of: find.text('Générer le projet de document'),
        matching: find.byType(FilledButton),
      )
      .first;
  await tester.ensureVisible(button);
  await tester.tap(button);
}

Future<void> _pumpRiskForm(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1200, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    const MaterialApp(
      locale: Locale('fr'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: DocumentFormScreen(documentType: 'Analyse de risques générale'),
    ),
  );
  await tester.pumpAndSettle();
}
