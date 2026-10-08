import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/models/preventia_company_project.dart';
import 'package:preventia_belgique_app/services/docx_export_service.dart';
import 'package:preventia_belgique_app/services/risk_assessment_assistant_service.dart';

void main() {
  final document = PreventiaCompanyDocument(
    id: 'assistant',
    documentType: 'Analyse assistée de risques',
    title: 'Analyse assistée — Ergonomie',
    status: 'Brouillon à valider',
    createdAt: DateTime(2026, 10, 4),
    autoCreated: false,
    source: 'assistant_local',
    reference: 'AA-2026-0001',
    companyName: 'SPGE',
    siteName: 'Bureau',
    formData: const {'subject': 'Ergonomie poste écran'},
    markdown: RiskAssessmentAssistantService.draft(
      subject: 'Ergonomie',
      answers: {'Qui est exposé ?': 'Employés'},
      questions: [FieldQuestion('Chaise adaptée ?')..answer = 'non'],
      dangers: [
        AssistantDanger('Posture')
          ..gravity = 3
          ..probability = 2
          ..exposure = 4,
      ],
      conclusions: {'Actions proposées': 'Régler la chaise'},
      decisions: {},
    ),
  );
  test('assisted documents support Word and a clean filename', () {
    expect(DocxExportService.isAssistedRiskDraft(document), isTrue);
    expect(
      DocxExportService.assistedRiskFileName(document),
      'analyse_assistee_spge_ergonomie_poste_ecran_20261004.docx',
    );
  });
  test('Word preserves draft content, metadata and validation', () {
    final markdown = DocxExportService.assistedRiskExportMarkdown(document);
    for (final text in [
      RiskAssessmentAssistantService.warning,
      'Questionnaire',
      'Employés',
      'Questions terrain',
      'Score : 24',
      'Régler la chaise',
      'AA-2026-0001',
      'Signatures / validation finale',
    ]) {
      expect(markdown, contains(text));
    }
    final xml = utf8.decode(
      DocxExportService.buildAssistedRiskAssessmentDocx(document),
      allowMalformed: true,
    );
    expect(xml, contains('Analyse assistée de risques'));
    expect(xml, contains('Régler la chaise'));
    expect(xml, isNot(contains('Page 1 / 1')));
    expect(xml, isNot(contains('SCÉNARIO TEST SPGE')));
  });
  test(
    'le markdown Word du brouillon nettoie les marqueurs et les réponses internes',
    () {
      final dirty = document.copyWith(
        markdown:
            '${document.markdown}\na_verifier\nPage 1 / 1\nSCÉNARIO TEST SPGE\nIntégration PIU : Oui',
      );
      final text = DocxExportService.assistedRiskExportMarkdown(dirty);
      expect(text, contains('À vérifier'));
      for (final marker in [
        'Page 1 / 1',
        'SCÉNARIO TEST SPGE',
        'a_verifier',
        'Intégration PIU',
      ]) {
        expect(text, isNot(contains(marker)));
      }
      expect(
        DocxExportService.buildAssistedRiskAssessmentDocx(dirty),
        isNotEmpty,
      );
    },
  );

  test('sanitizer removes noise and empty sections', () {
    final cleaned = sanitizeAssistedRiskMarkdownForExport(
      '# Titre\n\nRéférence AR-2026 — Page 1 / 1\nSCÉNARIO TEST SPGE\nDocument : Analyse de risques générale\n```debug\nsecret\n```\n## Vide\n\n## Contenu\nTexte\n\n\n\n',
    );
    expect(cleaned, '# Titre\n\n## Contenu\nTexte');
    expect(cleaned, isNot(contains('secret')));
  });
}
