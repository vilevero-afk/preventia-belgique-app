import '../models/preventia_company_project.dart';
import '../models/preventia_project.dart';
import 'preventia_company_project_service.dart';

const _decisionCells = '[ ] Valider  [ ] À revoir  [ ] Ignorer';

class CompanyPiuReviewDocumentService {
  const CompanyPiuReviewDocumentService._();

  static String buildPiuReviewMarkdown(PreventiaCompanyProject project) =>
      _buildPiuReviewMarkdown(project);

  static String buildPgpReviewMarkdown(PreventiaCompanyProject project) =>
      _buildPgpReviewMarkdown(project);

  static String cleanCandidateText(String value) => _cleanCandidateText(value);
}

String buildPiuReviewMarkdown(PreventiaCompanyProject project) =>
    _buildPiuReviewMarkdown(project);

String buildPgpReviewMarkdown(PreventiaCompanyProject project) =>
    _buildPgpReviewMarkdown(project);

String cleanCandidateText(String value) => _cleanCandidateText(value);

String _buildPiuReviewMarkdown(PreventiaCompanyProject project) {
  final profile = _resolvedProfile(project);
  final toValidate = project.piuItems
      .where(
        (item) =>
            _statusKey(item.status) == 'a valider' &&
            classifyReviewCandidate(item).shouldReview,
      )
      .toList(growable: false);
  final toReview = project.piuItems
      .where(
        (item) =>
            _statusKey(item.status) == 'a revoir' &&
            classifyReviewCandidate(item).shouldReview,
      )
      .toList(growable: false);
  final validatedCount = project.piuItems
      .where((item) => _statusKey(item.status) == 'valide')
      .length;
  final ignoredCount = project.piuItems
      .where((item) => _statusKey(item.status) == 'ignore')
      .length;
  final reviewItems = [...toValidate, ...toReview];
  final grouped = _groupPiuItems(reviewItems);

  final buffer = StringBuffer()
    ..writeln('# Revue des éléments PIU à valider — ${project.companyName}')
    ..writeln()
    ..writeln('## Avertissement')
    ..writeln(
      'Ce document est une aide au conseiller en prévention. Les éléments proposés sont issus des analyses de risques et doivent être vérifiés, complétés et validés avant intégration au Plan Interne d’Urgence.',
    )
    ..writeln()
    ..writeln('## Informations société')
    ..writeln('- Entreprise : ${_value(profile.companyName)}')
    ..writeln('- Site : ${_value(profile.siteName)}')
    ..writeln('- Adresse : ${_value(_formattedAddress(profile))}')
    ..writeln(
      '- Conseiller en prévention : ${_value(profile.preventionAdvisor)}',
    )
    ..writeln('- Responsable du site : ${_value(profile.siteManager)}')
    ..writeln(
      '- Service technique : ${_value(profile.technicalServiceContact)}',
    )
    ..writeln('- Profil de risque : ${_value(profile.riskProfile)}')
    ..writeln('- Nombre d’analyses sources : ${project.analyses.length}')
    ..writeln()
    ..writeln('## Synthèse')
    ..writeln('- Nombre d’éléments à valider : ${toValidate.length}')
    ..writeln('- Nombre d’éléments à revoir : ${toReview.length}')
    ..writeln('- Nombre d’éléments déjà validés : $validatedCount')
    ..writeln('- Nombre d’éléments ignorés : $ignoredCount')
    ..writeln()
    ..writeln('## Éléments PIU à valider');

  if (grouped.isEmpty) {
    buffer
      ..writeln()
      ..writeln('Aucun élément PIU à valider ou à revoir.');
  } else {
    var index = 1;
    for (final entry in grouped.entries) {
      buffer
        ..writeln()
        ..writeln('### ${entry.key}')
        ..writeln()
        ..writeln(
          '| N° | Scénario | Titre | Risque issu de l’analyse | Personnes concernées | Procédure à prévoir | Moyens nécessaires | Responsable proposé | Formation / exercice | Points à vérifier | Source | Décision du conseiller |',
        )
        ..writeln('|---|---|---|---|---|---|---|---|---|---|---|---|');
      for (final item in entry.value) {
        final cleanedTitle = cleanCandidateText(item.emergencyTopic);
        final cleanedInfo = cleanCandidateText(item.information);
        final cleanedAction = cleanCandidateText(item.actionRequired);
        final source = _sourceLabel(project, item.sourceDocumentId);
        buffer.writeln(
          '| ${index++} | ${_cell(entry.key)} | ${_cell(_title(cleanedTitle))} | ${_cell(_riskText(cleanedTitle, cleanedInfo))} | ${_cell(item.location)} | ${_cell(cleanedAction.isEmpty ? cleanedInfo : cleanedAction)} | ${_cell(_meansFor(item))} |  |  | ${_cell(_pointsToVerify(cleanedInfo, cleanedAction))} | ${_cell(source)} | ${_cell(_decisionCells)} |',
        );
      }
    }
  }

  return buffer.toString().trim();
}

String _buildPgpReviewMarkdown(PreventiaCompanyProject project) {
  final profile = _resolvedProfile(project);
  final toValidate = project.actionItems
      .where(
        (item) =>
            _statusKey(item.status) == 'a valider' &&
            classifyReviewCandidate(item).shouldReview,
      )
      .toList(growable: false);
  final toReview = project.actionItems
      .where(
        (item) =>
            _statusKey(item.status) == 'a revoir' &&
            classifyReviewCandidate(item).shouldReview,
      )
      .toList(growable: false);
  final validated = project.actionItems
      .where((item) => _statusKey(item.status) == 'valide')
      .toList(growable: false);
  final ignoredCount = project.actionItems
      .where((item) => _statusKey(item.status) == 'ignore')
      .length;
  final reviewItems = [...toValidate, ...toReview];

  final buffer = StringBuffer()
    ..writeln('# Revue des actions PGP/PAA à valider — ${project.companyName}')
    ..writeln()
    ..writeln('## Avertissement')
    ..writeln(
      'Ce document est une aide au conseiller en prévention. Les actions proposées sont issues des analyses de risques et doivent être vérifiées, complétées et validées avant intégration au PGP/PAA.',
    )
    ..writeln()
    ..writeln('## Informations société')
    ..writeln('- Entreprise : ${_value(profile.companyName)}')
    ..writeln('- Site : ${_value(profile.siteName)}')
    ..writeln('- Adresse : ${_value(_formattedAddress(profile))}')
    ..writeln(
      '- Conseiller en prévention : ${_value(profile.preventionAdvisor)}',
    )
    ..writeln('- Responsable du site : ${_value(profile.siteManager)}')
    ..writeln(
      '- Service technique : ${_value(profile.technicalServiceContact)}',
    )
    ..writeln('- Profil de risque : ${_value(profile.riskProfile)}')
    ..writeln('- Nombre d’analyses sources : ${project.analyses.length}')
    ..writeln()
    ..writeln('## Synthèse')
    ..writeln('- Nombre d’actions à valider : ${toValidate.length}')
    ..writeln('- Nombre d’actions à revoir : ${toReview.length}')
    ..writeln('- Nombre d’actions déjà validées : ${validated.length}')
    ..writeln('- Nombre d’actions ignorées : $ignoredCount')
    ..writeln()
    ..writeln('## Actions PGP/PAA à valider')
    ..writeln()
    ..writeln(
      '| N° | Objectif | Risque visé | Mesure principale | Type | Priorité | Responsable proposé | Délai proposé | Preuve attendue | Source | Décision du conseiller |',
    )
    ..writeln('|---|---|---|---|---|---|---|---|---|---|---|');

  if (reviewItems.isEmpty) {
    buffer.writeln(
      '|  | Aucun action à valider ou à revoir. |  |  |  |  |  |  |  |  | ${_cell(_decisionCells)} |',
    );
  } else {
    for (final entry in reviewItems.asMap().entries) {
      final item = entry.value;
      final action = cleanCandidateText(item.action);
      buffer.writeln(
        '| ${entry.key + 1} | ${_cell(_title(action))} | ${_cell(_sourceLabel(project, item.sourceDocumentId))} | ${_cell(action)} | ${_cell(_actionType(item))} | ${_cell(item.priority)} | ${_cell(item.responsible)} | ${_cell(item.deadline)} | ${_cell(item.evidenceExpected)} | ${_cell(_sourceLabel(project, item.sourceDocumentId))} | ${_cell(_decisionCells)} |',
      );
    }
  }

  if (validated.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Déjà validées')
      ..writeln()
      ..writeln('| N° | Action | Source |')
      ..writeln('|---|---|---|');
    for (final entry in validated.asMap().entries) {
      buffer.writeln(
        '| ${entry.key + 1} | ${_cell(_title(cleanCandidateText(entry.value.action)))} | ${_cell(_sourceLabel(project, entry.value.sourceDocumentId))} |',
      );
    }
  }

  return buffer.toString().trim();
}

String _cleanCandidateText(String value) {
  final normalized = value
      .replaceAll('\r\n', '\n')
      .replaceAll(RegExp(r'\s+\|\s+'), '|')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.isEmpty) return '';

  final rawSegments = normalized.contains('|')
      ? normalized.split('|')
      : normalized.split('\n');
  final seen = <String>{};
  final segments = <String>[];
  for (final raw in rawSegments) {
    final cleaned = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\-•]\s*'), '')
        .trim();
    if (cleaned.isEmpty || cleaned == '[à compléter]') continue;
    final key = _statusKey(cleaned);
    if (seen.add(key)) segments.add(cleaned);
  }
  return segments.join('\n');
}

Map<String, List<PreventiaPiuItem>> _groupPiuItems(
  List<PreventiaPiuItem> items,
) {
  const order = [
    'Incendie / évacuation',
    'Secours / accident / malaise',
    'Ascenseur',
    'Électricité / coupures techniques',
    'Accès secours / dossier pompiers',
    'Mise à l’abri / confinement',
    'Autres points à vérifier',
  ];
  final grouped = {for (final label in order) label: <PreventiaPiuItem>[]};
  for (final item in items) {
    grouped[_scenarioFor(item)]!.add(item);
  }
  return Map.fromEntries(
    grouped.entries.where((entry) => entry.value.isNotEmpty),
  );
}

String _scenarioFor(PreventiaPiuItem item) {
  final text = _statusKey(
    '${item.emergencyTopic} ${item.information} ${item.actionRequired}',
  );
  if (text.contains('ascenseur') || text.contains('bloque')) {
    return 'Ascenseur';
  }
  if (text.contains('electric') ||
      text.contains('tgbt') ||
      text.contains('coupure') ||
      text.contains('technique')) {
    return 'Électricité / coupures techniques';
  }
  if (text.contains('incend') || text.contains('evac')) {
    return 'Incendie / évacuation';
  }
  if (text.contains('secours') ||
      text.contains('accident') ||
      text.contains('malaise') ||
      text.contains('blesse')) {
    return 'Secours / accident / malaise';
  }
  if (text.contains('pompier') ||
      text.contains('acces') ||
      text.contains('dossier')) {
    return 'Accès secours / dossier pompiers';
  }
  if (text.contains('abri') ||
      text.contains('confin') ||
      text.contains('iode')) {
    return 'Mise à l’abri / confinement';
  }
  return 'Autres points à vérifier';
}

PreventiaCompanyProfile _resolvedProfile(PreventiaCompanyProject project) {
  final siteName = project.companyProfile.siteName.trim().isNotEmpty
      ? project.companyProfile.siteName
      : project.sites.isNotEmpty
      ? project.sites.first.name
      : '';
  return project.companyProfile.merge(
    PreventiaCompanyProfile(
      companyName: project.companyName,
      siteName: siteName,
    ),
  );
}

String _formattedAddress(PreventiaCompanyProfile profile) => [
  profile.address,
  [profile.postalCode, profile.city].where((part) => part.isNotEmpty).join(' '),
  profile.country,
].where((part) => part.trim().isNotEmpty).join(', ');

String _sourceLabel(PreventiaCompanyProject project, String sourceDocumentId) {
  for (final document in project.analyses) {
    if (document.id == sourceDocumentId) {
      return [
        document.reference,
        document.documentType,
      ].where((part) => part.trim().isNotEmpty).join(' — ');
    }
  }
  return sourceDocumentId;
}

String _title(String value) {
  final firstLine = value.split('\n').first.trim();
  if (firstLine.length <= 120) return firstLine;
  return '${firstLine.substring(0, 117).trimRight()}...';
}

String _riskText(String title, String information) {
  final lines = [
    ...title.split('\n').skip(1),
    ...information.split('\n'),
  ].where((line) => line.trim().isNotEmpty).join('\n');
  return lines.isEmpty ? information : lines;
}

String _meansFor(PreventiaPiuItem item) {
  final text = _statusKey('${item.emergencyTopic} ${item.information}');
  if (text.contains('extinct') || text.contains('incend')) {
    return 'Moyens d’alerte, évacuation et première intervention à confirmer';
  }
  if (text.contains('ascenseur')) {
    return 'Contacts maintenance, communication cabine et accès technique';
  }
  if (text.contains('electric') || text.contains('tgbt')) {
    return 'Localisation des coupures et accès aux locaux techniques';
  }
  return '';
}

String _pointsToVerify(String information, String action) {
  final value = [
    information,
    action,
  ].where((part) => part.trim().isNotEmpty).join('\n');
  return value.isEmpty ? 'À vérifier sur site' : value;
}

String _actionType(PreventiaActionItem item) {
  final destination = item.destination.trim();
  if (destination.isNotEmpty) return destination;
  final text = _statusKey(item.action);
  if (text.contains('formation')) return 'Formation';
  if (text.contains('controle') || text.contains('verifier')) return 'Contrôle';
  if (text.contains('procedure')) return 'Procédure';
  return 'Mesure de prévention';
}

String _value(String value) => value.trim().isEmpty ? '[à compléter]' : value;

String _cell(String value) {
  if (value == _decisionCells) return value;
  return cleanCandidateText(
    value,
  ).replaceAll('|', '/').replaceAll('\n', '<br>').trim();
}

String _statusKey(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[àáâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u')
    .replaceAll(RegExp('[ç]'), 'c')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();
