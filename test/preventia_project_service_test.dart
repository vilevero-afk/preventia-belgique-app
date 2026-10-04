import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:preventia_belgique_app/models/preventia_project.dart';
import 'package:preventia_belgique_app/services/preventia_project_service.dart';
import 'package:preventia_belgique_app/services/preventia_risk_extractor.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory temporaryDirectory;
  late PreventiaProjectService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'preventia_project_test_',
    );
    service = PreventiaProjectService(
      preferences: await SharedPreferences.getInstance(),
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('returns null and does not crash without an active project', () async {
    expect(await service.getCurrentProject(), isNull);
    await service.addActionItemsToCurrentProject(const []);
    await service.addRiskItemsToCurrentProject(const []);
  });

  test('does not write an export without an active project', () async {
    final savedPath = await service.saveExportToCurrentProject(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'document.pdf',
      documentType: 'Annexe',
      title: 'Document',
      reference: 'REF-1',
      language: 'fr',
      source: 'local',
      isPdf: true,
    );

    expect(savedPath, isNull);
    expect(await temporaryDirectory.list().toList(), isEmpty);
  });

  test('creates the complete tree and saves a loadable JSON index', () async {
    final project = await service.createProject(
      companyName: 'Entreprise Test',
      siteName: 'Site Bruxelles',
      baseDirectoryPath: temporaryDirectory.path,
    );

    for (final folder in PreventiaProjectService.subdirectories) {
      expect(
        Directory(path.join(project.basePath, folder)).existsSync(),
        isTrue,
      );
    }
    final jsonFile = File(
      path.join(project.basePath, PreventiaProjectService.projectFileName),
    );
    expect(jsonFile.existsSync(), isTrue);
    final decoded = jsonDecode(jsonFile.readAsStringSync());
    expect(decoded['companyName'], 'Entreprise Test');

    final loaded = await service.loadProject(jsonFile.path);
    expect(loaded.id, project.id);
    expect(loaded.siteName, 'Site Bruxelles');
  });

  test(
    'adds documents and actions and creates a backup before overwrite',
    () async {
      final project = await service.createProject(
        companyName: 'PreventIA',
        siteName: 'Liège',
        baseDirectoryPath: temporaryDirectory.path,
      );
      final now = DateTime(2026, 6, 20);
      await service.addDocumentToCurrentProject(
        PreventiaProjectDocument(
          id: 'document-1',
          documentType: 'Analyse de risques générale',
          title: 'Analyse atelier',
          reference: 'AR-2026-0001',
          language: 'fr',
          createdAt: now,
          wordPath: '',
          pdfPath: '/local/analyse.pdf',
          source: 'ai_backend',
        ),
      );
      await service.addActionItemsToCurrentProject([
        PreventiaActionItem(
          id: 'action-1',
          sourceDocumentId: 'document-1',
          sourceDocumentType: 'Analyse de risques générale',
          action: 'Sécuriser la machine',
          priority: 'Haute',
          responsible: 'Direction',
          deadline: '30 jours',
          status: 'à valider',
          evidenceExpected: 'Photo',
          destination: 'PAA/PGP',
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      final loaded = await service.getCurrentProject();
      expect(loaded?.documents.single.reference, 'AR-2026-0001');
      expect(loaded?.actionItems.single.status, 'à valider');
      expect(
        File(
          path.join(project.basePath, PreventiaProjectService.backupFileName),
        ).existsSync(),
        isTrue,
      );
    },
  );

  test(
    'recreates a missing company JSON inside an accessible company folder',
    () async {
      final siteDirectory = Directory(
        path.join(temporaryDirectory.path, 'PreventIA', 'Clients', 'Acme'),
      );
      await siteDirectory.create(recursive: true);
      final project = await service.loadProject(
        path.join(siteDirectory.path, PreventiaProjectService.projectFileName),
      );

      expect(project.companyName, 'Acme');
      expect(project.siteName, isEmpty);
      expect(
        File(
          path.join(
            siteDirectory.path,
            PreventiaProjectService.projectFileName,
          ),
        ).existsSync(),
        isTrue,
      );
    },
  );

  test('maps document types to the required local folders', () {
    expect(
      PreventiaProjectService.subdirectoryForDocumentType(
        'Analyse de risques incendie',
      ),
      '01_Analyses_de_risques',
    );
    expect(
      PreventiaProjectService.subdirectoryForDocumentType(
        'Analyse de risques — Installations électriques BT/HT',
      ),
      '01_Analyses_de_risques',
    );
    expect(
      PreventiaProjectService.subdirectoryForDocumentType(
        'Plan Interne d’Urgence',
      ),
      '02_PIU',
    );
    expect(
      PreventiaProjectService.subdirectoryForDocumentType(
        'Plan annuel d’action',
      ),
      '04_PGA_PAA_PGP',
    );
  });

  test('saves an export in its project folder and indexes it', () async {
    final project = await service.createProject(
      companyName: 'PreventIA',
      siteName: 'Namur',
      baseDirectoryPath: temporaryDirectory.path,
    );

    final savedPath = await service.saveExportToCurrentProject(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'AR-2026-0002.pdf',
      documentType: 'Analyse de risques générale',
      title: 'Analyse atelier',
      reference: 'AR-2026-0002',
      language: 'fr',
      source: 'ai_backend',
      isPdf: true,
    );

    expect(
      savedPath,
      path.join(project.basePath, '01_Analyses_de_risques', 'AR-2026-0002.pdf'),
    );
    expect(File(savedPath!).readAsBytesSync(), [1, 2, 3]);
    final loaded = await service.getCurrentProject();
    expect(loaded?.documents.single.pdfPath, savedPath);
  });

  test('remembers the root and finds a known company/site project', () async {
    final project = await service.createProject(
      companyName: 'Entreprise Test',
      siteName: 'Atelier Nord',
      baseDirectoryPath: temporaryDirectory.path,
    );

    expect(await service.getRootDirectoryPath(), temporaryDirectory.path);
    expect(
      (await service.findProject(
        companyName: 'entreprise test',
        siteName: 'atelier nord',
      ))?.id,
      project.id,
    );
    expect(await service.getKnownProjects(), hasLength(1));
  });

  test('uses one stable project key despite accents, case and spaces', () {
    expect(projectKey(' SPGE ', 'Site  administratif de Verviers '), 'spge');
    expect(projectKey('spgé', 'SITE ADMINISTRATIF DE VERVIERS'), 'spge');
  });

  test('finds the same project with normalized SPGE identity', () async {
    final project = await service.createProject(
      companyName: 'SPGE',
      siteName: 'Site administratif de Verviers',
      baseDirectoryPath: temporaryDirectory.path,
    );

    final found = await service.findProject(
      companyName: ' spgé ',
      siteName: 'site  administratif de verviers ',
    );

    expect(found?.basePath, project.basePath);
    expect(await service.getKnownProjects(), hasLength(1));
  });

  test('rejects an app container as a client document destination', () async {
    final containerRoot = await Directory(
      path.join(
        temporaryDirectory.path,
        'Library',
        'Containers',
        'com.example.preventiaBelgiqueApp',
        'Data',
        'Documents',
      ),
    ).create(recursive: true);
    final project = await service.createProject(
      companyName: 'SPGE',
      siteName: 'Site administratif de Verviers',
      baseDirectoryPath: containerRoot.path,
    );

    expect(isValidClientProjectPath(project.basePath), isFalse);
    expect(
      await service.findProject(
        companyName: 'SPGE',
        siteName: 'Site administratif de Verviers',
      ),
      isNull,
    );
  });

  test('creates a one-document project without remembering it', () async {
    final project = await service.createProject(
      companyName: 'SPGE',
      siteName: 'Site administratif de Verviers',
      baseDirectoryPath: temporaryDirectory.path,
      register: false,
    );

    expect(
      File(path.join(project.basePath, 'preventia_company.json')).existsSync(),
      isTrue,
    );
    expect(await service.getKnownProjects(), isEmpty);
    expect(await service.getCurrentProject(), isNull);
  });

  test('removes a project from the app without deleting its files', () async {
    final project = await service.createProject(
      companyName: 'SPGE',
      siteName: 'Verviers',
      baseDirectoryPath: temporaryDirectory.path,
    );

    await service.removeProjectFromList(project);

    expect(Directory(project.basePath).existsSync(), isTrue);
    expect(await service.getKnownProjects(), isEmpty);
    expect(await service.getCurrentProject(), isNull);
  });

  test('permanently deletes only a verified PreventIA client folder', () async {
    final project = await service.createProject(
      companyName: 'SPGE',
      siteName: 'Verviers',
      baseDirectoryPath: temporaryDirectory.path,
    );
    await File(
      path.join(project.basePath, '01_Analyses_de_risques', 'test.pdf'),
    ).writeAsBytes([1, 2, 3]);

    await service.deleteProjectPermanently(project);

    expect(Directory(project.basePath).existsSync(), isFalse);
    expect(await service.getKnownProjects(), isEmpty);
    expect(await service.getCurrentProject(), isNull);
  });

  test('deletes only indexed Word/PDF files and keeps the project', () async {
    final project = await service.createProject(
      companyName: 'SPGE',
      siteName: 'Verviers',
      baseDirectoryPath: temporaryDirectory.path,
    );
    final pdf = File(
      path.join(project.basePath, '01_Analyses_de_risques', 'analyse.pdf'),
    );
    await pdf.writeAsBytes([1, 2, 3]);
    await service.addDocumentToCurrentProject(
      PreventiaProjectDocument(
        id: 'doc-1',
        documentType: 'Analyse de risques générale',
        title: 'Analyse SPGE',
        reference: 'AR-1',
        language: 'fr',
        createdAt: DateTime(2026, 6, 21),
        wordPath: '',
        pdfPath: pdf.path,
        source: 'generated',
      ),
    );

    final errors = await service.removeIndexedDocument(
      documentId: 'doc-1',
      documentType: 'Analyse de risques générale',
      title: 'Analyse SPGE',
      deleteFiles: true,
    );

    expect(errors, isEmpty);
    expect(pdf.existsSync(), isFalse);
    expect(Directory(project.basePath).existsSync(), isTrue);
    expect((await service.getCurrentProject())?.documents, isEmpty);
  });

  test('refuses to delete a folder outside PreventIA Clients', () async {
    final unsafeDirectory = await Directory(
      path.join(temporaryDirectory.path, 'Documents'),
    ).create();
    await File(
      path.join(unsafeDirectory.path, PreventiaProjectService.projectFileName),
    ).writeAsString('{}');
    final unsafeProject = PreventiaProject(
      id: 'unsafe',
      companyName: 'SPGE',
      siteName: 'Verviers',
      basePath: unsafeDirectory.path,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await expectLater(
      service.deleteProjectPermanently(unsafeProject),
      throwsA(isA<PreventiaProjectException>()),
    );
    expect(unsafeDirectory.existsSync(), isTrue);
  });

  test('stores generated content and indexes it before PDF export', () async {
    final project = await service.createProject(
      companyName: 'PreventIA',
      siteName: 'Mons',
      baseDirectoryPath: temporaryDirectory.path,
    );

    final savedPath = await service.saveGeneratedContentToCurrentProject(
      content: '# Analyse\nAction : vérifier la protection',
      fileName: 'AR-2026-0003 - Analyse atelier',
      documentType: 'Analyse de risques générale',
      title: 'Analyse atelier',
      reference: 'AR-2026-0003',
      language: 'fr',
      source: 'ai_backend',
    );

    expect(
      savedPath,
      path.join(
        project.basePath,
        '01_Analyses_de_risques',
        'AR-2026-0003 - Analyse atelier.md',
      ),
    );
    expect(File(savedPath!).readAsStringSync(), contains('Action'));
    final loaded = await service.getCurrentProject();
    expect(loaded?.documents.single.documentType, contains('Analyse'));
    expect(loaded?.documents.single.wordPath, isEmpty);
    expect(loaded?.documents.single.pdfPath, isEmpty);
  });

  test('extracts unvalidated local items from risk markdown', () {
    final extraction = extractProjectItemsFromRiskAssessment(
      markdown: '''
Risque résiduel : moyen | Priorité : haute | DIU
Action : sécuriser la zone | Responsable : Direction | Délai : 30 jours | PAA | PIU
Mesure à prévoir : installer un garde-corps | Priorité : haute | PGAA
Preuve à obtenir : rapport de contrôle
Photo à prendre : protection de la machine
''',
      documentType: 'Analyse de risques générale',
      documentId: 'AR-2026-0001',
    );

    expect(extraction.riskItems, hasLength(1));
    expect(extraction.riskItems.single.status, 'à valider');
    expect(extraction.actionItems, hasLength(2));
    final action = extraction.actionItems.firstWhere(
      (item) => item.action == 'sécuriser la zone',
    );
    expect(action.responsible, 'Direction');
    expect(action.destination, contains('PAA/PGP'));
    expect(extraction.evidenceItems, hasLength(2));
    expect(extraction.diuItems, isNotEmpty);
    expect(extraction.piuItems, isNotEmpty);
  });
}
