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
  });
}
