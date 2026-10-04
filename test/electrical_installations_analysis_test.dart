import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/l10n/generated/app_localizations.dart';
import 'package:preventia_belgique_app/models/document_type.dart';
import 'package:preventia_belgique_app/screens/document_type_screen.dart';

void main() {
  const documentType = 'Analyse de risques — Installations électriques BT/HT';

  test('registers the exact backend document type as a risk analysis', () {
    final type = documentTypeByLabel(documentType);

    expect(type.id, 'electrical_installations_risk_analysis');
    expect(type.label, documentType);
    expect(type.isRiskAnalysis, isTrue);
    expect(type.supportsActionSummary, isTrue);
  });

  testWidgets('opens the generic form with electrical fields and warning', (
    tester,
  ) async {
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
        home: DocumentTypeScreen(),
      ),
    );

    final button = find.text('Installations électriques BT/HT');
    expect(button, findsOneWidget);
    expect(
      find.text(
        'Basse tension, haute tension, armoires, cabines, consignation, BA4/BA5.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.ancestor(of: button, matching: find.byType(ListTile)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Cette analyse est une aide au conseiller en prévention. Elle doit être '
        'vérifiée, complétée sur site et confrontée aux rapports RGIE, contrôles '
        'périodiques et constats réels.',
      ),
      findsOneWidget,
    );

    final section = find.text('I. Installations électriques BT/HT');
    expect(section, findsOneWidget);
    await tester.tap(section);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Type d’installation : basse tension / haute tension / mixte',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.text('PV RGIE disponible', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Commentaires / points d’attention', skipOffstage: false),
      findsOneWidget,
    );
  });
}
