import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/services/risk_assessment_assistant_service.dart';

void main() {
  test('ergonomie et écran proposent les questions et dangers attendus', () {
    for (final subject in ['Ergonomie', 'ÉCRAN']) {
      final questions = RiskAssessmentAssistantService.questionsFor(subject);
      expect(questions.length, 9);
      expect(questions.first.text, 'La hauteur de l’écran est-elle adaptée ?');
      expect(questions.every((q) => !q.verified), isTrue);
      expect(RiskAssessmentAssistantService.dangersFor(subject).length, 8);
    }
  });
  test('poste de travail et accueil proposent les questions spécifiques', () {
    for (final subject in ['Poste de travail administratif', 'Accueil']) {
      expect(
        RiskAssessmentAssistantService.questionsFor(subject).map((q) => q.text),
        contains('Y a-t-il accueil du public ?'),
      );
      expect(
        RiskAssessmentAssistantService.dangersFor(subject).map((d) => d.danger),
        contains('Évacuation visiteurs'),
      );
    }
  });
  test('score, seuils et absence de cotation', () {
    expect(RiskAssessmentAssistantService.score(3, 4, 5), 60);
    expect(
      () => RiskAssessmentAssistantService.score(0, 4, 5),
      throwsArgumentError,
    );
    expect(
      () => RiskAssessmentAssistantService.score(3, 6, 5),
      throwsArgumentError,
    );
    for (final entry in {
      19: 'faible',
      20: 'moyen',
      49: 'moyen',
      50: 'élevé',
      99: 'élevé',
      100: 'critique',
      125: 'critique',
    }.entries) {
      expect(RiskAssessmentAssistantService.level(entry.key), entry.value);
    }
    expect(AssistantDanger('Danger').score, isNull);
  });
  test('brouillon reprend les modifications et exige une validation', () {
    final questions = RiskAssessmentAssistantService.questionsFor('ergonomie');
    questions.first.text = 'Question modifiée';
    questions.first.verified = true;
    final danger = AssistantDanger('Danger personnalisé')
      ..scenario = 'Chute'
      ..people = 'Visiteur'
      ..measures = 'Balisage'
      ..evidence = 'Contrôle'
      ..photo = 'Passage'
      ..gravity = 3
      ..probability = 4
      ..exposure = 5;
    final draft = RiskAssessmentAssistantService.draft(
      subject: 'Mon sujet',
      answers: {'Où se situe la situation ?': 'Bureau'},
      questions: questions,
      dangers: [danger],
      conclusions: {'Actions proposées': 'Dégager le passage'},
      decisions: {'Intégration PIU': 'Non'},
    );
    for (final text in [
      RiskAssessmentAssistantService.warning,
      'Validation',
      'Mon sujet',
      'Bureau',
      '[x] Question modifiée',
      'Danger personnalisé',
      'Score : 60',
      'Dégager le passage',
      'Intégration PIU : Non',
    ]) {
      expect(draft, contains(text));
    }
    expect(draft, isNot(contains('Page 1 / 1')));
    expect(draft, isNot(contains('SCÉNARIO TEST SPGE')));
  });
  test('chaque sujet propose des hypothèses indépendantes', () {
    for (final subject in RiskAssessmentAssistantService.subjects) {
      expect(RiskAssessmentAssistantService.questionsFor(subject), isNotEmpty);
      expect(RiskAssessmentAssistantService.dangersFor(subject), isNotEmpty);
    }
    final first = RiskAssessmentAssistantService.questionsFor('Accueil');
    first.clear();
    expect(
      RiskAssessmentAssistantService.questionsFor('Accueil'),
      hasLength(9),
    );
  });
}
