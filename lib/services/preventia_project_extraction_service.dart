import '../models/preventia_project.dart';
import 'preventia_risk_extractor.dart';

PreventiaProjectExtraction extractItemsFromRiskAssessment({
  required String documentType,
  required String markdown,
  required Map<String, dynamic> formData,
  required String sourceDocumentId,
}) {
  const status = 'à valider';
  final now = DateTime.now();
  final combinedLines = <String>[
    ...markdown.split('\n'),
    for (final entry in formData.entries)
      if (entry.value != null && entry.value.toString().trim().isNotEmpty)
        '${entry.key} : ${entry.value}',
  ];
  final legacy = extractProjectItemsFromRiskAssessment(
    markdown: markdown,
    documentType: documentType,
    documentId: sourceDocumentId,
  );

  final risks = [...legacy.riskItems];
  final actions = [...legacy.actionItems];
  final piuItems = [...legacy.piuItems];
  final diuItems = [...legacy.diuItems];
  final evidenceItems = [...legacy.evidenceItems];
  final paaPgpItems = [...legacy.paaPgpItems];

  for (final rawLine in combinedLines) {
    final line = _cleanLine(rawLine);
    if (line.isEmpty || _isNoise(line) || _isLowValueCandidate(line)) continue;
    final normalized = _normalize(line);
    final priority = _field(line, const ['Priorité', 'priority']);
    final responsible = _field(line, const ['Responsable', 'responsible']);
    final deadline = _field(line, const ['Délai', 'deadline']);
    final proof = _field(line, const [
      'Preuve à obtenir',
      'Preuve',
      'evidenceToCollect',
    ]);

    if (_containsAny(normalized, _riskKeywords)) {
      risks.add(
        PreventiaRiskItem(
          id: _itemId(sourceDocumentId, 'risk', line),
          sourceDocumentId: sourceDocumentId,
          sourceDocumentType: documentType,
          riskTitle: _field(line, const [
            'Risque',
            'Danger',
            'mainRisks',
            'fireRisks',
          ], fallback: line),
          location: _field(line, const [
            'Zone',
            'Localisation',
            'concernedAreas',
          ]),
          exposedPersons: _field(line, const [
            'Personnes exposées',
            'exposedPersons',
          ]),
          existingMeasures: _field(line, const [
            'Mesures existantes',
            'existingMeasures',
          ]),
          residualRisk: _field(line, const ['Risque résiduel']),
          priority: priority,
          evidenceToCollect: proof,
          photoToTake: '',
          linkedToDiu: _containsAny(normalized, _diuKeywords),
          linkedToPaaPgp: _containsAny(normalized, _paaPgpKeywords),
          linkedToPiu: _containsAny(normalized, _piuKeywords),
          status: status,
        ),
      );
    }

    if (_containsAny(normalized, _actionKeywords) && _isUsefulAction(line)) {
      final action = PreventiaActionItem(
        id: _itemId(sourceDocumentId, 'action', line),
        sourceDocumentId: sourceDocumentId,
        sourceDocumentType: documentType,
        action: _field(line, const [
          'Action',
          'Mesure à prévoir',
          'Mesures à prévoir',
          'Mesures complémentaires',
          'plannedMeasures',
        ], fallback: line),
        priority: priority,
        responsible: responsible,
        deadline: deadline,
        status: status,
        evidenceExpected: proof,
        destination: 'PGA/PAA/PGP',
        createdAt: now,
        updatedAt: now,
      );
      actions.add(action);
      paaPgpItems.add(action);
    }

    if (_containsAny(normalized, _piuKeywords) && _isUsefulPiu(line)) {
      piuItems.add(
        PreventiaPiuItem(
          id: _itemId(sourceDocumentId, 'piu', line),
          sourceDocumentId: sourceDocumentId,
          emergencyTopic: line,
          information: line,
          location: _field(line, const [
            'Zone',
            'Localisation',
            'concernedAreas',
          ]),
          actionRequired: _field(line, const [
            'Action',
            'Mesure à prévoir',
            'plannedMeasures',
          ]),
          status: status,
        ),
      );
    }

    if (_containsAny(normalized, _diuKeywords)) {
      diuItems.add(
        PreventiaDiuItem(
          id: _itemId(sourceDocumentId, 'diu', line),
          sourceDocumentId: sourceDocumentId,
          riskOrConstraint: line,
          location: _field(line, const [
            'Zone',
            'Localisation',
            'concernedAreas',
          ]),
          instructionForFutureWork: _field(line, const [
            'Instruction',
            'Mesure à prévoir',
            'plannedMeasures',
          ]),
          planOrPhoto: proof,
          status: status,
        ),
      );
    }

    if (_containsAny(normalized, _evidenceKeywords)) {
      evidenceItems.add(
        PreventiaEvidenceItem(
          id: _itemId(sourceDocumentId, 'evidence', line),
          sourceDocumentId: sourceDocumentId,
          label: _field(line, const [
            'Preuve à obtenir',
            'Preuve',
            'Photo',
            'evidenceToCollect',
          ], fallback: line),
          location: _field(line, const [
            'Zone',
            'Localisation',
            'concernedAreas',
          ]),
          type: normalized.contains('photo') ? 'photo' : 'preuve',
          status: status,
        ),
      );
    }
  }

  final deduplicatedActions = _prioritizeActions(
    _deduplicate(actions, (item) => _normalizeActionTitle(item.action)),
    documentType,
  ).take(80).toList(growable: false);
  final deduplicatedPiuItems = _prioritizePiu(
    _deduplicate(
      piuItems,
      (item) => _normalizeActionTitle(item.emergencyTopic),
    ),
    documentType,
  ).take(40).toList(growable: false);
  return PreventiaProjectExtraction(
    riskItems: _deduplicate(
      risks,
      (item) => '${item.sourceDocumentId}|${_normalize(item.riskTitle)}',
    ),
    actionItems: deduplicatedActions,
    paaPgpItems: _deduplicate([
      ...paaPgpItems,
      ...deduplicatedActions,
    ], (item) => '${item.sourceDocumentId}|${_normalize(item.action)}'),
    piuItems: deduplicatedPiuItems,
    diuItems: _deduplicate(
      diuItems,
      (item) => '${item.sourceDocumentId}|${_normalize(item.riskOrConstraint)}',
    ),
    evidenceItems: _deduplicate(
      evidenceItems,
      (item) => '${item.sourceDocumentId}|${_normalize(item.label)}',
    ),
  );
}

bool _isLowValueCandidate(String line) {
  final normalized = _normalize(line)
      .replaceAll(RegExp(r'[\[\]().:;|_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.length < 12) return true;
  if (RegExp(r'^\d+(\.\d+)*\s+').hasMatch(normalized)) return true;
  const ignored = {
    'a completer',
    'a verifier sur site',
    'preuve a obtenir',
    'validation requise',
  };
  if (ignored.contains(normalized)) return true;
  if (RegExp(r'^(chapitre|section|partie|annexe)\s+\d*').hasMatch(normalized)) {
    return true;
  }
  if (RegExp(r'^\d+(\.\d+)*\s*[a-z ]{0,50}$').hasMatch(normalized)) {
    return true;
  }
  return false;
}

bool _isUsefulAction(String line) {
  final normalized = _normalize(line);
  const useful = [
    'obtenir',
    'verifier',
    'formaliser',
    'planifier',
    'controler',
    'tester',
    'mettre a jour',
    'lever',
    'consignation',
    'thermographie',
    'rgie',
    'ba4',
    'ba5',
    'sect',
    'rapport',
    'procedure',
    'verrouillage',
    'schema',
    'differentiel',
    'communication bidirectionnelle',
    'portes palieres',
    'cuvette',
    'salle machines',
  ];
  return _containsAny(normalized, useful);
}

bool _isUsefulPiu(String line) {
  final normalized = _normalize(line);
  const useful = [
    'coupure',
    'tgbt',
    'local technique',
    'service technique',
    'incendie',
    'secours',
    'cabine ht',
    'personne bloquee',
    'communication bidirectionnelle',
    'maintenance ascenseur',
    'evacuation',
    'salle machines',
    'point de rassemblement',
    'pmr',
    'accueil secours',
    'dossier pompiers',
    'moyens incendie',
  ];
  return _containsAny(normalized, useful);
}

String _normalizeActionTitle(String value) => _normalize(value)
    .replaceAll(RegExp(r'\[[^\]]*\]'), '')
    .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

List<PreventiaActionItem> _prioritizeActions(
  List<PreventiaActionItem> items,
  String documentType,
) {
  final normalizedType = _normalize(documentType);
  int score(PreventiaActionItem item) {
    final value = _normalize('${item.action} ${item.sourceDocumentType}');
    var result = 0;
    if (_containsAny(value, const [
      'mesures de prevention proposees',
      'plan d action priorise',
      'points a integrer au paa',
      'points a integrer au pgp',
      'points bloquants avant validation',
    ])) {
      result += 20;
    }
    final electrical =
        normalizedType.contains('electrique') ||
        normalizedType.contains('bt ht');
    final elevator = normalizedType.contains('ascenseur');
    if (electrical &&
        _containsAny(value, const [
          'pv rgie',
          'rgie',
          'ba4',
          'ba5',
          'consignation',
          'thermographie',
          'verrouillage armoires',
          'schemas',
          'differentiels',
          'organisme agree',
        ])) {
      result += 50;
    }
    if (elevator &&
        _containsAny(value, const [
          'rapport sect',
          'sect',
          'communication bidirectionnelle',
          'eclairage de secours',
          'portes palieres',
          'cuvette',
          'salle machines',
          'personne bloquee',
        ])) {
      result += 50;
    }
    return result;
  }

  final sorted = [...items];
  sorted.sort((a, b) => score(b).compareTo(score(a)));
  return sorted;
}

List<PreventiaPiuItem> _prioritizePiu(
  List<PreventiaPiuItem> items,
  String documentType,
) {
  final normalizedType = _normalize(documentType);
  int score(PreventiaPiuItem item) {
    final value = _normalize('${item.emergencyTopic} ${item.information}');
    var result = 0;
    final electrical =
        normalizedType.contains('electrique') ||
        normalizedType.contains('bt ht');
    final elevator = normalizedType.contains('ascenseur');
    final fire = normalizedType.contains('incendie');
    if (electrical &&
        _containsAny(value, const [
          'coupure generale',
          'tgbt',
          'local technique',
          'service technique',
          'incendie electrique',
          'secours',
          'cabine ht',
        ])) {
      result += 50;
    }
    if (elevator &&
        _containsAny(value, const [
          'personne bloquee',
          'communication bidirectionnelle',
          'maintenance ascenseur',
          'evacuation',
          'salle machines',
          'secours',
        ])) {
      result += 50;
    }
    if (fire &&
        _containsAny(value, const [
          'point de rassemblement',
          'evacuation',
          'pmr',
          'accueil secours',
          'dossier pompiers',
          'coupures techniques',
          'moyens incendie',
        ])) {
      result += 50;
    }
    return result;
  }

  final sorted = [...items];
  sorted.sort((a, b) => score(b).compareTo(score(a)));
  return sorted;
}

const _actionKeywords = [
  'action',
  'mesure',
  'mesure proposee',
  'mesure a prevoir',
  'mesures a prevoir',
  'mesure complementaire',
  'a prevoir',
  'a mettre a jour',
  'a verifier',
  'a planifier',
  'a obtenir',
  'formation',
  'entretien',
  'controle',
  'maintenance',
  'levee remarque',
  'thermographie',
  'consignation',
  'sect',
  'rgie',
  'ba4',
  'ba5',
  'remarque ouverte',
  'mise a jour',
  'preuve',
  'priorite',
  'responsable',
  'delai',
  'preuve a obtenir',
  'plannedmeasures',
];

const _riskKeywords = [
  'risque',
  'danger',
  'situation dangereuse',
  'mainrisks',
  'firerisks',
];

const _piuKeywords = [
  'piu',
  'urgence',
  'evacuation',
  'incendie',
  'coupure generale',
  'personne bloquee',
  'ascenseur',
  'contact secours',
  'secours',
  'coupure electricite',
  'coupure gaz',
  'coupure eau',
  'tgbt',
  'cabine ht',
  'local technique',
  'communication bidirectionnelle',
  'dossier pompiers',
  'pmr',
  'point de rassemblement',
  'accueil secours',
  'mise a l abri',
];

const _diuKeywords = [
  'diu',
  'intervention future',
  'local technique',
  'armoire electrique',
  'tgbt',
  'ascenseur',
  'salle machines',
  'cuvette',
  'contrainte d acces',
  'entreprises exterieures',
  'acces reserve',
  'consignation',
  'zone a risque',
];

const _paaPgpKeywords = [
  'paa',
  'pgp',
  'pgaa',
  'plan d action',
  'mesure de prevention',
  'formation',
  'controle',
  'entretien',
  'modernisation',
  'levee remarque',
];

const _evidenceKeywords = [
  'preuve',
  'photo',
  'rapport',
  'pv',
  'attestation',
  'controle',
  'sect',
  'rgie',
  'fds',
  'thermographie',
  'schema',
  'plan',
];

String _cleanLine(String value) => value
    .replaceAll(RegExp(r'^\s*[#>*+-]+\s*'), '')
    .replaceAll(RegExp(r'\s*\|\s*'), ' | ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool _isNoise(String line) {
  final normalized = _normalize(line);
  return RegExp(r'^[-: |]+$').hasMatch(line) ||
      normalized == 'scenario test spge' ||
      normalized.startsWith('document :');
}

bool _containsAny(String value, List<String> keywords) =>
    keywords.any(value.contains);

String _field(String line, List<String> labels, {String fallback = ''}) {
  for (final label in labels) {
    final match = RegExp(
      '${RegExp.escape(label)}\\s*[:：-]\\s*([^|;]+)',
      caseSensitive: false,
    ).firstMatch(line);
    final value = match?.group(1)?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return fallback;
}

List<T> _deduplicate<T>(List<T> values, String Function(T) keyOf) {
  final result = <String, T>{};
  for (final value in values) {
    result.putIfAbsent(keyOf(value), () => value);
  }
  return result.values.toList(growable: false);
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[àáâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _itemId(String sourceDocumentId, String kind, String title) {
  final normalizedTitle = _normalize(title);
  final hash = '$sourceDocumentId|$normalizedTitle'.codeUnits.fold<int>(
    17,
    (result, unit) => (result * 37 + unit) & 0x7fffffff,
  );
  return '${kind}_$hash';
}
