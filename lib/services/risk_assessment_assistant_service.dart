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

enum AdvisorDecision { accepted, modified, refused }

extension AdvisorDecisionLabel on AdvisorDecision {
  String get label => switch (this) {
    AdvisorDecision.accepted => 'Accepté',
    AdvisorDecision.modified => 'Modifié',
    AdvisorDecision.refused => 'Refusé',
  };
}

class AdvisorReview {
  AdvisorDecision? decision;
  String advisorComment = '';
  String responsible = '';
  String deadline = '';
  String finalEvidence = '';
  bool get retained =>
      decision == AdvisorDecision.accepted ||
      decision == AdvisorDecision.modified;
}

class AssistantAction extends AdvisorReview {
  AssistantAction(
    this.action, {
    this.linkedRisk = '',
    this.priority = 'À déterminer',
    this.type = 'organisationnelle',
    this.integration = 'PAA',
  });
  String action;
  String linkedRisk;
  String priority;
  String type;
  String integration;
  static const types = [
    'technique',
    'organisationnelle',
    'formation',
    'preuve',
    'achat',
    'procédure',
  ];
}

class AssistantDanger extends AdvisorReview {
  AssistantDanger(this.danger)
    : proposedMeasure =
          'Vérifier $danger sur le terrain et définir les mesures adaptées.';
  String danger;
  String scenario = '';
  String people = '';
  String measures = '';
  String proposedMeasure;
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
      q.status = 'test — à vérifier sur site';
    }
  }

  static const ergonomicsActions = [
    'Adapter la hauteur des écrans.',
    'Vérifier le réglage des chaises.',
    'Corriger les reflets et mesurer l’éclairage.',
    'Sécuriser les câbles au poste accueil ou autour des postes.',
    'Fournir supports écran, clavier et souris adaptés.',
    'Vérifier les postes en télétravail.',
    'Organiser des pauses ou alternances de tâches.',
    'Former le personnel aux réglages du poste écran.',
    'Collecter les plaintes ou inconforts liés au dos, à la nuque, aux épaules ou aux poignets.',
    'Évaluer la gêne sonore en open space.',
    'Organiser la manutention ponctuelle du courrier et des colis.',
  ];

  static const _ergonomicsMeasures = {
    'Posture assise prolongée':
        'Organiser des pauses ou alternances de tâches.',
    'Hauteur écran inadaptée': 'Adapter la hauteur des écrans.',
    'Chaise mal réglée': 'Vérifier le réglage des chaises.',
    'Reflets ou éclairage inadapté':
        'Corriger les reflets et mesurer l’éclairage.',
    'Câbles au sol ou encombrement':
        'Sécuriser les câbles au poste accueil ou autour des postes.',
    'Télétravail partiel non vérifié': 'Vérifier les postes en télétravail.',
    'Charge mentale et interruptions': 'Évaluer la gêne sonore en open space.',
    'Manutention ponctuelle de dossiers ou colis':
        'Organiser la manutention ponctuelle du courrier et des colis.',
  };

  static void fillErgonomicsDangersTest(List<AssistantDanger> dangers) {
    const data = [
      (
        'Posture assise prolongée',
        'Travail prolongé en position assise sans alternance suffisante, pouvant entraîner fatigue, douleurs dorsales et inconfort.',
        'Personnel administratif travaillant sur écran.',
        'Pauses informelles uniquement, sans organisation structurée.',
        'Observation du poste et échange avec les travailleurs.',
        'Vue générale du poste.',
        3,
        3,
        4,
      ),
      (
        'Hauteur écran inadaptée',
        'Écran placé trop bas ou trop haut, entraînant flexion ou extension prolongée de la nuque.',
        'Personnel utilisant un écran plusieurs heures par jour.',
        'Aucun réglage systématique vérifié.',
        'Photo du poste et observation de la hauteur écran.',
        'Photo écran / position de travail.',
        3,
        3,
        4,
      ),
      (
        'Chaise mal réglée',
        'Chaise réglable mais non adaptée au travailleur, pouvant provoquer douleurs dos, épaules ou jambes.',
        'Personnel administratif et agents d’accueil.',
        'Chaises réglables disponibles mais réglage individuel non contrôlé.',
        'Photo de la chaise et observation du réglage.',
        'Photo chaise / position assise.',
        3,
        3,
        4,
      ),
      (
        'Reflets ou éclairage inadapté',
        'Reflets sur écran ou éclairage inadapté provoquant fatigue visuelle et postures compensatoires.',
        'Travailleurs proches des fenêtres ou zones très éclairées.',
        'Stores ou éclairage général à vérifier.',
        'Photo montrant les reflets ou l’orientation du poste.',
        'Photo écran avec reflet ou orientation du poste.',
        2,
        3,
        4,
      ),
      (
        'Câbles au sol ou encombrement',
        'Câbles visibles ou objets autour du poste créant un risque de trébuchement.',
        'Travailleurs, visiteurs internes et personnel de nettoyage.',
        'Rangement des câbles non systématisé.',
        'Photo des câbles ou zones encombrées.',
        'Photo câbles / passage.',
        3,
        3,
        3,
      ),
      (
        'Télétravail partiel non vérifié',
        'Poste à domicile non évalué, avec ordinateur portable utilisé sans support ou périphériques adaptés.',
        'Travailleurs en télétravail partiel.',
        'Télétravail autorisé mais poste non vérifié systématiquement.',
        'Questionnaire télétravail ou déclaration du travailleur.',
        'Photo du poste télétravail si acceptée par le travailleur, sans données personnelles.',
        3,
        3,
        3,
      ),
      (
        'Charge mentale et interruptions',
        'Interruptions fréquentes, appels et demandes simultanées pouvant réduire la concentration et augmenter la fatigue.',
        'Agents administratifs et agents d’accueil.',
        'Organisation actuelle à vérifier avec la ligne hiérarchique.',
        'Retour travailleurs, observation ou entretien avec la ligne hiérarchique.',
        'Non requise.',
        3,
        3,
        3,
      ),
      (
        'Manutention ponctuelle de dossiers ou colis',
        'Manipulation ponctuelle de dossiers, bacs courrier ou petits colis dans des postures défavorables.',
        'Agents d’accueil et personnel administratif.',
        'Aide à la manutention non identifiée.',
        'Observation des tâches courrier / classement.',
        'Photo zone courrier ou classement.',
        2,
        3,
        2,
      ),
    ];
    for (final d in dangers) {
      for (final item in data.where((item) => item.$1 == d.danger)) {
        d.scenario = item.$2;
        d.people = item.$3;
        d.measures = item.$4;
        d.evidence = item.$5;
        d.photo = item.$6;
        d.gravity = item.$7;
        d.probability = item.$8;
        d.exposure = item.$9;
        d.proposedMeasure = _ergonomicsMeasures[d.danger]!;
      }
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
    return dangers.map((name) {
      final danger = AssistantDanger(name);
      if (_category(subject) == 'ergonomie') {
        danger.proposedMeasure = _ergonomicsMeasures[name]!;
      }
      return danger;
    }).toList();
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
      'Actions proposées':
          (dangers.any((d) => _ergonomicsMeasures.containsKey(d.danger))
                  ? ergonomicsActions
                  : [
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
                        (q) =>
                            q.text.contains('ordinateur portable') &&
                            q.answer == 'oui',
                      ))
                        'Fournir supports écran, clavier et souris adaptés.',
                      if (questions.any(
                        (q) => q.text.contains('douleurs') && q.answer == 'oui',
                      ))
                        'Collecter les plaintes ou inconforts liés au dos, à la nuque, aux épaules ou aux poignets.',
                      if (questions.any(
                        (q) => q.text.contains('bruit') && q.answer == 'oui',
                      ))
                        'Évaluer la gêne sonore en open space.',
                      ...dangers.map((d) => d.proposedMeasure),
                    ])
              .toSet()
              .join('\n'),
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

  static List<AssistantAction> actionsFor(
    List<AssistantDanger> dangers,
    String proposals,
  ) {
    final texts = <String>{
      ...proposals.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty),
      ...dangers
          .map((d) => d.proposedMeasure.trim())
          .where((s) => s.isNotEmpty),
    };
    return texts.map((text) {
      AssistantDanger? risk;
      for (final d in dangers) {
        if (d.proposedMeasure == text) {
          risk = d;
          break;
        }
      }
      if (risk == null &&
          dangers.any((d) => _ergonomicsMeasures.containsKey(d.danger))) {
        final name = text.contains('plaintes')
            ? 'Posture assise prolongée'
            : text.contains('Former') || text.contains('supports écran')
            ? 'Hauteur écran inadaptée'
            : '';
        for (final d in dangers.where((d) => d.danger == name)) {
          risk = d;
        }
      }
      return AssistantAction(
        text,
        linkedRisk: risk?.danger ?? 'À préciser par le conseiller',
        priority: risk?.level ?? 'À déterminer',
        type: text.startsWith('Former')
            ? 'formation'
            : text.startsWith('Fournir')
            ? 'achat'
            : text.startsWith('Collecter')
            ? 'preuve'
            : text.startsWith('Adapter') ||
                  text.startsWith('Corriger') ||
                  text.startsWith('Sécuriser')
            ? 'technique'
            : 'organisationnelle',
      );
    }).toList();
  }

  static void fillValidationTest(
    List<AssistantDanger> dangers,
    List<AssistantAction> actions,
  ) {
    for (final review in <AdvisorReview>[...dangers, ...actions]) {
      review.decision = AdvisorDecision.accepted;
      review.responsible = 'Service prévention';
      review.deadline = '3 mois';
      review.finalEvidence = 'Photo après correction ou preuve documentaire';
      review.advisorComment = 'À vérifier et valider sur site.';
    }
    for (final d in dangers) {
      d.gravity ??= 3;
      d.probability ??= 3;
      d.exposure ??= 3;
    }
  }

  static List<String> validationErrors(
    List<AssistantDanger> dangers,
    List<AssistantAction> actions,
  ) {
    final errors = <String>[];
    if (dangers.isEmpty) errors.add('Ajoutez au moins un danger.');
    for (final d in dangers) {
      if (d.decision == null) errors.add('Décision requise : ${d.danger}');
      if (d.retained && d.score == null) {
        errors.add('Cotation finale requise : ${d.danger}');
      }
    }
    for (final a in actions) {
      if (a.decision == null) errors.add('Décision requise : ${a.action}');
      if (a.retained &&
          [
            a.responsible,
            a.deadline,
            a.finalEvidence,
          ].any((v) => v.trim().isEmpty)) {
        errors.add(
          'Responsable, délai et preuve attendue requis : ${a.action}',
        );
      }
    }
    return errors;
  }

  static const finalNotice =
      'Ce document constitue une analyse assistée préparée à partir des informations encodées. Il doit être vérifié, complété et validé par le conseiller en prévention, l’employeur et les instances compétentes.';

  static String finalAnalysis({
    required String subject,
    required Map<String, String> answers,
    required List<FieldQuestion> questions,
    required List<AssistantDanger> dangers,
    required List<AssistantAction> actions,
    required String conclusion,
    required String advisor,
    String reference = '',
    DateTime? date,
    String companyName = '',
    String siteName = '',
    bool validated = true,
  }) => buildFinalAssistedRiskMarkdown(
    subject: subject,
    answers: answers,
    questions: questions,
    dangers: dangers,
    actions: actions,
    conclusion: conclusion,
    advisor: advisor,
    reference: reference,
    date: date,
    companyName: companyName,
    siteName: siteName,
    validated: validated,
  );

  static String buildFinalAssistedRiskMarkdown({
    required String subject,
    required Map<String, String> answers,
    required List<FieldQuestion> questions,
    required List<AssistantDanger> dangers,
    required List<AssistantAction> actions,
    required String conclusion,
    required String advisor,
    String reference = '',
    DateTime? date,
    String companyName = '',
    String siteName = '',
    bool validated = false,
  }) {
    final errors = validationErrors(dangers, actions);
    if (errors.isNotEmpty) throw StateError(errors.join('\n'));
    String value(String? v) =>
        v == null || v.trim().isEmpty ? 'À compléter' : v.trim();
    final dateLabel = date == null
        ? 'À compléter'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final b = StringBuffer('# Analyse finale assistée de risques\n\n');
    b.writeln(
      'Référence : ${value(reference)}\nDate : $dateLabel\nEntreprise : ${value(companyName)}\nSite : ${value(siteName)}\nSujet analysé : ${value(subject)}\nStatut : ${validated ? 'Analyse finale validée' : 'Analyse finale à valider'}\n',
    );
    b.writeln('$finalNotice\n\n$warning\n');
    b.writeln(
      validated
          ? 'Document validé par le conseiller en prévention : ${value(advisor)}.\n'
          : 'Préparé pour validation par le conseiller en prévention : ${value(advisor)}.\n',
    );
    b.writeln('## Questionnaire de base');
    for (final label in questionnaire) {
      b.writeln('\n### $label\n${value(answers[label])}');
    }
    b.writeln('\n## Questions terrain et réponses');
    if (questions.isEmpty) b.writeln('Aucune question terrain renseignée.');
    if (questions.isNotEmpty) {
      b.writeln(
        '| Question | Réponse | Commentaire | Preuve attendue | Photo | Importance |',
      );
      b.writeln('|---|---|---|---|---|---|');
      for (final q in questions) {
        String cell(String v) =>
            value(v).replaceAll('|', r'\|').replaceAll('\n', '<br>');
        b.writeln(
          '| ${cell(q.text)} | ${answerLabel(q.answer)} | ${cell(q.comment)} | ${cell(q.evidenceExpected)} | ${q.photoRequired ? 'À prendre' : 'Non requise'} | ${cell(q.importance)} |',
        );
      }
    }
    b.writeln('\n## Dangers retenus et cotations finales');
    b.writeln(
      'G, P, E de 1 à 5 ; score G × P × E. Faible < 20, moyen 20–49, élevé 50–99, critique 100–125. Grille à vérifier pour la situation étudiée.',
    );
    final retained = dangers.where((d) => d.retained).toList();
    if (retained.isEmpty) b.writeln('Aucun danger retenu par le conseiller.');
    for (final d in retained) {
      b.writeln(
        '\n### ${value(d.danger)}\nScénario plausible : ${value(d.scenario)}\nPersonnes exposées : ${value(d.people)}\nMesures existantes : ${value(d.measures)}\nPreuve attendue : ${value(d.evidence)}\nPhoto attendue : ${value(d.photo)}\nCotation finale G/P/E : ${d.gravity}/${d.probability}/${d.exposure}\nScore : ${d.score} ; Niveau : ${d.level}\nStatut conseiller : ${d.decision!.label}\nCommentaire conseiller : ${value(d.advisorComment)}\nResponsable : ${value(d.responsible)}\nDélai : ${value(d.deadline)}\nPreuve finale attendue : ${value(d.finalEvidence)}',
      );
    }
    b.writeln('\n## Plan d’action retenu');
    final accepted = actions.where((a) => a.retained).toList();
    if (accepted.isEmpty) b.writeln('Aucune action retenue par le conseiller.');
    for (final a in accepted) {
      b.writeln(
        '\n### ${a.action}\nRisque lié : ${value(a.linkedRisk)}\nPriorité : ${a.priority}\nType : ${a.type}\nProposition d’intégration : ${a.integration}\nStatut conseiller : ${a.decision!.label}\nResponsable : ${a.responsible}\nDélai : ${a.deadline}\nPreuve attendue : ${a.finalEvidence}\nCommentaire conseiller : ${value(a.advisorComment)}',
      );
    }
    final refused = actions
        .where((a) => a.decision == AdvisorDecision.refused)
        .toList();
    if (refused.isNotEmpty) {
      b.writeln('\n## Actions écartées ou refusées');
      for (final a in refused) {
        b.writeln(
          '\n### ${a.action}\nCommentaire conseiller : ${value(a.advisorComment)}',
        );
      }
    }
    b.writeln(
      '\n## Conclusion finale du conseiller\n${value(conclusion)}\n\n## Signatures\nConseiller en prévention : ${value(advisor)}\nSignature : ____________________\nEmployeur : ____________________\nDate de validation : ____________________',
    );
    return cleanMarkdownForExport(b.toString());
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
      '# Brouillon d’analyse de risques — à valider\n\n$warning\n\n## Sujet\n${value(subject)}\n\n## Questionnaire de base\n',
    );
    for (final label in questionnaire) {
      b.writeln('\n### $label\n${value(answers[label])}');
    }
    b.writeln('\n## Questions terrain');
    b.writeln(
      '| Question | Réponse | Commentaire | Preuve attendue | Photo | Importance |',
    );
    b.writeln('|---|---|---|---|---|---|');
    for (final q in questions) {
      b.writeln(
        '| ${q.text} | ${answerLabel(q.answer)} | ${value(q.comment)} | ${value(q.evidenceExpected)} | ${q.photoRequired ? 'À prendre' : 'Non requise'} | ${q.importance} |',
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
      '\n## Validation\nBrouillon non validé. Observation terrain, compléments et validation requis avant utilisation. Les choix PAA/PGP sont des intentions à valider, sans intégration automatique.',
    );
    return cleanMarkdownForExport(b.toString());
  }

  static String cleanMarkdownForExport(String markdown) {
    var text = markdown
        .replaceAll('\r\n', '\n')
        .replaceAll('a_verifier', 'À vérifier');
    text = text.replaceAll(
      RegExp(
        r'```(?:debug|json|log|logs)[^\n]*\n[\s\S]*?```',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->', multiLine: true), '');
    text = text
        .split('\n')
        .where(
          (line) => !RegExp(
            r'Intégration PIU|Page\s+1\s*/\s*1|SC[ÉE]NARIO TEST SPGE|Document\s*:\s*Analyse de risques|^\s*(?:\[DEBUG\]|DEBUG\s*:)',
            caseSensitive: false,
          ).hasMatch(line),
        )
        .join('\n');
    final lines = text.split('\n');
    for (var i = lines.length - 1; i >= 0; i--) {
      final heading = RegExp(r'^(#{1,6})\s').firstMatch(lines[i].trim());
      if (heading == null || i == 0) continue;
      var next = i + 1;
      while (next < lines.length && lines[next].trim().isEmpty) {
        next++;
      }
      final nextHeading = next < lines.length
          ? RegExp(r'^(#{1,6})\s').firstMatch(lines[next].trim())
          : null;
      final level = heading.group(1)!.length;
      final nextLevel = nextHeading?.group(1)?.length;
      if (next == lines.length || (nextLevel != null && nextLevel <= level)) {
        lines.removeAt(i);
      }
    }
    return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}
