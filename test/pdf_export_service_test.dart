import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/services/pdf_export_service.dart';

void main() {
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

    test(
      'fixes abnormal English apostrophes without breaking contractions',
      () {
        final normalized = PdfExportService.normalizePdfText(
          'Municipal’Administration, municipal’interventions, '
          'specialised’interventions, road’interventions, don’t, isn’t, '
          'worker’s, employer’s, l’analyse, d’intervention',
          language: 'en',
        );

        expect(normalized, contains('Municipal Administration'));
        expect(normalized, contains('municipal interventions'));
        expect(normalized, contains('specialised interventions'));
        expect(normalized, contains('road interventions'));
        expect(normalized, contains('don’t'));
        expect(normalized, contains('isn’t'));
        expect(normalized, contains('worker’s'));
        expect(normalized, contains('employer’s'));
        expect(normalized, contains('l’analyse'));
        expect(normalized, contains('d’intervention'));
      },
    );
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
}
