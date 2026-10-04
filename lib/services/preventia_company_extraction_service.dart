import '../models/preventia_project.dart';
import 'preventia_project_extraction_service.dart';
import 'preventia_risk_extractor.dart';
import 'prevention_dossier_extraction_service.dart';

typedef ExtractionResult = PreventiaProjectExtraction;

ExtractionResult extractFromRiskAssessment({
  required String documentType,
  required String markdown,
  required Map<String, dynamic> formData,
  required String sourceDocumentId,
  String sourceReference = '',
}) {
  final legacy = extractItemsFromRiskAssessment(
    documentType: documentType,
    markdown: markdown,
    formData: formData,
    sourceDocumentId: sourceDocumentId,
  );
  final dossier = PreventionDossierExtractionService()
      .extractFromRiskAssessment(
        documentType: documentType,
        markdown: markdown,
        formData: formData,
        sourceDocumentId: sourceDocumentId,
        sourceReference: sourceReference,
      );
  final pgpActions = dossier.pgpCandidates.map(_actionFromPgp);
  return PreventionProjectExtractionWithDossier(
    riskItems: legacy.riskItems,
    actionItems: _dedupeActions([
      ...legacy.actionItems,
      ...pgpActions,
      ...dossier.priorityActions.map(_actionFromPriority),
    ]),
    paaPgpItems: _dedupeActions([...legacy.paaPgpItems, ...pgpActions]),
    piuItems: _dedupePiu([
      ...legacy.piuItems,
      ...dossier.piuCandidates.map(_piuFromMap),
    ]),
    diuItems: _dedupeDiu([
      ...legacy.diuItems,
      ...dossier.diuCandidates.map(_diuFromMap),
    ]),
    evidenceItems: _dedupeEvidence([
      ...legacy.evidenceItems,
      ...dossier.evidenceItems.map(_evidenceFromMap),
    ]),
    pointsToVerify: dossier.pointsToVerify,
    requiredValidations: dossier.requiredValidations,
  );
}

class PreventionProjectExtractionWithDossier
    extends PreventiaProjectExtraction {
  const PreventionProjectExtractionWithDossier({
    super.riskItems,
    super.actionItems,
    super.paaPgpItems,
    super.diuItems,
    super.piuItems,
    super.evidenceItems,
    this.pointsToVerify = const [],
    this.requiredValidations = const [],
  });

  final List<String> pointsToVerify;
  final List<String> requiredValidations;
}

PreventiaActionItem _actionFromPgp(Map<String, dynamic> item) {
  final now = DateTime.now();
  return PreventiaActionItem(
    id: item['id']?.toString() ?? '',
    sourceDocumentId: item['sourceDocumentId']?.toString() ?? '',
    sourceDocumentType: item['sourceDocumentType']?.toString() ?? '',
    action: item['mainMeasure']?.toString() ?? '',
    priority: item['priority']?.toString() ?? '',
    responsible: item['responsible']?.toString() ?? '',
    deadline: item['deadline']?.toString() ?? '',
    status: item['status']?.toString() ?? 'à valider',
    evidenceExpected: item['expectedEvidence']?.toString() ?? '',
    destination: 'PGP/PAA',
    createdAt: now,
    updatedAt: now,
  );
}

PreventiaActionItem _actionFromPriority(Map<String, dynamic> item) {
  final now = DateTime.now();
  return PreventiaActionItem(
    id: item['id']?.toString() ?? '',
    sourceDocumentId: item['sourceDocumentId']?.toString() ?? '',
    sourceDocumentType: item['sourceDocumentType']?.toString() ?? '',
    action: item['title']?.toString() ?? '',
    priority: '',
    responsible: item['responsible']?.toString() ?? '',
    deadline: item['proposedDeadline']?.toString() ?? '',
    status: item['status']?.toString() ?? 'à valider',
    evidenceExpected: item['expectedEvidence']?.toString() ?? '',
    destination:
        item['destination']?.toString() ?? 'À vérifier avant intégration',
    createdAt: now,
    updatedAt: now,
  );
}

PreventiaPiuItem _piuFromMap(Map<String, dynamic> item) => PreventiaPiuItem(
  id: item['id']?.toString() ?? '',
  sourceDocumentId: item['sourceDocumentId']?.toString() ?? '',
  emergencyTopic: item['title']?.toString() ?? '',
  information: item['scenario']?.toString() ?? '',
  location: '',
  actionRequired: item['procedureToPlan']?.toString() ?? '',
  status: item['status']?.toString() ?? 'à valider',
);

PreventiaDiuItem _diuFromMap(Map<String, dynamic> item) => PreventiaDiuItem(
  id: item['id']?.toString() ?? '',
  sourceDocumentId: item['sourceDocumentId']?.toString() ?? '',
  riskOrConstraint: item['riskOrConstraint']?.toString() ?? '',
  location: item['location']?.toString() ?? '',
  instructionForFutureWork: item['instructionForFutureWork']?.toString() ?? '',
  planOrPhoto: item['planOrPhoto']?.toString() ?? '',
  status: item['status']?.toString() ?? 'à valider',
);

PreventiaEvidenceItem _evidenceFromMap(Map<String, dynamic> item) =>
    PreventiaEvidenceItem(
      id: item['id']?.toString() ?? '',
      sourceDocumentId: item['sourceDocumentId']?.toString() ?? '',
      label: item['label']?.toString() ?? '',
      location: item['location']?.toString() ?? '',
      type: item['type']?.toString() ?? 'preuve',
      status: item['status']?.toString() ?? 'à valider',
    );

List<PreventiaActionItem> _dedupeActions(Iterable<PreventiaActionItem> items) {
  final seen = <String>{};
  return items
      .where((item) => item.action.trim().isNotEmpty)
      .where((item) => seen.add(_normalize(item.action)))
      .take(80)
      .toList(growable: false);
}

List<PreventiaPiuItem> _dedupePiu(Iterable<PreventiaPiuItem> items) {
  final seen = <String>{};
  return items
      .where((item) => item.emergencyTopic.trim().isNotEmpty)
      .where((item) => seen.add(_normalize(item.emergencyTopic)))
      .take(40)
      .toList(growable: false);
}

List<PreventiaDiuItem> _dedupeDiu(Iterable<PreventiaDiuItem> items) {
  final seen = <String>{};
  return items
      .where((item) => item.riskOrConstraint.trim().isNotEmpty)
      .where((item) => seen.add(_normalize(item.riskOrConstraint)))
      .toList(growable: false);
}

List<PreventiaEvidenceItem> _dedupeEvidence(
  Iterable<PreventiaEvidenceItem> items,
) {
  final seen = <String>{};
  return items
      .where((item) => item.label.trim().isNotEmpty)
      .where((item) => seen.add(_normalize(item.label)))
      .toList(growable: false);
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[àáâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u')
    .trim();
