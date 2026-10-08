import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/services/risk_assessment_assistant_service.dart';

void main() {
  test('ergonomie et écran proposent les questions et dangers attendus', () {
    for (final subject in ['Ergonomie', 'ÉCRAN']) {
      final questions = RiskAssessmentAssistantService.questionsFor(subject);
      expect(questions.length, 10);
      expect(
        questions.first.text,
        'La hauteur de l’écran est-elle adaptée au travailleur ?',
      );
      expect(questions.every((q) => q.answer == 'a_verifier'), isTrue);
      expect(questions.every((q) => q.text.contains('?')), isTrue);
      expect(RiskAssessmentAssistantService.dangersFor(subject).length, 8);
    }
  });
  test('poste de travail et accueil proposent les questions spécifiques', () {
    for (final subject in ['Poste de travail administratif', 'Accueil']) {
      expect(
        RiskAssessmentAssistantService.questionsFor(subject).map((q) => q.text),
        contains('Le poste accueille-t-il du public ?'),
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
      'Question | Réponse | Commentaire',
      'Danger personnalisé',
      'Score : 60',
      'Dégager le passage',
      'Intégration PAA/PGP',
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
      hasLength(10),
    );
  });

  test('réponses structurées et conclusions automatiques', () {
    final q = FieldQuestion('La chaise est-elle réglable ?')..answer = 'non';
    q.comment = 'Réglage impossible';
    q.evidenceExpected = 'Fiche mobilier';
    q.photoRequired = true;
    final verify = FieldQuestion('Le poste est-il documenté ?');
    final conclusions = RiskAssessmentAssistantService.conclusionsFor([
      q,
      verify,
    ], []);
    expect(conclusions['Actions proposées'], contains('chaise'));
    expect(conclusions['Points bloquants'], contains('poste est-il documenté'));
    final markdown = RiskAssessmentAssistantService.draft(
      subject: 'Ergonomie',
      answers: {},
      questions: [q],
      dangers: [],
      conclusions: conclusions,
      decisions: {},
    );
    expect(markdown, contains('| Question | Réponse | Commentaire |'));
    expect(markdown, contains('Réglage impossible'));
    expect(markdown, contains('À prendre'));
  });
  test(
    'le scénario ergonomie rien n’est fait remplit les réponses lisibles',
    () {
      final questions = RiskAssessmentAssistantService.questionsFor(
        'Ergonomie poste écran',
      );
      RiskAssessmentAssistantService.fillErgonomicsTest(questions);
      expect(questions.first.answer, 'non');
      expect(questions.first.comment, contains('hauteurs différentes'));
      expect(questions.first.photoRequired, isTrue);
      expect(questions.first.importance, 'élevée');
      expect(
        questions.any((q) => q.text.contains('reflets') && q.answer == 'oui'),
        isTrue,
      );
      expect(
        questions.any(
          (q) => q.text.contains('télétravail') && q.answer == 'non',
        ),
        isTrue,
      );
      final markdown = RiskAssessmentAssistantService.draft(
        subject: 'Ergonomie',
        answers: {},
        questions: questions,
        dangers: [],
        conclusions: RiskAssessmentAssistantService.conclusionsFor(
          questions,
          [],
        ),
        decisions: {},
      );
      expect(
        markdown,
        contains(
          '| La hauteur de l’écran est-elle adaptée au travailleur ? | Non |',
        ),
      );
      expect(markdown, isNot(contains('a_verifier')));
      expect(markdown, contains('Adapter la hauteur des écrans.'));
      expect(markdown, contains('Évaluer la gêne sonore en open space.'));
    },
  );
  test('le scénario ergonomie remplit le questionnaire de base', () {
    final answers = <String, String>{};
    RiskAssessmentAssistantService.fillErgonomicsBaseQuestionnaire(answers);
    expect(
      answers['Où se situe la situation ?'],
      contains(
        'Postes administratifs sur écran du site administratif de Verviers',
      ),
    );
    expect(
      answers['Qui est exposé ?'],
      contains('Personnel administratif, agents d’accueil'),
    );
    expect(answers['À quelle fréquence ?'], contains('5 à 7 heures par jour'));
    final markdown = RiskAssessmentAssistantService.draft(
      subject: 'Ergonomie',
      answers: answers,
      questions: [],
      dangers: [],
      conclusions: {},
      decisions: {},
    );
    expect(
      markdown,
      contains(
        'Postes administratifs sur écran du site administratif de Verviers',
      ),
    );
    expect(markdown, contains('Personnel administratif, agents d’accueil'));
    expect(
      markdown,
      isNot(contains('### Où se situe la situation ?\nÀ compléter')),
    );
  });
}
