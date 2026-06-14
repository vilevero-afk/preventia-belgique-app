import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/services/file_export_service.dart';

void main() {
  group('FileExportService.cleanPdfFileName', () {
    test('replaces desktop-invalid filename characters and keeps pdf', () {
      final cleaned = FileExportService.cleanPdfFileName(
        'AR-2026-0001/analyse: risques*?.pdf',
      );

      expect(cleaned, 'AR-2026-0001-analyse-risques.pdf');
    });

    test('uses expected risk analysis and action summary names', () {
      const projectTitle =
          'AR-2026-0001 – Gemeentebestuur van Verviers – Technische dienst';

      expect(
        FileExportService.riskAnalysisFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: projectTitle,
          locale: const Locale('fr'),
        ),
        'AR-2026-0001-gemeentebestuur-van-verviers-technische-dienst-analyse-de-risques.pdf',
      );
      expect(
        FileExportService.actionSummaryFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: projectTitle,
          locale: const Locale('fr'),
        ),
        'AR-2026-0001-gemeentebestuur-van-verviers-technische-dienst-recapitulatif-actions.pdf',
      );
      expect(
        FileExportService.riskAnalysisFileName(),
        'analyse-de-risques.pdf',
      );
      expect(
        FileExportService.actionSummaryFileName(),
        'recapitulatif-actions.pdf',
      );
    });

    test('uses matching docx names for editable risk analysis exports', () {
      expect(
        FileExportService.riskAnalysisWordFileName(
          referenceNumber: 'AR-2026-0006',
          languageCode: 'fr',
        ),
        'AR-2026-0006-analyse-de-risques.docx',
      );
      expect(
        FileExportService.riskAnalysisWordFileName(
          referenceNumber: 'AR-2026-0006',
          projectTitle: 'Administration communale de Verviers',
          languageCode: 'en',
        ),
        'AR-2026-0006-administration-communale-de-verviers-risk-assessment.docx',
      );
    });

    test('uses localized suffixes for project exports', () {
      const projectTitle =
          'AR-2026-0001 – Gemeentebestuur van Verviers – Technische dienst';

      expect(
        FileExportService.riskAnalysisFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: projectTitle,
          locale: const Locale('nl'),
        ),
        'AR-2026-0001-gemeentebestuur-van-verviers-technische-dienst-risicoanalyse.pdf',
      );
      expect(
        FileExportService.actionSummaryFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: projectTitle,
          locale: const Locale('nl'),
        ),
        'AR-2026-0001-gemeentebestuur-van-verviers-technische-dienst-actieoverzicht.pdf',
      );
      expect(
        FileExportService.riskAnalysisFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: projectTitle,
          locale: const Locale('en'),
        ),
        'AR-2026-0001-gemeentebestuur-van-verviers-technische-dienst-risk-assessment.pdf',
      );
      expect(
        FileExportService.actionSummaryFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: projectTitle,
          locale: const Locale('de'),
        ),
        'AR-2026-0001-gemeentebestuur-van-verviers-technische-dienst-massnahmenuebersicht.pdf',
      );
    });

    test('uses requested project-based names for French, English and German', () {
      expect(
        FileExportService.riskAnalysisFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle:
              'AR-2026-0001 – Administration communale de Verviers – Service technique',
          languageCode: 'fr',
        ),
        'AR-2026-0001-administration-communale-de-verviers-service-technique-analyse-de-risques.pdf',
      );
      expect(
        FileExportService.actionSummaryFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle:
              'AR-2026-0001 – Municipal Administration of Verviers – Technical Department',
          languageCode: 'en',
        ),
        'AR-2026-0001-municipal-administration-of-verviers-technical-department-action-summary.pdf',
      );
      expect(
        FileExportService.riskAnalysisFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle:
              'AR-2026-0001 – Gemeindeverwaltung Verviers – Technischer Dienst',
          languageCode: 'de',
        ),
        'AR-2026-0001-gemeindeverwaltung-verviers-technischer-dienst-gefaehrdungsbeurteilung.pdf',
      );
    });

    test('prefixes missing project reference number', () {
      expect(
        FileExportService.riskAnalysisFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: 'Gemeentebestuur van Verviers – Technische dienst',
          locale: const Locale('nl'),
        ),
        'AR-2026-0001-gemeentebestuur-van-verviers-technische-dienst-risicoanalyse.pdf',
      );
    });

    test('builds English names from content company and short service', () {
      const content = '''
1. Document identification

Company name: Municipal Administration of Verviers
Site concerned: Municipal workshop of Verviers, storage areas, vehicle garage, technical rooms and interventions on municipal sites
Service concerned: Technical Department
''';

      final title = FileExportService.projectTitleFromContent(content);

      expect(
        title,
        'Municipal Administration of Verviers – Technical Department',
      );
      expect(
        FileExportService.riskAnalysisFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: title,
          languageCode: 'en',
        ),
        'AR-2026-0001-municipal-administration-of-verviers-technical-department-risk-assessment.pdf',
      );
      expect(
        FileExportService.actionSummaryFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: title,
          languageCode: 'en',
        ),
        'AR-2026-0001-municipal-administration-of-verviers-technical-department-action-summary.pdf',
      );
    });

    test('does not use bad leading title fragments for export names', () {
      expect(
        FileExportService.riskAnalysisFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle:
              'of Verviers Technical Department concerned technical department maintenance of buildings roads and public areas',
          languageCode: 'en',
        ),
        'AR-2026-0001-risk-assessment.pdf',
      );
    });

    test('prefers existing German folder title with AR over form content', () {
      const folderTitle =
          'AR-2026-0001 – Gemeindeverwaltung Verviers – Technischer Dienst';
      const content = '''
1. Dokumentidentifikation

Name des Unternehmens: Gemeindeverwaltung Verviers
Betroffener Dienst: Technischer Dienst / Instandhaltung von Gebäuden, Straßen und öffentlichen Bereichen
''';

      final title = FileExportService.preferredProjectTitle(
        projectTitle: folderTitle,
        content: content,
      );

      expect(title, folderTitle);
      expect(
        FileExportService.riskAnalysisFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: title,
          languageCode: 'de',
        ),
        'AR-2026-0001-gemeindeverwaltung-verviers-technischer-dienst-gefaehrdungsbeurteilung.pdf',
      );
      expect(
        FileExportService.actionSummaryFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: title,
          languageCode: 'de',
        ),
        'AR-2026-0001-gemeindeverwaltung-verviers-technischer-dienst-massnahmenuebersicht.pdf',
      );
    });

    test('rebuilds German title from content when folder title is long form', () {
      const content = '''
1. Dokumentidentifikation

Name des Unternehmens: Gemeindeverwaltung Verviers
Betroffener Dienst: Technischer Dienst / Instandhaltung von Gebäuden, Straßen und öffentlichen Bereichen
''';

      final title = FileExportService.preferredProjectTitle(
        projectTitle:
            'Technischer Dienst Instandhaltung von Gebäuden Straßen und öffentlichen Bereichen',
        content: content,
      );

      expect(title, 'Gemeindeverwaltung Verviers – Technischer Dienst');
      expect(
        FileExportService.riskAnalysisFileName(
          referenceNumber: 'AR-2026-0001',
          projectTitle: title,
          languageCode: 'de',
        ),
        'AR-2026-0001-gemeindeverwaltung-verviers-technischer-dienst-gefaehrdungsbeurteilung.pdf',
      );
    });

    test('uses annual action plan names without AR suffixes', () {
      expect(
        FileExportService.cleanPdfFileName(
          'PAA-2026-0001 – Plan annuel d’action – Service technique.pdf',
        ),
        'PAA-2026-0001-plan-annuel-d-action-service-technique.pdf',
      );
      expect(
        FileExportService.documentFileName(
          referenceNumber: 'PAA-2026-0001',
          projectTitle:
              'PAA-2026-0001 – Plan annuel d’action – Service technique communal',
          documentType: 'Plan annuel d’action',
          languageCode: 'fr',
        ),
        'PAA-2026-0001-plan-annuel-d-action-service-technique-communal.pdf',
      );
      expect(
        FileExportService.documentFileName(
          referenceNumber: 'PAA-2026-0001',
          projectTitle:
              'PAA-2026-0001 – Annual Action Plan – Technical Department',
          documentType: 'Annual Action Plan',
          languageCode: 'en',
        ),
        'PAA-2026-0001-annual-action-plan-technical-department.pdf',
      );
      expect(
        FileExportService.documentFileName(
          projectTitle: 'Plan annuel d’action – Service technique',
          documentType: 'Plan annuel d’action',
          languageCode: 'fr',
        ),
        'plan-annuel-d-action-service-technique.pdf',
      );
      expect(
        FileExportService.documentFileName(
          projectTitle: 'Fiche de poste – Ouvrier polyvalent',
          documentType: 'Fiche de poste',
          languageCode: 'fr',
        ),
        'fiche-de-poste-ouvrier-polyvalent.pdf',
      );
    });

    test('uses the exact risk analysis document type as export slug', () {
      expect(
        FileExportService.documentFileName(
          referenceNumber: 'AR-2026-0011',
          documentType: 'Analyse de risques incendie et évacuation',
          languageCode: 'fr',
        ),
        'AR-2026-0011-analyse-de-risques-incendie-et-evacuation.pdf',
      );
      expect(
        FileExportService.documentWordFileName(
          referenceNumber: 'AR-2026-0011',
          documentType: 'Gefährdungsbeurteilung Brand und Evakuierung',
          languageCode: 'de',
        ),
        'AR-2026-0011-gefaehrdungsbeurteilung-brand-und-evakuierung.docx',
      );
    });

    test('uses localized suffixes for prevention document exports', () {
      expect(
        FileExportService.documentFileName(
          referenceNumber: 'PAA-2026-0001',
          documentType: 'Jaaractieplan',
          languageCode: 'nl',
        ),
        'PAA-2026-0001-jaaractieplan.pdf',
      );
      expect(
        FileExportService.documentFileName(
          referenceNumber: 'PGP-2026-0001',
          documentType: 'Five-Year Global Prevention Plan',
          languageCode: 'en',
        ),
        'PGP-2026-0001-five-year-global-prevention-plan.pdf',
      );
      expect(
        FileExportService.documentFileName(
          referenceNumber: 'FIS-2026-0001',
          documentType: 'Sicherheitsanweisungsblatt',
          languageCode: 'de',
        ),
        'FIS-2026-0001-sicherheitsanweisungsblatt.pdf',
      );
      expect(
        FileExportService.documentFileName(
          referenceNumber: 'RAI-2026-0001',
          documentType: 'Ongevallen- of incidentenrapport',
          languageCode: 'nl',
        ),
        'RAI-2026-0001-ongevallen-incidentenrapport.pdf',
      );
    });
  });
}
