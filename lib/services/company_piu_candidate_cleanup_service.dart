import 'package:flutter/foundation.dart';

import '../models/preventia_company_project.dart';
import '../models/preventia_project.dart';

const _piuRedirectReason =
    'Ne relève pas d’une situation d’urgence opérationnelle';

class PiuCleanupResult {
  const PiuCleanupResult({required this.project, required this.movedCount});

  final PreventiaCompanyProject project;
  final int movedCount;
}

class CompanyPiuCandidateCleanupService {
  const CompanyPiuCandidateCleanupService._();

  static bool isOperationalPiuCandidate(PreventiaPiuItem item) {
    final raw =
        '${item.emergencyTopic} ${item.information} ${item.actionRequired} ${item.location}';
    final normalized = _normalize(raw);
    final compact = normalized.replaceAll(' ', '');
    if (normalized.isEmpty) return false;
    if (_metadataKeys.any(compact.contains)) return false;
    final operational = _operationalKeywords.any(normalized.contains);
    if (!operational) return false;
    if (_negativeKeywords.any(normalized.contains) &&
        !_strongOperationalKeywords.any(normalized.contains)) {
      return false;
    }
    return true;
  }

  static PiuCleanupResult cleanupProject(PreventiaCompanyProject project) {
    final kept = <PreventiaPiuItem>[];
    final movedActions = <PreventiaActionItem>[];
    final movedEvidence = <PreventiaEvidenceItem>[];
    final movedPoints = <String>[];
    var movedCount = 0;

    for (final item in project.piuItems) {
      if (isOperationalPiuCandidate(item)) {
        kept.add(item);
      } else {
        movedCount += 1;
        final redirect = _redirect(item);
        if (redirect.action != null) movedActions.add(redirect.action!);
        if (redirect.evidence != null) movedEvidence.add(redirect.evidence!);
        if (redirect.pointToVerify != null) {
          movedPoints.add(redirect.pointToVerify!);
        }
      }
    }

    final limited = _limitOperationalItems(project, kept);
    final overflow = kept.where((item) => !limited.contains(item)).toList();
    for (final item in overflow) {
      movedCount += 1;
      final redirect = _redirect(item, forceAction: true);
      if (redirect.action != null) movedActions.add(redirect.action!);
    }

    final cleaned = project.copyWith(
      piuItems: _dedupePiu(limited),
      actionItems: _dedupeActions([...project.actionItems, ...movedActions]),
      evidenceItems: _dedupeEvidence([
        ...project.evidenceItems,
        ...movedEvidence,
      ]),
      pointsToVerify: _mergeStrings(project.pointsToVerify, movedPoints),
    );

    if (movedCount > 0) {
      debugPrint(
        '[PreventIA] PIU cleanup moved $movedCount items away from PIU for companyKey=${project.companyKey}',
      );
    }
    return PiuCleanupResult(project: cleaned, movedCount: movedCount);
  }

  static List<PreventiaPiuItem> _limitOperationalItems(
    PreventiaCompanyProject project,
    List<PreventiaPiuItem> items,
  ) {
    final limit = _limitForProfile(project.companyProfile.riskProfile);
    final pending = items
        .where((item) => _status(item.status) == 'a valider')
        .toList();
    if (pending.length <= limit) return items;
    final rankedPending = [...pending]
      ..sort((a, b) => _score(b).compareTo(_score(a)));
    final keepPendingIds = rankedPending
        .take(limit)
        .map((item) => item.id)
        .toSet();
    return items
        .where(
          (item) =>
              _status(item.status) != 'a valider' ||
              keepPendingIds.contains(item.id),
        )
        .toList(growable: false);
  }

  static int _limitForProfile(String profile) {
    final normalized = _normalize(profile);
    if (normalized.contains('seveso') ||
        normalized.contains('industriel majeur')) {
      return 40;
    }
    if (normalized.contains('eleve') || normalized.contains('tres eleve')) {
      return 25;
    }
    return 15;
  }

  static _Redirect _redirect(
    PreventiaPiuItem item, {
    bool forceAction = false,
  }) {
    final text =
        '${item.emergencyTopic} ${item.information} ${item.actionRequired}';
    final normalized = _normalize(text);
    if (!forceAction && _evidenceKeywords.any(normalized.contains)) {
      return _Redirect(
        evidence: PreventiaEvidenceItem(
          id: 'redirected_evidence_${item.id}',
          sourceDocumentId: item.sourceDocumentId,
          label: _labelFor(item),
          location: item.location,
          type: _evidenceType(normalized),
          status: 'à valider',
          redirectedFrom: 'PIU',
          redirectReason: _piuRedirectReason,
        ),
      );
    }
    if (!forceAction && _verifyKeywords.any(normalized.contains)) {
      return _Redirect(
        pointToVerify: '${_labelFor(item)} ($_piuRedirectReason)',
      );
    }
    return _Redirect(
      action: PreventiaActionItem(
        id: 'redirected_action_${item.id}',
        sourceDocumentId: item.sourceDocumentId,
        sourceDocumentType: '',
        action: _labelFor(item),
        priority: '',
        responsible: '',
        deadline: '',
        status: 'à valider',
        evidenceExpected: '',
        destination: 'PGP/PAA',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        redirectedFrom: 'PIU',
        redirectReason: _piuRedirectReason,
      ),
    );
  }

  static String _labelFor(PreventiaPiuItem item) {
    final parts = [
      item.emergencyTopic,
      item.actionRequired,
      item.information,
    ].where((part) => part.trim().isNotEmpty);
    return parts.first.trim();
  }

  static String _evidenceType(String normalized) {
    if (normalized.contains('photo')) return 'photo';
    if (normalized.contains('fds')) return 'FDS';
    if (normalized.contains('registre')) return 'registre';
    if (normalized.contains('rapport') || normalized.contains('pv')) {
      return 'rapport';
    }
    return 'preuve';
  }

  static int _score(PreventiaPiuItem item) {
    final text = _normalize(
      '${item.emergencyTopic} ${item.information} ${item.actionRequired}',
    );
    var score = 0;
    for (final keyword in _strongOperationalKeywords) {
      if (text.contains(keyword)) score += 4;
    }
    for (final keyword in _operationalKeywords) {
      if (text.contains(keyword)) score += 1;
    }
    return score;
  }
}

class _Redirect {
  const _Redirect({this.action, this.evidence, this.pointToVerify});

  final PreventiaActionItem? action;
  final PreventiaEvidenceItem? evidence;
  final String? pointToVerify;
}

const _metadataKeys = [
  'additionalinformation',
  'documenttype',
  'feedannualactionplan',
  'activity',
  'concernedtasks',
  'availableevidence',
  'periodiccontrols',
  'writteninstructions',
  'exposedworkers',
  'includedlocations',
];

const _operationalKeywords = [
  'incend',
  'evac',
  'alerte',
  'appel 112',
  '112',
  'accident grave',
  'malaise',
  'secours',
  'personne bloquee',
  'personne bloquee en cabine',
  'appel urgence cabine',
  'appel d urgence cabine',
  'contacts maintenance',
  'procedure de secours ascenseur',
  'information pmr',
  'fuite de gaz',
  'deversement',
  'explosion',
  'confin',
  'mise a l abri',
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
  'acces secours',
  'accueil secours',
  'pompier',
  'point de rassemblement',
  'pmr',
  'communication d urgence',
  'exercice evacuation',
  'visiteur',
  'sous traitant',
  'issue de secours',
  'extinction',
  'porte coupe feu',
  'compartimentage',
  'local technique',
];

const _strongOperationalKeywords = [
  'incend',
  'evac',
  'appel 112',
  'accident grave',
  'malaise',
  'secours',
  'personne bloquee',
  'personne bloquee en cabine',
  'appel urgence cabine',
  'appel d urgence cabine',
  'contacts maintenance',
  'procedure de secours ascenseur',
  'coupure electrique d urgence',
  'coupure generale tgbt',
  'coupure courant',
  'delestage',
  'danger electrique en intervention',
  'fuite de gaz',
  'explosion',
  'confin',
  'mise a l abri',
  'acces secours',
  'accueil secours',
  'pompier',
  'point de rassemblement',
];

const _negativeKeywords = [
  'rapport',
  'pv',
  'photo',
  'fds',
  'inventaire',
  'registre',
  'attestation',
  'controle periodique',
  'validation expert',
  'livre iii',
  'reference reglementaire',
  'planification',
  'maintenance',
  'pgp',
  'paa',
  'preuve',
];

const _evidenceKeywords = [
  'rapport',
  'pv',
  'photo',
  'fds',
  'inventaire',
  'registre',
  'attestation',
  'preuve',
];

const _verifyKeywords = [
  'controle',
  'validation expert',
  'expert',
  'obligation a confirmer',
  'reference reglementaire',
  'livre iii',
];

List<PreventiaPiuItem> _dedupePiu(List<PreventiaPiuItem> items) {
  final seen = <String>{};
  return items
      .where((item) => seen.add(_normalize(item.emergencyTopic)))
      .toList();
}

List<PreventiaActionItem> _dedupeActions(List<PreventiaActionItem> items) {
  final seen = <String>{};
  return items.where((item) => seen.add(_normalize(item.action))).toList();
}

List<PreventiaEvidenceItem> _dedupeEvidence(List<PreventiaEvidenceItem> items) {
  final seen = <String>{};
  return items.where((item) => seen.add(_normalize(item.label))).toList();
}

List<String> _mergeStrings(List<String> existing, List<String> additions) {
  final result = [...existing];
  final seen = existing.map(_normalize).toSet();
  for (final addition in additions) {
    if (addition.trim().isNotEmpty && seen.add(_normalize(addition))) {
      result.add(addition);
    }
  }
  return result;
}

String _status(String value) => _normalize(value);

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[àáâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();
