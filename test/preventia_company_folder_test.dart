import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:preventia_belgique_app/models/preventia_project.dart';
import 'package:preventia_belgique_app/screens/history_screen.dart';
import 'package:preventia_belgique_app/services/preventia_company_extraction_service.dart';
import 'package:preventia_belgique_app/services/preventia_company_project_service.dart';
import 'package:preventia_belgique_app/services/preventia_document_storage_service.dart';
import 'package:preventia_belgique_app/services/preventia_project_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory root;
  late PreventiaProjectService projects;
  late PreventiaDocumentStorageService documents;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('preventia_company_');
    projects = PreventiaProjectService(
      preferences: await SharedPreferences.getInstance(),
    );
    documents = PreventiaDocumentStorageService(projectService: projects);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('normalizeCompanyName creates the stable SPGE key', () {
    expect(normalizeCompanyName(' SPGÉ\u200b '), 'spge');
    expect(companyKey('SPGE'), 'spge');
    expect(companyKey('spge  '), 'spge');
    expect(normalizeCompanyName('Société / Wallonie'), 'societe wallonie');
  });

  test('different sites reuse one company folder and are metadata', () async {
    final first = await projects.createProject(
      companyName: 'SPGE',
      siteName: 'Verviers',
      baseDirectoryPath: root.path,
    );
    final found = await projects.findProject(
      companyName: 'spgé',
      siteName: 'Liège',
    );

    expect(
      first.basePath,
      path.join(root.path, 'PreventIA', 'Clients', 'SPGE'),
    );
    expect(found?.basePath, first.basePath);

    await documents.saveGeneratedDocument(
      documentType: 'Analyse de risques générale',
      companyName: 'SPGE',
      siteName: 'Liège',
      title: 'Analyse Liège',
      markdown: 'Action : contrôle et maintenance',
    );
    final company = await projects.getCurrentProject();
    expect(company?.sites, containsAll(['Verviers', 'Liège']));
  });

  test(
    'first risk analysis creates PIU and PGA once and updates JSON',
    () async {
      await projects.createProject(
        companyName: 'SPGE',
        siteName: 'Verviers',
        baseDirectoryPath: root.path,
      );
      final first = await documents.saveGeneratedDocument(
        documentType: 'Analyse de risques — Installations électriques BT/HT',
        companyName: 'SPGE',
        siteName: 'Verviers',
        title: 'Analyse électrique 1',
        markdown: '''
Mesure proposée : formaliser la consignation
Thermographie à planifier et rapport RGIE à obtenir
Coupure générale et TGBT à intégrer au PIU
''',
      );
      final second = await documents.saveGeneratedDocument(
        documentType: 'Analyse de risques — Installations électriques BT/HT',
        companyName: 'SPGE',
        siteName: 'Namur',
        title: 'Analyse électrique 2',
        markdown: 'Maintenance et contrôle SECT à planifier',
      );

      expect(first.piuCreated, isTrue);
      expect(first.pgaCreated, isTrue);
      expect(second.piuCreated, isFalse);
      expect(second.pgaCreated, isFalse);
      expect(
        Directory(path.join(first.folderPath, '02_PIU')).listSync(),
        hasLength(1),
      );
      expect(
        Directory(path.join(first.folderPath, '04_PGA_PAA_PGP')).listSync(),
        hasLength(1),
      );

      final jsonFile = File(
        path.join(first.folderPath, 'preventia_company.json'),
      );
      final json =
          jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>;
      expect(json['companyKey'], 'spge');
      expect(json['companyPath'], first.folderPath);
      expect(json['documents'], isNotEmpty);
      expect(json['actionItems'], isNotEmpty);
      expect(json['piuItems'], isNotEmpty);
    },
  );

  test('electrical and elevator extraction creates required candidates', () {
    final electrical = extractFromRiskAssessment(
      documentType: 'Analyse de risques — Installations électriques BT/HT',
      markdown: '''
Action : consignation à mettre à jour
Thermographie à planifier
Coupure générale au TGBT
''',
      formData: const {},
      sourceDocumentId: 'electric',
    );
    final elevator = extractFromRiskAssessment(
      documentType: 'Analyse de risques — Ascenseur',
      markdown: '''
Personne bloquée : communication bidirectionnelle et accueil secours
Contrôle SECT à planifier
''',
      formData: const {},
      sourceDocumentId: 'elevator',
    );

    expect(
      electrical.actionItems.any(
        (item) => item.action.contains('consignation'),
      ),
      isTrue,
    );
    expect(
      electrical.actionItems.any(
        (item) => item.action.contains('Thermographie'),
      ),
      isTrue,
    );
    expect(
      electrical.piuItems.any(
        (item) => item.emergencyTopic.contains('Coupure générale'),
      ),
      isTrue,
    );
    expect(
      elevator.piuItems.any(
        (item) => item.emergencyTopic.contains('Personne bloquée'),
      ),
      isTrue,
    );
    expect(
      elevator.actionItems.any((item) => item.action.contains('SECT')),
      isTrue,
    );
    expect(
      electrical.actionItems.every((item) => item.status == 'à valider'),
      isTrue,
    );
    expect(
      electrical.piuItems.every((item) => item.status == 'à valider'),
      isTrue,
    );
    expect(
      elevator.actionItems.every((item) => item.status == 'à valider'),
      isTrue,
    );
  });

  test('history loads the company name', () async {
    await PreventiaCompanyProjectService().addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    );
    final history = await loadPreventiaCompaniesForHistory();
    expect(history.map((item) => item.companyName), contains('SPGE'));
  });
}
