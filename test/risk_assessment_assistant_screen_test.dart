import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preventia_belgique_app/screens/risk_assessment_assistant_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> createDraft(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RiskAssessmentAssistantScreen()),
    );
    await tester.enterText(find.byType(TextField).first, 'Autre sujet');
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Créer un brouillon d’analyse'));
    await tester.pumpAndSettle();
  }

  testWidgets('brouillon : trois boutons accessibles sans fermer un dialogue', (
    tester,
  ) async {
    await createDraft(tester);
    expect(find.byType(AlertDialog), findsNothing);
    for (final label in [
      'Exporter Word — brouillon',
      'Passer à la validation',
      'Sauvegarder dans le dossier société',
    ]) {
      expect(find.text(label).hitTestable(), findsOneWidget);
    }
    await tester.runAsync(() async {
      await tester.tap(find.text('Exporter Word — brouillon'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    // No native save dialog in widget tests: the wired button reports the reason.
    expect(find.textContaining('Export Word impossible :'), findsOneWidget);
  });

  testWidgets(
    'validation test complète les champs et permet la création finale',
    (tester) async {
      await createDraft(tester);
      await tester.tap(find.text('Passer à la validation'));
      await tester.pumpAndSettle();
      expect(find.text('Actions proposées'), findsOneWidget);
      expect(find.text('Créer l’analyse finale').hitTestable(), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Créer l’analyse finale'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Remplir validation test'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is TextFormField && w.initialValue == 'Service prévention',
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is TextFormField && w.initialValue == '3 mois',
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is TextFormField &&
              w.initialValue == 'Photo après correction ou preuve documentaire',
        ),
        findsWidgets,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Créer l’analyse finale'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Créer l’analyse finale'));
      await tester.pumpAndSettle();
      expect(find.text('Analyse finale créée'), findsOneWidget);
      expect(
        find.text('Exporter Word — analyse finale').hitTestable(),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      final finalText = prefs.getString(
        'risk_assessment_assistant_latest_final_markdown',
      )!;
      expect(finalText, contains('Analyse finale assistée de risques'));
      expect(finalText, contains('Service prévention'));
      expect(finalText, contains('3 mois'));
      expect(finalText, contains('Statut conseiller : Accepté'));
      expect(finalText, isNot(contains('PIU')));
      await tester.runAsync(() async {
        await tester.tap(find.text('Exporter Word — analyse finale'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('Export Word impossible :'), findsOneWidget);
    },
  );

  testWidgets(
    'scénario ergonomie visible puis Word final prêt sans validation implicite',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RiskAssessmentAssistantScreen()),
      );
      Future<void> enter(String label, String value) async {
        final field = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }

      await enter('Quel sujet voulez-vous analyser ?', 'Ergonomie poste écran');
      await enter('Entreprise', 'SPGE');
      await enter('Site', 'Verviers');
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Remplir automatiquement — test ergonomie rien n’est fait'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Questionnaire de base et scénario ergonomie remplis.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is TextFormField &&
              (w.initialValue ?? '').startsWith(
                'Postes administratifs sur écran du site administratif de Verviers',
              ),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is TextFormField &&
              (w.initialValue ?? '').startsWith(
                'Personnel administratif, agents d’accueil',
              ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DropdownButtonFormField<String> && w.initialValue == 'non',
        ),
        findsNWidgets(5),
      );
      expect(find.text('Photo : À prendre'), findsNWidgets(6));
      expect(find.text('a_verifier'), findsNothing);
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is TextFormField &&
              (w.initialValue ?? '').contains(
                'flexion ou extension prolongée de la nuque',
              ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Score : 36 — Niveau : moyen'), findsNWidgets(3));
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer un brouillon d’analyse'));
      await tester.pumpAndSettle();
      for (final label in [
        'Exporter Word — brouillon',
        'Sauvegarder dans le dossier société',
        'Remplir validation test',
        'Créer l’analyse finale',
      ]) {
        expect(find.text(label).hitTestable(), findsOneWidget);
      }
      await tester.tap(find.text('Remplir validation test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer l’analyse finale'));
      await tester.pumpAndSettle();
      expect(
        find.text('Exporter Word — analyse finale').hitTestable(),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(
        'risk_assessment_assistant_latest_final_markdown',
      )!;
      expect(text, contains('Entreprise : SPGE'));
      expect(text, contains('Site : Verviers'));
      expect(text, contains('Statut : Analyse finale à valider'));
      expect(text, contains('Cotation finale G/P/E : 3/3/4'));
      expect(text, contains('Plan d’action retenu'));
      expect(text, contains('Adapter la hauteur des écrans.'));
      expect(text, isNot(contains('Document validé par le conseiller')));
    },
  );

  testWidgets(
    'les quatre boutons du brouillon restent accessibles sur écran étroit',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await createDraft(tester);
      for (final label in [
        'Exporter Word — brouillon',
        'Sauvegarder dans le dossier société',
        'Remplir validation test',
        'Créer l’analyse finale',
      ]) {
        expect(find.text(label).hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('action acceptée incomplète explique le blocage', (tester) async {
    await createDraft(tester);
    await tester.tap(find.text('Passer à la validation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remplir validation test'));
    await tester.pumpAndSettle();
    final responsible = find
        .byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Responsable',
        )
        .first;
    await tester.ensureVisible(responsible);
    await tester.pumpAndSettle();
    await tester.enterText(responsible, '');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Créer l’analyse finale'),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.text(
        'Complétez responsable, délai et preuve attendue pour les actions acceptées.',
      ),
      findsOneWidget,
    );
    expect(find.text('Exporter Word — analyse finale'), findsNothing);
  });
}
