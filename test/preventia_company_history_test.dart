import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/l10n/generated/app_localizations.dart';
import 'package:preventia_belgique_app/models/generation_source.dart';
import 'package:preventia_belgique_app/models/preventia_company_project.dart';
import 'package:preventia_belgique_app/models/preventia_project.dart';
import 'package:preventia_belgique_app/screens/history_screen.dart';
import 'package:preventia_belgique_app/screens/company_folder_detail_screen.dart';
import 'package:preventia_belgique_app/screens/preventia_company_project_screen.dart';
import 'package:preventia_belgique_app/screens/result_screen.dart';
import 'package:preventia_belgique_app/services/company_piu_review_document_service.dart';
import 'package:preventia_belgique_app/services/preventia_company_extraction_service.dart';
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

  test('no company project exists before a generated analysis', () async {
    expect(await service.getProjects(migrateLegacy: false), isEmpty);
    expect(await loadPreventiaCompaniesForHistory(), isEmpty);
    expect(await service.getProjects(migrateLegacy: false), isEmpty);
  });

  test(
    'first SPGE analysis creates one company project, PIU and PGA',
    () async {
      final first = await service.addRiskAssessment(
        documentType: 'Analyse de risques — Installations électriques BT/HT',
        markdown: '''
Entreprise : SPGE
Action : consignation à vérifier et thermographie à planifier
Coupure générale du TGBT à intégrer au PIU
Preuve à obtenir : rapport RGIE
''',
        formData: const {'companyName': 'SPGE'},
        reference: 'AR-2026-0045',
      );
      final second = await service.addRiskAssessment(
        documentType: 'Analyse de risques — Ascenseur',
        markdown:
            'Personne bloquée : accueil secours. Contrôle SECT à planifier.',
        formData: const {'enterpriseName': ' spgé '},
        reference: 'AR-2026-0046',
      );
      final projects = await service.getProjects(migrateLegacy: false);

      expect(projects, hasLength(1));
      expect(projects.single.companyName, 'SPGE');
      expect(projects.single.analyses, hasLength(2));
      expect(
        projects.single.documents.where(
          (item) => item.documentType.contains('Analyse de risques'),
        ),
        hasLength(2),
      );
      expect(first.piuCreated, isTrue);
      expect(first.pgaCreated, isTrue);
      expect(second.piuCreated, isFalse);
      expect(second.pgaCreated, isFalse);
      expect(projects.single.piuDocument?.title, 'PIU — SPGE');
      expect(projects.single.pgaDocument?.title, 'PGA/PAA/PGP — SPGE');
      expect(projects.single.actionItems, isNotEmpty);
      expect(
        projects.single.piuItems.any(
          (item) => item.emergencyTopic.contains('Personne bloquée'),
        ),
        isTrue,
      );
    },
  );

  test('history root contains only company labels', () async {
    await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE\nAction : contrôle à planifier',
      formData: const {},
      reference: 'AR-2026-0045',
    );
    final labels = companyHistoryRootLabels(
      await service.getProjects(migrateLegacy: false),
    );

    expect(labels, ['SPGE']);
    expect(labels.any((label) => label.contains('AR-2026')), isFalse);
    expect(
      labels.any((label) => label.contains('Récapitulatif des actions')),
      isFalse,
    );
  });

  test('history includes a project without analyses', () {
    final now = DateTime(2026, 6, 23);
    final empty = PreventiaCompanyProject(
      id: 'empty',
      companyName: 'SPGE',
      companyKey: 'spge',
      createdAt: now,
      updatedAt: now,
    );
    expect(companyHistoryRootLabels([empty]), ['SPGE']);
  });

  test('a new company is created only by its first analysis', () async {
    await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    );
    expect(await service.findByKey('acme'), isNull);
    await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : ACME',
      formData: const {'companyName': 'ACME'},
    );
    expect(await service.getProjects(migrateLegacy: false), hasLength(2));
  });

  test(
    'central add function persists visible document paths and JSON',
    () async {
      final project = await service.addRiskAssessmentToCompanyProject(
        documentType: 'Analyse de risques générale',
        markdown: 'Entreprise : SPGE',
        formData: const {'companyName': 'SPGE', 'siteName': 'Verviers'},
        reference: 'AR-2026-0045',
        wordPath: '/tmp/AR-2026-0045.docx',
        pdfPath: '/tmp/AR-2026-0045.pdf',
      );
      final decoded = PreventiaCompanyProject.fromJson(project.toJson());

      expect(decoded.analyses.single.companyName, 'SPGE');
      expect(decoded.analyses.single.siteName, 'Verviers');
      expect(decoded.analyses.single.wordPath, endsWith('.docx'));
      expect(decoded.analyses.single.pdfPath, endsWith('.pdf'));
      expect(
        decoded.documents.map((item) => item.id),
        contains(decoded.analyses.single.id),
      );
      expect(decoded.sites.single.name, 'Verviers');
      expect(decoded.analyses.single.markdown, contains('Entreprise : SPGE'));
      expect(decoded.analyses.single.formData['companyName'], 'SPGE');
    },
  );

  test(
    'company folder stores companyProfile from risk assessment formData',
    () async {
      final update = await service.addRiskAssessment(
        documentType: 'Analyse de risques générale',
        markdown: 'Entreprise : SPGE',
        formData: const {
          'companyName': 'SPGE',
          'siteName': 'Site administratif de Verviers',
          'address': 'Rue des Écoles 12',
          'postalCode': '4800',
          'city': 'Verviers',
          'country': 'Belgique',
          'siteContact': 'Sophie Martin',
          'preventionAdvisor': 'Vincent Legrand',
          'siteManager': 'Marc Delvaux',
          'technicalServiceContact': 'Jean Peeters',
          'activityDescription': 'Bureaux administratifs',
        },
      );

      expect(update.project.companyProfile.address, 'Rue des Écoles 12');
      expect(
        update.project.companyProfile.preventionAdvisor,
        'Vincent Legrand',
      );
      expect(update.project.companyProfile.siteContact, 'Sophie Martin');
    },
  );

  test(
    'risk assessment stays saved and prevention dossier data is stored',
    () async {
      final update = await service.addRiskAssessment(
        documentType: 'Analyse de risques générale',
        markdown: '''
Entreprise : SPGE
Mesure complémentaire : planifier les contrôles périodiques RGIE.
Rapport à obtenir : contrôle réglementaire à confirmer.
Incendie : évacuation et accueil secours à organiser.
''',
        formData: const {
          'companyName': 'SPGE',
          'siteName': 'Site administratif de Verviers',
          'address': 'Rue des Écoles 12',
          'postalCode': '4800',
          'city': 'Verviers',
          'siteContact': 'Sophie Martin',
          'preventionAdvisor': 'Vincent Legrand',
          'activityDescription': 'Bureaux administratifs',
          'riskProfile': 'élevé',
        },
        reference: 'AR-RISK-PROFILE',
      );

      expect(update.project.analyses.single.reference, 'AR-RISK-PROFILE');
      expect(
        update.project.analyses.single.markdown,
        contains('Entreprise : SPGE'),
      );
      expect(update.project.companyProfile.riskProfile, 'élevé');
      expect(update.project.actionItems, isNotEmpty);
      expect(update.project.piuItems, isNotEmpty);
      expect(update.project.pointsToVerify, isNotEmpty);
    },
  );

  test('PIU generation formData receives company profile fields', () async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {
        'companyName': 'SPGE',
        'siteName': 'Site administratif de Verviers',
        'address': 'Rue des Écoles 12',
        'postalCode': '4800',
        'city': 'Verviers',
        'preventionAdvisor': 'Vincent Legrand',
        'siteManager': 'Marc Delvaux',
        'siteContact': 'Sophie Martin',
        'activityDescription': 'Bureaux administratifs',
        'riskProfile': 'modéré',
      },
    )).project;

    final formData = service.buildPiuGenerationFormData(project);

    expect(formData['address'], 'Rue des Écoles 12');
    expect(formData['preventionAdvisor'], 'Vincent Legrand');
    expect(formData['siteManager'], 'Marc Delvaux');
    expect(formData['riskProfile'], 'modéré');
  });

  test('PGA generation formData receives companyProfile', () async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {
        'companyName': 'SPGE',
        'siteName': 'Site administratif de Verviers',
        'address': 'Rue des Écoles 12',
        'postalCode': '4800',
        'city': 'Verviers',
        'preventionAdvisor': 'Vincent Legrand',
        'siteContact': 'Sophie Martin',
        'activityDescription': 'Bureaux administratifs',
        'riskProfile': 'modéré',
      },
    )).project;

    final formData = service.buildPgaGenerationFormData(project);

    expect(formData['companyProfile'], isA<Map<String, dynamic>>());
    expect(
      (formData['companyProfile'] as Map<String, dynamic>)['address'],
      'Rue des Écoles 12',
    );
    expect(
      (formData['companyProfile'] as Map<String, dynamic>)['riskProfile'],
      'modéré',
    );
  });

  test('company profile is not overwritten by placeholder values', () async {
    final first = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {
        'companyName': 'SPGE',
        'siteName': 'Site administratif de Verviers',
        'address': 'Rue des Écoles 12',
        'preventionAdvisor': 'Vincent Legrand',
        'siteContact': 'Sophie Martin',
        'activityDescription': 'Bureaux administratifs',
      },
    )).project;
    final second = (await service.addRiskAssessment(
      documentType: 'Analyse de risques incendie',
      markdown: 'Entreprise : SPGE',
      formData: const {
        'companyName': 'SPGE',
        'siteName': 'Site administratif de Verviers',
        'address': '[à compléter]',
        'preventionAdvisor': '[à compléter]',
        'siteContact': '[à compléter]',
        'activityDescription': '[à compléter]',
      },
    )).project;

    expect(first.companyProfile.address, 'Rue des Écoles 12');
    expect(second.companyProfile.address, 'Rue des Écoles 12');
    expect(second.companyProfile.preventionAdvisor, 'Vincent Legrand');
  });

  testWidgets('company analysis card exposes open export word and delete', (
    tester,
  ) async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE\nAction : obtenir PV RGIE',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-0045',
    )).project;

    await tester.pumpWidget(
      MaterialApp(
        home: CompanyFolderDetailScreen(companyKey: project.companyKey),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir'), findsWidgets);
    expect(find.text('Exporter PDF'), findsOneWidget);
    expect(find.text('Télécharger Word'), findsOneWidget);
    expect(find.text('Supprimer'), findsWidgets);
  });

  testWidgets('PIU screen displays candidates and can validate one', (
    tester,
  ) async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques — Ascenseur',
      markdown:
          'Entreprise : SPGE\nProcédure personne bloquée ascenseur à intégrer au PIU.',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-ASC',
    )).project;
    expect(project.piuItems, isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(home: CompanyPiuScreen(companyKey: project.companyKey)),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Informations issues des analyses de risques'),
      findsOneWidget,
    );
    expect(find.textContaining('personne bloquée'), findsWidgets);
    await tester.tap(find.text('Valider').first);
    await tester.pumpAndSettle();

    final updated = await service.findByKey(project.companyKey);
    expect(updated!.piuItems.any((item) => item.status == 'validé'), isTrue);
    expect(
      find.text('Informations issues des analyses de risques — À valider : 0'),
      findsOneWidget,
    );
    expect(find.text('Points validés : 1'), findsOneWidget);
  });

  testWidgets('PIU status changes move items out of the validation section', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques incendie',
      markdown: '''
Entreprise : SPGE
Alerte incendie et évacuation générale à intégrer au PIU.
Accueil secours et accès pompiers à intégrer au PIU.
Point de rassemblement évacuation visiteurs à intégrer au PIU.
''',
      formData: const {'companyName': 'SPGE', 'riskProfile': 'modéré'},
      reference: 'AR-2026-FIRE',
    )).project;
    await tester.pumpWidget(
      MaterialApp(home: CompanyPiuScreen(companyKey: project.companyKey)),
    );
    await tester.pumpAndSettle();

    var updated = await service.findByKey(project.companyKey);
    var pendingCount = updated!.piuItems
        .where((item) => item.status == 'à valider')
        .length;
    expect(pendingCount, greaterThanOrEqualTo(1));
    expect(
      find.text(
        'Informations issues des analyses de risques — À valider : $pendingCount',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('À revoir').first);
    await tester.pumpAndSettle();
    updated = await service.findByKey(project.companyKey);
    pendingCount = updated!.piuItems
        .where((item) => item.status == 'à valider')
        .length;
    expect(
      find.text(
        'Informations issues des analyses de risques — À valider : $pendingCount',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Points à revoir : 1'), 300);
    expect(find.text('Points à revoir : 1'), findsOneWidget);
  });

  testWidgets('PIU ignore moves item out of the validation section', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques incendie',
      markdown:
          'Entreprise : SPGE\nAlerte incendie et évacuation générale à intégrer au PIU.',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-FIRE',
    )).project;
    await tester.pumpWidget(
      MaterialApp(home: CompanyPiuScreen(companyKey: project.companyKey)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ignorer').first);
    await tester.pumpAndSettle();

    final updated = await service.findByKey(project.companyKey);
    final pendingCount = updated!.piuItems
        .where((item) => item.status == 'à valider')
        .length;
    expect(
      find.text(
        'Informations issues des analyses de risques — À valider : $pendingCount',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Points ignorés : 1'), 300);
    expect(find.text('Points ignorés : 1'), findsOneWidget);
  });

  testWidgets('PIU review Word button exports candidate review markdown', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques — Ascenseur',
      markdown:
          'Entreprise : SPGE\nProcédure personne bloquée ascenseur à intégrer au PIU.',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-ASC',
    )).project;
    var called = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CompanyPiuScreen(
          companyKey: project.companyKey,
          piuReviewWordExporter: (context, project, document) async {
            called = true;
            expect(document.markdown, isNotEmpty);
            expect(
              document.markdown,
              contains('Revue des éléments PIU à valider'),
            );
            expect(document.markdown, contains('[ ] Valider'));
            expect(document.markdown, contains('[ ] À revoir'));
            expect(document.markdown, contains('[ ] Ignorer'));
            return '/tmp/Revue_PIU_SPGE_20260627.docx';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Télécharger Word — éléments à valider'), findsOneWidget);
    await tester.tap(find.text('Télécharger Word — éléments à valider'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(
      find.text('Document Word généré : /tmp/Revue_PIU_SPGE_20260627.docx'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Télécharger Word — PIU généré'),
      300,
    );
    expect(find.text('Télécharger Word — PIU généré'), findsOneWidget);
  });

  testWidgets('PIU review Word button reports empty export when no candidate', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime(2026, 6, 27);
    await service.saveProject(
      PreventiaCompanyProject(
        id: 'empty',
        companyName: 'SPGE',
        companyKey: 'spge',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: CompanyPiuScreen(companyKey: 'spge')),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.text('Télécharger Word — éléments à valider'),
    );
    await tester.tap(find.text('Télécharger Word — éléments à valider'));
    await tester.pumpAndSettle();

    expect(find.text('Aucun élément PIU à exporter.'), findsOneWidget);
  });

  testWidgets('PGA screen displays actions and can validate one', (
    tester,
  ) async {
    final base = (await service.addRiskAssessment(
      documentType: 'Analyse de risques — Installations électriques BT/HT',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-ELEC',
    )).project;
    final now = DateTime(2026, 6, 27);
    final project = base.copyWith(
      actionItems: [
        PreventiaActionItem(
          id: 'action-concrete-pga',
          sourceDocumentId: base.analyses.first.id,
          sourceDocumentType:
              'Analyse de risques — Installations électriques BT/HT',
          action:
              'Dégager les voies, marquer les zones interdites au stockage et contrôler quotidiennement.',
          priority: 'Court terme',
          responsible: '',
          deadline: '1 à 3 mois',
          status: 'à valider',
          evidenceExpected: '',
          destination: 'PGA/PAA/PGP',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    await service.saveProject(project);
    expect(project.actionItems, isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(home: CompanyPgaScreen(companyKey: project.companyKey)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actions issues des analyses de risques'), findsOneWidget);
    expect(find.textContaining('Dégager les voies'), findsWidgets);
    await tester.tap(find.text('Valider').first);
    await tester.pumpAndSettle();

    final updated = await service.findByKey(project.companyKey);
    expect(updated!.actionItems.any((item) => item.status == 'validé'), isTrue);
  });

  testWidgets('PIU generation without validated item shows message', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques — Ascenseur',
      markdown:
          'Entreprise : SPGE\nProcédure personne bloquée ascenseur à intégrer au PIU.',
      formData: const {'companyName': 'SPGE'},
    )).project;
    await tester.pumpWidget(
      MaterialApp(home: CompanyPiuScreen(companyKey: project.companyKey)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Générer PIU avec éléments validés'),
      300,
    );
    await tester.ensureVisible(find.text('Générer PIU avec éléments validés'));
    await tester.tap(find.text('Générer PIU avec éléments validés'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Aucun élément PIU validé. Validez d’abord des points candidats ou générez un modèle vierge.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('PGA generation without validated action shows message', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques — Installations électriques BT/HT',
      markdown: 'Entreprise : SPGE\nAction : obtenir PV RGIE.',
      formData: const {'companyName': 'SPGE'},
    )).project;
    await tester.pumpWidget(
      MaterialApp(home: CompanyPgaScreen(companyKey: project.companyKey)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Générer avec actions validées'),
      300,
    );
    await tester.ensureVisible(find.text('Générer avec actions validées'));
    await tester.tap(find.text('Générer avec actions validées'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Aucune action validée. Validez d’abord des actions candidates ou générez un modèle vierge.',
      ),
      findsOneWidget,
    );
  });

  test('blank PIU generation saves full document markdown', () async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    )).project;

    final updated = await service.generatePiuDocument(
      companyKey: project.companyKey,
      withValidatedItems: false,
    );

    expect(updated?.piuDocument?.markdown, isNotEmpty);
    expect(updated?.piuDocument?.markdown, contains('Plan Interne d’Urgence'));
    expect(updated?.piuDocument?.markdown, contains('FICHE 00'));
    expect(updated?.piuDocument?.markdown, contains('FICHE 22'));
    expect(updated?.piuDocument?.status, 'généré');
    expect(
      updated?.documents.map((item) => item.id),
      contains(updated?.piuDocument?.id),
    );
  });

  test('PIU with validated items saves importedPiuItems and content', () async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques — Ascenseur',
      markdown:
          'Entreprise : SPGE\nProcédure personne bloquée ascenseur à intégrer au PIU.',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-ASC',
    )).project;
    await service.updatePiuStatus(
      companyKey: project.companyKey,
      itemId: project.piuItems.first.id,
      status: 'validé',
    );
    final updated = await service.generatePiuDocument(
      companyKey: project.companyKey,
      withValidatedItems: true,
    );

    expect(updated?.piuDocument?.markdown, contains('personne bloquée'));
    expect(updated?.piuDocument?.formData['mode'], 'with_validated_items');
    expect(updated?.piuDocument?.formData['importedPiuItems'], hasLength(1));
    expect(
      (updated?.piuDocument?.formData['importedPiuItems'] as List)
          .single['sourceDocumentType'],
      'Analyse de risques — Ascenseur',
    );
  });

  testWidgets('PIU export buttons require generated markdown', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    )).project;
    await tester.pumpWidget(
      MaterialApp(home: CompanyPiuScreen(companyKey: project.companyKey)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Télécharger Word — PIU généré'));
    await tester.tap(find.text('Télécharger Word — PIU généré'));
    await tester.pumpAndSettle();
    expect(find.text('Générez d’abord le PIU.'), findsOneWidget);
    await tester.ensureVisible(find.text('Exporter PDF — PIU généré'));
    await tester.tap(find.text('Exporter PDF — PIU généré'));
    await tester.pumpAndSettle();
    expect(find.text('Générez d’abord le PIU.'), findsOneWidget);
  });

  test('blank PGA generation saves structured markdown', () async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    )).project;

    final updated = await service.generatePgaDocument(
      companyKey: project.companyKey,
      withValidatedActions: false,
    );

    expect(updated?.pgaDocument?.markdown, isNotEmpty);
    expect(updated?.pgaDocument?.markdown, contains('PGA / PAA / PGP — SPGE'));
    expect(updated?.pgaDocument?.markdown, contains('## 10. Signatures'));
    expect(updated?.pgaDocument?.status, 'généré');
  });

  test('review candidate classification keeps only business decisions', () {
    void expectIgnored(String value) {
      final classification = classifyReviewCandidate(value);
      expect(classification.shouldReview, isFalse, reason: value);
    }

    expectIgnored('additionalInformation');
    expectIgnored('documentType');
    expectIgnored('Page 1 / 1');
    expectIgnored('Livre III');
    expectIgnored('Méthode de cotation');

    var classification = classifyReviewCandidate(
      'Vérifier la compatibilité, la ventilation et les quantités stockées.',
    );
    expect(classification.shouldReview, isTrue);
    expect(classification.destination, 'pgp');

    classification = classifyReviewCandidate(
      'Dégager les voies d’évacuation et contrôler quotidiennement.',
    );
    expect(classification.shouldReview, isTrue);
    expect(classification.destination, 'pgp');

    classification = classifyReviewCandidate('Point de rassemblement');
    expect(classification.shouldReview, isTrue);
    expect(classification.destination, 'piu');

    classification = classifyReviewCandidate('Avis CPPT à confirmer');
    expect(classification.shouldReview, isTrue);
    expect(classification.destination, 'validationPoint');

    classification = classifyReviewCandidate('Rapport extincteurs à obtenir');
    expect(classification.shouldReview, isTrue);
    expect(classification.destination, 'evidence');
  });

  test('review document contains only reviewable candidates', () async {
    final base = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    )).project;
    final now = DateTime(2026, 6, 27);
    final project = base.copyWith(
      actionItems: [
        PreventiaActionItem(
          id: 'action-reviewable',
          sourceDocumentId: base.analyses.first.id,
          sourceDocumentType: 'Analyse de risques générale',
          action: 'Dégager les voies d’évacuation.',
          priority: 'Court terme',
          responsible: '',
          deadline: '',
          status: 'à valider',
          evidenceExpected: '',
          destination: 'PGA/PAA/PGP',
          createdAt: now,
          updatedAt: now,
        ),
        PreventiaActionItem(
          id: 'action-technical',
          sourceDocumentId: base.analyses.first.id,
          sourceDocumentType: 'Analyse de risques générale',
          action: 'additionalInformation',
          priority: '',
          responsible: '',
          deadline: '',
          status: 'à valider',
          evidenceExpected: '',
          destination: 'PGA/PAA/PGP',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    final markdown = buildPgpReviewMarkdown(project);

    expect(markdown, contains('Dégager les voies'));
    expect(markdown, isNot(contains('additionalInformation')));
    expect(markdown, isNot(contains('Page 1 / 1')));
    expect(markdown, isNot(contains('Méthode de cotation')));
  });

  test('PGA uses only validated PGP destination items', () async {
    final base = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    )).project;
    final now = DateTime(2026, 6, 27);
    final project = base.copyWith(
      actionItems: [
        PreventiaActionItem(
          id: 'action-pgp-valid',
          sourceDocumentId: base.analyses.first.id,
          sourceDocumentType: 'Analyse de risques générale',
          action: 'Dégager les voies d’évacuation.',
          priority: 'Court terme',
          responsible: '',
          deadline: '',
          status: 'validé',
          evidenceExpected: '',
          destination: 'PGA/PAA/PGP',
          createdAt: now,
          updatedAt: now,
        ),
        PreventiaActionItem(
          id: 'action-technical-valid',
          sourceDocumentId: base.analyses.first.id,
          sourceDocumentType: 'Analyse de risques générale',
          action: 'Page 1 / 1',
          priority: 'Court terme',
          responsible: '',
          deadline: '',
          status: 'validé',
          evidenceExpected: '',
          destination: 'PGA/PAA/PGP',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    await service.saveProject(project);

    final updated = await service.generatePgaDocument(
      companyKey: project.companyKey,
      withValidatedActions: true,
    );
    final markdown = updated!.pgaDocument!.markdown;

    expect(markdown, contains('Dégager les voies d’évacuation'));
    expect(markdown, isNot(contains('Page 1 / 1')));
  });

  test('PIU uses only validated PIU destination items', () async {
    final base = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    )).project;
    final project = base.copyWith(
      piuItems: [
        PreventiaPiuItem(
          id: 'piu-valid',
          sourceDocumentId: base.analyses.first.id,
          emergencyTopic: 'Point de rassemblement',
          information: 'Point de rassemblement à confirmer.',
          location: '',
          actionRequired: 'Intégrer la procédure au PIU.',
          status: 'validé',
        ),
        PreventiaPiuItem(
          id: 'piu-technical',
          sourceDocumentId: base.analyses.first.id,
          emergencyTopic: 'Page 1 / 1',
          information: 'Page 1 / 1',
          location: '',
          actionRequired: '',
          status: 'validé',
        ),
      ],
    );
    await service.saveProject(project);

    final updated = await service.generatePiuDocument(
      companyKey: project.companyKey,
      withValidatedItems: true,
    );
    final markdown = updated!.piuDocument!.markdown;

    expect(markdown, contains('Point de rassemblement'));
    expect(markdown, isNot(contains('Page 1 / 1')));
  });

  test('new analysis enriches existing prevention folder', () async {
    final now = DateTime(2026, 6, 27);
    final first = (await service.addRiskAssessment(
      documentType: 'Analyse de risques incendie',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-001',
    )).project;
    final firstAnalysisId = first.analyses.first.id;
    final initialProject = first.copyWith(
      piuItems: [
        PreventiaPiuItem(
          id: 'piu-old-1',
          sourceDocumentId: firstAnalysisId,
          emergencyTopic: 'Point de rassemblement évacuation',
          information: 'Point de rassemblement à confirmer.',
          location: '',
          actionRequired: 'Intégrer le point de rassemblement au PIU.',
          status: 'validé',
          destination: 'piu',
        ),
        PreventiaPiuItem(
          id: 'piu-old-2',
          sourceDocumentId: firstAnalysisId,
          emergencyTopic: 'Ascenseur personne bloquée',
          information: 'Personne bloquée à prendre en charge.',
          location: '',
          actionRequired: 'Prévoir la procédure personne bloquée.',
          status: 'validé',
          destination: 'piu',
        ),
      ],
      actionItems: [
        PreventiaActionItem(
          id: 'pgp-old-1',
          sourceDocumentId: firstAnalysisId,
          sourceDocumentType: 'Analyse de risques incendie',
          action: 'Dégager les voies d’évacuation.',
          priority: 'Court terme',
          responsible: '',
          deadline: '1 à 3 mois',
          status: 'validé',
          evidenceExpected: '',
          destination: 'pgp',
          createdAt: now,
          updatedAt: now,
        ),
        PreventiaActionItem(
          id: 'pgp-old-2',
          sourceDocumentId: firstAnalysisId,
          sourceDocumentType: 'Analyse de risques incendie',
          action: 'Rendre les équipements visibles et accessibles.',
          priority: 'Court terme',
          responsible: '',
          deadline: '1 à 3 mois',
          status: 'validé',
          evidenceExpected: '',
          destination: 'pgp',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    await service.saveProject(initialProject);

    final generatedPiu = await service.generatePiuDocument(
      companyKey: initialProject.companyKey,
      withValidatedItems: true,
    );
    final generatedPga = await service.generatePgaDocument(
      companyKey: initialProject.companyKey,
      withValidatedActions: true,
    );
    final oldPiuId = generatedPiu!.piuDocument!.id;
    final oldPgaId = generatedPga!.pgaDocument!.id;
    final oldPiuMarkdown = generatedPiu.piuDocument!.markdown;
    final oldPgaMarkdown = generatedPga.pgaDocument!.markdown;

    final afterSecond = (await service.addRiskAssessment(
      documentType: 'Analyse de risques circulation interne',
      markdown: '''
Entreprise : SPGE
Action : sécuriser la zone de circulation.
Point de rassemblement secondaire à intégrer au PIU.
''',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-002',
    )).project;

    expect(afterSecond.analyses, hasLength(2));
    expect(afterSecond.piuDocument?.id, oldPiuId);
    expect(afterSecond.pgaDocument?.id, oldPgaId);
    expect(afterSecond.piuDocument?.markdown, oldPiuMarkdown);
    expect(afterSecond.pgaDocument?.markdown, oldPgaMarkdown);
    expect(
      afterSecond.piuItems.where((item) => item.status == 'validé'),
      hasLength(2),
    );
    expect(
      afterSecond.actionItems.where((item) => item.status == 'validé'),
      hasLength(2),
    );

    final secondAnalysisId = afterSecond.analyses
        .firstWhere((item) => item.reference == 'AR-2026-002')
        .id;
    final enriched = afterSecond.copyWith(
      piuItems: [
        ...afterSecond.piuItems.where((item) => item.status == 'validé'),
        PreventiaPiuItem(
          id: 'piu-new-1',
          sourceDocumentId: secondAnalysisId,
          emergencyTopic: 'Fuite de gaz',
          information: 'Fuite de gaz à intégrer.',
          location: '',
          actionRequired: 'Formaliser la procédure fuite de gaz.',
          status: 'à valider',
          destination: 'piu',
        ),
        PreventiaPiuItem(
          id: 'piu-new-duplicate',
          sourceDocumentId: secondAnalysisId,
          emergencyTopic: 'Fuite de gaz',
          information: 'Fuite de gaz à intégrer.',
          location: '',
          actionRequired: 'Formaliser la procédure fuite de gaz.',
          status: 'à valider',
          destination: 'piu',
        ),
      ],
      actionItems: [
        ...afterSecond.actionItems.where((item) => item.status == 'validé'),
        PreventiaActionItem(
          id: 'pgp-new-1',
          sourceDocumentId: secondAnalysisId,
          sourceDocumentType: 'Analyse de risques circulation interne',
          action: 'Sécuriser la zone de circulation.',
          priority: 'Court terme',
          responsible: '',
          deadline: '1 à 3 mois',
          status: 'à valider',
          evidenceExpected: '',
          destination: 'pgp',
          createdAt: now,
          updatedAt: now,
        ),
        PreventiaActionItem(
          id: 'pgp-new-duplicate',
          sourceDocumentId: secondAnalysisId,
          sourceDocumentType: 'Analyse de risques circulation interne',
          action: 'Sécuriser la zone de circulation.',
          priority: 'Court terme',
          responsible: '',
          deadline: '1 à 3 mois',
          status: 'à valider',
          evidenceExpected: '',
          destination: 'pgp',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    await service.saveProject(enriched);

    final pendingProject = await service.findByKey(enriched.companyKey);
    expect(
      pendingProject!.piuItems.where((item) => item.status == 'validé'),
      hasLength(2),
    );
    expect(
      pendingProject.piuItems.where((item) => item.status == 'à valider'),
      hasLength(2),
    );
    expect(
      pendingProject.actionItems.where((item) => item.status == 'validé'),
      hasLength(2),
    );
    expect(
      pendingProject.actionItems.where((item) => item.status == 'à valider'),
      hasLength(2),
    );

    for (final item in pendingProject.piuItems.where(
      (item) => item.status == 'à valider',
    )) {
      await service.updatePiuStatus(
        companyKey: pendingProject.companyKey,
        itemId: item.id,
        status: 'validé',
      );
    }
    final withPiuValidated = await service.findByKey(pendingProject.companyKey);
    for (final item in withPiuValidated!.actionItems.where(
      (item) => item.status == 'à valider',
    )) {
      await service.updateActionStatus(
        companyKey: withPiuValidated.companyKey,
        itemId: item.id,
        status: 'validé',
      );
    }

    final finalPiuProject = await service.generatePiuDocument(
      companyKey: pendingProject.companyKey,
      withValidatedItems: true,
    );
    final finalPgaProject = await service.generatePgaDocument(
      companyKey: pendingProject.companyKey,
      withValidatedActions: true,
    );
    final piuMarkdown = finalPiuProject!.piuDocument!.markdown;
    final pgaMarkdown = finalPgaProject!.pgaDocument!.markdown;
    final piuAnalysisSection = piuMarkdown
        .split('## 3. Informations issues des analyses de risques')
        .last
        .split('## 4. Fiches réflexes')
        .first;
    final pgaSynthesis = pgaMarkdown
        .split('## 4. Synthèse des actions retenues')
        .last
        .split('## 5. Plan Annuel')
        .first;

    expect(piuMarkdown, contains('Point de rassemblement'));
    expect(piuMarkdown, contains('Ascenseur personne bloquée'));
    expect(piuMarkdown, contains('Fuite de gaz'));
    expect('- **Fuite de gaz**'.allMatches(piuAnalysisSection), hasLength(1));
    expect(pgaMarkdown, contains('Dégager les voies d’évacuation'));
    expect(pgaMarkdown, contains('Rendre les équipements visibles'));
    expect(pgaMarkdown, contains('Sécuriser la zone de circulation'));
    expect(
      'Sécuriser la zone de circulation'.allMatches(pgaSynthesis),
      hasLength(1),
    );
    expect(finalPiuProject.piuDocument!.markdown, isNotEmpty);
    expect(finalPgaProject.pgaDocument!.markdown, isNotEmpty);
  });

  test('PGA generation stops after signatures', () async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    )).project;

    final updated = await service.generatePgaDocument(
      companyKey: project.companyKey,
      withValidatedActions: false,
      markdown: '''
# PGA / PAA / PGP — SPGE

## 10. Signatures

Direction, conseiller en prévention et validation CPPT le cas échéant.

## 11. Méthode de cotation

11. Méthode de cotation

12. Tableau principal d’analyse des risques

13. Analyse des risques résiduels

Mention de validation

Page 1 / 1
''',
    );

    final markdown = updated!.pgaDocument!.markdown;
    expect(markdown, contains('## 10. Signatures'));
    expect(markdown, isNot(contains('11. Méthode de cotation')));
    expect(markdown, isNot(contains('12. Tableau principal')));
    expect(markdown, isNot(contains('13. Analyse des risques résiduels')));
    expect(markdown, isNot(contains('Mention de validation')));
    expect(markdown, isNot(contains('Page 1 / 1')));
  });

  test('PGA generation filters technical metadata and keeps real actions', () async {
    final now = DateTime(2026, 6, 27);
    final base = (await service.addRiskAssessment(
      documentType: 'Analyse de risques incendie',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-FIRE',
    )).project;
    final noisyActions = <String>[
      'additionalInformation : vérifier champ brut',
      'documentType : Analyse de risques incendie',
      'safetyDataSheetsAvailable : vérifier si les FDS sont disponibles',
      'jobObservationDone : valider observation au poste',
      'vehiclePedestrianTraffic : contrôler circulation',
      'newWorkers : informer accueil',
      'dangerousMachines : vérifier inventaire',
      'dangerousProducts : documenter liste',
      'measuresToVerify : valider mesures',
      'Le conseiller en prévention niveau 3 Valider la méthode',
      'Employeur ou ligne hiérarchique Valider le plan',
      'Famille de danger | Danger précis | Scénario plausible',
      'Livre III - vérifier référence réglementaire',
      'Page 1 / 1',
      'Vérifier compatibilité, ventilation, quantités stockées et séparation des produits 1. Incendie lié aux produits inflammables SIPPT / responsable de site À planifier avant validation.',
      'Dégager les voies, marquer les zones interdites au stockage et contrôler quotidiennement 3. Obstruction des issues de secours Responsable logistique.',
      'Rendre les équipements visibles et accessibles, ajouter marquage au sol si nécessaire.',
      'Supprimer les cales, vérifier fermeture automatique et sensibiliser le personnel.',
      'Centraliser FDS, vérifier étiquetage CLP et séparer incompatibilités.',
    ];
    final project = base.copyWith(
      actionItems: noisyActions
          .asMap()
          .entries
          .map(
            (entry) => PreventiaActionItem(
              id: 'action-${entry.key}',
              sourceDocumentId: base.analyses.first.id,
              sourceDocumentType: 'Analyse de risques incendie',
              action: entry.value,
              priority: entry.key >= 5 ? 'Court terme' : '',
              responsible: '',
              deadline: entry.key >= 5 ? '1 à 3 mois' : '',
              status: entry.key >= 14 ? 'validé' : 'à valider',
              evidenceExpected: entry.value.contains('FDS')
                  ? 'FDS et photos à obtenir'
                  : '',
              destination: 'PGA/PAA/PGP',
              createdAt: now,
              updatedAt: now,
            ),
          )
          .toList(growable: false),
      evidenceItems: [
        PreventiaEvidenceItem(
          id: 'evidence-1',
          sourceDocumentId: base.analyses.first.id,
          label: 'Rapport de visite terrain à obtenir',
          location: '',
          type: 'preuve',
          status: 'à valider',
        ),
        PreventiaEvidenceItem(
          id: 'evidence-2',
          sourceDocumentId: base.analyses.first.id,
          label:
              'N° Mesure complémentaire | Risque concerné | Action à réaliser | Responsable | Échéance | Preuve attendue',
          location: '',
          type: 'preuve',
          status: 'à valider',
        ),
        PreventiaEvidenceItem(
          id: 'evidence-3',
          sourceDocumentId: base.analyses.first.id,
          label:
              '11. Méthode de cotation\n12. Tableau principal d’analyse des risques\n13. Analyse des risques résiduels\nSCÉNARIO TEST SPGE\nadditionalInformation',
          location: '',
          type: 'preuve',
          status: 'à valider',
        ),
      ],
      pointsToVerify: const [
        'CPPT à confirmer',
        'Avis externe expert incendie',
      ],
    );
    await service.saveProject(project);

    final updated = await service.generatePgaDocument(
      companyKey: project.companyKey,
      withValidatedActions: true,
    );
    final markdown = updated!.pgaDocument!.markdown;

    expect(markdown, contains('## 4. Synthèse des actions retenues'));
    expect(markdown, contains('Vérifier la compatibilité'));
    expect(markdown, contains('Dégager les voies d’évacuation'));
    expect(markdown, contains('Rendre les équipements visibles'));
    expect(markdown, contains('Supprimer les cales'));
    expect(markdown, contains('Centraliser les FDS'));
    expect(markdown, contains('## 7. Preuves à obtenir'));
    expect(markdown, contains('Rapport de visite terrain.'));
    expect(markdown, isNot(contains('additionalInformation')));
    expect(markdown, isNot(contains('documentType')));
    expect(markdown, isNot(contains('safetyDataSheetsAvailable')));
    expect(markdown, isNot(contains('jobObservationDone')));
    expect(markdown, isNot(contains('vehiclePedestrianTraffic')));
    expect(markdown, isNot(contains('newWorkers :')));
    expect(markdown, isNot(contains('dangerousMachines')));
    expect(markdown, isNot(contains('dangerousProducts')));
    expect(markdown, isNot(contains('measuresToVerify')));
    expect(markdown, isNot(contains('Le conseiller en prévention niveau 3')));
    expect(markdown, isNot(contains('Employeur ou ligne hiérarchique')));
    expect(markdown, isNot(contains('Famille de danger')));
    expect(markdown, isNot(contains('Livre III')));
    expect(markdown, isNot(contains('Page 1 / 1')));
    expect(markdown, isNot(contains('N° Mesure complémentaire')));
    expect(markdown, isNot(contains('Méthode de cotation')));
    expect(markdown, isNot(contains('Tableau principal d’analyse')));
    expect(markdown, isNot(contains('Analyse des risques résiduels')));
    expect(markdown, isNot(contains('SCÉNARIO TEST')));
    expect(markdown, isNot(contains('## 13. Analyse des risques résiduels')));
    expect(markdown, contains('## 8. Points à vérifier avant validation'));

    final synthesis = markdown
        .split('## 4. Synthèse des actions retenues')
        .last
        .split('## 5. Plan Annuel')
        .first;
    final actionLines = synthesis
        .split('\n')
        .where((line) => RegExp(r'^\|\s*\d+\s*\|').hasMatch(line))
        .length;
    expect(actionLines, lessThan(50));
  });

  test('PGA with validated actions contains validated actions', () async {
    final base = (await service.addRiskAssessment(
      documentType: 'Analyse de risques — Installations électriques BT/HT',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-ELEC',
    )).project;
    final now = DateTime(2026, 6, 27);
    final project = base.copyWith(
      actionItems: [
        PreventiaActionItem(
          id: 'action-concrete-pga',
          sourceDocumentId: base.analyses.first.id,
          sourceDocumentType:
              'Analyse de risques — Installations électriques BT/HT',
          action:
              'Dégager les voies, marquer les zones interdites au stockage et contrôler quotidiennement.',
          priority: 'Court terme',
          responsible: '',
          deadline: '1 à 3 mois',
          status: 'à valider',
          evidenceExpected: '',
          destination: 'PGA/PAA/PGP',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    await service.saveProject(project);
    await service.updateActionStatus(
      companyKey: project.companyKey,
      itemId: project.actionItems.first.id,
      status: 'validé',
    );

    final updated = await service.generatePgaDocument(
      companyKey: project.companyKey,
      withValidatedActions: true,
    );

    expect(
      updated?.pgaDocument?.markdown,
      contains('Dégager les voies d’évacuation'),
    );
    expect(updated?.pgaDocument?.formData['mode'], 'with_validated_actions');
    expect(
      updated?.pgaDocument?.formData['importedActionItems'],
      contains(
        isA<Map>().having(
          (item) => item['title'],
          'title',
          contains('Dégager les voies d’évacuation'),
        ),
      ),
    );
  });

  test(
    'PGA extracts validated actions from multiple stored analyses',
    () async {
      final fire = (await service.addRiskAssessment(
        documentType: 'Analyse de risques incendie / évacuation',
        markdown: '''
Entreprise : SPGE
Voies d’évacuation, moyens d’extinction, portes coupe-feu et accès pompiers.
additionalInformation : texte technique à ignorer.
Page 1 / 1
Méthode de cotation
Conclusion
''',
        formData: const {'companyName': 'SPGE', 'documentType': 'metadata'},
        reference: 'AR-2026-FIRE',
      )).project;
      final electrical = (await service.addRiskAssessment(
        documentType: 'Analyse de risques — Installations électriques BT/HT',
        markdown: '''
Entreprise : SPGE
PV RGIE, habilitations BA4/BA5, schémas électriques et coupure d’urgence.
Livre III
Tableau principal d’analyse des risques
''',
        formData: const {'companyName': 'SPGE', 'additionalInformation': 'x'},
        reference: 'AR-2026-ELEC',
      )).project;
      final validatedProject = electrical.copyWith(
        analyses: electrical.analyses
            .map((item) => item.copyWith(status: 'validé'))
            .toList(growable: false),
        documents: electrical.documents
            .map(
              (item) => item.documentType.contains('Analyse de risques')
                  ? item.copyWith(status: 'validé')
                  : item,
            )
            .toList(growable: false),
      );
      await service.saveProject(validatedProject);

      final updated = await service.generatePgaDocument(
        companyKey: fire.companyKey,
        withValidatedActions: true,
      );
      final markdown = updated!.pgaDocument!.markdown;

      expect(markdown, contains('Dégager les voies d’évacuation'));
      expect(markdown, contains('Rendre les moyens d’extinction visibles'));
      expect(markdown, contains('Obtenir ou vérifier le PV RGIE'));
      expect(markdown, contains('Vérifier les habilitations BA4/BA5'));
      expect(markdown, contains('Mettre à jour les schémas électriques'));
      expect(
        markdown,
        contains('Formaliser la procédure de coupure électrique d’urgence'),
      );
      expect(markdown, isNot(contains('Aucune action exploitable')));
      expect(markdown, isNot(contains('additionalInformation')));
      expect(markdown, isNot(contains('documentType')));
      expect(markdown, isNot(contains('Page 1 / 1')));
      expect(markdown, isNot(contains('Livre III')));
      expect(markdown, isNot(contains('Méthode de cotation')));
      expect(markdown, isNot(contains('Conclusion')));
    },
  );

  test('PGA sources and PIU categories stay tied to each analysis', () async {
    await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE\nSynthèse générale du site.',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-0066',
    );
    await service.addRiskAssessment(
      documentType: 'Analyse de risques — Ascenseur',
      markdown: '''
Entreprise : SPGE
Personne bloquée en cabine, appel d’urgence cabine et contacts maintenance.
Page 1 / 1
''',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-0068',
    );
    await service.addRiskAssessment(
      documentType: 'Analyse de risques — Installations électriques BT/HT',
      markdown: '''
Entreprise : SPGE
PV RGIE, BA4/BA5, schémas électriques, coupure électrique d’urgence,
accès TGBT pour les secours, dossier pompiers et plans des coupures.
Référence AR-2026-0069 — Page 1 / 1
''',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-0069',
    );
    await service.addRiskAssessment(
      documentType: 'Analyse de risques ergonomie / postes écran',
      markdown: '''
Entreprise : SPGE
Postes écran, câbles accueil, reflets, éclairage, télétravail, manutention et bruit.
''',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-0070',
    );
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques incendie / évacuation',
      markdown: '''
Entreprise : SPGE
Voies d’évacuation, moyens d’extinction, portes coupe-feu et accès pompiers.
''',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-0071',
    )).project;

    final byReference = {
      for (final analysis in project.analyses) analysis.reference: analysis.id,
    };
    final now = DateTime(2026, 6, 28);
    final withValidatedPiu = project.copyWith(
      piuItems: [
        PreventiaPiuItem(
          id: 'piu-electric-specific',
          sourceDocumentId: byReference['AR-2026-0069']!,
          emergencyTopic: 'Coupure électrique d’urgence',
          information:
              'Accès TGBT pour les secours, dossier pompiers et plans des coupures.',
          location: 'Local technique',
          actionRequired: 'Formaliser la fiche coupure courant / délestage.',
          status: 'validé',
          destination: 'piu',
        ),
        PreventiaPiuItem(
          id: 'piu-electric-generic',
          sourceDocumentId: byReference['AR-2026-0069']!,
          emergencyTopic: 'Installation électrique BT/HT',
          information: 'PV RGIE et contrôle périodique.',
          location: 'Local technique',
          actionRequired: 'Suivi documentaire.',
          status: 'validé',
          destination: 'piu',
        ),
        PreventiaPiuItem(
          id: 'piu-elevator-specific',
          sourceDocumentId: byReference['AR-2026-0068']!,
          emergencyTopic: 'Personne bloquée en cabine',
          information: 'Appel d’urgence cabine et contacts maintenance.',
          location: 'Ascenseur',
          actionRequired: 'Organiser la procédure de secours ascenseur.',
          status: 'validé',
          destination: 'piu',
        ),
        PreventiaPiuItem(
          id: 'piu-elevator-generic',
          sourceDocumentId: byReference['AR-2026-0068']!,
          emergencyTopic: 'Ascenseur contrôle périodique',
          information: 'Rapport SECT.',
          location: 'Ascenseur',
          actionRequired: 'Suivi documentaire.',
          status: 'validé',
          destination: 'piu',
        ),
      ],
      actionItems: [
        ...project.actionItems,
        PreventiaActionItem(
          id: 'action-noisy-ergonomics',
          sourceDocumentId: byReference['AR-2026-0070']!,
          sourceDocumentType: 'Analyse de risques ergonomie / postes écran',
          action: 'Organisationnelle + Protection individuelle',
          priority: 'Court terme',
          responsible: '',
          deadline: '',
          status: 'validé',
          evidenceExpected: '',
          destination: 'PGA/PAA/PGP',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    await service.saveProject(withValidatedPiu);

    final pgaProject = await service.generatePgaDocument(
      companyKey: project.companyKey,
      withValidatedActions: true,
    );
    final imported =
        pgaProject!.pgaDocument!.formData['importedActionItems'] as List;
    Map sourceFor(String title) => imported.cast<Map>().firstWhere(
      (item) => item['title'].toString().contains(title),
    );

    expect(
      sourceFor('Obtenir ou vérifier le PV RGIE')['sourceDocumentReference'],
      'AR-2026-0069',
    );
    expect(
      sourceFor('Tester l’appel d’urgence')['sourceDocumentReference'],
      'AR-2026-0068',
    );
    expect(
      sourceFor('Adapter les postes écran')['sourceDocumentReference'],
      'AR-2026-0070',
    );
    expect(
      sourceFor('Dégager les voies d’évacuation')['sourceDocumentReference'],
      'AR-2026-0071',
    );
    expect(
      pgaProject.pgaDocument!.markdown,
      isNot(contains('Organisationnelle + Protection individuelle')),
    );
    expect(pgaProject.pgaDocument!.markdown, isNot(contains('Page 1 / 1')));

    final piuProject = await service.generatePiuDocument(
      companyKey: project.companyKey,
      withValidatedItems: true,
    );
    final piuMarkdown = piuProject!.piuDocument!.markdown;
    final piuAnalysisSection = piuMarkdown
        .split('## 3. Informations issues des analyses de risques')
        .last
        .split('## 4. Fiches réflexes')
        .first;

    expect(piuAnalysisSection, contains('Coupure électrique d’urgence'));
    expect(
      piuAnalysisSection,
      contains('Coupures techniques et dossier pompiers'),
    );
    expect(piuAnalysisSection, contains('Personne bloquée en cabine'));
    expect(piuAnalysisSection, contains('Ascenseurs et personnes bloquées'));
    expect(
      piuAnalysisSection,
      isNot(contains('Installation électrique BT/HT')),
    );
    expect(
      piuAnalysisSection,
      isNot(contains('Ascenseur contrôle périodique')),
    );
    expect(piuAnalysisSection, isNot(contains('Incendie et évacuation')));
    expect(piuMarkdown, isNot(contains('Page 1 / 1')));
  });

  testWidgets('PGA export buttons require generated markdown', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE\nAction : obtenir PV RGIE.',
      formData: const {'companyName': 'SPGE'},
    )).project;
    await tester.pumpWidget(
      MaterialApp(home: CompanyPgaScreen(companyKey: project.companyKey)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Télécharger Word'), 300);
    await tester.ensureVisible(find.text('Télécharger Word'));
    await tester.tap(find.text('Télécharger Word'));
    await tester.pumpAndSettle();
    expect(find.text('Générez d’abord le PGA/PAA/PGP.'), findsOneWidget);
    await tester.ensureVisible(find.text('Exporter PDF'));
    await tester.tap(find.text('Exporter PDF'));
    await tester.pumpAndSettle();
    expect(find.text('Générez d’abord le PGA/PAA/PGP.'), findsOneWidget);
  });

  test('generated document export paths are saved locally', () async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    )).project;
    final withPiu = await service.generatePiuDocument(
      companyKey: project.companyKey,
      withValidatedItems: false,
    );
    await service.updateGeneratedDocumentExportPaths(
      companyKey: project.companyKey,
      documentId: withPiu!.piuDocument!.id,
      wordPath: '/tmp/PIU_SPGE_20260626.docx',
      pdfPath: '/tmp/PIU_SPGE_20260626.pdf',
    );
    final updated = await service.findByKey(project.companyKey);

    expect(updated?.piuDocument?.wordPath, endsWith('.docx'));
    expect(updated?.piuDocument?.pdfPath, endsWith('.pdf'));
  });

  test('validated items are exported in generation formData only', () async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques — Ascenseur',
      markdown: '''
Entreprise : SPGE
Action : obtenir rapport SECT.
Action : tester communication bidirectionnelle.
Appel 112 personne bloquée ascenseur à intégrer au PIU.
Accueil secours pour personne bloquée ascenseur à intégrer au PIU.
''',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-ASC',
    )).project;
    await service.updateActionStatus(
      companyKey: project.companyKey,
      itemId: project.actionItems.first.id,
      status: 'validé',
    );
    await service.updateActionStatus(
      companyKey: project.companyKey,
      itemId: project.actionItems.last.id,
      status: 'ignoré',
    );
    await service.updatePiuStatus(
      companyKey: project.companyKey,
      itemId: project.piuItems.first.id,
      status: 'validé',
    );
    await service.updatePiuStatus(
      companyKey: project.companyKey,
      itemId: project.piuItems.last.id,
      status: 'ignoré',
    );
    final updated = await service.findByKey(project.companyKey);
    final piuFormData = service.buildPiuGenerationFormData(updated!);
    final pgaFormData = service.buildPgaGenerationFormData(updated);

    expect(piuFormData['mode'], 'with_validated_items');
    expect(pgaFormData['mode'], 'with_validated_actions');
    expect(piuFormData['importedPiuItems'], hasLength(1));
    expect(pgaFormData['importedActionItems'], isNotEmpty);
    expect(
      (piuFormData['importedPiuItems'] as List).single['title'],
      isNot(contains('Accueil secours')),
    );
    expect(
      (pgaFormData['importedActionItems'] as List).map(
        (item) => (item as Map)['title'],
      ),
      isNot(contains(contains('communication bidirectionnelle'))),
    );
  });

  test('company extraction limits and deduplicates actions and PIU items', () {
    final noisyLines = List.generate(
      140,
      (index) =>
          'Action : obtenir PV RGIE et vérifier BA4/BA5 numéro ${index % 20}.',
    ).join('\n');
    final piuLines = List.generate(
      90,
      (index) =>
          'Coupure générale électrique et accès TGBT à intégrer au PIU ${index % 10}.',
    ).join('\n');
    final extraction = extractFromRiskAssessment(
      documentType: 'Analyse de risques — Installations électriques BT/HT',
      markdown:
          'Entreprise : SPGE\n[à compléter]\n## 1. Chapitre\n$noisyLines\n$piuLines',
      formData: const {'companyName': 'SPGE'},
      sourceDocumentId: 'analysis-1',
    );

    expect(extraction.actionItems.length, lessThanOrEqualTo(80));
    expect(extraction.piuItems.length, lessThanOrEqualTo(40));
    expect(
      extraction.actionItems.map((item) => item.action).toSet().length,
      extraction.actionItems.length,
    );
    expect(
      extraction.piuItems.map((item) => item.emergencyTopic).toSet().length,
      extraction.piuItems.length,
    );
  });

  test(
    'missing company falls back to company extracted from markdown',
    () async {
      final update = await service.addRiskAssessment(
        documentType: 'Analyse de risques générale',
        markdown: '| Société | SPGE |\n| Site | Verviers |',
        formData: const {},
      );
      expect(update.project.companyName, 'SPGE');
    },
  );

  testWidgets('generation shows company summary without location dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: ResultScreen(
          documentType: 'Analyse de risques générale',
          content: 'Entreprise : SPGE\nAction : contrôle à planifier',
          companyName: 'SPGE',
          formData: {'companyName': 'SPGE'},
          generationSource: GenerationSource.aiBackend,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Analyse ajoutée au dossier société'), findsOneWidget);
    expect(find.text('Créer le dossier PreventIA'), findsNothing);
    expect(find.text('Choisir un emplacement'), findsNothing);
  });

  testWidgets('FilePicker callback is only called from define folder button', (
    tester,
  ) async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    )).project;
    var pickerCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PreventiaCompanyProjectScreen(
          companyKey: project.companyKey,
          directoryPicker: () async {
            pickerCalls++;
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(pickerCalls, 0);
    expect(find.text('Définir un dossier local'), findsOneWidget);

    await tester.tap(find.byKey(const Key('define-local-folder-button')));
    await tester.pump();
    expect(pickerCalls, 1);
  });

  testWidgets('company folder reloads analysis PIU PGA and back pops', (
    tester,
  ) async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE\nAction : contrôle à planifier',
      formData: const {'companyName': 'SPGE'},
      reference: 'AR-2026-0045',
    )).project;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CompanyFolderDetailScreen(companyKey: project.companyKey),
                ),
              ),
              child: const Text('Ouvrir SPGE'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir SPGE'));
    await tester.pumpAndSettle();

    expect(find.textContaining('AR-2026-0045'), findsWidgets);
    expect(find.text('Analyses de risques'), findsOneWidget);
    expect(find.text('PIU — SPGE'), findsOneWidget);
    expect(find.text('PGA/PAA/PGP — SPGE'), findsOneWidget);
    expect(find.text('Actions extraites'), findsOneWidget);
    expect(find.text('Candidats PIU'), findsOneWidget);
    expect(find.text('Candidats DIU'), findsOneWidget);
    expect(find.text('Preuves/photos'), findsOneWidget);

    await tester.tap(find.byKey(const Key('company-folder-detail-back')));
    await tester.pumpAndSettle();
    expect(find.text('Ouvrir SPGE'), findsOneWidget);
  });

  testWidgets('company folder always renders empty section messages', (
    tester,
  ) async {
    final now = DateTime(2026, 6, 23);
    await service.saveProject(
      PreventiaCompanyProject(
        id: 'empty',
        companyName: 'Société test',
        companyKey: 'societe test',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: CompanyFolderDetailScreen(companyKey: 'societe test'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Aucune analyse de risques enregistrée dans ce dossier.'),
      findsOneWidget,
    );
    expect(find.text('PIU non créé.'), findsOneWidget);
    expect(find.text('PGA/PAA/PGP non créé.'), findsOneWidget);
    expect(find.text('Aucune action extraite pour l’instant.'), findsOneWidget);
    expect(
      find.text('Aucun point PIU extrait pour l’instant.'),
      findsOneWidget,
    );
    expect(
      find.text('Aucun point DIU extrait pour l’instant.'),
      findsOneWidget,
    );
    expect(
      find.text('Aucune preuve/photo à collecter pour l’instant.'),
      findsOneWidget,
    );
  });

  testWidgets('company detail deletes history entry and returns true', (
    tester,
  ) async {
    final project = (await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    )).project;
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => CompanyFolderDetailScreen(
                      companyKey: project.companyKey,
                    ),
                  ),
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('delete-company-folder-button')),
    );
    await tester.tap(find.byKey(const Key('delete-company-folder-button')));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer le dossier SPGE ?'), findsOneWidget);
    await tester.tap(find.text('Supprimer de l’historique'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(await service.findByKey('spge'), isNull);
  });

  testWidgets('history card delete removes only the local company entry', (
    tester,
  ) async {
    await service.addRiskAssessment(
      documentType: 'Analyse de risques générale',
      markdown: 'Entreprise : SPGE',
      formData: const {'companyName': 'SPGE'},
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: HistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SPGE'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-company-history-spge')));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer le dossier SPGE ?'), findsOneWidget);
    await tester.tap(find.text('Supprimer de l’historique'));
    await tester.pumpAndSettle();

    expect(await service.findByKey('spge'), isNull);
  });
}
