import '../models/analysis_project.dart';
import '../models/saved_document.dart';
import 'action_summary_service.dart';
import 'document_reference_service.dart';
import 'local_document_storage.dart';

class AnalysisProjectService {
  Future<AnalysisProject> saveDocumentPackage({
    required String documentTitle,
    required String documentContent,
    String? referenceNumber,
    required String projectStatus,
    required String sourceValue,
    List<LinkedDocumentDraft> linkedDocuments = const [],
  }) async {
    final storage = LocalDocumentStorage();
    final now = DateTime.now();
    final projectId = now.microsecondsSinceEpoch.toString();
    final resolvedReferenceNumber = await _resolveReferenceNumber(
      documentType: documentTitle,
      referenceNumber: referenceNumber,
    );
    final projectName = buildProjectName(
      analysisTitle: documentTitle,
      analysisContent: documentContent,
      referenceNumber: resolvedReferenceNumber,
      includeDocumentTitle: true,
    );

    final mainDocument = SavedDocument(
      id: '${projectId}_main',
      title: projectName,
      documentType: documentTitle,
      content: documentContent,
      createdAt: now,
      localDocumentType: SavedDocumentLocalType.preventionDocument,
      projectId: projectId,
      status: projectStatus,
      sourceLabel: sourceValue,
    );

    final savedLinkedDocuments = linkedDocuments
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key + 1;
          final draft = entry.value;
          return SavedDocument(
            id: '${projectId}_linked_$index',
            title: '${draft.title} - $projectName',
            documentType: draft.title,
            content: draft.content,
            createdAt: now,
            localDocumentType: SavedDocumentLocalType.linkedDocument,
            sourceDocumentId: mainDocument.id,
            sourceDocumentTitle: projectName,
            sourceLabel: sourceValue,
            status: projectStatus,
            projectId: projectId,
          );
        })
        .toList(growable: false);

    final project = AnalysisProject(
      id: projectId,
      name: projectName,
      createdAt: now,
      modifiedAt: now,
      referenceNumber: resolvedReferenceNumber,
      analysisTitle: projectName,
      analysisDocumentId: mainDocument.id,
      linkedDocumentIds: savedLinkedDocuments.map((doc) => doc.id).toList(),
      folderType: documentTitle,
      status: projectStatus,
    );

    await storage.saveDocument(mainDocument);
    for (final document in savedLinkedDocuments) {
      await storage.saveDocument(document);
    }
    await storage.saveOrUpdateProject(project);
    return project;
  }

  Future<AnalysisProject> saveAnalysisWithSummary({
    required String analysisTitle,
    required String analysisContent,
    String? referenceNumber,
    required String projectStatus,
    required String actionSummaryTitle,
    required String linkedAnalysisLabel,
    required String generatedAtLabel,
    required String sourceFieldLabel,
    required String sourceValue,
    required String statusLabel,
    required String validationNoticeTitle,
    required String validationNotice,
  }) async {
    final storage = LocalDocumentStorage();
    final now = DateTime.now();
    final projectId = now.microsecondsSinceEpoch.toString();
    final resolvedReferenceNumber = await _resolveReferenceNumber(
      documentType: analysisTitle,
      referenceNumber: referenceNumber,
    );
    final projectName = buildProjectName(
      analysisTitle: analysisTitle,
      analysisContent: analysisContent,
      referenceNumber: resolvedReferenceNumber,
    );

    final analysisDocument = SavedDocument(
      id: '${projectId}_analysis',
      title: projectName,
      documentType: analysisTitle,
      content: analysisContent,
      createdAt: now,
      localDocumentType: SavedDocumentLocalType.riskAnalysis,
      projectId: projectId,
      status: projectStatus,
    );

    final summary = ActionSummaryService().build(analysisContent);
    final summaryLanguage = ActionSummaryService().detectLanguage(
      analysisContent,
    );
    final summaryContent = _summaryContent(
      summary: summary,
      summaryLanguage: summaryLanguage,
      analysisTitle: projectName,
      generatedAt: now,
      actionSummaryTitle: actionSummaryTitle,
      projectStatus: projectStatus,
      linkedAnalysisLabel: linkedAnalysisLabel,
      generatedAtLabel: generatedAtLabel,
      sourceFieldLabel: sourceFieldLabel,
      sourceValue: sourceValue,
      statusLabel: statusLabel,
      validationNoticeTitle: validationNoticeTitle,
      validationNotice: validationNotice,
    );
    final summaryDocument = SavedDocument(
      id: '${projectId}_summary',
      title: '$actionSummaryTitle - $projectName',
      documentType: actionSummaryTitle,
      content: summaryContent,
      createdAt: now,
      localDocumentType: SavedDocumentLocalType.actionSummary,
      sourceDocumentId: analysisDocument.id,
      sourceDocumentTitle: projectName,
      sourceLabel: sourceValue,
      status: projectStatus,
      projectId: projectId,
    );

    final project = AnalysisProject(
      id: projectId,
      name: projectName,
      createdAt: now,
      modifiedAt: now,
      referenceNumber: resolvedReferenceNumber,
      analysisTitle: projectName,
      analysisDocumentId: analysisDocument.id,
      actionSummaryDocumentId: summaryDocument.id,
      linkedDocumentIds: [summaryDocument.id],
    );

    await storage.saveDocument(analysisDocument);
    await storage.saveDocument(summaryDocument);
    await storage.saveOrUpdateProject(project);
    return project;
  }

  String buildProjectName({
    required String analysisTitle,
    required String analysisContent,
    required String referenceNumber,
    bool includeDocumentTitle = false,
  }) {
    final organization = _extractValue(analysisContent, [
      'Nom de l’entreprise',
      'Entreprise',
      'Administration',
      'Naam van de onderneming',
      'Onderneming',
      'Company name',
      'Company',
      'Name des Unternehmens',
      'Unternehmen',
    ]);
    final service = _extractValue(analysisContent, [
      'Service concerné',
      'Service',
      'Betrokken dienst',
      'Dienst',
      'Service concerned',
      'Department concerned',
      'Department',
      'Betroffener Dienst',
    ]);
    final site = _extractValue(analysisContent, ['Site concerné', 'Site']);
    final context = _bestContext(
      organization: organization,
      service: service,
      site: site,
    );
    final parts = [
      referenceNumber,
      if (includeDocumentTitle) analysisTitle,
      context ?? (!includeDocumentTitle ? analysisTitle : null),
    ].whereType<String>();

    return _sanitizeProjectName(parts.join(' – '));
  }

  Future<String> _resolveReferenceNumber({
    required String documentType,
    required String? referenceNumber,
  }) async {
    final referenceService = DocumentReferenceService();
    final trimmedReference = referenceNumber?.trim();
    if (trimmedReference != null && trimmedReference.isNotEmpty) {
      await referenceService.registerReference(trimmedReference);
      return trimmedReference;
    }
    return referenceService.nextReference(documentType: documentType);
  }

  String? _bestContext({
    required String? organization,
    required String? service,
    required String? site,
  }) {
    final cleanedOrganization = _cleanContextPart(organization);
    final cleanedService = _cleanContextPart(service);
    final cleanedSite = _cleanContextPart(site);
    final secondary = cleanedService ?? cleanedSite;

    if (cleanedOrganization == null) {
      return secondary;
    }
    if (secondary == null ||
        _containsEquivalent(cleanedOrganization, secondary)) {
      return cleanedOrganization;
    }
    return '$cleanedOrganization – $secondary';
  }

  String _summaryContent({
    required ActionSummary summary,
    required String summaryLanguage,
    required String analysisTitle,
    required DateTime generatedAt,
    required String actionSummaryTitle,
    required String projectStatus,
    required String linkedAnalysisLabel,
    required String generatedAtLabel,
    required String sourceFieldLabel,
    required String sourceValue,
    required String statusLabel,
    required String validationNoticeTitle,
    required String validationNotice,
  }) {
    return [
      'PreventIA Belgique',
      actionSummaryTitle,
      projectStatus,
      '',
      '$linkedAnalysisLabel : $analysisTitle',
      '$generatedAtLabel : ${_formatDate(generatedAt)}',
      '$sourceFieldLabel : $sourceValue',
      '$statusLabel : $projectStatus',
      '',
      ActionSummaryService().buildCopyText(summary, language: summaryLanguage),
      '',
      validationNoticeTitle,
      validationNotice,
    ].join('\n');
  }

  String? _extractValue(String content, List<String> labels) {
    for (final rawLine in content.split('\n')) {
      final line = rawLine
          .replaceAll('*', '')
          .replaceAll('|', ' ')
          .replaceAll('#', '')
          .trim();
      final lowerLine = line.toLowerCase();
      for (final label in labels) {
        final lowerLabel = label.toLowerCase();
        if (!lowerLine.startsWith(lowerLabel)) {
          continue;
        }
        final afterLabel = line.substring(label.length).trim();
        if (!RegExp(r'^[:\-–]').hasMatch(afterLabel)) {
          continue;
        }
        final cleaned = afterLabel
            .replaceFirst(RegExp(r'^[:\-–]\s*'), '')
            .split(RegExp(r'\s{2,}|\s+[|]\s+'))
            .first
            .trim();
        if (cleaned.isNotEmpty && cleaned.length <= 90) {
          return cleaned;
        }
      }
    }
    return null;
  }

  String? _cleanContextPart(String? value) {
    if (value == null) {
      return null;
    }
    var cleaned = value
        .replaceAll(RegExp(r'[\/\\:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s+-\s+'), ' – ')
        .trim();
    cleaned = cleaned.split(RegExp(r'\s+[\/|]\s+|\s+[–—-]\s+')).first.trim();
    cleaned = cleaned.replaceAll(
      RegExp(r'\s+–\s+ma$', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\s+ma$', caseSensitive: false), '');
    cleaned = _trimWithoutCuttingWord(cleaned, 70);
    return cleaned.isEmpty ? null : cleaned;
  }

  bool _containsEquivalent(String parent, String child) {
    final normalizedParent = _normalize(parent);
    final normalizedChild = _normalize(child);
    return normalizedParent.contains(normalizedChild) ||
        normalizedChild.contains(normalizedParent);
  }

  String _sanitizeProjectName(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[\/\\:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
    return _trimWithoutCuttingWord(sanitized, 110);
  }

  String _trimWithoutCuttingWord(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value.trim();
    }
    final shortened = value.substring(0, maxLength);
    final lastSpace = shortened.lastIndexOf(' ');
    if (lastSpace <= 0) {
      return shortened.trim();
    }
    return shortened.substring(0, lastSpace).trim();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class LinkedDocumentDraft {
  const LinkedDocumentDraft({required this.title, required this.content});

  final String title;
  final String content;
}
