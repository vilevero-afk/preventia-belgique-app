import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/models/preventia_company_project.dart';
import 'package:preventia_belgique_app/models/preventia_project.dart';
import 'package:preventia_belgique_app/services/company_piu_review_document_service.dart';

void main() {
  test('buildPiuReviewMarkdown creates a readable review document', () {
    final project = _project(
      piuItems: const [
        PreventiaPiuItem(
          id: 'piu-1',
          sourceDocumentId: 'analysis-1',
          emergencyTopic:
              'Ascenseur | Personne bloquée | [à compléter] | Personne bloquée',
          information:
              'Risque panique usager | Communication cabine à tester | ',
          location: 'Bâtiment A',
          actionRequired:
              'Prévoir procédure personne bloquée | Contact maintenance',
          status: 'à valider',
        ),
        PreventiaPiuItem(
          id: 'piu-2',
          sourceDocumentId: 'analysis-1',
          emergencyTopic: 'Coupure générale TGBT',
          information: 'Localisation coupure à confirmer',
          location: 'Local technique',
          actionRequired: 'Intégrer au PIU',
          status: 'à revoir',
        ),
        PreventiaPiuItem(
          id: 'piu-3',
          sourceDocumentId: 'analysis-1',
          emergencyTopic: 'Point ignoré',
          information: 'Ne doit pas apparaître',
          location: '',
          actionRequired: '',
          status: 'ignoré',
        ),
        PreventiaPiuItem(
          id: 'piu-4',
          sourceDocumentId: 'analysis-1',
          emergencyTopic: 'Point déjà validé',
          information: 'Section séparée',
          location: '',
          actionRequired: '',
          status: 'validé',
        ),
      ],
    );

    final markdown = buildPiuReviewMarkdown(project);

    expect(markdown, isNotEmpty);
    expect(markdown, contains('Revue des éléments PIU à valider'));
    expect(markdown, contains('aide au conseiller en prévention'));
    expect(markdown, contains('Ascenseur'));
    expect(markdown, contains('Coupure générale TGBT'));
    expect(markdown, isNot(contains('Point ignoré')));
    expect(markdown, isNot(contains('## Déjà validés')));
    expect(markdown, isNot(contains('Point déjà validé')));
    expect(markdown, contains('[ ] Valider  [ ] À revoir  [ ] Ignorer'));
    expect(markdown, isNot(contains('[à compléter]')));
    expect(markdown, isNot(contains('Personne bloquée<br>Personne bloquée')));
  });

  test('cleanCandidateText removes pipe noise and exact repetitions', () {
    expect(
      cleanCandidateText('Action | [à compléter] | Action |  Contact  secours'),
      'Action\nContact secours',
    );
  });

  test('buildPgpReviewMarkdown creates a local action review document', () {
    final project = _project(
      actionItems: [
        _action(
          id: 'action-1',
          action: 'Obtenir PV RGIE | Planifier correction | Obtenir PV RGIE',
          status: 'à valider',
        ),
        _action(
          id: 'action-2',
          action: 'Former les équipiers',
          status: 'à revoir',
        ),
        _action(id: 'action-3', action: 'Action ignorée', status: 'ignoré'),
      ],
    );

    final markdown = buildPgpReviewMarkdown(project);

    expect(markdown, isNotEmpty);
    expect(markdown, contains('Revue des actions PGP/PAA à valider'));
    expect(markdown, contains('Obtenir PV RGIE'));
    expect(markdown, contains('Planifier correction'));
    expect(markdown, contains('Former les équipiers'));
    expect(markdown, isNot(contains('Action ignorée')));
    expect(markdown, contains('[ ] Valider  [ ] À revoir  [ ] Ignorer'));
  });

  test('review export metadata stays local and does not request backend', () {
    final project = _project();
    final markdown = buildPiuReviewMarkdown(project);
    final document = PreventiaCompanyDocument(
      id: 'review',
      documentType: 'Revue PIU à valider',
      title: 'Revue des éléments PIU à valider — SPGE',
      status: 'revue locale',
      createdAt: DateTime(2026, 6, 27),
      autoCreated: false,
      source: 'company-folder-local-review',
      markdown: markdown,
      formData: const {'backendGeneration': false},
    );

    expect(document.source, 'company-folder-local-review');
    expect(document.formData['backendGeneration'], isFalse);
    expect(document.markdown, isNotEmpty);
  });
}

PreventiaCompanyProject _project({
  List<PreventiaPiuItem> piuItems = const [],
  List<PreventiaActionItem> actionItems = const [],
}) {
  return PreventiaCompanyProject(
    id: 'company-1',
    companyName: 'SPGE',
    companyKey: 'spge',
    createdAt: DateTime(2026, 6, 27),
    updatedAt: DateTime(2026, 6, 27),
    analyses: [
      PreventiaCompanyDocument(
        id: 'analysis-1',
        documentType: 'Analyse de risques — Ascenseur',
        title: 'AR-2026-ASC — Analyse de risques',
        status: 'généré',
        createdAt: DateTime(2026, 6, 27),
        autoCreated: false,
        source: 'backend',
        reference: 'AR-2026-ASC',
      ),
    ],
    companyProfile: const PreventiaCompanyProfile(
      companyName: 'SPGE',
      siteName: 'Verviers',
      address: 'Rue du Site 1',
      postalCode: '4800',
      city: 'Verviers',
      preventionAdvisor: 'CP',
      siteManager: 'Responsable',
      technicalServiceContact: 'Technique',
      riskProfile: 'élevé',
    ),
    piuItems: piuItems,
    actionItems: actionItems,
  );
}

PreventiaActionItem _action({
  required String id,
  required String action,
  required String status,
}) {
  return PreventiaActionItem(
    id: id,
    sourceDocumentId: 'analysis-1',
    sourceDocumentType: 'Analyse de risques — Ascenseur',
    action: action,
    priority: 'Haute',
    responsible: 'Direction',
    deadline: '30 jours',
    status: status,
    evidenceExpected: 'Preuve attendue',
    destination: 'PGP/PAA',
    createdAt: DateTime(2026, 6, 27),
    updatedAt: DateTime(2026, 6, 27),
  );
}
