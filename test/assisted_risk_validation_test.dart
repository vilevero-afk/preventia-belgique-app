import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preventia_belgique_app/services/preventia_company_project_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/services/risk_assessment_assistant_service.dart';
import 'package:preventia_belgique_app/services/docx_export_service.dart';
import 'package:preventia_belgique_app/models/preventia_company_project.dart';

void main() {
  late AssistantDanger danger;
  late AssistantAction action;
  setUp(() {
    danger = AssistantDanger('Chute')
      ..gravity = 3
      ..probability = 2
      ..exposure = 4
      ..decision = AdvisorDecision.modified;
    action = AssistantAction('Balisage', linkedRisk: 'Chute')
      ..decision = AdvisorDecision.accepted
      ..responsible = 'Conseiller'
      ..deadline = '30 jours'
      ..finalEvidence = 'Photo du balisage';
  });
  String finalText(List<AssistantAction> actions) =>
      RiskAssessmentAssistantService.finalAnalysis(
        subject: 'Bureau',
        answers: {'Qui est exposé ?': 'Personnel'},
        questions: [FieldQuestion('Passage dégagé ?')..answer = 'non'],
        dangers: [danger],
        actions: actions,
        conclusion: 'Sécuriser les passages',
        advisor: 'Vincent',
      );
  test('toutes les décisions et cotations finales sont obligatoires', () {
    danger.decision = null;
    expect(() => finalText([action]), throwsStateError);
    danger.decision = AdvisorDecision.accepted;
    danger.gravity = null;
    expect(() => finalText([action]), throwsStateError);
    danger.gravity = 3;
    action.decision = null;
    expect(() => finalText([action]), throwsStateError);
  });
  test(
    'action acceptée sans responsable, délai ou preuve bloque la création',
    () {
      action.responsible = ' ';
      expect(() => finalText([action]), throwsStateError);
      action.responsible = 'Conseiller';
      action.deadline = '';
      expect(() => finalText([action]), throwsStateError);
      action.deadline = '30 jours';
      action.finalEvidence = '';
      expect(() => finalText([action]), throwsStateError);
    },
  );
  test('actions retenues présentes et refusées uniquement en annexe', () {
    final refused = AssistantAction('Acheter du matériel')
      ..decision = AdvisorDecision.refused;
    final text = finalText([action, refused]);
    final sections = text.split('## Annexe — Actions refusées');
    expect(sections.first, contains('Balisage'));
    expect(sections.first, contains('Conseiller'));
    expect(sections.first, contains('30 jours'));
    expect(sections.first, contains('Photo du balisage'));
    expect(sections.first, isNot(contains('Acheter du matériel')));
    expect(sections.last, contains('Acheter du matériel'));
    action.decision = AdvisorDecision.modified;
    expect(finalText([action]), contains('Statut conseiller : Modifié'));
    expect(text, contains('Score : 24'));
    expect(text, contains('Document validé par le conseiller'));
    expect(text, contains('Personnel'));
    expect(text, contains('Passage dégagé ?'));
    expect(text, isNot(contains('PIU')));
  });
  test(
    'le dossier prévention et le PAA/PGP reçoivent uniquement les actions retenues',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = PreventiaCompanyProjectService(
        preferences: await SharedPreferences.getInstance(),
      );
      final refused = AssistantAction('Acheter du matériel')
        ..decision = AdvisorDecision.refused;
      final project = await service.saveAssistedDraft(
        subject: 'Ergonomie',
        companyName: 'Test validation',
        markdown: finalText([action, refused]),
        status: 'Analyse finale créée',
        actions: [action, refused],
      );
      expect(project.piuDocument, isNull);
      expect(project.piuItems, isEmpty);
      expect(project.actionItems.map((a) => a.action), ['Balisage']);
      final data = service.buildPgaGenerationFormData(project);
      final imported = data['importedActionItems'] as List;
      expect(imported, hasLength(1));
      expect(imported.single['title'], 'Balisage');
      expect(imported.single['responsible'], 'Conseiller');
      expect(imported.single['risk'], 'Chute');
    },
  );

  test('Word final validé sans bruit ni section PIU', () {
    final document = PreventiaCompanyDocument(
      id: 'final',
      documentType: 'Analyse assistée de risques',
      title: 'Analyse finale',
      status: 'Analyse finale créée',
      createdAt: DateTime(2026, 10, 8),
      autoCreated: false,
      source: 'assistant_local',
      reference: '',
      companyName: '',
      formData: const {'subject': 'Bureau'},
      markdown: finalText([action]),
    );
    final markdown = DocxExportService.assistedRiskExportMarkdown(document);
    expect(markdown, isNot(contains('Brouillon')));
    final xml = utf8.decode(
      DocxExportService.buildAssistedRiskAssessmentDocx(document),
      allowMalformed: true,
    );
    expect(xml, contains('Balisage'));
    expect(xml, isNot(contains('PIU')));
    expect(xml, isNot(contains('Page 1 / 1')));
    expect(xml, isNot(contains('SCÉNARIO TEST SPGE')));
  });
}
