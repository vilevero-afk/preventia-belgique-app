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
    await tester.tap(find.text('Créer l’analyse finale'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Complétez responsable, délai et preuve attendue pour les actions acceptées.',
      ),
      findsOneWidget,
    );
    expect(find.text('Exporter Word — analyse finale'), findsNothing);
  });
}
