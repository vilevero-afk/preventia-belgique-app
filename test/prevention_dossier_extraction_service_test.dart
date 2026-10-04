import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/services/prevention_dossier_extraction_service.dart';

void main() {
  final service = PreventionDossierExtractionService();

  PreventionDossierExtractionResult extract({
    required String markdown,
    required String riskProfile,
  }) {
    return service.extractFromRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: markdown,
      formData: {
        'riskProfile': riskProfile,
        'responsible': 'SIPP',
        'evidenceToCollect': 'Preuve terrain',
      },
      sourceDocumentId: 'analysis-1',
      sourceReference: 'AR-1',
    );
  }

  test('riskProfile faible limite les candidats PIU', () {
    final result = extract(
      riskProfile: 'faible',
      markdown: '''
Incendie : vérifier évacuation et point de rassemblement.
TGBT : coupure électrique et accès cabine HT à organiser.
Ascenseur : personne bloquée et communication bidirectionnelle.
Malaise : procédure premiers secours à prévoir.
''',
    );

    expect(result.piuCandidates, isNotEmpty);
    expect(
      result.piuCandidates.every(
        (item) => !item['title'].toString().toLowerCase().contains('tgbt'),
      ),
      isTrue,
    );
  });

  test('riskProfile élevé extrait consignation maintenance et contrôles', () {
    final result = extract(
      riskProfile: 'élevé',
      markdown: '''
Mesure complémentaire : formaliser la consignation avant maintenance.
Action corrective : planifier les contrôles périodiques RGIE.
À mettre à jour : procédure de maintenance des machines.
''',
    );

    final actions = result.pgpCandidates
        .map((item) => item['mainMeasure'].toString().toLowerCase())
        .join('\n');
    expect(actions, contains('consignation'));
    expect(actions, contains('maintenance'));
    expect(actions, contains('contrôles'));
  });

  test('riskProfile Seveso ajoute point spécialisé sans inventer', () {
    final result = extract(
      riskProfile: 'Seveso seuil haut',
      markdown: 'Stockage administratif sans scénario décrit.',
    );

    expect(result.piuCandidates, isEmpty);
    expect(
      result.pointsToVerify.any(
        (item) => item.contains('obligations Seveso applicables'),
      ),
      isTrue,
    );
    expect(
      result.requiredValidations,
      contains('Validation spécialisée obligatoire.'),
    );
  });

  test('extraction PIU ne dépasse pas 40 items', () {
    final markdown = List.generate(
      80,
      (index) => 'Incendie zone $index : évacuation et accueil secours.',
    ).join('\n');
    final result = extract(riskProfile: 'très élevé', markdown: markdown);

    expect(result.piuCandidates.length, lessThanOrEqualTo(40));
  });

  test('extraction PGP/PAA ne dépasse pas 80 items', () {
    final markdown = List.generate(
      140,
      (index) => 'Mesure complémentaire : contrôle périodique zone $index.',
    ).join('\n');
    final result = extract(riskProfile: 'élevé', markdown: markdown);

    expect(result.pgpCandidates.length, lessThanOrEqualTo(80));
  });

  test('aucun item extrait n’est validé automatiquement', () {
    final result = extract(
      riskProfile: 'élevé',
      markdown: '''
Incendie : évacuation à organiser.
Mesure complémentaire : contrôle périodique à planifier.
DIU : contrainte future à documenter.
Preuve à obtenir : rapport de contrôle.
''',
    );
    final statuses = [
      ...result.piuCandidates,
      ...result.pgpCandidates,
      ...result.diuCandidates,
      ...result.evidenceItems,
      ...result.priorityActions,
    ].map((item) => item['status']);

    expect(statuses, everyElement('à valider'));
  });

  test('destination est parmi les valeurs autorisées', () {
    final result = extract(
      riskProfile: 'élevé',
      markdown: 'Mesure complémentaire : procédure incendie à mettre à jour.',
    );
    const allowed = {
      'Analyse de risques uniquement',
      'PIU',
      'PGP/PAA',
      'PIU + PGP/PAA',
      'DIU',
      'À vérifier avant intégration',
    };

    expect(
      result.priorityActions.map((item) => item['destination']),
      everyElement(isIn(allowed)),
    );
  });

  test('points à vérifier contiennent la mention prudente', () {
    final result = extract(
      riskProfile: 'inconnu / à déterminer',
      markdown: 'Rapport à obtenir : contrôle réglementaire à confirmer.',
    );

    expect(
      result.pointsToVerify,
      everyElement(
        contains(
          'À vérifier dans la version applicable du Code du bien-être au travail ou auprès des personnes compétentes.',
        ),
      ),
    );
  });
}
