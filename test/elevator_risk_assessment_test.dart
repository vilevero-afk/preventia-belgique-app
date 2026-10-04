import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/l10n/generated/app_localizations.dart';
import 'package:preventia_belgique_app/models/document_type.dart';
import 'package:preventia_belgique_app/screens/document_type_screen.dart';
import 'package:preventia_belgique_app/services/preventia_project_service.dart';
import 'package:preventia_belgique_app/services/preventia_risk_extractor.dart';

void main() {
  const documentType = 'Analyse de risques — Ascenseur';

  test('registers the exact backend document type as a risk analysis', () {
    final type = documentTypeByLabel(documentType);

    expect(type.id, 'elevator_risk_assessment');
    expect(type.label, documentType);
    expect(type.isRiskAnalysis, isTrue);
    expect(type.supportsActionSummary, isTrue);
    expect(
      PreventiaProjectService.subdirectoryForDocumentType(documentType),
      '01_Analyses_de_risques',
    );
  });

  testWidgets('opens the generic form with elevator fields and warning', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 3800));
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

    final button = find.text('Ascenseur');
    expect(button, findsOneWidget);
    expect(
      find.text(
        'Cabine, portes palières, gaine, cuvette, salle machines, SECT.',
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
        'vérifiée, complétée sur site et confrontée aux rapports SECT, contrôles '
        'périodiques, documents de maintenance et constats réels.',
      ),
      findsOneWidget,
    );

    final section = find.text('I. Ascenseur');
    expect(section, findsOneWidget);
    await tester.ensureVisible(section);
    await tester.tap(section);
    await tester.pumpAndSettle();
    expect(find.text('Propriétaire', skipOffstage: false), findsOneWidget);
    expect(find.text('SECT connu', skipOffstage: false), findsOneWidget);
    expect(
      find.text('Adresse de l’ascenseur', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text(
        'Type d’ascenseur : électrique / hydraulique / vis sans fin / autre',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.text('Rapport SECT disponible', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Commentaires / points d’attention', skipOffstage: false),
      findsOneWidget,
    );
  });

  test(
    'extracts elevator risks and prioritized actions for the local index',
    () {
      final extraction = extractProjectItemsFromRiskAssessment(
        markdown: '''
## 6. Analyse des risques principaux

| Danger / situation dangereuse | Personnes exposées | Situation à vérifier | Risque potentiel | Mesures existantes | Mesures complémentaires proposées | Gravité | Probabilité | Exposition | Priorité | Preuve à obtenir | Destination possible : PAA / PGP / DIU / PIU | Statut |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Défaut de verrouillage des portes palières | Utilisateurs | Verrouillage à vérifier | Chute dans la gaine | À vérifier | Contrôler le verrouillage | 4 | 2 | 3 | Haute | Rapport SECT | PAA / PGP / DIU | À valider |

## 15. Plan d’action priorisé

| N° | Action | Priorité | Responsable | Délai | Preuve | Destination PAA/PGP/DIU/PIU | Statut |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Vérifier les verrouillages portes | Haute | Gestionnaire | 30 jours | Rapport d’intervention | PAA / DIU | À valider |
''',
        documentType: documentType,
        documentId: 'AR-2026-ASC-1',
      );

      expect(extraction.riskItems, hasLength(1));
      expect(
        extraction.riskItems.single.riskTitle,
        'Défaut de verrouillage des portes palières',
      );
      expect(extraction.riskItems.single.linkedToDiu, isTrue);
      expect(extraction.actionItems, hasLength(1));
      expect(
        extraction.actionItems.single.action,
        'Vérifier les verrouillages portes',
      );
      expect(extraction.actionItems.single.status, 'à valider');
    },
  );
}
