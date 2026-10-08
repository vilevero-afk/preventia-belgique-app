import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/services/risk_assessment_assistant_service.dart';

void main() {
  test(
    'le remplissage de validation test permet une analyse finale complète',
    () {
      final dangers = RiskAssessmentAssistantService.dangersFor('Autre sujet');
      final actions = RiskAssessmentAssistantService.actionsFor(
        dangers,
        'Installer un balisage',
      );
      RiskAssessmentAssistantService.fillValidationTest(dangers, actions);
      for (final a in actions) {
        expect(a.decision, AdvisorDecision.accepted);
        expect(a.responsible, 'Service prévention');
        expect(a.deadline, '3 mois');
        expect(
          a.finalEvidence,
          'Photo après correction ou preuve documentaire',
        );
        expect(a.advisorComment, 'À vérifier et valider sur site.');
      }
      expect(
        RiskAssessmentAssistantService.validationErrors(dangers, actions),
        isEmpty,
      );
      final text = RiskAssessmentAssistantService.finalAnalysis(
        subject: 'Bureau',
        answers: {'Qui est exposé ?': 'Personnel'},
        questions: [FieldQuestion('Observation terrain ?')],
        dangers: dangers,
        actions: actions,
        advisor: 'Service prévention',
        conclusion: 'À vérifier et valider sur site.',
      );
      for (final value in [
        'Analyse finale assistée de risques',
        'Bureau',
        'Personnel',
        'Observation terrain ?',
        'Installer un balisage',
        '3 mois',
        'Photo après correction ou preuve documentaire',
        'Commentaire conseiller',
        'Conclusion finale',
        'Signatures',
      ]) {
        expect(text, contains(value));
      }
      expect(text, isNot(contains('PIU')));
      expect(text, isNot(contains('a_verifier')));
    },
  );

  test(
    'scénario ergonomie complet : questionnaire, terrain, huit dangers cotés et onze actions concrètes',
    () {
      final answers = <String, String>{};
      final questions = RiskAssessmentAssistantService.questionsFor(
        'Ergonomie poste écran',
      );
      final dangers = RiskAssessmentAssistantService.dangersFor(
        'Ergonomie poste écran',
      );
      RiskAssessmentAssistantService.fillErgonomicsBaseQuestionnaire(answers);
      RiskAssessmentAssistantService.fillErgonomicsTest(questions);
      RiskAssessmentAssistantService.fillErgonomicsDangersTest(dangers);
      expect(answers.length, 8);
      expect(
        questions.map(
          (q) => RiskAssessmentAssistantService.answerLabel(q.answer),
        ),
        ['Non', 'Non', 'Non', 'Oui', 'Oui', 'Oui', 'Non', 'Oui', 'Non', 'Oui'],
      );
      expect(questions.map((q) => q.photoRequired), [
        true,
        true,
        true,
        true,
        true,
        true,
        false,
        false,
        false,
        false,
      ]);
      expect(questions.map((q) => q.importance), [
        'élevée',
        'élevée',
        'moyenne',
        'élevée',
        'élevée',
        'moyenne',
        'moyenne',
        'élevée',
        'moyenne',
        'moyenne',
      ]);
      expect(
        questions.every(
          (q) => q.comment.isNotEmpty && q.evidenceExpected.isNotEmpty,
        ),
        isTrue,
      );
      expect(dangers, hasLength(8));
      expect(dangers.map((d) => d.score), [36, 36, 36, 24, 27, 27, 27, 12]);
      expect(dangers.map((d) => d.level), [
        'moyen',
        'moyen',
        'moyen',
        'moyen',
        'moyen',
        'moyen',
        'moyen',
        'faible',
      ]);
      for (final d in dangers) {
        expect(
          [
            d.scenario,
            d.people,
            d.measures,
            d.evidence,
            d.photo,
          ].every((v) => v.isNotEmpty),
          isTrue,
        );
        expect(d.gravity, isNotNull);
        expect(d.probability, isNotNull);
        expect(d.exposure, isNotNull);
      }
      final conclusions = RiskAssessmentAssistantService.conclusionsFor(
        questions,
        dangers,
      );
      final actions = RiskAssessmentAssistantService.actionsFor(
        dangers,
        conclusions['Actions proposées']!,
      );
      expect(actions, hasLength(11));
      expect(
        actions.every((a) => a.linkedRisk != 'À préciser par le conseiller'),
        isTrue,
      );
      for (final action in RiskAssessmentAssistantService.ergonomicsActions) {
        expect(actions.map((a) => a.action), contains(action));
      }
      final markdown = RiskAssessmentAssistantService.draft(
        subject: 'Ergonomie poste écran',
        answers: answers,
        questions: questions,
        dangers: dangers,
        conclusions: conclusions,
        decisions: {},
      );
      final questionnaire = markdown
          .split('## Questionnaire de base')
          .last
          .split('## Questions terrain')
          .first;
      expect(questionnaire, isNot(contains('À compléter')));
      for (final text in [
        'Postes administratifs sur écran du site administratif de Verviers',
        'Personnel administratif, agents d’accueil',
        '5 à 7 heures par jour',
        'Score : 36',
        'Niveau : moyen',
      ]) {
        expect(markdown, contains(text));
      }
      for (final text in [
        'Non coté',
        'Scénario plausible : À compléter',
        'Personnes exposées : À compléter',
        'Mesures existantes : À compléter',
        'Vérifier Posture assise prolongée sur le terrain',
        'Vérifier Hauteur écran inadaptée sur le terrain',
        'a_verifier',
        'non_applicable',
        'Intégration PIU',
      ]) {
        expect(markdown, isNot(contains(text)));
      }
    },
  );

  test(
    'constructeur pur du document final : métadonnées, statut, avis et séparation des décisions',
    () {
      final danger = AssistantDanger('Chute')
        ..decision = AdvisorDecision.accepted
        ..gravity = 3
        ..probability = 3
        ..exposure = 4;
      final accepted =
          AssistantAction('Installer un balisage', linkedRisk: 'Chute')
            ..decision = AdvisorDecision.accepted
            ..responsible = 'Service prévention'
            ..deadline = '3 mois'
            ..finalEvidence = 'Photo après correction'
            ..advisorComment = 'À vérifier sur site.';
      final refused = AssistantAction('Acheter un équipement')
        ..decision = AdvisorDecision.refused
        ..advisorComment = 'Mesure non adaptée.';
      String build(
        bool validated,
      ) => RiskAssessmentAssistantService.buildFinalAssistedRiskMarkdown(
        subject: 'Ergonomie poste écran',
        reference: 'AA-2026-001',
        date: DateTime(2026, 10, 8),
        companyName: 'SPGE',
        siteName: 'Verviers',
        answers: {'Qui est exposé ?': 'Personnel'},
        questions: [FieldQuestion('Question à vérifier ?')],
        dangers: [danger],
        actions: [accepted, refused],
        advisor: 'Conseiller',
        conclusion:
            'Sécuriser les passages.\nPage 1 / 1\nSCÉNARIO TEST SPGE\na_verifier\nIntégration PIU',
        validated: validated,
      );
      final text = build(false);
      expect(build(false), text);
      for (final value in [
        'Analyse finale assistée de risques',
        'AA-2026-001',
        '08/10/2026',
        'Entreprise : SPGE',
        'Site : Verviers',
        'Sujet analysé : Ergonomie poste écran',
        'Statut : Analyse finale à valider',
        RiskAssessmentAssistantService.finalNotice,
        RiskAssessmentAssistantService.warning,
        'Service prévention',
        '3 mois',
        'Photo après correction',
        'Commentaire conseiller : À vérifier sur site.',
        'Signatures',
      ]) {
        expect(text, contains(value));
      }
      final sections = text.split('## Actions écartées ou refusées');
      final plan = sections.first.split('## Plan d’action retenu').last;
      expect(plan, contains('Installer un balisage'));
      expect(plan, isNot(contains('Acheter un équipement')));
      expect(sections.first, isNot(contains('Acheter un équipement')));
      expect(sections.last, contains('Acheter un équipement'));
      expect(sections.last, contains('Mesure non adaptée.'));
      for (final value in [
        'Page 1 / 1',
        'SCÉNARIO TEST SPGE',
        'a_verifier',
        'Intégration PIU',
        'Brouillon non validé',
      ]) {
        expect(text, isNot(contains(value)));
      }
      expect(build(true), contains('Statut : Analyse finale validée'));
      expect(build(true), contains('Document validé par le conseiller'));
      refused.decision = AdvisorDecision.accepted;
      expect(() => build(false), throwsStateError);
    },
  );

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
