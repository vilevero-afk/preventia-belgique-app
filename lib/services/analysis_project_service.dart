import '../models/analysis_project.dart';
import '../models/saved_document.dart';
import 'action_summary_service.dart';
import 'local_document_storage.dart';

class AnalysisProjectService {
  Future<AnalysisProject> saveAnalysisWithSummary({
    required String analysisTitle,
    required String analysisContent,
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
    final referenceNumber = await _nextReferenceNumber(storage, now.year);
    final projectName = buildProjectName(
      analysisTitle: analysisTitle,
      analysisContent: analysisContent,
      referenceNumber: referenceNumber,
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
      referenceNumber: referenceNumber,
      analysisTitle: projectName,
      analysisDocumentId: analysisDocument.id,
      actionSummaryDocumentId: summaryDocument.id,
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
    final parts = [referenceNumber, context ?? analysisTitle];

    return _sanitizeProjectName(parts.join(' – '));
  }

  Future<String> _nextReferenceNumber(
    LocalDocumentStorage storage,
    int year,
  ) async {
    final projects = await storage.loadProjects();
    var maxNumber = 0;
    final prefix = 'AR-$year-';

    for (final project in projects) {
      final reference = project.referenceNumber;
      if (!reference.startsWith(prefix)) {
        continue;
      }
      final number = int.tryParse(reference.substring(prefix.length));
      if (number != null && number > maxNumber) {
        maxNumber = number;
      }
    }

    final next = (maxNumber + 1).toString().padLeft(4, '0');
    return '$prefix$next';
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
      for (final label in labels) {
        final index = line.toLowerCase().indexOf(label.toLowerCase());
        if (index == -1) {
          continue;
        }
        final afterLabel = line.substring(index + label.length).trim();
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
