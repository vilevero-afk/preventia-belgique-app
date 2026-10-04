import '../models/preventia_project.dart';

class PreventiaProjectExtraction {
  const PreventiaProjectExtraction({
    this.riskItems = const [],
    this.actionItems = const [],
    this.paaPgpItems = const [],
    this.diuItems = const [],
    this.piuItems = const [],
    this.evidenceItems = const [],
  });

  final List<PreventiaRiskItem> riskItems;
  final List<PreventiaActionItem> actionItems;
  final List<PreventiaActionItem> paaPgpItems;
  final List<PreventiaDiuItem> diuItems;
  final List<PreventiaPiuItem> piuItems;
  final List<PreventiaEvidenceItem> evidenceItems;
}

PreventiaProjectExtraction extractProjectItemsFromRiskAssessment({
  required String markdown,
  required String documentType,
  required String documentId,
}) {
  const status = 'à valider';
  final risks = <PreventiaRiskItem>[];
  final actions = <PreventiaActionItem>[];
  final diuItems = <PreventiaDiuItem>[];
  final piuItems = <PreventiaPiuItem>[];
  final evidence = <PreventiaEvidenceItem>[];
  final now = DateTime.now();
  final isElevatorAssessment = _normalize(documentType).contains('ascenseur');
  var inElevatorRiskTable = false;
  var inElevatorActionPlan = false;

  for (final rawLine in markdown.split('\n')) {
    final trimmedRawLine = rawLine.trim();
    if (isElevatorAssessment && trimmedRawLine.startsWith('## ')) {
      inElevatorRiskTable = RegExp(r'^##\s+6\.').hasMatch(trimmedRawLine);
      inElevatorActionPlan = RegExp(r'^##\s+15\.').hasMatch(trimmedRawLine);
    }
    final line = rawLine
        .replaceAll(RegExp(r'^\s*[#>*+-]+\s*'), '')
        .replaceAll(RegExp(r'\s*\|\s*'), ' | ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (line.isEmpty || RegExp(r'^[-: ]+$').hasMatch(line)) continue;
    final normalized = _normalize(line);
    final isDiu = RegExp(r'\bdiu\b').hasMatch(normalized);
    final isPaaPgp = RegExp(r'\b(paa|pgp|pgaa)\b').hasMatch(normalized);
    final isPiu = RegExp(r'\bpiu\b').hasMatch(normalized);
    final priority = _field(line, 'Priorité');
    final responsible = _field(line, 'Responsable');
    final deadline = _field(line, 'Délai');
    final markdownCells = _markdownCells(rawLine);

    if (inElevatorRiskTable &&
        markdownCells.length >= 13 &&
        !_isMarkdownHeaderOrSeparator(markdownCells)) {
      final destination = markdownCells[11];
      risks.add(
        PreventiaRiskItem(
          id: _itemId(documentId, 'risk', markdownCells.join('|')),
          sourceDocumentId: documentId,
          sourceDocumentType: documentType,
          riskTitle: markdownCells[0],
          location: '',
          exposedPersons: markdownCells[1],
          existingMeasures: markdownCells[4],
          residualRisk: markdownCells[3],
          priority: markdownCells[9],
          evidenceToCollect: markdownCells[10],
          photoToTake: '',
          linkedToDiu: RegExp(r'\bdiu\b').hasMatch(_normalize(destination)),
          linkedToPaaPgp: RegExp(
            r'\b(paa|pgp|pgaa)\b',
          ).hasMatch(_normalize(destination)),
          linkedToPiu: RegExp(r'\bpiu\b').hasMatch(_normalize(destination)),
          status: status,
        ),
      );
    }

    if (inElevatorActionPlan &&
        markdownCells.length >= 8 &&
        !_isMarkdownHeaderOrSeparator(markdownCells)) {
      actions.add(
        PreventiaActionItem(
          id: _itemId(documentId, 'action', markdownCells.join('|')),
          sourceDocumentId: documentId,
          sourceDocumentType: documentType,
          action: markdownCells[1],
          priority: markdownCells[2],
          responsible: markdownCells[3],
          deadline: markdownCells[4],
          status: status,
          evidenceExpected: markdownCells[5],
          destination: markdownCells[6],
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (normalized.contains('risque residuel')) {
      risks.add(
        PreventiaRiskItem(
          id: _itemId(documentId, 'risk', line),
          sourceDocumentId: documentId,
          sourceDocumentType: documentType,
          riskTitle: line,
          location: '',
          exposedPersons: '',
          existingMeasures: '',
          residualRisk: _field(line, 'Risque résiduel', fallback: line),
          priority: priority,
          evidenceToCollect: '',
          photoToTake: '',
          linkedToDiu: isDiu,
          linkedToPaaPgp: isPaaPgp,
          linkedToPiu: isPiu,
          status: status,
        ),
      );
    }

    if (!(isElevatorAssessment && inElevatorActionPlan) &&
        (RegExp(r'\bactions?\b', caseSensitive: false).hasMatch(normalized) ||
            normalized.contains('mesure a prevoir'))) {
      actions.add(
        PreventiaActionItem(
          id: _itemId(documentId, 'action', line),
          sourceDocumentId: documentId,
          sourceDocumentType: documentType,
          action: _field(
            line,
            'Action',
            fallback: _field(line, 'Mesure à prévoir', fallback: line),
          ),
          priority: priority,
          responsible: responsible,
          deadline: deadline,
          status: status,
          evidenceExpected: _field(line, 'Preuve à obtenir'),
          destination: [
            if (isDiu) 'DIU',
            if (isPaaPgp) 'PAA/PGP',
            if (isPiu) 'PIU',
          ].join(', '),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (normalized.contains('preuve a obtenir')) {
      evidence.add(
        PreventiaEvidenceItem(
          id: _itemId(documentId, 'evidence', line),
          sourceDocumentId: documentId,
          label: _field(line, 'Preuve à obtenir', fallback: line),
          location: '',
          type: 'preuve',
          status: status,
        ),
      );
    }
    if (normalized.contains('photo a prendre')) {
      evidence.add(
        PreventiaEvidenceItem(
          id: _itemId(documentId, 'photo', line),
          sourceDocumentId: documentId,
          label: _field(line, 'Photo à prendre', fallback: line),
          location: '',
          type: 'photo',
          status: status,
        ),
      );
    }
    if (isDiu) {
      diuItems.add(
        PreventiaDiuItem(
          id: _itemId(documentId, 'diu', line),
          sourceDocumentId: documentId,
          riskOrConstraint: line,
          location: '',
          instructionForFutureWork: '',
          planOrPhoto: '',
          status: status,
        ),
      );
    }
    if (isPiu) {
      piuItems.add(
        PreventiaPiuItem(
          id: _itemId(documentId, 'piu', line),
          sourceDocumentId: documentId,
          emergencyTopic: line,
          information: line,
          location: '',
          actionRequired: '',
          status: status,
        ),
      );
    }
  }

  return PreventiaProjectExtraction(
    riskItems: risks,
    actionItems: actions,
    paaPgpItems: actions
        .where(
          (item) => RegExp(
            r'PAA|PGP|PGAA',
            caseSensitive: false,
          ).hasMatch(item.destination),
        )
        .toList(),
    diuItems: diuItems,
    piuItems: piuItems,
    evidenceItems: evidence,
  );
}

List<String> _markdownCells(String rawLine) {
  final trimmed = rawLine.trim();
  if (!trimmed.startsWith('|') || !trimmed.endsWith('|')) return const [];
  return trimmed
      .substring(1, trimmed.length - 1)
      .split(RegExp(r'(?<!\\)\|'))
      .map((cell) => cell.replaceAll(r'\|', '|').trim())
      .toList(growable: false);
}

bool _isMarkdownHeaderOrSeparator(List<String> cells) {
  if (cells.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell))) {
    return true;
  }
  final first = _normalize(cells.first);
  return first.startsWith('danger /') || first == 'n°' || first == 'no';
}

String _field(String line, String label, {String fallback = ''}) {
  final match = RegExp(
    '${RegExp.escape(label)}\\s*[:：-]\\s*([^|;]+)',
    caseSensitive: false,
  ).firstMatch(line);
  return match?.group(1)?.trim() ?? fallback;
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[àáâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u');

String _itemId(String documentId, String kind, String content) {
  final value = '$documentId|$kind|$content';
  final hash = value.codeUnits.fold<int>(17, (result, unit) {
    return (result * 37 + unit) & 0x7fffffff;
  });
  return '${kind}_$hash';
}
