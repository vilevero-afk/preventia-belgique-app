import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/models/document_family.dart';
import 'package:preventia_belgique_app/services/docx_export_service.dart';
import 'package:preventia_belgique_app/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfExportService.normalizeFrenchText', () {
    test('restores French apostrophes and special characters', () {
      const input =
          'l entreprise, l employeur, l utilisation, l exécution, '
          'l Administration, d analyse, d Action, d action, d information, '
          'd intervention, d intégration, d évaluation, chefs d équipe, '
          'mise en uvre, man uvre, man uvres, oeuvre, Cet analyse, '
          'annue de prévention, Plan Annuel d Action, Plan Global de Prévention';

      final normalized = PdfExportService.normalizeFrenchText(input);

      expect(normalized, contains('l’entreprise'));
      expect(normalized, contains('l’employeur'));
      expect(normalized, contains('l’utilisation'));
      expect(normalized, contains('l’exécution'));
      expect(normalized, contains('l’Administration'));
      expect(normalized, contains('d’analyse'));
      expect(normalized, contains('d’Action'));
      expect(normalized, contains('d’action'));
      expect(normalized, contains('d’information'));
      expect(normalized, contains('d’intervention'));
      expect(normalized, contains('d’intégration'));
      expect(normalized, contains('d’évaluation'));
      expect(normalized, contains('chefs d’équipe'));
      expect(normalized, contains('mise en œuvre'));
      expect(normalized, contains('manœuvre'));
      expect(normalized, contains('manœuvres'));
      expect(normalized, contains('œuvre'));
      expect(normalized, contains('Cette analyse'));
      expect(normalized, contains('annuel de prévention'));
      expect(normalized, contains('Plan Annuel d’Action'));
      expect(normalized, contains('Plan Global de Prévention'));
    });

    test('keeps accents and apostrophes instead of removing Unicode', () {
      final normalized = PdfExportService.normalizeFrenchText(
        'Prévention, échéance, évaluation, œuvre, l’entreprise',
      );

      expect(
        normalized,
        'Prévention, échéance, évaluation, œuvre, l’entreprise',
      );
    });

    test('translates PDF fallback text for non-French documents', () {
      expect(
        PdfExportService.normalizePdfText(
          'Information à compléter ou à valider sur le terrain.',
          language: 'en',
        ),
        'Information to be completed or validated during the site visit.',
      );
      expect(
        PdfExportService.normalizePdfText(
          'Information à compléter ou à valider sur le terrain.',
          language: 'nl',
        ),
        'Informatie aan te vullen of te valideren tijdens het terreinbezoek.',
      );
      expect(
        PdfExportService.normalizePdfText(
          'Information à compléter ou à valider sur le terrain.',
          language: 'de',
        ),
        'Informationen sind vor Ort zu ergänzen oder zu validieren.',
      );
    });

    test('returns localized fallback text', () {
      expect(
        PdfExportService.localizedFallback('en'),
        'Information to be completed or validated during the site visit.',
      );
    });

    test(
      'fixes abnormal English apostrophes without breaking contractions',
      () {
        final normalized = PdfExportService.cleanLanguageSpecificText(
          'Municipal’Administration, municipal’interventions, '
              'specialised’interventions, road’interventions, planned’actions, '
              'closed’actions, completed’actions, structured’actions, '
              'listed’action, proposed’actions, implemented’actions, '
              'completed’action, implemented’action, completed\'action, '
              'implemented\'action, and’interventions, don’t, isn’t, worker’s, '
              'employer’s, Verviers’ local context',
          'en',
        );

        expect(normalized, contains('Municipal Administration'));
        expect(normalized, contains('municipal interventions'));
        expect(normalized, contains('specialised interventions'));
        expect(normalized, contains('road interventions'));
        expect(normalized, contains('planned actions'));
        expect(normalized, contains('closed actions'));
        expect(normalized, contains('completed actions'));
        expect(normalized, contains('structured actions'));
        expect(normalized, contains('listed action'));
        expect(normalized, contains('proposed actions'));
        expect(normalized, contains('implemented actions'));
        expect(normalized, contains('completed action'));
        expect(normalized, contains('implemented action'));
        expect(normalized, contains('and interventions'));
        expect(normalized, contains('don’t'));
        expect(normalized, contains('isn’t'));
        expect(normalized, contains('worker’s'));
        expect(normalized, contains('employer’s'));
        expect(normalized, contains('Verviers’ local context'));
      },
    );

    test('applies light German lexical cleanup before PDF rendering', () {
      final normalized = PdfExportService.normalizePdfText(
        'Verkehr Fahrzeuge/Pedestrian, Pedestrian, Photos, Plan Global de Prévention, '
        'SDS-Register, SDS, Glissaden und Stürze',
        language: 'de',
      );

      expect(normalized, contains('Fahrzeug- und Fußgängerverkehr'));
      expect(normalized, contains('Fußgänger'));
      expect(normalized, contains('Fotos'));
      expect(normalized, contains('Globaler Präventionsplan'));
      expect(normalized, contains('Sicherheitsdatenblatt-Register'));
      expect(normalized, contains('Sicherheitsdatenblatt'));
      expect(normalized, contains('Ausrutschen und Stürze'));
    });
  });

  group('PdfExportService.stripDuplicatedValidationHeading', () {
    test('removes duplicated English validation heading', () {
      expect(
        PdfExportService.stripDuplicatedValidationHeading(
          sectionTitle: '13. VALIDATION STATEMENT',
          sectionContent: 'Validation Statement:\nThis document is a draft...',
          languageCode: 'en',
        ),
        'This document is a draft...',
      );
    });

    test('removes duplicated Dutch validation heading', () {
      expect(
        PdfExportService.stripDuplicatedValidationHeading(
          sectionTitle: '13. Validatievermelding',
          sectionContent:
              '  validatievermelding  :\nDit document is een ontwerp...',
          languageCode: 'nl',
        ),
        'Dit document is een ontwerp...',
      );
    });

    test('removes duplicated German validation heading', () {
      expect(
        PdfExportService.stripDuplicatedValidationHeading(
          sectionTitle: '13. VERBINDLICHER ABSCHLUSSHINWEIS',
          sectionContent:
              'Verbindlicher Abschlusshinweis :\nDieses Dokument ist ein Entwurf...',
          languageCode: 'de',
        ),
        'Dieses Dokument ist ein Entwurf...',
      );
    });

    test('removes duplicated French validation heading', () {
      expect(
        PdfExportService.stripDuplicatedValidationHeading(
          sectionTitle: '13. Mention de validation',
          sectionContent: 'MENTION DE VALIDATION\nCe document est un projet...',
          languageCode: 'fr',
        ),
        'Ce document est un projet...',
      );
    });
  });

  group('PdfExportService document footer', () {
    test('formats localized footer text with an existing reference', () {
      expect(
        PdfExportService.documentFooterText(
          languageCode: 'fr',
          referenceNumber: 'AR-2026-0011',
          pageNumber: '1',
          pagesCount: '16',
        ),
        'Référence AR-2026-0011 — Page 1 / 16',
      );
      expect(
        PdfExportService.documentFooterText(
          languageCode: 'nl',
          referenceNumber: 'AR-2026-0011',
          pageNumber: '1',
          pagesCount: '16',
        ),
        'Referentie AR-2026-0011 — Pagina 1 / 16',
      );
      expect(
        PdfExportService.documentFooterText(
          languageCode: 'en',
          referenceNumber: 'AR-2026-0011',
          pageNumber: '1',
          pagesCount: '16',
        ),
        'Reference AR-2026-0011 — Page 1 / 16',
      );
      expect(
        PdfExportService.documentFooterText(
          languageCode: 'de',
          referenceNumber: 'AR-2026-0011',
          pageNumber: '1',
          pagesCount: '16',
        ),
        'Referenz AR-2026-0011 — Seite 1 / 16',
      );
    });

    test('extracts an existing analysis reference from supported labels', () {
      expect(
        PdfExportService.resolveDocumentReference(
          content: 'Référence / N° analyse : AR-2026-0011',
        ),
        'AR-2026-0011',
      );
      expect(
        PdfExportService.resolveDocumentReference(
          content: 'Referentie: AR-2026-0012',
        ),
        'AR-2026-0012',
      );
    });
  });

  group('PdfExportService.getRiskLevelFromScore', () {
    test('uses the mandatory Belgian risk grid', () {
      expect(PdfExportService.getRiskLevelFromScore(1), 'Faible');
      expect(PdfExportService.getRiskLevelFromScore(18), 'Faible');
      expect(PdfExportService.getRiskLevelFromScore(20), 'Faible');
      expect(PdfExportService.getRiskLevelFromScore(21), 'Moyen');
      expect(PdfExportService.getRiskLevelFromScore(36), 'Moyen');
      expect(PdfExportService.getRiskLevelFromScore(48), 'Moyen');
      expect(PdfExportService.getRiskLevelFromScore(50), 'Moyen');
      expect(PdfExportService.getRiskLevelFromScore(51), 'Élevé');
      expect(PdfExportService.getRiskLevelFromScore(100), 'Élevé');
      expect(PdfExportService.getRiskLevelFromScore(101), 'Critique');
      expect(PdfExportService.getRiskLevelFromScore(125), 'Critique');
      expect(PdfExportService.getRiskLevelFromScore(0), 'À vérifier');
      expect(PdfExportService.getRiskLevelFromScore(126), 'À vérifier');
    });

    test(
      'can render risk level labels in Dutch without changing thresholds',
      () {
        expect(
          PdfExportService.getRiskLevelFromScore(20, language: 'nl'),
          'Laag',
        );
        expect(
          PdfExportService.getRiskLevelFromScore(21, language: 'nl'),
          'Gemiddeld',
        );
        expect(
          PdfExportService.getRiskLevelFromScore(51, language: 'nl'),
          'Hoog',
        );
        expect(
          PdfExportService.getRiskLevelFromScore(101, language: 'nl'),
          'Kritiek',
        );
        expect(
          PdfExportService.getRiskLevelFromScore(126, language: 'nl'),
          'Te controleren',
        );
      },
    );

    test('can render risk level labels in English and German', () {
      expect(PdfExportService.getRiskLevelFromScore(20, language: 'en'), 'Low');
      expect(
        PdfExportService.getRiskLevelFromScore(21, language: 'en'),
        'Medium',
      );
      expect(
        PdfExportService.getRiskLevelFromScore(101, language: 'en'),
        'Critical',
      );
      expect(
        PdfExportService.getRiskLevelFromScore(20, language: 'de'),
        'Niedrig',
      );
      expect(
        PdfExportService.getRiskLevelFromScore(21, language: 'de'),
        'Mittel',
      );
      expect(
        PdfExportService.getRiskLevelFromScore(101, language: 'de'),
        'Kritisch',
      );
    });
  });

  group('PdfExportService.detectDocumentLanguage', () {
    test('detects supported document languages from generated titles', () {
      expect(
        PdfExportService.detectDocumentLanguage(
          'Risk assessment – Draft for validation',
        ),
        'en',
      );
      expect(
        PdfExportService.detectDocumentLanguage(
          'Risicoanalyse – Ontwerp te valideren',
        ),
        'nl',
      );
      expect(
        PdfExportService.detectDocumentLanguage(
          'Gefährdungsbeurteilung – Entwurf zur Validierung',
        ),
        'de',
      );
      expect(
        PdfExportService.detectDocumentLanguage(
          'Analyse de risques – Projet à valider',
        ),
        'fr',
      );
    });
  });

  group('resolveDocumentFamily', () {
    test('recognizes annual action plans in four languages', () {
      expect(
        resolveDocumentFamily('Plan annuel d’action'),
        DocumentFamily.annualActionPlan,
      );
      expect(
        resolveDocumentFamily('Jaaractieplan'),
        DocumentFamily.annualActionPlan,
      );
      expect(
        resolveDocumentFamily('Annual Action Plan'),
        DocumentFamily.annualActionPlan,
      );
      expect(
        resolveDocumentFamily('Jährlicher Aktionsplan'),
        DocumentFamily.annualActionPlan,
      );
    });

    test('recognizes the other prevention document families', () {
      expect(
        resolveDocumentFamily('Plan global de prévention sur 5 ans'),
        DocumentFamily.globalPreventionPlan,
      );
      expect(
        resolveDocumentFamily('Safety Visit Report'),
        DocumentFamily.safetyVisitReport,
      );
      expect(
        resolveDocumentFamily('Functiefiche'),
        DocumentFamily.jobDescriptionSheet,
      );
      expect(
        resolveDocumentFamily('Sicherheitsanweisungsblatt'),
        DocumentFamily.safetyInstructionSheet,
      );
      expect(
        resolveDocumentFamily('Rapport d’accident ou d’incident'),
        DocumentFamily.accidentIncidentReport,
      );
    });

    test('does not classify unknown documents as risk assessments', () {
      expect(resolveDocumentFamily('Document inconnu'), DocumentFamily.unknown);
    });
  });

  group('PdfExportService.displayPdfDocumentTitle', () {
    test('returns localized titles for prevention documents', () {
      expect(
        PdfExportService.displayPdfDocumentTitle('Fiche de poste', 'en'),
        'Job Description Sheet – Draft to be adapted and validated',
      );
      expect(
        PdfExportService.displayPdfDocumentTitle('Plan annuel d’action', 'nl'),
        'Jaaractieplan – Ontwerp aan te passen en te valideren',
      );
      expect(
        PdfExportService.displayPdfDocumentTitle(
          'Fiche d’instruction sécurité',
          'de',
        ),
        'Sicherheitsanweisungsblatt – Entwurf zur Anpassung und Validierung',
      );
    });

    test('returns non-French titles for risk assessments', () {
      expect(
        PdfExportService.displayPdfDocumentTitle(
          'Analyse de risques générale',
          'en',
        ),
        'Risk Assessment – Draft to be adapted and validated',
      );
      expect(
        PdfExportService.displayPdfDocumentTitle(
          'Analyse de risques générale',
          'nl',
        ),
        'Risicoanalyse – Ontwerp aan te passen en te valideren',
      );
      expect(
        PdfExportService.displayPdfDocumentTitle(
          'Analyse de risques générale',
          'de',
        ),
        'Gefährdungsbeurteilung – Entwurf zur Anpassung und Validierung',
      );
    });
  });

  group('PdfExportService localized PDF content', () {
    test('returns required localized document titles', () {
      expect(
        PdfExportService.localizedDocumentTitle(
          family: DocumentFamily.safetyInstructionSheet,
          languageCode: 'en',
        ),
        'Safety Instruction Sheet – Draft to be adapted and validated',
      );
      expect(
        PdfExportService.localizedDocumentTitle(
          family: DocumentFamily.jobDescriptionSheet,
          languageCode: 'de',
        ),
        'Stellenbeschreibung – Entwurf zur Anpassung und Validierung',
      );
    });

    test('returns localized validation text without French leakage', () {
      expect(
        PdfExportService.localizedValidationText('en'),
        isNot(contains('Ce document')),
      );
      expect(
        PdfExportService.localizedValidationText('nl'),
        isNot(contains('Ce document')),
      );
    });

    test(
      'keeps valid English apostrophes while fixing joined action labels',
      () {
        expect(
          PdfExportService.cleanLanguageSpecificText(
            'Prohibited’Actions',
            'en',
          ),
          'Prohibited Actions',
        );
        expect(
          PdfExportService.cleanLanguageSpecificText('worker’s', 'en'),
          'worker’s',
        );
      },
    );

    test('removes French validation block from normalized English content', () {
      final normalized = PdfExportService.normalizePdfContent(
        rawMarkdown:
            '## 1. Context\nInformation à compléter ou à valider sur le terrain.\n\n'
            '13. Mention de validation\n'
            'Ce document est un projet à adapter à la situation réelle de l’entreprise et à valider par le conseiller en prévention, l’employeur et, le cas échéant, le service externe, le médecin du travail ou le CPPT. Il ne constitue pas à lui seul une preuve de conformité réglementaire.',
        documentType: 'Safety Instruction Sheet',
        languageCode: 'en',
        documentFamily: DocumentFamily.safetyInstructionSheet,
      );

      expect(normalized.rawMarkdown, isNot(contains('Mention de validation')));
      expect(normalized.rawMarkdown, isNot(contains('Ce document')));
      expect(
        normalized.rawMarkdown,
        contains(
          'Information to be completed or validated during the site visit.',
        ),
      );
      expect(
        'Validation Statement'.allMatches(normalized.rawMarkdown),
        hasLength(1),
      );
      expect(normalized.rawMarkdown, contains('## 14. Validation Statement'));
    });

    test('removes only leading duplicated risk assessment titles', () {
      final cases = {
        'fr': (
          title: 'Analyse de risques – Projet à valider',
          firstKept: 'Référence : AR-2026-0010',
        ),
        'nl': (
          title: 'Risicoanalyse – Ontwerp te valideren',
          firstKept: 'Referentie : AR-2026-0010',
        ),
        'en': (
          title: 'Risk Assessment – Draft for validation',
          firstKept: 'Reference: AR-2026-0010',
        ),
        'de': (
          title: 'Gefährdungsbeurteilung – Zu validierender Entwurf',
          firstKept: 'Referenz: AR-2026-0010',
        ),
      };

      for (final entry in cases.entries) {
        final normalized = PdfExportService.normalizePdfContent(
          rawMarkdown:
              '# ${entry.value.title}\n'
              '${entry.value.firstKept}\n\n'
              '1. Identification du document\n'
              'Contenu à conserver.',
          documentType: 'Analyse de risques générale',
          languageCode: entry.key,
          documentFamily: DocumentFamily.riskAssessment,
        );

        expect(normalized.rawMarkdown, startsWith(entry.value.firstKept));
        expect(
          normalized.rawMarkdown,
          contains('1. Identification du document'),
        );
      }
    });

    test('builds a PDF with a very wide main risk table', () async {
      final bytes = await PdfExportService.buildDocumentPdf(
        documentType: 'Analyse de risques générale',
        content: _wideRiskAssessmentMarkdown(),
        generatedAt: DateTime(2026, 6, 14),
      );

      expect(bytes, isNotEmpty);
    });

    test('builds editable Word output for very wide risk tables', () {
      final bytes = DocxExportService.buildRiskAssessmentDocx(
        documentType: 'Analyse de risques générale',
        content: _wideRiskAssessmentMarkdown(),
        generatedAt: DateTime(2026, 6, 14),
        languageCode: 'fr',
        referenceNumber: 'AR-2026-0011',
      );
      final rawPackage = utf8.decode(bytes, allowMalformed: true);

      expect(bytes, isNotEmpty);
      expect(rawPackage, contains('word/footer1.xml'));
      expect(rawPackage, contains('Référence AR-2026-0011'));
      expect(rawPackage, contains('w:instr="PAGE"'));
      expect(rawPackage, contains('w:instr="NUMPAGES"'));
      expect(rawPackage, contains('r:id="rIdFooter1"'));
      expect(
        rawPackage,
        contains('<w:trPr><w:tblHeader/><w:cantSplit/></w:trPr>'),
      );
      expect(rawPackage, contains('<w:keepNext/><w:keepLines/>'));
      expect(
        rawPackage,
        contains('Tableau principal A - Évaluation du risque'),
      );
      expect(
        rawPackage,
        contains('Tableau principal B - Mesures, suivi et validation'),
      );
      expect(rawPackage, contains('Point bloquant'));
      expect(rawPackage, contains('Avis externe'));
    });

    test(
      'keeps backend risk assessment headings and split section 12 tables',
      () async {
        final markdown = _backendRiskAssessmentMarkdown();
        final pdfBytes = await PdfExportService.buildDocumentPdf(
          documentType: 'Analyse de risques générale',
          content: markdown,
          generatedAt: DateTime(2026, 6, 14),
          referenceNumber: 'AR-2026-TEST',
        );
        final docxBytes = DocxExportService.buildRiskAssessmentDocx(
          documentType: 'Analyse de risques générale',
          content: markdown,
          generatedAt: DateTime(2026, 6, 14),
          languageCode: 'fr',
          referenceNumber: 'AR-2026-TEST',
        );
        final rawPackage = utf8.decode(docxBytes, allowMalformed: true);

        expect(pdfBytes, isNotEmpty);
        expect(docxBytes, isNotEmpty);
        expect(rawPackage, contains('4. Glossaire des abréviations utilisées'));
        expect(rawPackage, contains('9. Plan photos'));
        expect(rawPackage, contains('11. Méthode de cotation'));
        expect(
          rawPackage,
          contains(
            '16. Lien avec le Plan Annuel d’Action et le Plan Global de Prévention',
          ),
        );
        expect(
          rawPackage,
          contains('17. Documents à créer ou à mettre à jour'),
        );
        expect(rawPackage, contains('22. Conclusion'));

        final section121 = rawPackage.indexOf(
          '12.1 Évaluation initiale des risques',
        );
        final initialTable = rawPackage.indexOf('Score initial');
        final section122 = rawPackage.indexOf(
          '12.2 Mesures, suivi et validation',
        );
        final measuresTable = rawPackage.indexOf('Mesure complémentaire');
        expect(section121, greaterThanOrEqualTo(0));
        expect(initialTable, greaterThan(section121));
        expect(section122, greaterThan(initialTable));
        expect(measuresTable, greaterThan(section122));

        expect(rawPackage, isNot(contains('4. Périmètre de l’analyse')));
        expect(
          rawPackage,
          isNot(contains('9. Tableau principal d’analyse des risques')),
        );
        expect(rawPackage, isNot(contains('11. Priorités d’action')));
        expect(rawPackage, isNot(contains('16. Annexes nécessaires')));
        expect(rawPackage, isNot(contains('17. Conclusion')));
        expect('Référence : AR-2026-TEST'.allMatches(rawPackage), hasLength(1));
        expect('Date : 14/06/2026'.allMatches(rawPackage), hasLength(1));
      },
    );

    test(
      'keeps mocked section 12 tables separate without adding placeholders',
      () async {
        final markdown = _completeBackendRiskAssessmentMarkdown();
        final pdfBytes = await PdfExportService.buildDocumentPdf(
          documentType: 'Analyse de risques générale',
          content: markdown,
          generatedAt: DateTime(2026, 6, 14),
          referenceNumber: 'AR-2026-MOCK',
        );
        final docxBytes = DocxExportService.buildRiskAssessmentDocx(
          documentType: 'Analyse de risques générale',
          content: markdown,
          generatedAt: DateTime(2026, 6, 14),
          languageCode: 'fr',
          referenceNumber: 'AR-2026-MOCK',
        );
        final rawPackage = utf8.decode(docxBytes, allowMalformed: true);

        expect(pdfBytes, isNotEmpty);
        expect(docxBytes, isNotEmpty);
        expect('Référence : AR-2026-MOCK'.allMatches(rawPackage), hasLength(1));
        expect('Date : 14/06/2026'.allMatches(rawPackage), hasLength(1));
        expect(rawPackage, isNot(contains('À compléter')));
        expect(rawPackage, isNot(contains('To complete')));
        expect(rawPackage, isNot(contains('Aan te vullen')));
        expect(rawPackage, isNot(contains('Zu ergänzen')));

        final section121 = rawPackage.indexOf(
          '12.1 Évaluation initiale des risques',
        );
        final firstInitialRow = rawPackage.indexOf('Stockage produits');
        final secondInitialRow = rawPackage.indexOf('Maintenance convoyeur');
        final section122 = rawPackage.indexOf(
          '12.2 Mesures, suivi et validation',
        );
        final firstFollowUpRow = rawPackage.indexOf('Créer une zone dédiée');
        final secondFollowUpRow = rawPackage.indexOf(
          'Ajouter consignation écrite',
        );

        expect(section121, greaterThanOrEqualTo(0));
        expect(firstInitialRow, greaterThan(section121));
        expect(secondInitialRow, greaterThan(firstInitialRow));
        expect(section122, greaterThan(secondInitialRow));
        expect(firstFollowUpRow, greaterThan(section122));
        expect(secondFollowUpRow, greaterThan(firstFollowUpRow));
        expect(rawPackage, contains('4. Glossaire des abréviations utilisées'));
        expect(rawPackage, contains('9. Plan photos'));
        expect(rawPackage, contains('11. Méthode de cotation'));
        expect(
          rawPackage,
          contains(
            '16. Lien avec le Plan Annuel d’Action et le Plan Global de Prévention',
          ),
        );
        expect(
          rawPackage,
          contains('17. Documents à créer ou à mettre à jour'),
        );
      },
    );

    test('removes a duplicate leading reference/date block only', () {
      final markdown = _completeBackendRiskAssessmentMarkdown(
        duplicateReferenceDate: true,
      );
      final cleaned = PdfExportService.removeDuplicateLeadingReferenceDate(
        markdown,
      );

      expect('Référence : AR-2026-MOCK'.allMatches(cleaned), hasLength(1));
      expect('Date : 14/06/2026'.allMatches(cleaned), hasLength(1));
      expect(cleaned, contains('12.1 Évaluation initiale des risques'));
      expect(cleaned, contains('12.2 Mesures, suivi et validation'));
    });
  });
}

String _wideRiskAssessmentMarkdown() {
  final headers = [
    'N°',
    'Activité ou tâche',
    'Danger',
    'Situation dangereuse',
    'Risque',
    'Personnes exposées',
    'Mesures existantes',
    'Preuves existantes',
    'Éléments observés',
    'Éléments à confirmer',
    'G',
    'P',
    'E',
    'Score initial',
    'Niveau initial',
    'Mesure complémentaire',
    'Niveau STOP',
    'Responsable',
    'Échéance',
    'Score résiduel',
    'Justification du score résiduel',
    'Preuve attendue',
    'Photo à insérer',
    'Annexe à joindre',
    'Priorité',
    'Point bloquant',
    'Avis externe',
  ];
  final values = [
    '1',
    'Inspection incendie du local technique',
    'Départ de feu',
    'Présence de stockage près du tableau électrique',
    'Brûlure et propagation',
    'Techniciens et visiteurs',
    'Extincteur disponible',
    'Registre de contrôle',
    'Stockage observé',
    'Validation terrain',
    '4',
    '3',
    '2',
    '24',
    'Moyen',
    'Déplacer le stockage et formaliser le contrôle',
    'Suppression',
    'Responsable maintenance',
    '30/06/2026',
    '8',
    'La mesure réduit la probabilité et l’exposition',
    'Photo après rangement et registre signé',
    'Photo 1',
    'Annexe A',
    'Haute',
    'Non',
    'Service externe si doute',
  ];
  return [
    'Analyse de risques – Projet à valider',
    '',
    '9. Tableau principal d’analyse des risques',
    '| ${headers.join(' | ')} |',
    '| ${headers.map((_) => '---').join(' | ')} |',
    '| ${values.join(' | ')} |',
  ].join('\n');
}

String _backendRiskAssessmentMarkdown() {
  return [
    'Analyse de risques – Projet à adapter et à valider',
    'Référence : AR-2026-TEST',
    'Date : 14/06/2026',
    '',
    '1. Identification du document',
    'Entreprise test.',
    '',
    '4. Glossaire des abréviations utilisées',
    '',
    '| Abréviation | Définition |',
    '| --- | --- |',
    '| PAA | Plan Annuel d’Action |',
    '',
    '5. Périmètre de l’analyse',
    '',
    'Périmètre à valider.',
    '',
    '9. Plan photos',
    '',
    '| Numéro photo | Zone ou tâche |',
    '| --- | --- |',
    '| 1 | Local produits inflammables |',
    '',
    '11. Méthode de cotation',
    '',
    'Score = Gravité x Probabilité x Exposition',
    '',
    '12. Tableau principal d’analyse des risques',
    '',
    '12.1 Évaluation initiale des risques',
    '',
    '| N° | Tâche | Danger | G | P | E | Score initial |',
    '| --- | --- | --- | --- | --- | --- | --- |',
    '| 1 | Stockage | Incendie | 3 | 3 | 3 | 27 |',
    '',
    '12.2 Mesures, suivi et validation',
    '',
    '| N° | Mesure complémentaire | Niveau STOP | Responsable |',
    '| --- | --- | --- | --- |',
    '| 1 | Vérifier stockage | Technique | SIPPT |',
    '',
    '16. Lien avec le Plan Annuel d’Action et le Plan Global de Prévention',
    '',
    '17. Documents à créer ou à mettre à jour',
    '',
    '22. Conclusion',
    '',
    '23. Mention de validation',
  ].join('\n');
}

String _completeBackendRiskAssessmentMarkdown({
  bool duplicateReferenceDate = false,
}) {
  final leadingReferenceDate = [
    'Référence : AR-2026-MOCK',
    'Date : 14/06/2026',
  ];
  return [
    'Analyse de risques – Projet à adapter et à valider',
    ...leadingReferenceDate,
    if (duplicateReferenceDate) ...leadingReferenceDate,
    '',
    '1. Identification du document',
    'Entreprise test.',
    '',
    '4. Glossaire des abréviations utilisées',
    '',
    '| Abréviation | Définition |',
    '| --- | --- |',
    '| PAA | Plan Annuel d’Action |',
    '',
    '9. Plan photos',
    '',
    '| Numéro photo | Zone ou tâche |',
    '| --- | --- |',
    '| 1 | Local produits inflammables |',
    '',
    '11. Méthode de cotation',
    '',
    'Score = Gravité x Probabilité x Exposition',
    '',
    '12. Tableau principal d’analyse des risques',
    '',
    '12.1 Évaluation initiale des risques',
    '',
    '| N° | Tâche | Danger | G | P | E | Score initial |',
    '| --- | --- | --- | --- | --- | --- | --- |',
    '| 1 | Stockage produits | Incendie | 3 | 3 | 3 | 27 |',
    '| 2 | Maintenance convoyeur | Coincement | 4 | 2 | 2 | 16 |',
    '',
    '12.2 Mesures, suivi et validation',
    '',
    '| N° | Mesure complémentaire | Niveau STOP | Responsable |',
    '| --- | --- | --- | --- |',
    '| 1 | Créer une zone dédiée | Technique | Responsable maintenance |',
    '| 2 | Ajouter consignation écrite | Organisation | Conseiller prévention |',
    '',
    '14. Analyse des risques résiduels',
    '',
    '| N° | Risque | Score résiduel |',
    '| --- | --- | --- |',
    '| 1 | Incendie | 9 |',
    '',
    '15. Projet de plan d’action',
    '',
    '| N° | Mesure proposée | Responsable | Échéance | Statut |',
    '| --- | --- | --- | --- | --- |',
    '| 1 | Formaliser le contrôle | Responsable maintenance | 30/06/2026 | Ouvert |',
    '',
    '16. Lien avec le Plan Annuel d’Action et le Plan Global de Prévention',
    '',
    '17. Documents à créer ou à mettre à jour',
    '',
    '22. Conclusion',
    '',
    '23. Mention de validation',
  ].join('\n');
}
