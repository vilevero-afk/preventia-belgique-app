import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/models/preventia_company_project.dart';
import 'package:preventia_belgique_app/models/preventia_project.dart';
import 'package:preventia_belgique_app/services/preventia_company_project_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PreventiaCompanyProjectService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = PreventiaCompanyProjectService(
      preferences: await SharedPreferences.getInstance(),
    );
  });

  test(
    'soft cleanup redirects false PIU candidates without losing data',
    () async {
      final now = DateTime(2026, 6, 27);
      await service.saveProject(
        PreventiaCompanyProject(
          id: 'spge',
          companyName: 'SPGE',
          companyKey: 'spge',
          createdAt: now,
          updatedAt: now,
          companyProfile: const PreventiaCompanyProfile(riskProfile: 'modéré'),
          piuItems: const [
            PreventiaPiuItem(
              id: 'meta-additional',
              sourceDocumentId: 'analysis-1',
              emergencyTopic: 'additionalInformation',
              information: 'additionalInformation à intégrer au PIU',
              location: '',
              actionRequired: '',
              status: 'à valider',
            ),
            PreventiaPiuItem(
              id: 'meta-doc-type',
              sourceDocumentId: 'analysis-1',
              emergencyTopic: 'documentType',
              information: 'documentType',
              location: '',
              actionRequired: '',
              status: 'à valider',
            ),
            PreventiaPiuItem(
              id: 'available-evidence',
              sourceDocumentId: 'analysis-1',
              emergencyTopic: 'availableEvidence',
              information: 'availableEvidence',
              location: '',
              actionRequired: '',
              status: 'à valider',
            ),
            PreventiaPiuItem(
              id: 'evidence-report',
              sourceDocumentId: 'analysis-1',
              emergencyTopic: 'Rapport FDS photo à obtenir',
              information: 'PV, FDS, inventaire et photo',
              location: '',
              actionRequired: '',
              status: 'à valider',
            ),
            PreventiaPiuItem(
              id: 'expert-control',
              sourceDocumentId: 'analysis-1',
              emergencyTopic: 'Contrôle périodique et validation expert',
              information: 'Livre III référence réglementaire',
              location: '',
              actionRequired: '',
              status: 'à valider',
            ),
            PreventiaPiuItem(
              id: 'planning-action',
              sourceDocumentId: 'analysis-1',
              emergencyTopic: 'Action de planification maintenance PGP/PAA',
              information: 'Mesure de prévention à planifier',
              location: '',
              actionRequired: '',
              status: 'à valider',
            ),
            PreventiaPiuItem(
              id: 'fire',
              sourceDocumentId: 'analysis-1',
              emergencyTopic: 'Alerte incendie et évacuation générale',
              information: 'Appel 112',
              location: '',
              actionRequired: '',
              status: 'à valider',
            ),
            PreventiaPiuItem(
              id: 'rescue',
              sourceDocumentId: 'analysis-1',
              emergencyTopic: 'Accueil secours et accès pompiers',
              information: 'Dossier pompiers',
              location: '',
              actionRequired: '',
              status: 'à valider',
            ),
            PreventiaPiuItem(
              id: 'meeting-point',
              sourceDocumentId: 'analysis-1',
              emergencyTopic: 'Point de rassemblement évacuation',
              information: 'Gestion visiteurs',
              location: '',
              actionRequired: '',
              status: 'à valider',
            ),
          ],
        ),
      );

      final cleaned = await service.findByKey('spge');

      expect(cleaned, isNotNull);
      final piuTitles = cleaned!.piuItems.map((item) => item.emergencyTopic);
      expect(piuTitles, isNot(contains('additionalInformation')));
      expect(piuTitles, isNot(contains('documentType')));
      expect(piuTitles, isNot(contains('availableEvidence')));
      expect(piuTitles, contains('Alerte incendie et évacuation générale'));
      expect(piuTitles, contains('Accueil secours et accès pompiers'));
      expect(piuTitles, contains('Point de rassemblement évacuation'));
      expect(
        cleaned.evidenceItems.map((item) => item.label).join('\n'),
        contains('Rapport FDS photo'),
      );
      expect(
        cleaned.evidenceItems.any((item) => item.redirectedFrom == 'PIU'),
        isTrue,
      );
      expect(
        cleaned.pointsToVerify.join('\n'),
        contains('Contrôle périodique et validation expert'),
      );
      expect(
        cleaned.actionItems.map((item) => item.action).join('\n'),
        contains('Action de planification maintenance PGP/PAA'),
      );
      expect(
        cleaned.actionItems.any((item) => item.redirectedFrom == 'PIU'),
        isTrue,
      );
    },
  );
}
