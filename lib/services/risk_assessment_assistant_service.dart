/// Local, deterministic suggestions. No network or existing document storage.
class FieldQuestion {
  FieldQuestion(this.text, {this.verified = false});
  String text;
  bool verified;
}

class AssistantDanger {
  AssistantDanger(this.danger);
  String danger;
  String scenario = '';
  String people = '';
  String measures = '';
  String evidence = '';
  String photo = '';
  int? gravity;
  int? probability;
  int? exposure;
  int? get score => gravity == null || probability == null || exposure == null
      ? null
      : RiskAssessmentAssistantService.score(gravity!, probability!, exposure!);
  String get level =>
      score == null ? 'Non coté' : RiskAssessmentAssistantService.level(score!);
}

class RiskAssessmentAssistantService {
  static const warning =
      'Cet assistant constitue une aide à l’analyse. Il ne remplace pas l’observation terrain, le conseiller en prévention, l’employeur, le CPPT, le service externe ou un organisme agréé. Les conclusions doivent être vérifiées, complétées et validées.';
  static const subjects = [
    'Poste de travail administratif',
    'Ergonomie poste écran',
    'Incendie / évacuation',
    'Installation électrique',
    'Ascenseur',
    'Produit dangereux',
    'Circulation interne',
    'Entreprise extérieure',
    'Autre sujet',
  ];
  static const questionnaire = [
    'Où se situe la situation ?',
    'Qui est exposé ?',
    'Quelle tâche est réalisée ?',
    'À quelle fréquence ?',
    'Quels incidents, plaintes ou observations existent ?',
    'Quelles mesures existent déjà ?',
    'Quels documents ou preuves sont disponibles ?',
    'Quelles photos faut-il prendre ?',
  ];
  static const conclusionLabels = [
    'Risques prioritaires',
    'Actions proposées',
    'Preuves manquantes',
    'Points bloquants',
  ];
  static const decisionLabels = [
    'Avis externe nécessaire',
    'Intégration PAA/PGP',
    'Intégration PIU',
  ];
  static String _normalize(String subject) => subject
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e');
  static String _category(String subject) {
    final s = _normalize(subject);
    if (s.contains('ergonomie') || s.contains('ecran')) return 'ergonomie';
    if (s.contains('poste de travail') || s.contains('accueil')) return 'poste';
    if (s.contains('incendie') || s.contains('evacuation')) return 'incendie';
    if (s.contains('electrique')) return 'électricité';
    if (s.contains('ascenseur')) return 'ascenseur';
    if (s.contains('produit dangereux')) return 'produit';
    if (s.contains('circulation')) return 'circulation';
    if (s.contains('entreprise exterieure')) return 'entreprise';
    return 'autre';
  }

  static List<FieldQuestion> questionsFor(String subject) {
    final questions = switch (_category(subject)) {
      'ergonomie' => [
        'La hauteur de l’écran est-elle adaptée ?',
        'La chaise est-elle réglée correctement ?',
        'Le clavier et la souris sont-ils bien positionnés ?',
        'Y a-t-il des reflets sur l’écran ?',
        'Les câbles gênent-ils le passage ?',
        'Le travailleur utilise-t-il un ordinateur portable sans support ?',
        'Le poste en télétravail est-il vérifié ?',
        'Des douleurs nuque, dos, épaules ou poignets sont-elles signalées ?',
        'Les pauses ou alternances de tâches sont-elles suffisantes ?',
      ],
      'poste' => [
        'Quelles tâches sont réellement réalisées ?',
        'Combien de temps le travailleur reste-t-il sur écran ?',
        'Y a-t-il accueil du public ?',
        'Existe-t-il des situations d’agressivité verbale ?',
        'Existe-t-il un moyen d’alerte interne ?',
        'Les visiteurs connaissent-ils les consignes d’évacuation ?',
        'Le poste présente-t-il des câbles ou obstacles ?',
        'Y a-t-il manutention de courrier ou petits colis ?',
        'La confidentialité des données affichées est-elle assurée ?',
      ],
      'incendie' => [
        'Les issues sont-elles dégagées ?',
        'Les moyens d’alerte sont-ils accessibles ?',
        'Les consignes et exercices d’évacuation sont-ils connus ?',
      ],
      'électricité' => [
        'Les rapports de contrôle sont-ils disponibles ?',
        'Les câbles et coffrets présentent-ils des défauts visibles ?',
        'Les accès et interventions sont-ils réservés aux personnes autorisées ?',
      ],
      'ascenseur' => [
        'Les rapports de contrôle et de maintenance sont-ils disponibles ?',
        'Le moyen d’alarme fonctionne-t-il ?',
        'Les consignes en cas de blocage sont-elles connues ?',
      ],
      'produit' => [
        'La fiche de données de sécurité est-elle disponible ?',
        'Le stockage et l’étiquetage sont-ils adaptés ?',
        'Les protections et la ventilation sont-elles adaptées à l’usage ?',
      ],
      'circulation' => [
        'Les flux piétons et véhicules sont-ils séparés ?',
        'La visibilité et la signalisation sont-elles suffisantes ?',
        'Les voies sont-elles dégagées ?',
      ],
      'entreprise' => [
        'Les risques de coactivité ont-ils été échangés ?',
        'Les consignes et permis nécessaires sont-ils disponibles ?',
        'Qui coordonne et surveille les interventions ?',
      ],
      _ => [
        'Quelles tâches sont réellement réalisées ?',
        'Quels événements pourraient causer un dommage ?',
        'Quelles protections sont présentes et vérifiées ?',
        'Quelles preuves restent à recueillir ?',
      ],
    };
    return questions.map(FieldQuestion.new).toList();
  }

  static List<AssistantDanger> dangersFor(String subject) {
    final dangers = switch (_category(subject)) {
      'ergonomie' => [
        'Posture assise prolongée',
        'Hauteur écran inadaptée',
        'Chaise mal réglée',
        'Reflets ou éclairage inadapté',
        'Câbles au sol ou encombrement',
        'Télétravail partiel non vérifié',
        'Charge mentale et interruptions',
        'Manutention ponctuelle de dossiers ou colis',
      ],
      'poste' => [
        'Posture écran prolongée',
        'Charge mentale et interruptions',
        'Accueil visiteurs difficiles',
        'Câbles ou trébuchement',
        'Confidentialité des données affichées',
        'Évacuation visiteurs',
        'Travail isolé ponctuel',
        'Manutention légère courrier ou colis',
      ],
      'incendie' => ['Départ de feu', 'Évacuation entravée', 'Alerte tardive'],
      'électricité' => [
        'Contact électrique',
        'Incendie électrique',
        'Intervention non sécurisée',
      ],
      'ascenseur' => [
        'Blocage de personnes',
        'Chute ou coincement',
        'Maintenance non sécurisée',
      ],
      'produit' => [
        'Inhalation de produit',
        'Contact cutané ou projection',
        'Stockage incompatible',
      ],
      'circulation' => [
        'Collision piéton véhicule',
        'Trébuchement',
        'Visibilité insuffisante',
      ],
      'entreprise' => [
        'Coactivité non coordonnée',
        'Intervention non sécurisée',
        'Consignes méconnues',
      ],
      _ => ['Danger à préciser sur le terrain'],
    };
    return dangers.map(AssistantDanger.new).toList();
  }

  static int score(int g, int p, int e) {
    for (final value in [g, p, e]) {
      if (value < 1 || value > 5) throw ArgumentError('Cotation entre 1 et 5');
    }
    return g * p * e;
  }

  static String level(int score) => score < 20
      ? 'faible'
      : score < 50
      ? 'moyen'
      : score < 100
      ? 'élevé'
      : 'critique';

  static Map<String, String> conclusionsFor(
    List<FieldQuestion> questions,
    List<AssistantDanger> dangers,
  ) {
    final priority = dangers
        .where((d) => (d.score ?? 0) >= 50)
        .map((d) => d.danger)
        .toList();
    return {
      'Risques prioritaires': priority.isEmpty
          ? 'À déterminer après observation et cotation complète.'
          : priority.join('\n'),
      'Actions proposées': dangers
          .map(
            (d) =>
                'Vérifier ${d.danger} sur le terrain et définir les mesures adaptées.',
          )
          .join('\n'),
      'Preuves manquantes': dangers
          .map(
            (d) =>
                '${d.danger} : ${d.evidence.isEmpty ? 'preuve à préciser' : d.evidence} ; ${d.photo.isEmpty ? 'photo à préciser' : d.photo} (collecte à confirmer)',
          )
          .join('\n'),
      'Points bloquants':
          '${questions.where((q) => !q.verified).length} questions non vérifiées ; ${dangers.where((d) => d.score == null).length} dangers non cotés. Scénarios, exposition et preuves à valider.',
    };
  }

  static String draft({
    required String subject,
    required Map<String, String> answers,
    required List<FieldQuestion> questions,
    required List<AssistantDanger> dangers,
    required Map<String, String> conclusions,
    required Map<String, String> decisions,
  }) {
    String value(String? text) =>
        text == null || text.trim().isEmpty ? 'À compléter' : text.trim();
    final b = StringBuffer(
      '# Brouillon d’analyse de risques — à valider\n\n$warning\n\n## Sujet\n${value(subject)}\n\n## Questionnaire\n',
    );
    for (final label in questionnaire) {
      b.writeln('\n### $label\n${value(answers[label])}');
    }
    b.writeln('\n## Questions terrain');
    for (final q in questions) {
      b.writeln('- [${q.verified ? 'x' : ' '}] ${q.text}');
    }
    b.writeln(
      '\n## Dangers et cotations provisoires\nÉchelle expérimentale : G, P, E de 1 à 5 ; score G × P × E. Faible < 20, moyen 20–49, élevé 50–99, critique 100–125. Seuils à valider.',
    );
    for (final d in dangers) {
      b.writeln(
        '\n### ${value(d.danger)}\n- Scénario plausible : ${value(d.scenario)}\n- Personnes exposées : ${value(d.people)}\n- Mesures existantes : ${value(d.measures)}\n- Preuve attendue : ${value(d.evidence)}\n- Photo attendue : ${value(d.photo)}\n- Gravité : ${d.gravity ?? 'Non cotée'} ; Probabilité : ${d.probability ?? 'Non cotée'} ; Exposition : ${d.exposure ?? 'Non cotée'}\n- Score : ${d.score ?? 'Non coté'} ; Niveau : ${d.level}',
      );
    }
    b.writeln('\n## Conclusions provisoires');
    for (final label in conclusionLabels) {
      b.writeln('\n### $label\n${value(conclusions[label])}');
    }
    for (final label in decisionLabels) {
      b.writeln('- $label : ${value(decisions[label])}');
    }
    b.writeln(
      '\n## Validation\nBrouillon non validé. Observation terrain, compléments et validation requis avant utilisation. Les choix PAA/PGP et PIU sont des intentions à valider, sans intégration automatique.',
    );
    return b.toString();
  }
}
