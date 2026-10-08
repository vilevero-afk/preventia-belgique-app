import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/preventia_company_project.dart';
import '../models/preventia_project.dart';
import 'company_piu_candidate_cleanup_service.dart';
import 'local_document_storage.dart';
import 'risk_assessment_assistant_service.dart';
import 'preventia_company_extraction_service.dart';

class PreventiaCompanyUpdateResult {
  const PreventiaCompanyUpdateResult({
    required this.project,
    required this.actionCount,
    required this.piuCount,
    required this.diuCount,
    required this.evidenceCount,
    required this.piuCreated,
    required this.pgaCreated,
  });

  final PreventiaCompanyProject project;
  final int actionCount;
  final int piuCount;
  final int diuCount;
  final int evidenceCount;
  final bool piuCreated;
  final bool pgaCreated;
}

class ReviewClassification {
  const ReviewClassification({
    required this.shouldReview,
    required this.destination,
    required this.reason,
  });

  final bool shouldReview;
  final String destination;
  final String reason;
}

ReviewClassification classifyReviewCandidate(dynamic item) {
  final text = _reviewCandidateText(item);
  final normalized = normalizeCompanyName(text);
  if (normalized.isEmpty) {
    return const ReviewClassification(
      shouldReview: false,
      destination: 'ignoredTechnical',
      reason: 'empty',
    );
  }
  if (_isAlwaysIgnoredReviewCandidate(text)) {
    return const ReviewClassification(
      shouldReview: false,
      destination: 'ignoredTechnical',
      reason: 'technical_or_documentary',
    );
  }
  if (_isAnnexCandidate(normalized)) {
    return const ReviewClassification(
      shouldReview: false,
      destination: 'annex',
      reason: 'annex',
    );
  }
  if (_isValidationPointCandidate(normalized)) {
    return const ReviewClassification(
      shouldReview: true,
      destination: 'validationPoint',
      reason: 'decision_point',
    );
  }
  if (item is PreventiaPiuItem && _isPiuReviewCandidate(normalized)) {
    return const ReviewClassification(
      shouldReview: true,
      destination: 'piu',
      reason: 'emergency_procedure',
    );
  }
  if (item is PreventiaActionItem &&
      _isPgpReviewCandidate(normalizeCompanyName(item.action))) {
    return const ReviewClassification(
      shouldReview: true,
      destination: 'pgp',
      reason: 'prevention_action',
    );
  }
  if (_isEvidenceCandidate(normalized)) {
    final blocking = _hasAny(normalized, const [
      'obligatoire',
      'bloquant',
      'manquant',
      'a reclamer',
      'a obtenir',
      'a prendre',
      'a joindre',
      'a completer',
    ]);
    return ReviewClassification(
      shouldReview: blocking,
      destination: 'evidence',
      reason: blocking ? 'mandatory_evidence' : 'evidence',
    );
  }
  if (_isPgpReviewCandidate(normalized)) {
    return const ReviewClassification(
      shouldReview: true,
      destination: 'pgp',
      reason: 'prevention_action',
    );
  }
  if (_isPiuReviewCandidate(normalized)) {
    return const ReviewClassification(
      shouldReview: true,
      destination: 'piu',
      reason: 'emergency_procedure',
    );
  }
  return const ReviewClassification(
    shouldReview: false,
    destination: 'info',
    reason: 'informative',
  );
}

class PreventiaCompanyProjectService {
  PreventiaCompanyProjectService({SharedPreferences? preferences})
    : _preferences = preferences;

  static const projectsKey = 'preventia_company_projects_v1';
  static const migrationKey = 'preventia_company_history_migrated_v1';
  static const _uuid = Uuid();
  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<List<PreventiaCompanyProject>> getProjects({
    bool migrateLegacy = false,
  }) async {
    if (migrateLegacy) await migrateLegacyHistory();
    final values = (await _prefs).getStringList(projectsKey) ?? const [];
    final projects = <PreventiaCompanyProject>[];
    for (final value in values) {
      try {
        final json = jsonDecode(value);
        if (json is Map) {
          projects.add(
            PreventiaCompanyProject.fromJson(Map<String, dynamic>.from(json)),
          );
        }
      } on Object {
        // Ignore a corrupt local entry without scanning or sending data.
      }
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  Future<PreventiaCompanyProject?> findByKey(String key) async {
    PreventiaCompanyProject? found;
    for (final project in await getProjects(migrateLegacy: false)) {
      if (project.companyKey == key) {
        found = project;
        break;
      }
    }
    if (found != null) {
      final cleanup = CompanyPiuCandidateCleanupService.cleanupProject(found);
      if (cleanup.movedCount > 0) {
        await saveProject(cleanup.project);
        found = cleanup.project;
      }
    }
    if (found != null) {
      _debugReviewCleanup(found);
    }
    debugPrint(
      '[PreventIA] find company project companyKey=$key found=${found != null}',
    );
    return found;
  }

  Future<PreventiaCompanyProject> _getOrCreateCompanyProject(
    String companyName,
  ) async {
    final resolvedName = companyName.trim().isEmpty
        ? 'Société à compléter'
        : companyName.trim();
    final key = normalizeCompanyName(resolvedName);
    final existing = await findByKey(key);
    if (existing != null) return existing;
    final now = DateTime.now();
    final project = PreventiaCompanyProject(
      id: _uuid.v4(),
      companyName: resolvedName,
      companyKey: key,
      createdAt: now,
      updatedAt: now,
    );
    await saveProject(project);
    return project;
  }

  Future<PreventiaCompanyUpdateResult> addRiskAssessment({
    required String documentType,
    required String markdown,
    required Map<String, dynamic> formData,
    String? companyName,
    String? siteName,
    String? reference,
    String source = 'backend',
  }) async {
    final name = companyName?.trim().isNotEmpty == true
        ? companyName!.trim()
        : detectCompanyName(formData, markdown);
    final project = await _getOrCreateCompanyProject(name);
    final resolvedSiteName = siteName?.trim().isNotEmpty == true
        ? siteName!.trim()
        : detectSiteName(formData, markdown);
    final incomingProfile = _profileFromFormData(
      formData,
      companyName: project.companyName,
      siteName: resolvedSiteName,
    );
    final now = DateTime.now();
    final documentId = _stableId(
      'analysis',
      '${reference ?? ''}|$documentType|$markdown',
    );
    final analysis = PreventiaCompanyDocument(
      id: documentId,
      documentType: documentType,
      title: reference?.trim().isNotEmpty == true
          ? '${reference!.trim()} — $documentType'
          : documentType,
      status: 'à compléter et valider',
      createdAt: now,
      autoCreated: false,
      source: source,
      markdown: markdown,
      reference: reference ?? '',
      companyName: project.companyName,
      siteName: resolvedSiteName,
      formData: formData,
    );
    debugPrint(
      '[PreventIA] analysis saved markdownLength=${markdown.length} reference=${reference ?? ''}',
    );
    final piuCreated = project.piuDocument == null;
    final pgaCreated = project.pgaDocument == null;
    final piu =
        project.piuDocument ??
        PreventiaCompanyDocument(
          id: _stableId('piu', project.companyKey),
          documentType: 'Plan Interne d’Urgence',
          title: 'PIU — ${project.companyName}',
          status: 'modèle vierge à compléter',
          createdAt: now,
          autoCreated: true,
          source: 'auto-created-from-risk-assessment',
          companyName: project.companyName,
        );
    final pga =
        project.pgaDocument ??
        PreventiaCompanyDocument(
          id: _stableId('pga', project.companyKey),
          documentType: 'PGA/PAA/PGP',
          title: 'PGA/PAA/PGP — ${project.companyName}',
          status: 'alimenté par les analyses de risques',
          createdAt: now,
          autoCreated: true,
          source: 'auto-created-from-risk-assessment',
          companyName: project.companyName,
        );
    final extraction = extractFromRiskAssessment(
      documentType: documentType,
      markdown: markdown,
      formData: formData,
      sourceDocumentId: documentId,
      sourceReference: reference ?? '',
    );
    final dossierExtraction =
        extraction is PreventionProjectExtractionWithDossier
        ? extraction
        : null;
    final newActions = _prepareNewActionItems(
      extraction.actionItems.isEmpty
          ? [_genericAction(documentId, documentType, reference ?? '', now)]
          : extraction.actionItems,
    );
    final newPiuItems = _prepareNewPiuItems(extraction.piuItems);
    final newEvidenceItems = _prepareNewEvidenceItems(extraction.evidenceItems);
    final projectWithAnalysisForKeys = project.copyWith(
      analyses: _mergeDocuments(project.analyses, [analysis]),
    );
    final updatedBeforeCleanup = project.copyWith(
      updatedAt: now,
      companyProfile: project.companyProfile.merge(incomingProfile),
      sites: _mergeSites(project.sites, resolvedSiteName),
      analyses: _mergeDocuments(project.analyses, [analysis]),
      documents: _mergeDocuments(project.documents, [analysis, piu, pga]),
      piuDocument: piu,
      pgaDocument: pga,
      actionItems: _mergeActionItems(
        projectWithAnalysisForKeys,
        project.actionItems,
        newActions,
      ),
      piuItems: _mergePiuItems(
        projectWithAnalysisForKeys,
        project.piuItems,
        newPiuItems,
      ),
      diuItems: _mergeById(
        project.diuItems,
        extraction.diuItems,
        (item) => item.id,
      ),
      evidenceItems: _mergeEvidenceItems(
        projectWithAnalysisForKeys,
        project.evidenceItems,
        newEvidenceItems,
      ),
      pointsToVerify: _mergeStrings(
        project.pointsToVerify,
        dossierExtraction?.pointsToVerify ?? const [],
      ),
      requiredValidations: _mergeStrings(
        project.requiredValidations,
        dossierExtraction?.requiredValidations ?? const [],
      ),
    );
    final updated = CompanyPiuCandidateCleanupService.cleanupProject(
      updatedBeforeCleanup,
    ).project;
    await saveProject(updated);
    final persisted = await findByKey(updated.companyKey) ?? updated;
    return PreventiaCompanyUpdateResult(
      project: persisted,
      actionCount: extraction.actionItems.isEmpty
          ? 1
          : extraction.actionItems.length,
      piuCount: extraction.piuItems.length,
      diuCount: extraction.diuItems.length,
      evidenceCount: extraction.evidenceItems.length,
      piuCreated: piuCreated,
      pgaCreated: pgaCreated,
    );
  }

  Future<PreventiaCompanyProject> saveAssistedDraft({
    required String subject,
    required String markdown,
    String status = 'Brouillon à valider',
    List<AssistantAction> actions = const [],
    String? companyName,
    String? siteName,
  }) async {
    final project = await _getOrCreateCompanyProject(
      companyName ?? 'Société à compléter',
    );
    final now = DateTime.now();
    final reference =
        'AA-${now.year}-${_uuid.v4().substring(0, 4).toUpperCase()}';
    final document = PreventiaCompanyDocument(
      id: _uuid.v4(),
      documentType: 'Analyse assistée de risques',
      title: 'Analyse assistée — ${subject.trim()}',
      status: status,
      createdAt: now,
      updatedAt: now,
      autoCreated: false,
      source: 'assistant_local',
      isAssistedDraft: status != 'Analyse finale créée',
      markdown: markdown,
      reference: reference,
      companyName: project.companyName,
      siteName: siteName?.trim() ?? '',
      formData: {
        'subject': subject.trim(),
        if (status == 'Analyse finale créée')
          'actions': [
            for (final a in actions.where((a) => a.retained))
              {
                'action': a.action,
                'risk': a.linkedRisk,
                'priority': a.priority,
                'type': a.type,
                'integration': a.integration,
                'status': 'validé',
                'advisorDecision': a.decision!.label,
                'responsible': a.responsible,
                'deadline': a.deadline,
                'evidence': a.finalEvidence,
              },
          ],
      },
    );
    final updated = project.copyWith(
      actionItems: [
        ...project.actionItems,
        if (status == 'Analyse finale créée')
          for (final a in actions.where((a) => a.retained))
            PreventiaActionItem(
              id: _uuid.v4(),
              sourceDocumentId: document.id,
              sourceDocumentType: document.documentType,
              action: a.action,
              priority: a.priority,
              responsible: a.responsible,
              deadline: a.deadline,
              status: 'validé',
              evidenceExpected: a.finalEvidence,
              destination: 'PGA/PAA/PGP',
              createdAt: now,
              updatedAt: now,
            ),
      ],
      updatedAt: now,
      sites: _mergeSites(project.sites, document.siteName),
      analyses: _mergeDocuments(project.analyses, [document]),
      documents: _mergeDocuments(project.documents, [document]),
    );
    await saveProject(updated);
    return await findByKey(updated.companyKey) ?? updated;
  }

  Future<PreventiaCompanyProject> addRiskAssessmentToCompanyProject({
    required String documentType,
    required String markdown,
    required Map<String, dynamic> formData,
    required String reference,
    String? wordPath,
    String? pdfPath,
  }) async {
    final update = await addRiskAssessment(
      documentType: documentType,
      markdown: markdown,
      formData: formData,
      reference: reference,
      source: 'backend',
    );
    var persisted = update.project;
    if (wordPath == null && pdfPath == null) {
      _debugSavedProject(persisted);
      return persisted;
    }
    final analysisId = update.project.analyses
        .firstWhere((item) => item.reference == reference)
        .id;
    PreventiaCompanyDocument withPaths(PreventiaCompanyDocument item) =>
        item.id != analysisId
        ? item
        : PreventiaCompanyDocument(
            id: item.id,
            documentType: item.documentType,
            title: item.title,
            status: item.status,
            createdAt: item.createdAt,
            autoCreated: item.autoCreated,
            source: item.source,
            markdown: item.markdown,
            reference: item.reference,
            companyName: item.companyName,
            siteName: item.siteName,
            formData: item.formData,
            wordPath: wordPath,
            pdfPath: pdfPath,
          );
    final updated = update.project.copyWith(
      analyses: update.project.analyses.map(withPaths).toList(),
      documents: update.project.documents.map(withPaths).toList(),
    );
    await saveProject(updated);
    persisted = await findByKey(updated.companyKey) ?? updated;
    _debugSavedProject(persisted);
    return persisted;
  }

  Future<PreventiaCompanyProject?> deleteAnalysis(
    String companyKey,
    String documentId,
  ) async {
    final project = await findByKey(companyKey);
    if (project == null) return null;
    final updated = project.copyWith(
      analyses: project.analyses
          .where((item) => item.id != documentId)
          .toList(),
      documents: project.documents
          .where((item) => item.id != documentId)
          .toList(),
      actionItems: project.actionItems
          .where((item) => item.sourceDocumentId != documentId)
          .toList(),
      piuItems: project.piuItems
          .where((item) => item.sourceDocumentId != documentId)
          .toList(),
      diuItems: project.diuItems
          .where((item) => item.sourceDocumentId != documentId)
          .toList(),
      evidenceItems: project.evidenceItems
          .where((item) => item.sourceDocumentId != documentId)
          .toList(),
    );
    await saveProject(updated);
    return findByKey(companyKey);
  }

  Future<PreventiaCompanyProject?> updateAnalysisExportPaths({
    required String companyKey,
    required String documentId,
    String? wordPath,
    String? pdfPath,
  }) async {
    final project = await findByKey(companyKey);
    if (project == null) return null;
    PreventiaCompanyDocument update(PreventiaCompanyDocument item) =>
        item.id == documentId
        ? item.copyWith(wordPath: wordPath, pdfPath: pdfPath)
        : item;
    final updated = project.copyWith(
      analyses: project.analyses.map(update).toList(growable: false),
      documents: project.documents.map(update).toList(growable: false),
    );
    await saveProject(updated);
    return findByKey(companyKey);
  }

  Future<PreventiaCompanyProject?> updateGeneratedDocumentExportPaths({
    required String companyKey,
    required String documentId,
    String? wordPath,
    String? pdfPath,
  }) async {
    final project = await findByKey(companyKey);
    if (project == null) return null;
    PreventiaCompanyDocument update(PreventiaCompanyDocument item) =>
        item.id == documentId
        ? item.copyWith(
            markdown: _isPgaDocument(item)
                ? _cleanFinalPgaMarkdown(item.markdown)
                : item.markdown,
            wordPath: wordPath,
            pdfPath: pdfPath,
          )
        : item;
    final updated = project.copyWith(
      documents: project.documents.map(update).toList(growable: false),
      piuDocument: project.piuDocument?.id == documentId
          ? project.piuDocument!.copyWith(wordPath: wordPath, pdfPath: pdfPath)
          : project.piuDocument,
      pgaDocument: project.pgaDocument?.id == documentId
          ? project.pgaDocument!.copyWith(
              markdown: _cleanFinalPgaMarkdown(project.pgaDocument!.markdown),
              wordPath: wordPath,
              pdfPath: pdfPath,
            )
          : project.pgaDocument,
    );
    await saveProject(updated);
    return findByKey(companyKey);
  }

  Future<PreventiaCompanyProject?> updateActionStatus({
    required String companyKey,
    required String itemId,
    required String status,
  }) async {
    final project = await findByKey(companyKey);
    if (project == null) return null;
    final updated = project.copyWith(
      actionItems: project.actionItems
          .map(
            (item) => item.id == itemId ? item.copyWith(status: status) : item,
          )
          .toList(growable: false),
    );
    await saveProject(updated);
    return findByKey(companyKey);
  }

  Future<PreventiaCompanyProject?> updatePiuStatus({
    required String companyKey,
    required String itemId,
    required String status,
  }) async {
    final project = await findByKey(companyKey);
    if (project == null) return null;
    final updated = project.copyWith(
      piuItems: project.piuItems
          .map(
            (item) => item.id == itemId ? item.copyWith(status: status) : item,
          )
          .toList(growable: false),
    );
    await saveProject(updated);
    return findByKey(companyKey);
  }

  Map<String, dynamic> buildPiuGenerationFormData(
    PreventiaCompanyProject project,
  ) {
    final profile = _resolvedProfile(project);
    return {
      ...profile.toJson(),
      'importedPiuItems': project.piuItems
          .where(
            (item) =>
                item.status == 'validé' &&
                classifyReviewCandidate(item).destination == 'piu',
          )
          .map(
            (item) => {
              'title': item.emergencyTopic,
              'description': item.information,
              'sourceDocumentReference': _referenceFor(
                project,
                item.sourceDocumentId,
              ),
              'sourceDocumentType': _documentTypeFor(
                project,
                item.sourceDocumentId,
              ),
              'chapterSuggestion': _piuChapterSuggestion(item.emergencyTopic),
            },
          )
          .toList(growable: false),
      'mode': 'with_validated_items',
      'source': 'company-folder',
    };
  }

  Future<PreventiaCompanyProject?> updateCompanyProfile({
    required String companyKey,
    required PreventiaCompanyProfile profile,
  }) async {
    final project = await findByKey(companyKey);
    if (project == null) return null;
    final updated = project.copyWith(
      companyProfile: project.companyProfile.merge(profile),
      sites: _mergeSites(project.sites, profile.siteName),
    );
    await saveProject(updated);
    return findByKey(companyKey);
  }

  Map<String, dynamic> buildPgaGenerationFormData(
    PreventiaCompanyProject project,
  ) {
    final profile = _resolvedProfile(project);
    final actions = _extractPgpActionsFromProject(project);
    return {
      ...profile.toJson(),
      'companyProfile': profile.toJson(),
      'importedActionItems': actions
          .map(
            (item) => {
              'title': item.action,
              'priority': item.priority,
              'responsible': item.responsible,
              'deadline': item.deadline,
              'evidence': item.evidence,
              'sourceDocumentReference': item.source,
              'risk': item.risk,
              'type': item.type,
              'status': item.status,
            },
          )
          .toList(growable: false),
      'mode': 'with_validated_actions',
      'source': 'company-folder',
    };
  }

  Future<PreventiaCompanyProject?> generatePiuDocument({
    required String companyKey,
    required bool withValidatedItems,
    String? markdown,
    Map<String, dynamic>? formData,
    String source = 'company-folder',
  }) async {
    final project = await findByKey(companyKey);
    if (project == null) return null;
    final now = DateTime.now();
    final validated = withValidatedItems
        ? project.piuItems
              .where(
                (item) =>
                    item.status == 'validé' &&
                    classifyReviewCandidate(item).destination == 'piu',
              )
              .toList()
        : const <PreventiaPiuItem>[];
    final resolvedFormData =
        formData ??
        (withValidatedItems
            ? buildPiuGenerationFormData(project)
            : _blankPiuFormData(project));
    final resolvedMarkdown = markdown?.trim().isNotEmpty == true
        ? markdown!.trim()
        : _piuMarkdown(project, validated);
    final document = PreventiaCompanyDocument(
      id: _uuid.v4(),
      documentType: 'Plan Interne d’Urgence',
      title: 'PIU — ${project.companyName}',
      status: 'généré',
      createdAt: now,
      autoCreated: false,
      source: source,
      markdown: resolvedMarkdown,
      reference: 'PIU-${now.millisecondsSinceEpoch}',
      companyName: project.companyName,
      siteName: resolvedFormData['siteName']?.toString() ?? '',
      formData: resolvedFormData,
    );
    final updated = project.copyWith(
      piuDocument: document,
      documents: _mergeDocuments(project.documents, [document]),
    );
    await saveProject(updated);
    return findByKey(companyKey);
  }

  Future<PreventiaCompanyProject?> generatePgaDocument({
    required String companyKey,
    required bool withValidatedActions,
    String? markdown,
    Map<String, dynamic>? formData,
    String source = 'company-folder',
  }) async {
    final project = await findByKey(companyKey);
    if (project == null) return null;
    final now = DateTime.now();
    final actions = withValidatedActions
        ? _extractPgpActionsFromProject(project)
        : const <_CleanPgpAction>[];
    final resolvedFormData =
        formData ??
        (withValidatedActions
            ? buildPgaGenerationFormData(project)
            : _blankPgaFormData(project));
    final constructedMarkdown = _trimPgaAfterSignatures(
      markdown?.trim().isNotEmpty == true
          ? markdown!.trim()
          : _pgaMarkdown(project, actions),
    );
    final resolvedMarkdown = _trimPgaAfterSignatures(
      _cleanFinalPgaMarkdown(constructedMarkdown),
    );
    final document = PreventiaCompanyDocument(
      id: _uuid.v4(),
      documentType: 'PGA/PAA/PGP',
      title: 'PGA/PAA/PGP — ${project.companyName}',
      status: 'généré',
      createdAt: now,
      autoCreated: false,
      source: source,
      markdown: resolvedMarkdown,
      reference: 'PGA-${now.millisecondsSinceEpoch}',
      companyName: project.companyName,
      siteName: resolvedFormData['siteName']?.toString() ?? '',
      formData: resolvedFormData,
    );
    final updated = project.copyWith(
      pgaDocument: document,
      documents: _mergeDocuments(project.documents, [document]),
    );
    await saveProject(updated);
    return findByKey(companyKey);
  }

  Future<void> saveProject(PreventiaCompanyProject project) async {
    final preferences = await _prefs;
    final projects = await getProjects(migrateLegacy: false);
    final index = projects.indexWhere(
      (item) => item.companyKey == project.companyKey,
    );
    final value = project.copyWith(updatedAt: DateTime.now());
    if (index < 0) {
      projects.add(value);
    } else {
      projects[index] = value;
    }
    await preferences.setStringList(
      projectsKey,
      projects.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> deleteProjectFromHistory(String companyKey) async {
    debugPrint('[PreventIA] delete company project companyKey=$companyKey');
    final preferences = await _prefs;
    final projects = await getProjects(migrateLegacy: false);
    await preferences.setStringList(
      projectsKey,
      projects
          .where((project) => project.companyKey != companyKey)
          .map((project) => jsonEncode(project.toJson()))
          .toList(),
    );
  }

  Future<void> setLocalFolder(
    PreventiaCompanyProject project,
    String folderPath,
  ) => saveProject(project.copyWith(localFolderPath: folderPath));

  Future<void> migrateLegacyHistory() async {
    final preferences = await _prefs;
    if (preferences.getBool(migrationKey) == true) {
      return;
    }
    final legacy = await LocalDocumentStorage().loadDocuments();
    for (final document in legacy.where((item) => !item.isActionSummary)) {
      final company = detectCompanyName(const {}, document.content);
      if (company == 'Société à compléter' &&
          !_looksLikeRiskAssessment(document.documentType)) {
        continue;
      }
      await addRiskAssessment(
        documentType: document.documentType,
        markdown: document.content,
        formData: const {},
        companyName: company,
        reference: _referenceFromText('${document.title}\n${document.content}'),
        source: document.sourceLabel ?? 'legacy-local-history',
      );
    }
    await preferences.setBool(migrationKey, true);
  }

  Future<void> repairEmptyProjectsFromLegacyHistory() async {
    final emptyByKey = {
      for (final project in await getProjects(migrateLegacy: false))
        if (project.analyses.isEmpty) project.companyKey: project,
    };
    if (emptyByKey.isEmpty) return;
    for (final document in await LocalDocumentStorage().loadDocuments()) {
      if (document.isActionSummary ||
          !_looksLikeRiskAssessment(document.documentType)) {
        continue;
      }
      final companyName = detectCompanyName(const {}, document.content);
      final key = normalizeCompanyName(companyName);
      final emptyProject = emptyByKey[key];
      if (emptyProject == null) continue;
      await addRiskAssessment(
        documentType: document.documentType,
        markdown: document.content,
        formData: {'companyName': emptyProject.companyName},
        reference: _referenceFromText('${document.title}\n${document.content}'),
        source: document.sourceLabel ?? 'legacy-local-history',
      );
    }
  }
}

String _referenceFor(PreventiaCompanyProject project, String sourceDocumentId) {
  return project.analyses
      .firstWhere(
        (item) => item.id == sourceDocumentId,
        orElse: () => PreventiaCompanyDocument(
          id: sourceDocumentId,
          documentType: '',
          title: '',
          status: '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          autoCreated: false,
          source: '',
        ),
      )
      .reference;
}

String _reviewCandidateText(dynamic item) {
  if (item is PreventiaActionItem) {
    return [
      item.action,
      item.priority,
      item.responsible,
      item.deadline,
      item.evidenceExpected,
      item.destination,
    ].where((value) => value.trim().isNotEmpty).join('\n');
  }
  if (item is PreventiaPiuItem) {
    return [
          item.emergencyTopic,
          item.information,
          item.location,
          item.actionRequired,
        ]
        .map((value) => value.replaceAll('|', '\n'))
        .where((value) => value.trim().isNotEmpty)
        .join('\n');
  }
  if (item is PreventiaEvidenceItem) {
    return [
      item.label,
      item.location,
      item.type,
    ].where((value) => value.trim().isNotEmpty).join('\n');
  }
  return item?.toString() ?? '';
}

bool _isAlwaysIgnoredReviewCandidate(String text) {
  final trimmed = text.trim();
  final normalized = normalizeCompanyName(trimmed);
  if (RegExp(
    r'^\s*page\s+\d+\s*/\s*\d+\s*$',
    caseSensitive: false,
  ).hasMatch(trimmed)) {
    return true;
  }
  if (RegExp(r'^\s*#{0,3}\s*\d{1,2}\.\s*[^.\n]{3,80}\s*$').hasMatch(trimmed) &&
      !_hasAny(normalized, const [
        'point de rassemblement',
        'accueil secours',
        'acces pompiers',
      ])) {
    return true;
  }
  if ('|'.allMatches(trimmed).length >= 6) return true;
  const ignoredFragments = [
    'additionalinformation',
    'documenttype',
    'activity',
    'concernedtasks',
    'includedlocations',
    'exposedworkers',
    'documentobjective',
    'firerisk',
    'sector',
    'visitdate',
    'youngworkers',
    'safetydatasheetsavailable',
    'jobobservationdone',
    'vehiclepedestriantraffic',
    'dangerousmachines',
    'dangerousproducts',
    'writteninstructions',
    'periodiccontrols',
    'availableevidence',
    'famille de danger',
    'danger precis',
    'scenario plausible',
    'reference ou domaine reglementaire',
    'livre ier',
    'livre iii',
    'livre ix',
    'code belge du bien etre',
    'methode de cotation',
    'tableau principal d analyse',
    'analyse des risques residuels',
    'conclusion',
    'mention de validation',
    'paa seul',
    'pgp seul',
    'cppt seul',
  ];
  if (ignoredFragments.any(normalized.contains)) return true;
  if (normalized == 'paa' || normalized == 'pgp' || normalized == 'cppt') {
    return true;
  }
  const tableHeaders = [
    'numero mesure complementaire',
    'risque concerne action a realiser responsable echeance preuve attendue',
    'activite ou tache danger situation dangereuse risque personnes exposees',
    'objectif risque vise mesure principale type priorite responsable propose',
  ];
  return tableHeaders.any(normalized.contains);
}

bool _isAnnexCandidate(String normalized) {
  return _hasAny(normalized, const [
    'annexe',
    'a annexer',
    'document a joindre en annexe',
  ]);
}

bool _isValidationPointCandidate(String normalized) {
  return _hasAny(normalized, const [
    'avis cppt a confirmer',
    'avis service externe',
    'avis expert',
    'validation employeur',
    'visite terrain requise',
    'preuve manquante bloquante',
    'responsabilite a confirmer',
    'delai a confirmer',
    'responsable a confirmer',
    'point bloquant',
    'bloquant a confirmer',
  ]);
}

bool _isPiuReviewCandidate(String normalized) {
  return _hasAny(normalized, const [
    'alerte incendie',
    'evacuation',
    'point de rassemblement',
    'accueil secours',
    'acces pompiers',
    'acces pompier',
    'mise a l abri',
    'accident',
    'malaise',
    'fuite gaz',
    'fuite de gaz',
    'deversement dangereux',
    'confinement',
    'urgence operationnelle',
    'personne bloquee',
    'appel urgence cabine',
    'appel d urgence cabine',
    'procedure de secours ascenseur',
    'coupure electrique d urgence',
    'coupure generale tgbt',
    'coupure courant',
    'delestage',
    'acces local technique',
    'acces tgbt',
    'tgbt pour les secours',
    'danger electrique en intervention',
    'dossier pompiers',
    'plans des coupures',
  ]);
}

bool _isPgpReviewCandidate(String normalized) {
  return _hasAny(normalized, const [
    'verifier',
    'controler',
    'planifier',
    'formaliser',
    'mettre a jour',
    'obtenir',
    'centraliser',
    'degager',
    'rendre accessible',
    'rendre les moyens',
    'rendre les equipements accessibles',
    'rendre les equipements visibles',
    'supprimer',
    'sensibiliser',
    'former',
    'informer',
    'organiser',
    'corriger',
    'tester',
    'adapter',
    'lever',
    'securiser',
    'signaler',
  ]);
}

bool _isEvidenceCandidate(String normalized) {
  if ((normalized.contains('rapport') && normalized.contains('a obtenir')) ||
      (normalized.contains('photo') && normalized.contains('a prendre')) ||
      (normalized.contains('fds') && normalized.contains('a obtenir')) ||
      (normalized.contains('plan') && normalized.contains('a joindre')) ||
      (normalized.contains('registre') && normalized.contains('a completer')) ||
      (normalized.contains('attestation') &&
          normalized.contains('a obtenir'))) {
    return true;
  }
  return _hasAny(normalized, const [
    'rapport a obtenir',
    'rapport extincteurs a obtenir',
    'photo a prendre',
    'fds a obtenir',
    'plan a joindre',
    'registre a completer',
    'attestation a obtenir',
    'preuve obligatoire',
    'preuve a reclamer',
  ]);
}

bool _hasAny(String normalized, List<String> fragments) {
  return fragments.any(normalized.contains);
}

void _debugReviewCleanup(PreventiaCompanyProject project) {
  var hidden = 0;
  var redirected = 0;
  for (final item in project.piuItems) {
    final classification = classifyReviewCandidate(item);
    if (normalizeCompanyName(item.status) == 'a valider' &&
        !classification.shouldReview) {
      hidden++;
    }
    if (classification.destination != 'piu' &&
        classification.destination != 'ignoredTechnical' &&
        classification.destination != 'info') {
      redirected++;
    }
  }
  for (final item in project.actionItems) {
    final classification = classifyReviewCandidate(item);
    if (normalizeCompanyName(item.status) == 'a valider' &&
        !classification.shouldReview) {
      hidden++;
    }
    if (classification.destination != 'pgp' &&
        classification.destination != 'ignoredTechnical' &&
        classification.destination != 'info') {
      redirected++;
    }
  }
  for (final item in project.evidenceItems) {
    final classification = classifyReviewCandidate(item);
    if (normalizeCompanyName(item.status) == 'a valider' &&
        !classification.shouldReview) {
      hidden++;
    }
    if (classification.destination != 'evidence' &&
        classification.destination != 'ignoredTechnical' &&
        classification.destination != 'info') {
      redirected++;
    }
  }
  for (final item in [
    ...project.pointsToVerify,
    ...project.requiredValidations,
  ]) {
    final classification = classifyReviewCandidate(item);
    if (!classification.shouldReview) hidden++;
    if (classification.destination != 'validationPoint' &&
        classification.destination != 'ignoredTechnical' &&
        classification.destination != 'info') {
      redirected++;
    }
  }
  if (hidden > 0 || redirected > 0) {
    debugPrint(
      '[PreventIA] review cleanup: hidden=$hidden redirected=$redirected companyKey=${project.companyKey}',
    );
  }
}

String _documentTypeFor(
  PreventiaCompanyProject project,
  String sourceDocumentId,
) {
  return project.analyses
      .firstWhere(
        (item) => item.id == sourceDocumentId,
        orElse: () => PreventiaCompanyDocument(
          id: sourceDocumentId,
          documentType: '',
          title: '',
          status: '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          autoCreated: false,
          source: '',
        ),
      )
      .documentType;
}

String _primarySite(PreventiaCompanyProject project) {
  if (project.companyProfile.siteName.trim().isNotEmpty) {
    return project.companyProfile.siteName.trim();
  }
  if (project.sites.isNotEmpty) return project.sites.first.name;
  for (final analysis in project.analyses) {
    if (analysis.siteName.trim().isNotEmpty) return analysis.siteName.trim();
  }
  return '';
}

PreventiaCompanyProfile _resolvedProfile(PreventiaCompanyProject project) {
  return const PreventiaCompanyProfile().merge(
    project.companyProfile.merge(
      PreventiaCompanyProfile(
        companyName: project.companyName,
        siteName: _primarySite(project),
      ),
    ),
  );
}

PreventiaCompanyProfile _profileFromFormData(
  Map<String, dynamic> formData, {
  required String companyName,
  required String siteName,
}) {
  String value(List<String> keys, [String fallback = '']) {
    for (final key in keys) {
      final raw = formData[key]?.toString().trim() ?? '';
      if (raw.isNotEmpty) return raw;
    }
    return fallback;
  }

  return PreventiaCompanyProfile(
    companyName: value(const ['companyName', 'enterpriseName'], companyName),
    siteName: value(const [
      'siteName',
      'siteConcerned',
      'buildingName',
    ], siteName),
    address: value(const ['address', 'siteAddress', 'elevatorAddress']),
    postalCode: value(const ['postalCode']),
    city: value(const ['city']),
    country: value(const ['country'], 'Belgique'),
    siteContact: value(const ['siteContact', 'contactPerson']),
    preventionAdvisor: value(const [
      'preventionAdvisor',
      'author',
      'preparedBy',
    ]),
    siteManager: value(const ['siteManager', 'manager']),
    technicalServiceContact: value(const [
      'technicalServiceContact',
      'maintenanceCompany',
    ]),
    generalPhone: value(const ['generalPhone', 'phone']),
    generalEmail: value(const ['generalEmail', 'email']),
    activityDescription: value(const [
      'activityDescription',
      'activity',
      'activityType',
    ]),
    riskProfile: value(const ['riskProfile']),
    numberOfWorkers: value(const ['numberOfWorkers', 'workerCount']),
    visitorsPresence: value(const ['visitorsPresence', 'visitors']),
    externalCompaniesPresence: value(const [
      'externalCompaniesPresence',
      'externalCompanies',
    ]),
    workingHours: value(const ['workingHours', 'openingHours']),
  );
}

Map<String, dynamic> _blankPiuFormData(PreventiaCompanyProject project) {
  final profile = _resolvedProfile(project);
  return {
    ...profile.toJson(),
    'mode': 'blank',
    'source': 'company-folder',
    'importedPiuItems': const [],
  };
}

Map<String, dynamic> _blankPgaFormData(PreventiaCompanyProject project) {
  final profile = _resolvedProfile(project);
  return {
    ...profile.toJson(),
    'companyProfile': profile.toJson(),
    'mode': 'blank',
    'source': 'company-folder',
    'importedActionItems': const [],
  };
}

String _piuChapterSuggestion(String value) {
  final normalized = normalizeCompanyName(value);
  if (normalized.contains('personne bloquee') ||
      normalized.contains('appel urgence cabine') ||
      normalized.contains('appel d urgence cabine') ||
      normalized.contains('ascenseur')) {
    return 'Ascenseurs et personnes bloquées';
  }
  if (normalized.contains('coupure electrique') ||
      normalized.contains('coupure courant') ||
      normalized.contains('delestage') ||
      normalized.contains('tgbt') ||
      normalized.contains('cabine ht') ||
      normalized.contains('danger electrique') ||
      normalized.contains('plans des coupures')) {
    return 'Coupures techniques et dossier pompiers';
  }
  if (normalized.contains('incend') || normalized.contains('evac')) {
    return 'Incendie et évacuation';
  }
  return 'Informations issues des analyses de risques';
}

String _piuMarkdown(
  PreventiaCompanyProject project,
  List<PreventiaPiuItem> validated,
) {
  final profile = _resolvedProfile(project);
  final piuItems = _dedupePiuDocumentItems(validated);
  final body = piuItems.isEmpty
      ? 'Aucun élément PIU validé issu des analyses de risques n’est encore intégré.'
      : piuItems
            .map(
              (item) =>
                  '- **${item.emergencyTopic}**  \n'
                  '  Description : ${item.information}  \n'
                  '  Source : ${_documentTypeFor(project, item.sourceDocumentId)} ${_referenceFor(project, item.sourceDocumentId)}  \n'
                  '  Chapitre suggéré : ${_piuChapterSuggestion(item.emergencyTopic)}',
            )
            .join('\n');
  final chapters = List.generate(
    28,
    (index) => '${index + 1}. ${_piuChapterTitle(index + 1)}',
  ).join('\n');
  final reflexSheets = List.generate(
    23,
    (index) =>
        '### FICHE ${index.toString().padLeft(2, '0')}\n'
        'Objectif, consignes immédiates, responsable, moyens disponibles et validation.\n',
  ).join('\n');
  return '# Plan Interne d’Urgence — ${project.companyName}\n\n'
      'Modèle opérationnel à compléter.\n\n'
      '## 1. Identification\n\n'
      'Entreprise : ${profile.companyName}\n\n'
      'Dénomination du bâtiment : ${profile.siteName.isEmpty ? '[à compléter]' : profile.siteName}\n\n'
      'Adresse complète : ${profile.address.isEmpty ? '[à compléter]' : '${profile.address}, ${profile.postalCode} ${profile.city}, ${profile.country}'}\n\n'
      'Téléphone : ${profile.generalPhone.isEmpty ? '[à compléter]' : profile.generalPhone}\n\n'
      'E-mail : ${profile.generalEmail.isEmpty ? '[à compléter]' : profile.generalEmail}\n\n'
      'Activité du site : ${profile.activityDescription.isEmpty ? '[à compléter]' : profile.activityDescription}\n\n'
      'Conseiller en prévention : ${profile.preventionAdvisor.isEmpty ? '[à compléter]' : profile.preventionAdvisor}\n\n'
      'Personne responsable du bâtiment : ${profile.siteManager.isEmpty ? '[à compléter]' : profile.siteManager}\n\n'
      'Service technique : ${profile.technicalServiceContact.isEmpty ? '[à compléter]' : profile.technicalServiceContact}\n\n'
      'Visiteurs : ${profile.visitorsPresence.isEmpty ? '[à compléter]' : profile.visitorsPresence}\n\n'
      'Entreprises extérieures : ${profile.externalCompaniesPresence.isEmpty ? '[à compléter]' : profile.externalCompaniesPresence}\n\n'
      'Horaires : ${profile.workingHours.isEmpty ? '[à compléter]' : profile.workingHours}\n\n'
      '## 2. Les 28 chapitres du PIU\n\n'
      '$chapters\n\n'
      '## 3. Informations issues des analyses de risques\n\n'
      '$body\n\n'
      '## 4. Fiches réflexes 00 à 22\n\n'
      '$reflexSheets\n'
      '## 5. Dossier pour les pompiers\n\n'
      'Informations d’accès, personnes de contact, risques particuliers et moyens disponibles.\n\n'
      '## 6. Plans\n\n'
      'Plans d’accès, plans d’évacuation, localisation des coupures techniques et zones sensibles.\n\n'
      '## 7. Mise à l’abri\n\n'
      'Procédure de mise à l’abri, locaux utilisables, communication interne et suivi des personnes.\n\n'
      '## 8. Prise d’iode\n\n'
      'Conditions d’application, autorité compétente, stock éventuel et traçabilité.\n\n'
      '## 9. Attestation de réception des consignes\n\n'
      'Nom, fonction, date, signature et confirmation de prise de connaissance.\n\n'
      '## 10. Signatures\n\n'
      'Direction, conseiller en prévention, responsables opérationnels et validation CPPT le cas échéant.\n';
}

List<PreventiaPiuItem> _dedupePiuDocumentItems(List<PreventiaPiuItem> items) {
  final result = <PreventiaPiuItem>[];
  final seen = <String>{};
  for (final item in items) {
    final key = _dedupePgpKey('${item.emergencyTopic} ${item.actionRequired}');
    if (seen.add(key)) result.add(item);
  }
  return result;
}

String _pgaMarkdown(
  PreventiaCompanyProject project,
  List<_CleanPgpAction> actions,
) {
  final profile = _resolvedProfile(project);
  final rows = actions.isEmpty
      ? '| | | | Aucune action validée n’est encore intégrée au PGA/PAA/PGP. | | | | | | |'
      : actions
            .asMap()
            .entries
            .map((entry) {
              final item = entry.value;
              return '| ${entry.key + 1} | ${_pgpCell(item.source)} | '
                  '${_pgpCell(item.risk)} | ${_pgpCell(item.action)} | '
                  '${_pgpCell(item.type)} | ${_pgpCell(item.priority)} | '
                  '${_pgpCell(item.responsible)} | ${_pgpCell(item.deadline)} | '
                  '${_pgpCell(item.evidence)} | ${_pgpCell(item.status)} |';
            })
            .join('\n');
  final shortTerm = actions
      .where(_isShortTermPgpAction)
      .map((item) => '- ${item.action} (${item.priority}, ${item.deadline})')
      .join('\n');
  final evidence = _extractPgpEvidenceItems(project, actions);
  final validationPoints = _extractPgpValidationPoints(project, actions);
  return '# PGA / PAA / PGP — ${profile.companyName}\n\n'
      'Statut : Document de travail à compléter et valider\n\n'
      '## 1. Identification\n\n'
      'Entreprise : ${profile.companyName}\n\n'
      'Site : ${profile.siteName.isEmpty ? '[à compléter]' : profile.siteName}\n\n'
      'Adresse : ${profile.address.isEmpty ? '[à compléter]' : '${profile.address}, ${profile.postalCode} ${profile.city}, ${profile.country}'}\n\n'
      'Conseiller en prévention : ${profile.preventionAdvisor.isEmpty ? '[à compléter]' : profile.preventionAdvisor}\n\n'
      'Responsable site : ${profile.siteManager.isEmpty ? '[à compléter]' : profile.siteManager}\n\n'
      'Activité : ${profile.activityDescription.isEmpty ? '[à compléter]' : profile.activityDescription}\n\n'
      'Nombre de travailleurs : ${profile.numberOfWorkers.isEmpty ? '[à compléter]' : profile.numberOfWorkers}\n\n'
      '## 2. Objectif du document\n\n'
      'Organiser le suivi des actions de prévention issues des analyses de risques.\n\n'
      '## 3. Sources utilisées\n\n'
      '${project.analyses.map((item) => '- ${item.reference} — ${item.documentType}').join('\n')}\n\n'
      '## 4. Synthèse des actions retenues\n\n'
      '| N° | Source | Risque visé | Action à réaliser | Type | Priorité | Responsable | Délai proposé | Preuve attendue | Statut |\n'
      '|---|---|---|---|---|---|---|---|---|---|\n'
      '$rows\n\n'
      '## 5. Plan Annuel d’Action — court terme\n\n'
      '${shortTerm.isEmpty ? 'À compléter après validation des priorités.' : shortTerm}\n\n'
      '## 6. Plan Global de Prévention — pluriannuel\n\n'
      'Année 1 : actions urgentes et conformité immédiate.\n\n'
      'Année 2 : consolidation organisationnelle.\n\n'
      'Année 3 : formation / exercices / suivi.\n\n'
      'Année 4 : amélioration documentaire.\n\n'
      'Année 5 : révision et amélioration continue.\n\n'
      '## 7. Preuves à obtenir\n\n'
      '${evidence.isEmpty ? '- À compléter.' : evidence.map((item) => '- $item').join('\n')}\n\n'
      '## 8. Points à vérifier avant validation\n\n'
      '${validationPoints.isEmpty ? '- À compléter.' : validationPoints.map((item) => '- $item').join('\n')}\n\n'
      '## 9. Suivi et validation\n\nÀ compléter.\n\n'
      '## 10. Signatures\n\nDirection, conseiller en prévention et validation CPPT le cas échéant.\n';
}

class _CleanPgpAction {
  const _CleanPgpAction({
    required this.source,
    required this.risk,
    required this.action,
    required this.type,
    required this.priority,
    required this.responsible,
    required this.deadline,
    required this.evidence,
    required this.status,
  });

  final String source;
  final String risk;
  final String action;
  final String type;
  final String priority;
  final String responsible;
  final String deadline;
  final String evidence;
  final String status;
}

List<_CleanPgpAction> _cleanPgpActions(
  PreventiaCompanyProject project,
  List<PreventiaActionItem> items,
) {
  final byAction = <String, _CleanPgpAction>{};
  for (final item in items) {
    // Structured assisted actions below carry the final risk and type.
    if (project.analyses.any(
      (d) => d.id == item.sourceDocumentId && d.source == 'assistant_local',
    )) {
      continue;
    }
    if (classifyReviewCandidate(item).destination != 'pgp') continue;
    if (!_isValidPgpActionText(item.action)) continue;
    final action = _cleanConcretePgpAction(item.action);
    if (action.isEmpty || !_isValidPgpActionText(action)) continue;
    final clean = _CleanPgpAction(
      source: _fallback(
        _referenceFor(project, item.sourceDocumentId),
        _fallback(item.sourceDocumentType, 'Analyse de risques'),
      ),
      risk: _pgpRisk(item),
      action: action,
      type: _pgpActionType(item),
      priority: _fallback(item.priority, 'À planifier'),
      responsible: _fallback(item.responsible, '[à compléter]'),
      deadline: _fallback(item.deadline, '[à planifier]'),
      evidence: _fallback(item.evidenceExpected, '[à compléter]'),
      status: _fallback(item.status, 'à valider'),
    );
    final key = _dedupePgpKey(clean.action);
    final existing = byAction[key];
    if (existing == null) {
      byAction[key] = clean;
      continue;
    }
    byAction[key] = _mergePgpAction(existing, clean);
  }
  final result = byAction.values.toList()
    ..sort((a, b) {
      final priority = _pgpPriorityScore(a).compareTo(_pgpPriorityScore(b));
      if (priority != 0) return priority;
      return a.action.length.compareTo(b.action.length);
    });
  return result.take(50).toList(growable: false);
}

List<_CleanPgpAction> _extractPgpActionsFromProject(
  PreventiaCompanyProject project,
) {
  final byActionAndRisk = <String, _CleanPgpAction>{};

  void add(_CleanPgpAction action, {bool advisorValidated = false}) {
    if (!_isValidatedStatus(action.status)) return;
    if (advisorValidated
        ? action.action.trim().isEmpty
        : !_isValidPgpActionText(action.action)) {
      return;
    }
    final cleaned = _CleanPgpAction(
      source: _fallback(action.source, 'Analyse de risques'),
      risk: _fallback(action.risk, 'Risque à préciser'),
      action: advisorValidated
          ? action.action.trim()
          : _cleanConcretePgpAction(action.action),
      type: _fallback(action.type, 'Action de prévention'),
      priority: _fallback(action.priority, 'À planifier'),
      responsible: _fallback(action.responsible, '[à compléter]'),
      deadline: _fallback(action.deadline, '[à planifier]'),
      evidence: _fallback(action.evidence, '[à compléter]'),
      status: 'validé',
    );
    if (!advisorValidated && !_isValidPgpActionText(cleaned.action)) return;
    final key =
        '${_dedupePgpKey(cleaned.action)}|${_dedupePgpKey(cleaned.risk)}';
    final existing = byActionAndRisk[key];
    if (existing == null) {
      byActionAndRisk[key] = cleaned;
      return;
    }
    byActionAndRisk[key] = _mergePgpAction(existing, cleaned);
  }

  for (final action in _cleanPgpActions(
    project,
    project.actionItems
        .where(
          (item) =>
              _isValidatedStatus(item.status) &&
              classifyReviewCandidate(item).destination == 'pgp',
        )
        .toList(growable: false),
  )) {
    add(action);
  }

  for (final document in _analysisDocuments(project)) {
    for (final action in _extractPgpActionsFromAnalysis(document)) {
      add(action);
    }
    for (final action in _extractPgpActionsFromFormData(document)) {
      add(
        action,
        advisorValidated:
            document.source == 'assistant_local' &&
            document.status == 'Analyse finale créée',
      );
    }
  }

  final result = byActionAndRisk.values.toList()
    ..sort((a, b) {
      final priority = _pgpPriorityScore(a).compareTo(_pgpPriorityScore(b));
      if (priority != 0) return priority;
      final risk = a.risk.compareTo(b.risk);
      if (risk != 0) return risk;
      return a.action.compareTo(b.action);
    });
  return result.take(80).toList(growable: false);
}

List<PreventiaCompanyDocument> _analysisDocuments(
  PreventiaCompanyProject project,
) {
  final byId = <String, PreventiaCompanyDocument>{};
  void add(PreventiaCompanyDocument document) {
    final type = normalizeCompanyName(document.documentType);
    final title = normalizeCompanyName(document.title);
    final isAssistedFinal =
        document.source == 'assistant_local' &&
        document.status == 'Analyse finale créée';
    if (!isAssistedFinal &&
        !type.contains('analyse de risques') &&
        !title.contains('analyse de risques')) {
      return;
    }
    byId[document.id] = document;
  }

  for (final document in project.analyses) {
    add(document);
  }
  for (final document in project.documents) {
    add(document);
  }
  return byId.values.toList(growable: false);
}

List<_CleanPgpAction> _extractPgpActionsFromAnalysis(
  PreventiaCompanyDocument document,
) {
  // Assisted assessments contribute only the actions explicitly retained by the advisor.
  if (document.source == 'assistant_local') return [];
  final normalizedLabel = normalizeCompanyName(
    '${document.documentType} ${document.title}',
  );
  final normalizedContent = normalizeCompanyName(document.markdown);
  final normalizedType = '$normalizedLabel $normalizedContent';
  final source = _documentSourceLabel(document);
  final actions = <_CleanPgpAction>[];

  void addAll(String risk, List<_PgpActionTemplate> templates) {
    for (final template in templates) {
      actions.add(
        _CleanPgpAction(
          source: source,
          risk: risk,
          action: template.action,
          type: template.type,
          priority: 'Court terme',
          responsible: '[à compléter]',
          deadline: '1 à 3 mois',
          evidence: template.evidence,
          status: 'validé',
        ),
      );
    }
  }

  if (_matchesFireEvacuationAnalysis(normalizedType, label: normalizedLabel)) {
    addAll('Incendie / évacuation', _fireEvacuationPgpActions);
  }
  if (_matchesElectricalAnalysis(normalizedType)) {
    addAll('Installations électriques BT/HT', _electricalPgpActions);
  }
  if (_matchesElevatorAnalysis(normalizedType)) {
    addAll('Ascenseur', _elevatorPgpActions);
  }
  if (_matchesErgonomicsAnalysis(normalizedType)) {
    addAll('Ergonomie', _ergonomicsPgpActions);
  }
  if (_matchesDangerousProductsAnalysis(normalizedType)) {
    addAll('Produits dangereux', _dangerousProductsPgpActions);
  }

  return actions;
}

List<_CleanPgpAction> _extractPgpActionsFromFormData(
  PreventiaCompanyDocument document,
) {
  final source = _documentSourceLabel(document);
  final fallbackRisk = _riskFromDocument(document);
  final actions = <_CleanPgpAction>[];

  void visit(Object? value) {
    if (value is List) {
      for (final item in value) {
        visit(item);
      }
      return;
    }
    if (value is! Map) return;
    final map = Map<String, dynamic>.from(value);
    final action = _firstNonEmpty(map, const [
      'action',
      'title',
      'actionRequired',
      'measure',
      'measureToTake',
      'preventiveAction',
    ]);
    if (action.isNotEmpty) {
      final status = _firstNonEmpty(map, const ['status', 'validationStatus']);
      actions.add(
        _CleanPgpAction(
          source: source,
          risk: _fallback(
            _firstNonEmpty(map, const ['risk', 'riskType', 'danger']),
            fallbackRisk,
          ),
          action: action,
          type: _fallback(
            _firstNonEmpty(map, const ['type', 'category']),
            'Action de prévention',
          ),
          priority: _fallback(
            _firstNonEmpty(map, const ['priority', 'priorite']),
            'À planifier',
          ),
          responsible: _fallback(
            _firstNonEmpty(map, const ['responsible', 'responsable']),
            '[à compléter]',
          ),
          deadline: _fallback(
            _firstNonEmpty(map, const ['deadline', 'echeance']),
            '[à planifier]',
          ),
          evidence: _fallback(
            _firstNonEmpty(map, const ['evidence', 'evidenceExpected']),
            '[à compléter]',
          ),
          status: status.isEmpty ? 'validé' : status,
        ),
      );
    }
    for (final entry in map.entries) {
      if (_isPgpActionContainerKey(entry.key.toString())) {
        visit(entry.value);
      }
    }
  }

  visit(document.formData['importedActionItems']);
  visit(document.formData['actionItems']);
  visit(document.formData['pgaItems']);
  visit(document.formData['actions']);
  return actions;
}

bool _isPgpActionContainerKey(String key) {
  final normalized = normalizeCompanyName(key);
  return normalized == 'importedactionitems' ||
      normalized == 'actionitems' ||
      normalized == 'pgaitems' ||
      normalized == 'actions';
}

String _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _documentSourceLabel(PreventiaCompanyDocument document) {
  return _fallback(
    document.reference,
    _fallback(document.documentType, _fallback(document.title, 'Analyse')),
  );
}

String _riskFromDocument(PreventiaCompanyDocument document) {
  final normalizedLabel = normalizeCompanyName(
    '${document.documentType} ${document.title}',
  );
  final normalized =
      '$normalizedLabel ${normalizeCompanyName(document.markdown)}';
  if (_matchesFireEvacuationAnalysis(normalized, label: normalizedLabel)) {
    return 'Incendie / évacuation';
  }
  if (_matchesElectricalAnalysis(normalized)) {
    return 'Installations électriques BT/HT';
  }
  if (_matchesElevatorAnalysis(normalized)) return 'Ascenseur';
  if (_matchesErgonomicsAnalysis(normalized)) return 'Ergonomie';
  if (_matchesDangerousProductsAnalysis(normalized)) {
    return 'Produits dangereux';
  }
  return 'Risque à préciser';
}

bool _matchesFireEvacuationAnalysis(String normalized, {String label = ''}) {
  if (label.contains('incendie') || label.contains('evacuation')) return true;
  if (_matchesElectricalAnalysis(label) ||
      _matchesElevatorAnalysis(label) ||
      _matchesErgonomicsAnalysis(label)) {
    return normalized.contains('incendie') || normalized.contains('evacuation');
  }
  return normalized.contains('incendie') ||
      normalized.contains('evacuation') ||
      normalized.contains('moyen extinction') ||
      normalized.contains('moyens extinction') ||
      normalized.contains('porte coupe feu') ||
      normalized.contains('acces pompiers');
}

bool _matchesElectricalAnalysis(String normalized) {
  return normalized.contains('electrique') ||
      normalized.contains('bt ht') ||
      normalized.contains('bt/ht') ||
      normalized.contains('tgbt') ||
      normalized.contains('cabine ht') ||
      normalized.contains('rgie') ||
      normalized.contains('ba4') ||
      normalized.contains('ba5');
}

bool _matchesElevatorAnalysis(String normalized) {
  return normalized.contains('ascenseur') ||
      normalized.contains('sect') ||
      normalized.contains('personne bloquee');
}

bool _matchesErgonomicsAnalysis(String normalized) {
  return normalized.contains('ergonomie') ||
      normalized.contains('poste ecran') ||
      normalized.contains('postes ecran') ||
      normalized.contains('teletravail') ||
      normalized.contains('manutention') ||
      normalized.contains('reflet') ||
      normalized.contains('eclairage') ||
      normalized.contains('bruit');
}

bool _matchesDangerousProductsAnalysis(String normalized) {
  return normalized.contains('produits dangereux') ||
      normalized.contains('produit dangereux') ||
      normalized.contains('fds') ||
      normalized.contains('clp') ||
      normalized.contains('retention');
}

bool _isValidatedStatus(String status) {
  final normalized = normalizeCompanyName(status);
  return normalized == 'valide' ||
      normalized == 'validated' ||
      normalized == 'integre' ||
      normalized == 'approuve';
}

class _PgpActionTemplate {
  const _PgpActionTemplate(
    this.action, {
    this.type = 'Action de prévention',
    this.evidence = '[à compléter]',
  });

  final String action;
  final String type;
  final String evidence;
}

const _fireEvacuationPgpActions = [
  _PgpActionTemplate(
    'Dégager les voies d’évacuation.',
    type: 'Organisation',
    evidence: 'Photos des voies d’évacuation dégagées.',
  ),
  _PgpActionTemplate(
    'Rendre les moyens d’extinction visibles et accessibles.',
    type: 'Technique',
    evidence: 'Photos des moyens d’extinction accessibles.',
  ),
  _PgpActionTemplate(
    'Vérifier les portes coupe-feu.',
    type: 'Contrôle',
    evidence: 'Rapport ou registre de vérification.',
  ),
  _PgpActionTemplate(
    'Planifier un exercice d’évacuation.',
    type: 'Organisation',
    evidence: 'Registre d’exercice d’évacuation.',
  ),
  _PgpActionTemplate(
    'Informer visiteurs, intérimaires et sous-traitants.',
    type: 'Information',
    evidence: 'Support ou registre d’information.',
  ),
  _PgpActionTemplate(
    'Dégager les accès pompiers.',
    type: 'Organisation',
    evidence: 'Photos des accès pompiers dégagés.',
  ),
  _PgpActionTemplate(
    'Mettre à jour le dossier intervention pompiers.',
    type: 'Documentation',
    evidence: 'Dossier intervention pompiers mis à jour.',
  ),
];

const _electricalPgpActions = [
  _PgpActionTemplate(
    'Obtenir ou vérifier le PV RGIE.',
    type: 'Conformité',
    evidence: 'PV RGIE disponible.',
  ),
  _PgpActionTemplate(
    'Planifier les contrôles périodiques électriques.',
    type: 'Contrôle',
    evidence: 'Planning des contrôles périodiques.',
  ),
  _PgpActionTemplate(
    'Mettre à jour les schémas électriques.',
    type: 'Documentation',
    evidence: 'Schémas électriques à jour.',
  ),
  _PgpActionTemplate(
    'Vérifier les habilitations BA4/BA5.',
    type: 'Organisation',
    evidence: 'Liste des habilitations BA4/BA5.',
  ),
  _PgpActionTemplate(
    'Vérifier l’accès aux locaux électriques ou à la cabine HT.',
    type: 'Contrôle',
    evidence: 'Constat de contrôle des accès.',
  ),
  _PgpActionTemplate(
    'Formaliser la procédure de coupure électrique d’urgence.',
    type: 'Procédure',
    evidence: 'Procédure de coupure électrique d’urgence.',
  ),
  _PgpActionTemplate(
    'Vérifier la signalisation danger électrique.',
    type: 'Contrôle',
    evidence: 'Photos de la signalisation.',
  ),
  _PgpActionTemplate(
    'Vérifier l’identification des tableaux et circuits.',
    type: 'Contrôle',
    evidence: 'Photos des tableaux et circuits identifiés.',
  ),
  _PgpActionTemplate(
    'Vérifier l’absence d’encombrement devant les armoires électriques.',
    type: 'Contrôle',
    evidence: 'Photos des armoires électriques dégagées.',
  ),
  _PgpActionTemplate(
    'Contrôler l’état des armoires électriques.',
    type: 'Contrôle',
    evidence: 'Rapport ou constat de contrôle.',
  ),
  _PgpActionTemplate(
    'Vérifier la consignation / LOTO si applicable.',
    type: 'Procédure',
    evidence: 'Procédure de consignation / LOTO.',
  ),
];

const _elevatorPgpActions = [
  _PgpActionTemplate(
    'Obtenir ou vérifier le rapport SECT.',
    type: 'Conformité',
    evidence: 'Rapport SECT disponible.',
  ),
  _PgpActionTemplate(
    'Planifier le contrôle périodique ascenseur.',
    type: 'Contrôle',
    evidence: 'Planning du contrôle périodique ascenseur.',
  ),
  _PgpActionTemplate(
    'Lever les remarques du rapport de contrôle.',
    type: 'Correction',
    evidence: 'Preuve de levée des remarques.',
  ),
  _PgpActionTemplate(
    'Vérifier le contrat de maintenance.',
    type: 'Documentation',
    evidence: 'Contrat de maintenance disponible.',
  ),
  _PgpActionTemplate(
    'Tester l’appel d’urgence.',
    type: 'Contrôle',
    evidence: 'Trace du test d’appel d’urgence.',
  ),
  _PgpActionTemplate(
    'Afficher les consignes ascenseur.',
    type: 'Information',
    evidence: 'Photos des consignes affichées.',
  ),
  _PgpActionTemplate(
    'Organiser la procédure personne bloquée.',
    type: 'Procédure',
    evidence: 'Procédure personne bloquée.',
  ),
];

const _ergonomicsPgpActions = [
  _PgpActionTemplate(
    'Adapter les postes écran après observation ergonomique.',
    type: 'Ergonomie',
    evidence: 'Rapport d’observation ergonomique et plan d’adaptation.',
  ),
  _PgpActionTemplate(
    'Sécuriser les câbles au poste accueil.',
    type: 'Technique',
    evidence: 'Photos des câbles sécurisés.',
  ),
  _PgpActionTemplate(
    'Corriger les reflets et mesurer l’éclairage.',
    type: 'Ergonomie',
    evidence: 'Mesure d’éclairage et constat de correction des reflets.',
  ),
  _PgpActionTemplate(
    'Fournir des supports adaptés aux postes en télétravail.',
    type: 'Ergonomie',
    evidence: 'Liste des supports fournis.',
  ),
  _PgpActionTemplate(
    'Former le personnel aux gestes de manutention.',
    type: 'Formation',
    evidence: 'Registre de formation manutention.',
  ),
  _PgpActionTemplate(
    'Planifier les interventions bruyantes hors périodes sensibles.',
    type: 'Organisation',
    evidence: 'Planning des interventions bruyantes.',
  ),
];

const _dangerousProductsPgpActions = [
  _PgpActionTemplate(
    'Centraliser les FDS.',
    type: 'Documentation',
    evidence: 'FDS centralisées et accessibles.',
  ),
  _PgpActionTemplate(
    'Vérifier l’étiquetage CLP.',
    type: 'Contrôle',
    evidence: 'Photos des étiquetages CLP.',
  ),
  _PgpActionTemplate(
    'Séparer les produits incompatibles.',
    type: 'Organisation',
    evidence: 'Photos du stockage séparé.',
  ),
  _PgpActionTemplate(
    'Vérifier la rétention.',
    type: 'Contrôle',
    evidence: 'Photos ou constat de rétention.',
  ),
  _PgpActionTemplate(
    'Ventiler le local.',
    type: 'Technique',
    evidence: 'Constat de ventilation.',
  ),
  _PgpActionTemplate(
    'Limiter les quantités stockées.',
    type: 'Organisation',
    evidence: 'Inventaire des quantités stockées.',
  ),
  _PgpActionTemplate(
    'Former les utilisateurs.',
    type: 'Formation',
    evidence: 'Registre de formation.',
  ),
];

bool _isValidPgpActionText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  final normalized = normalizeCompanyName(trimmed);
  if (normalized.isEmpty) return false;
  if (normalized == 'paa' || normalized.startsWith('paa actions urgentes')) {
    return false;
  }
  const excluded = [
    'safetydatasheetsavailable',
    'jobobservationdone',
    'vehiclepedestriantraffic',
    'newworkers',
    'dangerousmachines',
    'dangerousproducts',
    'measurestoverify',
    'additionalinformation',
    'documenttype',
    'activity',
    'concernedtasks',
    'includedlocations',
    'exposedworkers',
    'documentobjective',
    'firerisk',
    'youngworkers',
    'visitdate',
    'sector',
    'periodiccontrols',
    'writteninstructions',
    'availableevidence',
    'document pourquoi le creer',
    'visite terrain a obtenir',
    'accidents ou incidents a verifier',
    'rapport de visite terrain',
    'plan d action signe ou valide',
    'registre de formation ou information',
    'photos avant apres correction',
    'preuves des controles periodiques',
    'plan d evacuation et registre exercices incendie',
    'inventaire produits dangereux et fds',
    'le conseiller en prevention niveau 3',
    'employeur ou ligne hierarchique',
    'conseiller en prevention interne',
    'travailleurs concernes',
    'cppt si present',
    'service externe de prevention',
    'expert incendie',
    'famille de danger',
    'danger precis',
    'scenario plausible',
    'numero photo',
    'preuve necessaire',
    'recommande ou necessaire selon le risque',
    'paa plan annuel d action',
    'pgp plan global de prevention',
    'action risque concerne responsable echeance',
    'reference ou domaine reglementaire',
    'livre ier',
    'livre iii',
    'livre ix',
    'code belge du bien etre au travail',
    'cppt page',
    'page 1 1',
  ];
  if (excluded.any(normalized.contains)) return false;
  return _isStrongConcretePgpAction(trimmed);
}

bool _isStrongConcretePgpAction(String text) {
  final normalized = _loosePgpText(text);
  const concreteFragments = [
    'verifier compatibilite',
    'verifier la compatibilite',
    'controler chargeurs',
    'controler les chargeurs',
    'degager les voies',
    'rendre les equipements visibles',
    'supprimer les cales',
    'verifier fermeture automatique',
    'verifier la fermeture automatique',
    'sensibiliser le personnel',
    'centraliser fds',
    'centraliser les fds',
    'verifier etiquetage clp',
    'verifier l etiquetage clp',
    'separer incompatibilites',
    'separer les incompatibilites',
    'renforcer accueil securite',
    'renforcer l accueil securite',
    'planifier un exercice',
    'degager acces',
    'degager les acces',
    'marquer zones interdites',
    'marquer les zones interdites',
    'informer chauffeurs',
    'informer les chauffeurs',
    'mettre a jour le dossier intervention pompiers',
    'mettre a jour le dossier d intervention pompiers',
    'verifier le point de rassemblement',
    'formaliser l accueil des secours',
    'controler les stockages',
    'controler stockages',
    'rendre les moyens d extinction visibles',
    'verifier les portes coupe feu',
    'informer visiteurs interimaires et sous traitants',
    'obtenir ou verifier le pv rgie',
    'planifier les controles periodiques electriques',
    'mettre a jour les schemas electriques',
    'verifier les habilitations ba4 ba5',
    'verifier les habilitations ba4ba5',
    'verifier l acces aux locaux electriques',
    'verifier l acces aux locaux electriques ou a la cabine ht',
    'verifier acces aux locaux electriques',
    'verifier l acces aux locaux electriques ou a la cabine ht',
    'formaliser la procedure de coupure electrique d urgence',
    'verifier la signalisation danger electrique',
    'verifier l identification des tableaux et circuits',
    'verifier identification des tableaux et circuits',
    'verifier l absence d encombrement devant les armoires electriques',
    'verifier absence d encombrement devant les armoires electriques',
    'controler l etat des armoires electriques',
    'controler etat des armoires electriques',
    'verifier la consignation loto',
    'obtenir ou verifier le rapport sect',
    'planifier le controle periodique ascenseur',
    'lever les remarques du rapport de controle',
    'verifier le contrat de maintenance',
    'tester l appel d urgence',
    'afficher les consignes ascenseur',
    'organiser la procedure personne bloquee',
    'adapter les postes ecran apres observation ergonomique',
    'securiser les cables au poste accueil',
    'corriger les reflets et mesurer l eclairage',
    'fournir des supports adaptes aux postes en teletravail',
    'former le personnel aux gestes de manutention',
    'planifier les interventions bruyantes hors periodes sensibles',
    'separer les produits incompatibles',
    'verifier la retention',
    'ventiler le local',
    'limiter les quantites stockees',
    'former les utilisateurs',
    'securiser',
  ];
  return concreteFragments.any(normalized.contains);
}

String _loosePgpText(String value) => normalizeCompanyName(value)
    .replaceAll(RegExp(r'[’`´]'), ' ')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

List<String> _extractPgpEvidenceItems(
  PreventiaCompanyProject project,
  List<_CleanPgpAction> actions,
) {
  final values = <String>[
    ...project.evidenceItems
        .where(
          (item) => classifyReviewCandidate(item).destination == 'evidence',
        )
        .map((item) => item.label),
    ...actions.map((item) => item.evidence),
  ];
  final result = <String>[];
  final seen = <String>{};
  for (final value in values) {
    for (final proof in _canonicalPgpEvidenceItems(value)) {
      if (proof.length < 120 && seen.add(_dedupePgpKey(proof))) {
        result.add(proof);
      }
      if (result.length >= 12) return result;
    }
  }
  return result;
}

List<String> _extractPgpValidationPoints(
  PreventiaCompanyProject project,
  List<_CleanPgpAction> actions,
) {
  final values = <String>[
    ...project.pointsToVerify.where(
      (item) => classifyReviewCandidate(item).destination == 'validationPoint',
    ),
    ...project.requiredValidations.where(
      (item) => classifyReviewCandidate(item).destination == 'validationPoint',
    ),
    ...actions.map((item) => item.action),
  ];
  return _cleanPgpList(
    values.map(_cleanPgpValidationPoint).where((value) => value.isNotEmpty),
  );
}

String _cleanFinalPgaMarkdown(String markdown) {
  var cleaned = markdown
      .replaceAll(
        RegExp(r'^\s*Page\s+[0-9]+\s*/\s*[0-9]+\s*$', multiLine: true),
        '',
      )
      .replaceAll(
        RegExp(
          r'^\s*Référence.*Page\s+[0-9]+\s*/\s*[0-9]+\s*$',
          multiLine: true,
          caseSensitive: false,
        ),
        '',
      )
      .split('\n')
      .where((line) {
        final normalized = normalizeCompanyName(line);
        if (RegExp(
          r'\bpage\s+\d+\s*/\s*\d+\b',
          caseSensitive: false,
        ).hasMatch(line)) {
          return false;
        }
        return !RegExp(r'^reference .*\bpage \d+ \d+$').hasMatch(normalized);
      })
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  const signatureMarker =
      'Direction, conseiller en prévention et validation CPPT le cas échéant.';
  final signatureIndex = cleaned.indexOf(signatureMarker);
  if (signatureIndex >= 0) {
    cleaned = cleaned.substring(0, signatureIndex + signatureMarker.length);
  }
  return _trimPgaAfterSignatures(cleaned).trim();
}

String _trimPgaAfterSignatures(String markdown) {
  var cleaned = markdown.trim();
  final signaturesIndex = cleaned.indexOf('## 10. Signatures');
  if (signaturesIndex < 0) return cleaned;

  final markerStart = signaturesIndex + '## 10. Signatures'.length;
  final markers = <RegExp>[
    RegExp(r'^\s*##\s*11\.', multiLine: true),
    RegExp(r'^\s*(?:##\s*)?11\.\s*Méthode de cotation', multiLine: true),
    RegExp(r'^\s*(?:##\s*)?12\.\s*Tableau principal', multiLine: true),
    RegExp(
      r'^\s*(?:##\s*)?13\.\s*Analyse des risques résiduels',
      multiLine: true,
    ),
    RegExp(r'^\s*Mention de validation', multiLine: true),
    RegExp(r'^\s*Page\s+1\s*/\s*1\s*$', multiLine: true),
  ];
  int? cutIndex;
  for (final pattern in markers) {
    final matches = pattern.allMatches(cleaned, markerStart);
    if (matches.isEmpty) continue;
    final index = matches.first.start;
    if (cutIndex == null || index < cutIndex) {
      cutIndex = index;
    }
  }
  if (cutIndex != null) {
    cleaned = cleaned.substring(0, cutIndex);
  }
  return cleaned.trim();
}

bool _isPgaDocument(PreventiaCompanyDocument document) {
  return document.documentType == 'PGA/PAA/PGP' ||
      document.title.startsWith('PGA/PAA/PGP');
}

String _cleanConcretePgpAction(String value) {
  final normalized = _loosePgpText(value);
  if (normalized.contains('verifier compatibilite') ||
      normalized.contains('verifier la compatibilite')) {
    return 'Vérifier la compatibilité, la ventilation, les quantités stockées et la séparation des produits.';
  }
  if (normalized.contains('controler chargeurs') ||
      normalized.contains('controler les chargeurs')) {
    return 'Contrôler les chargeurs, la ventilation, l’éloignement des combustibles et la procédure incident batterie.';
  }
  if (normalized.contains('degager les voies')) {
    return 'Dégager les voies d’évacuation, marquer les zones interdites au stockage et contrôler leur maintien libre.';
  }
  if (normalized.contains('rendre les equipements visibles')) {
    return 'Rendre les équipements visibles et accessibles, ajouter un marquage au sol si nécessaire.';
  }
  if (normalized.contains('supprimer les cales')) {
    return 'Supprimer les cales, vérifier la fermeture automatique et sensibiliser le personnel.';
  }
  if (normalized.contains('centraliser fds') ||
      normalized.contains('centraliser les fds')) {
    return 'Centraliser les FDS, vérifier l’étiquetage CLP et séparer les incompatibilités.';
  }
  if (normalized.contains('renforcer accueil securite') ||
      normalized.contains('renforcer l accueil securite')) {
    return 'Renforcer l’accueil sécurité, le briefing des intérimaires et l’exercice d’évacuation.';
  }
  if (normalized.contains('degager acces') ||
      normalized.contains('degager les acces')) {
    return 'Dégager les accès, marquer les zones interdites et informer les chauffeurs et sous-traitants.';
  }
  if (normalized.contains('mettre a jour le dossier intervention pompiers') ||
      normalized.contains('mettre a jour le dossier d intervention pompiers')) {
    return 'Mettre à jour le dossier d’intervention pompiers.';
  }
  if (normalized.contains('verifier le point de rassemblement')) {
    return 'Vérifier le point de rassemblement.';
  }
  if (normalized.contains('formaliser l accueil des secours')) {
    return 'Formaliser l’accueil des secours.';
  }
  if (normalized.contains('controler les stockages') ||
      normalized.contains('controler stockages')) {
    return 'Contrôler les stockages.';
  }
  if (normalized.contains('planifier un exercice')) {
    return 'Planifier un exercice d’évacuation annuel.';
  }
  return _cleanPgpActionText(value);
}

List<String> _canonicalPgpEvidenceItems(String value) {
  final normalized = normalizeCompanyName(value);
  if (_looksLikeRawPgpEvidenceBlock(value, normalized)) return const [];
  final proofs = <String>[];
  void add(String proof) {
    if (proof.length < 120) proofs.add(proof);
  }

  if (normalized.contains('rapport de visite terrain')) {
    add('Rapport de visite terrain.');
  }
  if (normalized.contains('photos avant apres correction') ||
      normalized.contains('photo avant apres')) {
    add('Photos avant/après correction.');
  }
  if (normalized.contains('plan d action signe') ||
      normalized.contains('plan d action valide')) {
    add('Plan d’action signé ou validé.');
  }
  if (normalized.contains('registre de formation') ||
      normalized.contains('registre d information')) {
    add('Registre de formation ou information.');
  }
  if (normalized.contains('preuves des controles periodiques') ||
      normalized.contains('controle periodique')) {
    add('Preuves des contrôles périodiques.');
  }
  if (normalized.contains('plan d evacuation') &&
      normalized.contains('registre')) {
    add('Plan d’évacuation et registre exercices incendie.');
  }
  if (normalized.contains('inventaire produits dangereux') ||
      normalized.contains('fds')) {
    add('Inventaire produits dangereux et FDS.');
  }
  if (normalized.contains('extincteur') ||
      normalized.contains('detection') ||
      normalized.contains('eclairage de secours') ||
      normalized.contains('porte coupe feu')) {
    add(
      'Rapports extincteurs, détection, éclairage de secours et portes coupe-feu.',
    );
  }
  if (normalized.contains('maintenance chargeur')) {
    add('Rapport maintenance chargeurs.');
  }
  if (normalized.contains('photo') && normalized.contains('acces secours')) {
    add('Photos accès secours.');
  }
  if (normalized.contains('photo') && normalized.contains('porte coupe feu')) {
    add('Photos portes coupe-feu.');
  }
  if (normalized.contains('photo') && normalized.contains('issue de secours')) {
    add('Photos issues de secours.');
  }
  if (normalized.contains('photo') &&
      (normalized.contains('moyen d extinction') ||
          normalized.contains('moyens d extinction'))) {
    add('Photos moyens d’extinction.');
  }
  if (normalized.contains('consigne stockage')) {
    add('Consigne stockage.');
  }
  if (normalized.contains('plan intervention pompiers') ||
      normalized.contains('plan d intervention pompiers')) {
    add('Plan intervention pompiers.');
  }
  if (normalized.contains('sensibilisation du personnel') ||
      normalized.contains('preuve sensibilisation')) {
    add('Preuve sensibilisation du personnel.');
  }
  return proofs;
}

bool _looksLikeRawPgpEvidenceBlock(String original, String normalized) {
  if (original.length > 160) return true;
  if (original.split('|').length > 5) return true;
  const blocked = [
    'n mesure complementaire',
    'numero mesure complementaire',
    'methode de cotation',
    'tableau principal',
    'analyse des risques residuels',
    'priorites d action',
    'projet de plan d action',
    'famille de danger',
    'danger precis',
    'scenario plausible',
    'incendie et evacuation',
    'action risque concerne responsable',
    'preuve attendue',
    'a verifier sur le terrain',
    'le conseiller en prevention niveau 3',
    'ce document constitue',
    'code belge',
    'livre ier',
    'livre iii',
    'livre ix',
    'paa plan annuel',
    'pgp plan global',
    'scenario test',
    'additionalinformation',
    'periodiccontrols',
  ];
  return blocked.any(normalized.contains);
}

String _cleanPgpValidationPoint(String value) {
  final normalized = normalizeCompanyName(value);
  if (_looksLikeRawPgpBlock(normalized)) return '';
  if (normalized.contains('visite terrain')) {
    return 'Visite terrain à réaliser ou confirmer.';
  }
  if (normalized.contains('validation employeur') ||
      normalized.contains('employeur a valider')) {
    return 'Validation employeur à obtenir.';
  }
  if (normalized.contains('cppt')) {
    return 'Avis CPPT à confirmer si applicable.';
  }
  if (normalized.contains('service externe')) {
    return 'Avis service externe à confirmer si nécessaire.';
  }
  if (normalized.contains('expert incendie')) {
    return 'Avis expert incendie à confirmer si nécessaire.';
  }
  if (normalized.contains('preuve') && normalized.contains('manquant')) {
    return 'Preuves documentaires à compléter.';
  }
  if (normalized.contains('point bloquant') || normalized.contains('a lever')) {
    return 'Points bloquants à lever avant validation.';
  }
  return '';
}

bool _looksLikeRawPgpBlock(String normalized) {
  const blocked = [
    'code belge',
    'livre ier',
    'livre iii',
    'livre ix',
    'paa actions urgentes',
    'paa plan annuel',
    'pgp plan global',
    'situations incluses',
    'scenario test spge',
    'additionalinformation',
    'periodiccontrols',
    'numero mesure complementaire',
    'n mesure complementaire',
    'risque concerne action a realiser',
    'famille de danger',
    'danger precis',
    'scenario plausible',
    'conclusion',
    'page 1 1',
  ];
  return blocked.any(normalized.contains);
}

String _cleanPgpActionText(String value) {
  var cleaned = value
      .replaceAll('|', '\n')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(
        RegExp(
          r'^(action|mesure|mesure complémentaire|mesure principale)\s*[:\-]\s*',
          caseSensitive: false,
        ),
        '',
      )
      .trim();
  cleaned = cleaned.replaceAll(
    RegExp(
      r'\b(additionalInformation|documentType|activity|concernedTasks|exposedWorkers|includedLocations)\b\s*:?',
      caseSensitive: false,
    ),
    '',
  );
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleaned.length > 180) {
    cleaned = '${cleaned.substring(0, 177).trim()}...';
  }
  return cleaned;
}

String _pgpRisk(PreventiaActionItem item) {
  final sourceType = item.sourceDocumentType.trim();
  if (sourceType.isNotEmpty) return sourceType;
  return '[à compléter]';
}

String _pgpActionType(PreventiaActionItem item) {
  final normalized = normalizeCompanyName(item.action);
  if (normalized.contains('former') ||
      normalized.contains('sensibiliser') ||
      normalized.contains('informer')) {
    return 'Formation / sensibilisation';
  }
  if (normalized.contains('installer') ||
      normalized.contains('remplacer') ||
      normalized.contains('securiser') ||
      normalized.contains('degager') ||
      normalized.contains('rendre accessible')) {
    return 'Technique';
  }
  if (normalized.contains('documenter') ||
      normalized.contains('formaliser') ||
      normalized.contains('mettre a jour') ||
      normalized.contains('centraliser')) {
    return 'Documentaire';
  }
  return 'Organisationnelle';
}

bool _isShortTermPgpAction(_CleanPgpAction item) {
  final normalized = normalizeCompanyName(
    '${item.priority} ${item.deadline} ${item.action}',
  );
  return normalized.contains('urgent') ||
      normalized.contains('immediat') ||
      normalized.contains('prioritaire') ||
      normalized.contains('court terme') ||
      normalized.contains('1 mois') ||
      normalized.contains('2 mois') ||
      normalized.contains('3 mois');
}

_CleanPgpAction _mergePgpAction(_CleanPgpAction first, _CleanPgpAction second) {
  final action = first.action.length <= second.action.length
      ? first.action
      : second.action;
  return _CleanPgpAction(
    source: _mergePgpSources(first.source, second.source),
    risk: _fallback(first.risk, second.risk),
    action: action,
    type: _fallback(first.type, second.type),
    priority: _bestPgpPriority(first.priority, second.priority),
    responsible: _fallback(first.responsible, second.responsible),
    deadline: _fallback(first.deadline, second.deadline),
    evidence: _fallback(first.evidence, second.evidence),
    status:
        normalizeCompanyName(first.status) == 'valide' ||
            normalizeCompanyName(second.status) == 'valide'
        ? 'validé'
        : _fallback(first.status, second.status),
  );
}

String _mergePgpSources(String first, String second) {
  final values = <String>[];
  final seen = <String>{};
  for (final value in [...first.split(','), ...second.split(',')]) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) continue;
    if (seen.add(normalizeCompanyName(trimmed))) values.add(trimmed);
  }
  return values.join(', ');
}

String _bestPgpPriority(String first, String second) {
  return _pgpPriorityScoreValue(first) <= _pgpPriorityScoreValue(second)
      ? first
      : second;
}

int _pgpPriorityScore(_CleanPgpAction item) =>
    _pgpPriorityScoreValue('${item.priority} ${item.deadline}');

int _pgpPriorityScoreValue(String value) {
  final normalized = normalizeCompanyName(value);
  if (normalized.contains('urgent') || normalized.contains('immediat')) {
    return 0;
  }
  if (normalized.contains('prioritaire') || normalized.contains('eleve')) {
    return 1;
  }
  if (normalized.contains('court terme') ||
      normalized.contains('1 mois') ||
      normalized.contains('2 mois') ||
      normalized.contains('3 mois')) {
    return 2;
  }
  if (normalized.contains('moyen')) return 3;
  return 4;
}

String _dedupePgpKey(String value) => normalizeCompanyName(
  value,
).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

String _pgpCell(String value) =>
    value.replaceAll('|', '/').replaceAll('\n', ' ').trim();

String _fallback(String value, String fallback) =>
    value.trim().isEmpty ? fallback : value.trim();

List<String> _cleanPgpList(Iterable<String> values) {
  final result = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final cleaned = _cleanPgpActionText(value);
    if (cleaned.isEmpty) continue;
    final key = _dedupePgpKey(cleaned);
    if (seen.add(key)) result.add(cleaned);
  }
  return result.take(50).toList(growable: false);
}

String _piuChapterTitle(int chapter) {
  const titles = [
    'Objet et champ d’application',
    'Identification de l’entreprise',
    'Organisation des responsabilités',
    'Coordonnées utiles',
    'Description du site',
    'Risques principaux',
    'Moyens de détection et d’alerte',
    'Procédure d’alerte interne',
    'Appel et accueil des secours',
    'Évacuation',
    'Mise à l’abri',
    'Personnes à mobilité réduite',
    'Coupures techniques',
    'Incendie',
    'Accident grave',
    'Pollution ou fuite',
    'Ascenseurs et personnes bloquées',
    'Électricité et locaux techniques',
    'Produits dangereux',
    'Communication de crise',
    'Dossier pour les pompiers',
    'Plans',
    'Exercices et formation',
    'Consignes aux travailleurs',
    'Prise d’iode',
    'Attestation de réception des consignes',
    'Suivi des mises à jour',
    'Signatures',
  ];
  return titles[chapter - 1];
}

void _debugSavedProject(PreventiaCompanyProject project) {
  debugPrint(
    '[PreventIA] company project saved companyKey=${project.companyKey} '
    'analyses=${project.analyses.length} documents=${project.documents.length} '
    'piu=${project.piuDocument != null} pga=${project.pgaDocument != null}',
  );
}

String detectCompanyName(Map<String, dynamic> formData, String markdown) {
  const keys = [
    'companyName',
    'enterpriseName',
    'organisationName',
    'organizationName',
    'company',
    'employerName',
  ];
  for (final key in keys) {
    final value = formData[key]?.toString().trim() ?? '';
    if (_usefulCompanyName(value)) return value;
  }
  final match = RegExp(
    r'(?:entreprise|société)\s*(?:\||:|-)?\s*([^\n|]{2,80})',
    caseSensitive: false,
  ).firstMatch(markdown);
  final extracted =
      match?.group(1)?.replaceAll(RegExp(r'[*_#]'), '').trim() ?? '';
  if (_usefulCompanyName(extracted)) {
    return extracted;
  }
  if (RegExp(r'\bSPGE\b', caseSensitive: false).hasMatch(markdown)) {
    return 'SPGE';
  }
  return 'Société à compléter';
}

String detectSiteName(Map<String, dynamic> formData, String markdown) {
  const keys = ['siteName', 'siteConcerned', 'buildingName', 'workplaceName'];
  for (final key in keys) {
    final value = formData[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  final match = RegExp(
    r'(?:site|établissement)\s*(?:\||:|-)?\s*([^\n|]{2,80})',
    caseSensitive: false,
  ).firstMatch(markdown);
  return match?.group(1)?.replaceAll(RegExp(r'[*_#]'), '').trim() ?? '';
}

bool _usefulCompanyName(String value) {
  final normalized = normalizeCompanyName(value);
  return normalized.isNotEmpty &&
      !normalized.startsWith('ar-') &&
      !normalized.contains('analyse de risques') &&
      !normalized.contains('recapitulatif des actions') &&
      !normalized.contains('non renseigne');
}

bool _looksLikeRiskAssessment(String value) {
  final normalized = normalizeCompanyName(value);
  return normalized.contains('analyse') && normalized.contains('risque');
}

String _referenceFromText(String value) =>
    RegExp(
      r'AR-\d{4}-[A-Z0-9-]+',
      caseSensitive: false,
    ).firstMatch(value)?.group(0) ??
    '';

String _stableId(String type, String value) {
  final hash = value.codeUnits.fold<int>(
    17,
    (result, unit) => (result * 37 + unit) & 0x7fffffff,
  );
  return '${type}_$hash';
}

List<PreventiaSiteEntry> _mergeSites(
  List<PreventiaSiteEntry> existing,
  String siteName,
) {
  if (siteName.trim().isEmpty ||
      existing.any(
        (item) =>
            normalizeCompanyName(item.name) == normalizeCompanyName(siteName),
      )) {
    return existing;
  }
  return [...existing, PreventiaSiteEntry(name: siteName.trim())];
}

PreventiaActionItem _genericAction(
  String documentId,
  String documentType,
  String reference,
  DateTime now,
) => PreventiaActionItem(
  id: _stableId('action', '$documentId|generic'),
  sourceDocumentId: documentId,
  sourceDocumentType: documentType,
  action:
      'Analyser les mesures de prévention issues de l’analyse de risques ${reference.trim()}',
  priority: '',
  responsible: '',
  deadline: '',
  status: 'à valider',
  evidenceExpected: '',
  destination: 'PGA/PAA/PGP',
  createdAt: now,
  updatedAt: now,
);

List<PreventiaCompanyDocument> _mergeDocuments(
  List<PreventiaCompanyDocument> existing,
  List<PreventiaCompanyDocument> additions,
) => _mergeById(existing, additions, (item) => item.id);

List<String> _mergeStrings(List<String> existing, List<String> additions) {
  final result = [...existing];
  final seen = existing.map(_normalizeText).toSet();
  for (final addition in additions) {
    final trimmed = addition.trim();
    if (trimmed.isNotEmpty && seen.add(_normalizeText(trimmed))) {
      result.add(trimmed);
    }
  }
  return result;
}

String _normalizeText(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[àáâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .trim();

List<PreventiaActionItem> _prepareNewActionItems(
  List<PreventiaActionItem> items,
) {
  return items
      .map((item) {
        final destination = classifyReviewCandidate(item).destination;
        return PreventiaActionItem(
          id: item.id,
          sourceDocumentId: item.sourceDocumentId,
          sourceDocumentType: item.sourceDocumentType,
          action: item.action,
          priority: item.priority,
          responsible: item.responsible,
          deadline: item.deadline,
          status: 'à valider',
          evidenceExpected: item.evidenceExpected,
          destination: destination,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          redirectedFrom: item.redirectedFrom,
          redirectReason: item.redirectReason,
        );
      })
      .toList(growable: false);
}

List<PreventiaPiuItem> _prepareNewPiuItems(List<PreventiaPiuItem> items) {
  return items
      .map((item) {
        final destination = classifyReviewCandidate(item).destination;
        return PreventiaPiuItem(
          id: item.id,
          sourceDocumentId: item.sourceDocumentId,
          emergencyTopic: item.emergencyTopic,
          information: item.information,
          location: item.location,
          actionRequired: item.actionRequired,
          status: 'à valider',
          destination: destination,
        );
      })
      .toList(growable: false);
}

List<PreventiaEvidenceItem> _prepareNewEvidenceItems(
  List<PreventiaEvidenceItem> items,
) {
  return items
      .map((item) {
        final destination = classifyReviewCandidate(item).destination;
        return PreventiaEvidenceItem(
          id: item.id,
          sourceDocumentId: item.sourceDocumentId,
          label: item.label,
          location: item.location,
          type: item.type,
          status: 'à valider',
          destination: destination,
          redirectedFrom: item.redirectedFrom,
          redirectReason: item.redirectReason,
        );
      })
      .toList(growable: false);
}

List<PreventiaActionItem> _mergeActionItems(
  PreventiaCompanyProject project,
  List<PreventiaActionItem> existing,
  List<PreventiaActionItem> additions,
) {
  final result = [...existing];
  final seen = result.map((item) => _actionReviewKey(project, item)).toSet();
  for (final addition in additions) {
    if (seen.add(_actionReviewKey(project, addition))) {
      result.add(addition);
    }
  }
  return result;
}

List<PreventiaPiuItem> _mergePiuItems(
  PreventiaCompanyProject project,
  List<PreventiaPiuItem> existing,
  List<PreventiaPiuItem> additions,
) {
  final result = [...existing];
  final seen = result.map((item) => _piuReviewKey(project, item)).toSet();
  for (final addition in additions) {
    if (seen.add(_piuReviewKey(project, addition))) {
      result.add(addition);
    }
  }
  return result;
}

List<PreventiaEvidenceItem> _mergeEvidenceItems(
  PreventiaCompanyProject project,
  List<PreventiaEvidenceItem> existing,
  List<PreventiaEvidenceItem> additions,
) {
  final result = [...existing];
  final seen = result.map((item) => _evidenceReviewKey(project, item)).toSet();
  for (final addition in additions) {
    if (seen.add(_evidenceReviewKey(project, addition))) {
      result.add(addition);
    }
  }
  return result;
}

String _actionReviewKey(
  PreventiaCompanyProject project,
  PreventiaActionItem item,
) {
  return [
    _sourceReferenceKey(project, item.sourceDocumentId),
    classifyReviewCandidate(item).destination,
    _normalizeText(item.action),
    _normalizeText(item.sourceDocumentType),
  ].join('|');
}

String _piuReviewKey(PreventiaCompanyProject project, PreventiaPiuItem item) {
  return [
    _sourceReferenceKey(project, item.sourceDocumentId),
    classifyReviewCandidate(item).destination,
    _normalizeText('${item.emergencyTopic} ${item.actionRequired}'),
    _normalizeText(item.emergencyTopic),
  ].join('|');
}

String _evidenceReviewKey(
  PreventiaCompanyProject project,
  PreventiaEvidenceItem item,
) {
  return [
    _sourceReferenceKey(project, item.sourceDocumentId),
    classifyReviewCandidate(item).destination,
    _normalizeText(item.label),
    _normalizeText(item.type),
  ].join('|');
}

String _sourceReferenceKey(
  PreventiaCompanyProject project,
  String sourceDocumentId,
) {
  final reference = _referenceFor(project, sourceDocumentId).trim();
  return _normalizeText(reference.isEmpty ? sourceDocumentId : reference);
}

List<T> _mergeById<T>(
  List<T> existing,
  List<T> additions,
  String Function(T) id,
) {
  final result = [...existing];
  for (final addition in additions) {
    final index = result.indexWhere((item) => id(item) == id(addition));
    if (index < 0) {
      result.add(addition);
    } else {
      result[index] = addition;
    }
  }
  return result;
}
