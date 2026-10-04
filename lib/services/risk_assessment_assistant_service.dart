/// Local, deterministic suggestions. No network or existing document storage.
class FieldQuestion {
  FieldQuestion(
    this.text, {
    this.category = 'prévention',
    this.answer = 'a_verifier',
    this.status = 'brouillon',
    this.importance = 'moyenne',
  }) : id = 'Q-${DateTime.now().microsecondsSinceEpoch}';
  final String id;
  String text;
  String category;
  String answer;
  String comment = '';
  String evidenceExpected = '';
  bool photoRequired = false;
  List<String> photoPaths = [];
  String importance;
  String status;
  bool get verified => answer == 'oui' || status == 'vérifié';
  set verified(bool value) => status = value ? 'vérifié' : 'à compléter';
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
        'La hauteur de l’écran est-elle adaptée au travailleur ?',
        'La chaise est-elle réglable et correctement réglée ?',
        'Le clavier et la souris sont-ils positionnés de manière confortable ?',
        'Des reflets ou éblouissements sont-ils présents sur l’écran ?',
        'Des câbles ou objets gênent-ils les passages autour du poste ?',
        'Le travailleur utilise-t-il un ordinateur portable sans support ?',
        'Le poste en télétravail est-il vérifié ou documenté ?',
        'Des douleurs au dos, à la nuque, aux épaules ou aux poignets sont-elles signalées ?',
        'Des pauses ou alternances de tâches sont-elles organisées ?',
        'Le niveau de bruit gêne-t-il la concentration ?',
      ],
      'poste' => [
        'Les tâches réellement effectuées correspondent-elles à la description du poste ?',
        'Le travailleur reste-t-il plus de 4 heures par jour sur écran ?',
        'Le poste accueille-t-il du public ?',
        'Des situations d’agressivité verbale ou de tension avec visiteurs sont-elles possibles ?',
        'Un moyen d’alerte interne est-il disponible au poste ?',
        'Les visiteurs reçoivent-ils les consignes d’évacuation nécessaires ?',
        'Des câbles ou obstacles créent-ils un risque de trébuchement ?',
        'Le travailleur manipule-t-il régulièrement du courrier, des classeurs ou petits colis ?',
        'Les données visibles à l’écran ou sur papier sont-elles protégées ?',
        'Le travailleur peut-il être isolé ponctuellement à l’accueil ?',
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
        'Les tâches réellement effectuées correspondent-elles à la description du poste ?',
        'Quels événements pourraient causer un dommage ?',
        'Quelles protections sont présentes et vérifiées ?',
        'Quelles preuves restent à recueillir ?',
      ],
    };
    return questions.map(FieldQuestion.new).toList();
  }

  static void fillErgonomicsBaseQuestionnaire(Map<String, String> answers) {
    answers.addAll(const {
      'Où se situe la situation ?':
          'Postes administratifs sur écran du site administratif de Verviers : open space, bureaux individuels, poste d’accueil et postes en télétravail partiel.',
      'Qui est exposé ?':
          'Personnel administratif, agents d’accueil, direction et travailleurs en télétravail partiel.',
      'Quelle tâche est réalisée ?':
          'Travail prolongé sur écran, encodage administratif, traitement de dossiers, accueil téléphonique, accueil ponctuel du public, réunions, gestion du courrier et petits colis.',
      'À quelle fréquence ?':
          'Exposition quotidienne, environ 5 à 7 heures par jour sur écran selon les fonctions, avec interruptions liées aux appels, visiteurs et demandes internes.',
      'Quels incidents, plaintes ou observations existent ?':
          'Aucun accident confirmé lors du préremplissage. Des inconforts sont à vérifier : fatigue visuelle, douleurs nuque, épaules, dos ou poignets, gêne liée au bruit, interruptions fréquentes et difficultés de concentration.',
      'Quelles mesures existent déjà ?':
          'Chaises réglables disponibles pour la majorité des postes, écrans externes sur certains postes, éclairage général présent, télétravail partiel autorisé, pauses informelles selon l’organisation du travail. Aucun contrôle ergonomique systématique n’est encore réalisé.',
      'Quels documents ou preuves sont disponibles ?':
          'Inventaire des postes à compléter, photos terrain à réaliser, liste du matériel ergonomique à obtenir, retours travailleurs à collecter, politique télétravail à consulter, registre des plaintes ou demandes RH à vérifier.',
      'Quelles photos faut-il prendre ?':
          'Vue générale des postes, position écran/chaise/clavier/souris, poste accueil, câbles ou zones encombrées, reflets sur écran, zone courrier ou classement, poste en télétravail si accepté par le travailleur et sans données personnelles.',
    });
  }

  static void fillErgonomicsTest(List<FieldQuestion> questions) {
    const data = [
      (
        'non',
        'Les écrans sont placés à des hauteurs différentes et aucun réglage systématique n’est vérifié.',
        'Photo du poste et observation de la hauteur écran.',
        true,
        'élevée',
      ),
      (
        'non',
        'Les chaises sont réglables mais aucun contrôle du réglage individuel n’est réalisé.',
        'Photo de la chaise et observation du réglage.',
        true,
        'élevée',
      ),
      (
        'non',
        'Le clavier et la souris sont positionnés selon les habitudes de chacun, sans vérification ergonomique.',
        'Photo du plan de travail.',
        true,
        'moyenne',
      ),
      (
        'oui',
        'Des reflets sont possibles sur les postes proches des fenêtres.',
        'Photo montrant les reflets ou l’orientation du poste.',
        true,
        'élevée',
      ),
      (
        'oui',
        'Des câbles visibles peuvent gêner les déplacements autour de certains postes.',
        'Photo des câbles ou zones encombrées.',
        true,
        'élevée',
      ),
      (
        'oui',
        'Certains travailleurs utilisent un ordinateur portable sans support, clavier séparé ou souris adaptée.',
        'Photo du poste avec ordinateur portable.',
        true,
        'moyenne',
      ),
      (
        'non',
        'Les postes en télétravail ne sont pas vérifiés de manière systématique.',
        'Questionnaire télétravail ou déclaration du travailleur.',
        false,
        'moyenne',
      ),
      (
        'oui',
        'Des inconforts doivent être considérés comme possibles et vérifiés auprès des travailleurs.',
        'Retour travailleur, questionnaire ou signalement RH.',
        false,
        'élevée',
      ),
      (
        'non',
        'Les pauses sont informelles et aucune alternance structurée des tâches n’est prévue.',
        'Organisation du travail ou échange avec la ligne hiérarchique.',
        false,
        'moyenne',
      ),
      (
        'oui',
        'L’open space et les appels téléphoniques peuvent gêner la concentration.',
        'Observation terrain ou retour travailleurs.',
        false,
        'moyenne',
      ),
    ];
    for (var i = 0; i < questions.length && i < data.length; i++) {
      final q = questions[i];
      final item = data[i];
      q.answer = item.$1;
      q.comment = item.$2;
      q.evidenceExpected = item.$3;
      q.photoRequired = item.$4;
      q.importance = item.$5;
      q.status = 'vérifié';
    }
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

  static String answerLabel(String answer) => switch (answer) {
    'oui' => 'Oui',
    'non' => 'Non',
    'non_applicable' => 'Non applicable',
    _ => 'À vérifier',
  };

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
      'Actions proposées': [
        ...questions.where((q) => q.answer == 'non').map((q) {
          final text = q.text.toLowerCase();
          if (text.contains('hauteur de l’écran')) {
            return 'Adapter la hauteur des écrans.';
          }
          if (text.contains('chaise')) {
            return 'Vérifier le réglage des chaises.';
          }
          if (text.contains('télétravail')) {
            return 'Vérifier les postes en télétravail.';
          }
          if (text.contains('pauses')) {
            return 'Organiser des pauses ou alternances de tâches.';
          }
          return 'Action proposée : vérifier ou corriger — ${q.text}.';
        }),
        if (questions.any(
          (q) => q.text.contains('chaise') && q.answer == 'non',
        ))
          'Former le personnel aux réglages du poste écran.',
        if (questions.any(
          (q) => q.text.contains('reflets') && q.answer == 'oui',
        ))
          'Corriger les reflets et mesurer l’éclairage.',
        if (questions.any(
          (q) => q.text.contains('câbles') && q.answer == 'oui',
        ))
          'Sécuriser les câbles au poste accueil ou autour des postes.',
        if (questions.any(
          (q) => q.text.contains('ordinateur portable') && q.answer == 'oui',
        ))
          'Fournir supports écran, clavier et souris adaptés.',
        if (questions.any(
          (q) => q.text.contains('douleurs') && q.answer == 'oui',
        ))
          'Collecter les plaintes ou inconforts liés au dos, à la nuque, aux épaules ou aux poignets.',
        if (questions.any((q) => q.text.contains('bruit') && q.answer == 'oui'))
          'Évaluer la gêne sonore en open space.',
        ...dangers.map(
          (d) =>
              'Vérifier ${d.danger} sur le terrain et définir les mesures adaptées.',
        ),
      ].join('\n'),
      'Preuves manquantes': dangers
          .map(
            (d) =>
                '${d.danger} : ${d.evidence.isEmpty ? 'preuve à préciser' : d.evidence} ; ${d.photo.isEmpty ? 'photo à préciser' : d.photo} (collecte à confirmer)',
          )
          .join('\n'),
      'Points bloquants':
          '${questions.where((q) => q.answer == 'a_verifier').map((q) => q.text).join('\n')}\n${questions.where((q) => q.answer == 'a_verifier').length} questions non vérifiées ; ${dangers.where((d) => d.score == null).length} dangers non cotés. Scénarios, exposition et preuves à valider.',
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
    b.writeln('| Question | Réponse | Commentaire | Preuve attendue | Photo |');
    b.writeln('|---|---|---|---|---|');
    for (final q in questions) {
      b.writeln(
        '| ${q.text} | ${answerLabel(q.answer)} | ${value(q.comment)} | ${value(q.evidenceExpected)} | ${q.photoRequired ? 'À prendre' : 'Non requise'} |',
      );
    }
    final photos = questions
        .where((q) => q.photoRequired)
        .map((q) => q.text)
        .toList();
    b.writeln(
      '\n### Photos à prendre\n${photos.isEmpty ? 'Aucune photo requise à ce stade.' : photos.join('\n')}',
    );
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
    return b
        .toString()
        .replaceAll(RegExp(r'Page\s+1\s*/\s*1', caseSensitive: false), '')
        .replaceAll('SCÉNARIO TEST SPGE', '')
        .replaceAll('SCENARIO TEST SPGE', '');
  }
}
