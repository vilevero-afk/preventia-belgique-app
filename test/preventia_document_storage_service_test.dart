import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:preventia_belgique_app/services/preventia_document_storage_service.dart';
import 'package:preventia_belgique_app/services/preventia_project_extraction_service.dart';
import 'package:preventia_belgique_app/services/preventia_project_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory temporaryDirectory;
  late PreventiaProjectService projectService;
  late PreventiaDocumentStorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'preventia_document_storage_test_',
    );
    projectService = PreventiaProjectService(
      preferences: await SharedPreferences.getInstance(),
    );
    storageService = PreventiaDocumentStorageService(
      projectService: projectService,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('normalizes folder names without removing accents', () {
    expect(
      normalizeFolderName('  Société / Site: Nord  '),
      'Société - Site- Nord',
    );
    expect(normalizeFolderName('SPGE'), 'SPGE');
  });

  test('returns a clear non-indexed result without a selected root', () async {
    final result = await storageService.saveGeneratedDocument(
      documentType: 'Analyse de risques générale',
      companyName: 'SPGE',
      siteName: 'Site administratif de Verviers',
      title: 'Analyse générale',
      markdown: 'Action : vérifier les issues',
    );

    expect(result.isIndexed, isFalse);
    expect(result.error, contains('non enregistré'));
  });

  test(
    'does not create a new client silently from a remembered root',
    () async {
      await projectService.setRootDirectoryPath(temporaryDirectory.path);
      final result = await storageService.saveGeneratedDocument(
        documentType: 'Analyse de risques générale',
        companyName: 'Nouvelle société',
        siteName: 'Nouveau site',
        title: 'Analyse générale',
        markdown: 'Action : vérifier les issues',
      );

      expect(result.isIndexed, isFalse);
      expect(await projectService.getKnownProjects(), isEmpty);
    },
  );

  test('remembers that the root folder choice was already requested', () async {
    expect(await projectService.hasAskedForRootDirectory(), isFalse);
    await projectService.markRootDirectoryChoiceAsked();
    expect(await projectService.hasAskedForRootDirectory(), isTrue);
  });

  test(
    'stores Word/PDF, indexes extraction and deduplicates regeneration',
    () async {
      await projectService.createProject(
        companyName: 'SPGE',
        siteName: 'Site administratif de Verviers',
        baseDirectoryPath: temporaryDirectory.path,
      );
      final sourceDirectory = await Directory(
        path.join(temporaryDirectory.path, 'sources'),
      ).create();
      final wordSource = File(path.join(sourceDirectory.path, 'analyse.docx'));
      final pdfSource = File(path.join(sourceDirectory.path, 'analyse.pdf'));
      await wordSource.writeAsBytes([1, 2, 3]);
      await pdfSource.writeAsBytes([4, 5, 6]);
      const markdown = '''
Risque : personne bloquée dans l’ascenseur | Priorité : élevée
Action : tester le téléphone cabine | Responsable : Marc | Délai : 1 mois | PAA
PIU : contact secours et procédure personne bloquée
DIU : accès au local technique et à la cuvette
Preuve à obtenir : rapport SECT et photo cabine
''';
      final formData = <String, dynamic>{
        'documentReference': 'AR-2026-ASC-1',
        'companyName': 'SPGE',
        'siteName': 'Site administratif de Verviers',
        'plannedMeasures': 'Contrôle et entretien annuel à intégrer au PGP',
        'evidenceToCollect': 'PV de contrôle et attestation',
      };

      final first = await storageService.saveGeneratedDocument(
        documentType: 'Analyse de risques — Ascenseur',
        companyName: 'SPGE',
        siteName: 'Site administratif de Verviers',
        title: 'AR-2026-ASC-1 - Ascenseur',
        markdown: markdown,
        wordSourcePath: wordSource.path,
        pdfSourcePath: pdfSource.path,
        formData: formData,
      );

      expect(first.isIndexed, isTrue);
      expect(
        first.folderPath,
        path.join(temporaryDirectory.path, 'PreventIA', 'Clients', 'SPGE'),
      );
      expect(File(first.wordPath!).readAsBytesSync(), [1, 2, 3]);
      expect(File(first.pdfPath!).readAsBytesSync(), [4, 5, 6]);
      expect(first.actionCount, greaterThan(0));
      expect(first.piuCount, greaterThan(0));
      expect(first.diuCount, greaterThan(0));
      expect(first.evidenceCount, greaterThan(0));
      expect(first.piuCreated, isTrue);
      expect(first.pgaCreated, isTrue);
      expect(
        File(
          path.join(first.folderPath, 'preventia_company.json'),
        ).existsSync(),
        isTrue,
      );

      final initiallyIndexed = (await projectService.getCurrentProject())!;
      expect(
        initiallyIndexed.actionItems.every(
          (item) => item.status == 'à valider',
        ),
        isTrue,
      );
      final validatedActionId = initiallyIndexed.actionItems.first.id;
      await projectService.saveProject(
        initiallyIndexed.copyWith(
          actionItems: initiallyIndexed.actionItems
              .map(
                (item) => item.id == validatedActionId
                    ? item.copyWith(status: 'validé')
                    : item,
              )
              .toList(),
        ),
      );
      final beforeRegeneration = await projectService.getCurrentProject();
      await storageService.saveGeneratedDocument(
        documentType: 'Analyse de risques — Ascenseur',
        companyName: ' spge ',
        siteName: 'Site administratif de Verviers',
        title: 'AR-2026-ASC-1 - Ascenseur',
        markdown: markdown,
        formData: formData,
      );
      final afterRegeneration = await projectService.getCurrentProject();

      expect(afterRegeneration?.basePath, beforeRegeneration?.basePath);
      expect(
        afterRegeneration?.documents
            .where(
              (item) => item.documentType == 'Analyse de risques — Ascenseur',
            )
            .length,
        1,
      );
      expect(
        afterRegeneration?.actionItems.length,
        beforeRegeneration?.actionItems.length,
      );
      expect(
        afterRegeneration?.piuItems.length,
        beforeRegeneration?.piuItems.length,
      );
      expect(
        afterRegeneration?.diuItems.length,
        beforeRegeneration?.diuItems.length,
      );
      expect(
        afterRegeneration?.evidenceToCollect.length,
        beforeRegeneration?.evidenceToCollect.length,
      );
      expect(
        afterRegeneration?.actionItems
            .firstWhere((item) => item.id == validatedActionId)
            .status,
        'validé',
      );
    },
  );

  test('extracts keyword candidates from markdown and form data', () {
    final extraction = extractItemsFromRiskAssessment(
      documentType: 'Analyse de risques — Installations électriques BT/HT',
      markdown: '''
Mesure à prévoir : formaliser la consignation | Priorité : élevée
Coupure générale et contact secours à intégrer au PIU
TGBT et armoire électrique à documenter dans le DIU
Preuve : PV RGIE et photo du local technique
''',
      formData: const {
        'plannedMeasures':
            'Former les personnes BA4/BA5 et planifier le contrôle',
        'evidenceToCollect': 'Rapport de thermographie',
      },
      sourceDocumentId: 'AR-2026-ELEC-1',
    );

    expect(extraction.actionItems, isNotEmpty);
    expect(extraction.paaPgpItems, isNotEmpty);
    expect(extraction.piuItems, isNotEmpty);
    expect(extraction.diuItems, isNotEmpty);
    expect(extraction.evidenceItems, isNotEmpty);
    expect([
      ...extraction.actionItems.map((item) => item.status),
      ...extraction.piuItems.map((item) => item.status),
      ...extraction.diuItems.map((item) => item.status),
      ...extraction.evidenceItems.map((item) => item.status),
    ], everyElement('à valider'));
  });
}
