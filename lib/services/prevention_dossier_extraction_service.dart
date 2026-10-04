class PreventionDossierExtractionResult {
  const PreventionDossierExtractionResult({
    this.structuredRiskRows = const [],
    this.piuCandidates = const [],
    this.pgpCandidates = const [],
    this.diuCandidates = const [],
    this.evidenceItems = const [],
    this.priorityActions = const [],
    this.pointsToVerify = const [],
    this.requiredValidations = const [],
  });

  final List<Map<String, dynamic>> structuredRiskRows;
  final List<Map<String, dynamic>> piuCandidates;
  final List<Map<String, dynamic>> pgpCandidates;
  final List<Map<String, dynamic>> diuCandidates;
  final List<Map<String, dynamic>> evidenceItems;
  final List<Map<String, dynamic>> priorityActions;
  final List<String> pointsToVerify;
  final List<String> requiredValidations;
}

class PreventionDossierExtractionService {
  PreventionDossierExtractionResult extractFromRiskAssessment({
    required String documentType,
    required String markdown,
    required Map<String, dynamic> formData,
    required String sourceDocumentId,
    required String sourceReference,
  }) {
    const status = 'à valider';
    final riskProfile = _value(formData, 'riskProfile').trim().isEmpty
        ? 'inconnu / à déterminer'
        : _value(formData, 'riskProfile');
    final normalizedProfile = _normalize(riskProfile);
    final lines = [
      ...markdown.split('\n'),
      for (final entry in formData.entries)
        if (entry.value != null && entry.value.toString().trim().isNotEmpty)
          '${entry.key} : ${entry.value}',
    ].map(_cleanLine).where((line) => line.length >= 12).toList();

    final structuredRiskRows = <Map<String, dynamic>>[];
    final piuCandidates = <Map<String, dynamic>>[];
    final pgpCandidates = <Map<String, dynamic>>[];
    final diuCandidates = <Map<String, dynamic>>[];
    final evidenceItems = <Map<String, dynamic>>[];
    final priorityActions = <Map<String, dynamic>>[];
    final pointsToVerify = <String>{};
    final requiredValidations = <String>{};
    final seenPiu = <String>{};
    final seenPgp = <String>{};
    final seenDiu = <String>{};
    final seenEvidence = <String>{};

    if (normalizedProfile.contains('inconnu')) {
      pointsToVerify.add(
        'Déterminer le profil de risque de l’entreprise avant validation du PIU et du PGP/PAA. $_prudenceMention',
      );
    }
    final seveso = normalizedProfile.contains('seveso');
    if (seveso) {
      pointsToVerify.add(
        'Vérifier l’articulation avec les obligations Seveso applicables et les procédures validées par les personnes compétentes. $_prudenceMention',
      );
      requiredValidations.add('Validation spécialisée obligatoire.');
    }

    for (final line in lines) {
      final normalized = _normalize(line);
      if (_isNoise(normalized)) continue;
      if (_containsAny(normalized, _riskKeywords)) {
        structuredRiskRows.add({
          'id': _id(sourceDocumentId, 'risk', line),
          'sourceDocumentId': sourceDocumentId,
          'sourceReference': sourceReference,
          'sourceDocumentType': documentType,
          'risk': line,
          'status': status,
        });
      }

      if (_shouldExtractPiu(normalized, normalizedProfile)) {
        final title = _titleFromLine(line, _piuKeywords);
        final key = _normalize(title);
        if (seenPiu.add(key) && piuCandidates.length < 40) {
          piuCandidates.add({
            'id': _id(sourceDocumentId, 'piu', title),
            'sourceDocumentId': sourceDocumentId,
            'sourceReference': sourceReference,
            'sourceDocumentType': documentType,
            'title': title,
            'scenario': line,
            'riskSource': line,
            'personsConcerned': _value(formData, 'exposedPersons'),
            'existingMeasures': _value(formData, 'existingMeasures'),
            'procedureToPlan': _procedureSuggestion(normalized),
            'requiredMeans': _requiredMeans(normalized),
            'responsible': _value(formData, 'responsible'),
            'trainingOrExercise': _trainingSuggestion(normalized),
            'pointsToVerify': _prudenceMention,
            'chapterSuggestion': _chapterSuggestion(normalized),
            'status': status,
          });
        }
      }

      if (_shouldExtractPgp(normalized, normalizedProfile)) {
        final measure = _measureFromLine(line);
        final key = _normalize(measure);
        if (seenPgp.add(key) && pgpCandidates.length < 80) {
          final candidate = {
            'id': _id(sourceDocumentId, 'pgp', measure),
            'sourceDocumentId': sourceDocumentId,
            'sourceReference': sourceReference,
            'sourceDocumentType': documentType,
            'objective': 'Réduire ou maîtriser le risque identifié.',
            'riskTargeted': line,
            'mainMeasure': measure,
            'measureType': _measureType(normalized),
            'priority': _field(
              line,
              'Priorité',
              fallback: _priority(normalized),
            ),
            'deadline': _field(line, 'Délai'),
            'responsible': _field(
              line,
              'Responsable',
              fallback: _value(formData, 'responsible'),
            ),
            'requiredMeans': '',
            'followUpIndicator': 'Action vérifiée et preuve disponible.',
            'expectedEvidence': _field(
              line,
              'Preuve',
              fallback: _value(formData, 'evidenceToCollect'),
            ),
            'status': status,
          };
          pgpCandidates.add(candidate);
          priorityActions.add({
            'id': _id(sourceDocumentId, 'priority', measure),
            'sourceDocumentId': sourceDocumentId,
            'sourceReference': sourceReference,
            'sourceDocumentType': documentType,
            'title': measure,
            'sourceInRiskAssessment': line,
            'destination': _destination(normalized),
            'type': candidate['measureType'],
            'responsible': candidate['responsible'],
            'proposedDeadline': candidate['deadline'],
            'expectedEvidence': candidate['expectedEvidence'],
            'requiredValidation': 'Validation conseiller en prévention',
            'status': status,
          });
        }
      }

      if (_containsAny(normalized, _diuKeywords)) {
        final key = _normalize(line);
        if (seenDiu.add(key)) {
          diuCandidates.add({
            'id': _id(sourceDocumentId, 'diu', line),
            'sourceDocumentId': sourceDocumentId,
            'sourceReference': sourceReference,
            'sourceDocumentType': documentType,
            'riskOrConstraint': line,
            'location': _field(line, 'Zone'),
            'instructionForFutureWork': _field(
              line,
              'Instruction',
              fallback: line,
            ),
            'planOrPhoto': _value(formData, 'evidenceToCollect'),
            'status': status,
          });
        }
      }

      if (_containsAny(normalized, _evidenceKeywords)) {
        final evidence = _field(line, 'Preuve', fallback: line);
        final key = _normalize(evidence);
        if (seenEvidence.add(key)) {
          evidenceItems.add({
            'id': _id(sourceDocumentId, 'evidence', evidence),
            'sourceDocumentId': sourceDocumentId,
            'sourceReference': sourceReference,
            'sourceDocumentType': documentType,
            'label': evidence,
            'location': _field(line, 'Zone'),
            'type': normalized.contains('photo') ? 'photo' : 'preuve',
            'status': status,
          });
        }
      }

      if (_containsAny(normalized, _verificationKeywords)) {
        pointsToVerify.add('$line $_prudenceMention');
      }
    }

    if (seveso && _containsAny(_normalize(markdown), _sevesoMajorKeywords)) {
      requiredValidations.add(
        'Validation par les personnes compétentes avant intégration PIU/PGP.',
      );
    }

    return PreventionDossierExtractionResult(
      structuredRiskRows: structuredRiskRows,
      piuCandidates: piuCandidates,
      pgpCandidates: pgpCandidates,
      diuCandidates: diuCandidates,
      evidenceItems: evidenceItems,
      priorityActions: priorityActions,
      pointsToVerify: pointsToVerify.toList(growable: false),
      requiredValidations: requiredValidations.toList(growable: false),
    );
  }
}

const _prudenceMention =
    'À vérifier dans la version applicable du Code du bien-être au travail ou auprès des personnes compétentes.';

const _piuKeywords = [
  'incendie',
  'evacuation',
  'malaise',
  'accident grave',
  'fuite',
  'deversement',
  'produit dangereux',
  'explosion',
  'fuite de gaz',
  'confinement',
  'mise a l abri',
  'violence externe',
  'agression',
  'intrusion',
  'amok',
  'panne critique',
  'coupure electrique d urgence',
  'coupure generale tgbt',
  'coupure courant',
  'delestage',
  'acces local technique',
  'acces tgbt',
  'danger electrique en intervention',
  'dossier pompiers',
  'plans des coupures',
  'personne ba4',
  'personne ba5',
  'service technique a contacter',
  'personne bloquee',
  'personne bloquee en cabine',
  'appel urgence cabine',
  'appel d urgence cabine',
  'contacts maintenance',
  'procedure de secours ascenseur',
  'information pmr',
  'communication bidirectionnelle',
  'accueil secours',
  'dossier pompiers',
  'point de rassemblement',
];

const _lowPiuKeywords = [
  'incendie',
  'evacuation',
  'malaise',
  'accident grave',
  'violence externe',
  'agression',
  'intrusion',
  'amok',
  'panne critique',
];

const _pgpKeywords = [
  'mesure complementaire',
  'mesure proposee',
  'plan d action',
  'a prevoir',
  'a planifier',
  'a mettre a jour',
  'a obtenir',
  'formation',
  'information',
  'procedure',
  'controle',
  'entretien',
  'maintenance',
  'consignation',
  'thermographie',
  'sect',
  'rgie',
  'ba4',
  'ba5',
  'epi',
  'epc',
  'levee remarque',
  'verification periodique',
  'action corrective',
];

const _lowPgpKeywords = [
  'ergonomie',
  'rps',
  'ecran',
  'premiers secours',
  'ordre',
  'proprete',
  'evacuation',
  'formation',
  'information',
];

const _moderateKeywords = [
  'manutention',
  'circulation',
  'stockage',
  'equipement',
  'produit',
  'entreprise exterieure',
];

const _highKeywords = [
  'machine',
  'maintenance',
  'consignation',
  'produit dangereux',
  'incendie',
  'explosion',
  'circulation interne',
  'epi',
  'epc',
  'controle',
  'procedure',
];

const _diuKeywords = ['diu', 'travaux futurs', 'intervention future'];
const _evidenceKeywords = ['preuve', 'photo', 'rapport a obtenir', 'document'];
const _riskKeywords = [
  'risque',
  'danger',
  'exposition',
  'situation dangereuse',
];
const _verificationKeywords = [
  'a verifier',
  'rapport a obtenir',
  'validation',
  'avis cppt',
  'sipp',
  'sepp',
  'personne competente',
  'controle reglementaire',
  'document manquant',
];
const _sevesoMajorKeywords = [
  'accident majeur',
  'produit dangereux',
  'explosion',
  'toxique',
  'incendie industriel',
  'fuite massive',
];

bool _shouldExtractPiu(String normalized, String profile) {
  if (!_containsAny(normalized, _piuKeywords)) {
    return false;
  }
  if (profile.contains('faible')) {
    return _containsAny(normalized, _lowPiuKeywords);
  }
  if (profile.contains('seveso')) {
    return _containsAny(normalized, _sevesoMajorKeywords);
  }
  if (profile.contains('inconnu')) {
    return _containsAny(normalized, _lowPiuKeywords);
  }
  return true;
}

bool _shouldExtractPgp(String normalized, String profile) {
  if (!_containsAny(normalized, _pgpKeywords)) {
    return false;
  }
  if (profile.contains('faible')) {
    return _containsAny(normalized, _lowPgpKeywords);
  }
  if (profile.contains('modere')) {
    return _containsAny(normalized, [
      ..._lowPgpKeywords,
      ..._moderateKeywords,
      ..._pgpKeywords,
    ]);
  }
  if (profile.contains('seveso')) {
    return _containsAny(normalized, _sevesoMajorKeywords) ||
        _containsAny(normalized, _pgpKeywords);
  }
  return _containsAny(normalized, [..._highKeywords, ..._pgpKeywords]);
}

String _destination(String normalized) {
  final piu = _containsAny(normalized, _piuKeywords);
  final pgp = _containsAny(normalized, _pgpKeywords);
  if (piu && pgp) return 'PIU + PGP/PAA';
  if (piu) return 'PIU';
  if (pgp) return 'PGP/PAA';
  if (_containsAny(normalized, _diuKeywords)) return 'DIU';
  if (_containsAny(normalized, _verificationKeywords)) {
    return 'À vérifier avant intégration';
  }
  return 'Analyse de risques uniquement';
}

String _measureType(String normalized) {
  if (_containsAny(normalized, ['controle', 'verification', 'sect', 'rgie'])) {
    return 'contrôle / vérification';
  }
  if (_containsAny(normalized, ['formation', 'information'])) {
    return 'formation / information';
  }
  if (_containsAny(normalized, ['procedure', 'document', 'schema'])) {
    return 'documentaire';
  }
  if (_containsAny(normalized, ['organisation', 'planifier', 'coordination'])) {
    return 'organisationnelle';
  }
  if (_containsAny(normalized, ['epi', 'epc', 'maintenance', 'consignation'])) {
    return 'technique';
  }
  return 'autre';
}

String _chapterSuggestion(String normalized) {
  if (_containsAny(normalized, ['incendie', 'evacuation'])) {
    return 'Incendie et évacuation';
  }
  if (_containsAny(normalized, ['ascenseur', 'personne bloquee'])) {
    return 'Ascenseurs et personnes bloquées';
  }
  if (_containsAny(normalized, ['tgbt', 'cabine ht', 'coupure electrique'])) {
    return 'Installations techniques et coupures';
  }
  return 'Situations d’urgence issues des analyses';
}

String _procedureSuggestion(String normalized) {
  if (normalized.contains('ascenseur')) return 'Procédure personne bloquée.';
  if (normalized.contains('incendie')) return 'Procédure incendie/évacuation.';
  if (normalized.contains('fuite')) return 'Procédure fuite/déversement.';
  return 'Procédure à définir et valider.';
}

String _requiredMeans(String normalized) {
  if (normalized.contains('communication bidirectionnelle')) {
    return 'Moyens de communication et contact maintenance.';
  }
  if (normalized.contains('incendie')) {
    return 'Moyens incendie et accueil secours.';
  }
  return '';
}

String _trainingSuggestion(String normalized) {
  if (_containsAny(normalized, ['evacuation', 'incendie'])) {
    return 'Exercice ou information évacuation à prévoir.';
  }
  return '';
}

String _priority(String normalized) {
  if (_containsAny(normalized, [
    'accident grave',
    'explosion',
    'incendie',
    'toxique',
  ])) {
    return 'Haute';
  }
  return 'À définir';
}

String _measureFromLine(String line) =>
    _field(line, 'Action', fallback: _field(line, 'Mesure', fallback: line));

String _titleFromLine(String line, List<String> keywords) {
  final normalized = _normalize(line);
  for (final keyword in keywords) {
    if (normalized.contains(keyword)) return _capitalize(keyword);
  }
  return line.length > 90 ? '${line.substring(0, 90)}...' : line;
}

String _field(String line, String label, {String fallback = ''}) {
  final match = RegExp(
    '${RegExp.escape(label)}\\s*[:：-]\\s*([^|;]+)',
    caseSensitive: false,
  ).firstMatch(line);
  return match?.group(1)?.trim() ?? fallback;
}

String _value(Map<String, dynamic> formData, String key) =>
    formData[key]?.toString().trim() ?? '';

bool _containsAny(String normalized, Iterable<String> keywords) =>
    keywords.any((keyword) => normalized.contains(keyword));

bool _isNoise(String normalized) {
  if (RegExp(r'^\d+(\.\d+)*\s*[a-z ]{0,50}$').hasMatch(normalized)) {
    return true;
  }
  return normalized == 'a completer' ||
      normalized == 'a verifier sur site' ||
      normalized == 'preuve a obtenir';
}

String _cleanLine(String value) => value
    .replaceAll(RegExp(r'^\s*[#>*+-]+\s*'), '')
    .replaceAll(RegExp(r'\s*\|\s*'), ' | ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[àáâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u')
    .replaceAll('’', ' ')
    .replaceAll("'", ' ');

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

String _id(String sourceDocumentId, String kind, String content) {
  final hash = '$sourceDocumentId|$kind|$content'.codeUnits.fold<int>(
    17,
    (result, unit) => (result * 37 + unit) & 0x7fffffff,
  );
  return '${kind}_$hash';
}
