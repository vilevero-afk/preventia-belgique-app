import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/document_family.dart';
import '../models/preventia_project.dart';
import 'preventia_company_extraction_service.dart';
import 'preventia_project_service.dart';

export 'preventia_project_service.dart' show normalizeFolderName;

class PreventiaSavedDocument {
  const PreventiaSavedDocument({
    required this.documentId,
    required this.folderPath,
    this.wordPath,
    this.pdfPath,
    this.markdownPath,
    this.error,
    this.actionCount = 0,
    this.riskCount = 0,
    this.piuCount = 0,
    this.diuCount = 0,
    this.evidenceCount = 0,
    this.piuCreated = false,
    this.pgaCreated = false,
  });

  final String documentId;
  final String folderPath;
  final String? wordPath;
  final String? pdfPath;
  final String? markdownPath;
  final String? error;
  final int actionCount;
  final int riskCount;
  final int piuCount;
  final int diuCount;
  final int evidenceCount;
  final bool piuCreated;
  final bool pgaCreated;

  bool get isIndexed => folderPath.isNotEmpty && error == null;
}

class PreventiaDocumentStorageService {
  PreventiaDocumentStorageService({PreventiaProjectService? projectService})
    : _projectService = projectService ?? PreventiaProjectService();

  final PreventiaProjectService _projectService;

  Future<PreventiaSavedDocument> saveGeneratedDocument({
    required String documentType,
    required String companyName,
    required String siteName,
    required String title,
    String? markdown,
    String? wordSourcePath,
    String? pdfSourcePath,
    Map<String, dynamic>? formData,
    Uint8List? wordBytes,
    Uint8List? pdfBytes,
    String? wordFileName,
    String? pdfFileName,
    String? projectPath,
    bool rememberProject = true,
  }) async {
    final documentId = _documentId(documentType, title, formData);
    PreventiaProject? previousProject;
    PreventiaProject? temporaryProject;
    try {
      if (!rememberProject) {
        previousProject = await _projectService.getCurrentProject();
      }
      final project = await _resolveProject(
        companyName: companyName,
        siteName: siteName,
        projectPath: projectPath,
      );
      if (project == null) {
        return PreventiaSavedDocument(
          documentId: documentId,
          folderPath: '',
          error:
              resolveDocumentFamily(documentType) ==
                  DocumentFamily.riskAssessment
              ? 'Document généré, mais non enregistré dans un dossier PreventIA.'
              : 'Document généré, mais aucun dossier PreventIA n’est associé à ce site.',
        );
      }
      if (!rememberProject) temporaryProject = project;
      await _projectService.setCurrentProject(project);
      if (siteName.trim().isNotEmpty &&
          !project.sites.contains(siteName.trim())) {
        await _projectService.saveProject(
          project.copyWith(sites: {...project.sites, siteName.trim()}.toList()),
        );
      }

      final folder = Directory(
        path.join(
          project.basePath,
          PreventiaProjectService.subdirectoryForDocumentType(documentType),
        ),
      );
      await folder.create(recursive: true);
      final safeTitle = _safeFileName(title);
      final resolvedWordPath = await _storeFile(
        sourcePath: wordSourcePath,
        bytes: wordBytes,
        targetPath: path.join(
          folder.path,
          _fileName(wordFileName, safeTitle, '.docx'),
        ),
      );
      final resolvedPdfPath = await _storeFile(
        sourcePath: pdfSourcePath,
        bytes: pdfBytes,
        targetPath: path.join(
          folder.path,
          _fileName(pdfFileName, safeTitle, '.pdf'),
        ),
      );
      String? markdownPath;
      if (markdown != null && markdown.trim().isNotEmpty) {
        markdownPath = path.join(folder.path, '$safeTitle.md');
        await File(markdownPath).writeAsString(markdown, flush: true);
      }

      final data = formData ?? const <String, dynamic>{};
      final reference = _firstString(data, const [
        'documentReference',
        'reference',
        'analysisNumber',
      ]);
      await _projectService.addDocumentToCurrentProject(
        PreventiaProjectDocument(
          id: documentId,
          documentType: documentType,
          title: title,
          reference: reference,
          language: _firstString(data, const ['language', '_localeName'], 'fr'),
          createdAt: DateTime.now(),
          wordPath: resolvedWordPath ?? '',
          pdfPath: resolvedPdfPath ?? '',
          source: 'generated',
          companyName: project.companyName,
          siteName: siteName.trim(),
          folderPath: folder.path,
          extractedToPiu:
              resolveDocumentFamily(documentType) ==
              DocumentFamily.riskAssessment,
          extractedToPga:
              resolveDocumentFamily(documentType) ==
              DocumentFamily.riskAssessment,
          extractedToDiu:
              resolveDocumentFamily(documentType) ==
              DocumentFamily.riskAssessment,
        ),
      );
      PreventiaProjectDocument? indexedDocument;
      for (final item
          in (await _projectService.getCurrentProject())?.documents ??
              const []) {
        if (item.id == documentId) {
          indexedDocument = item;
          break;
        }
      }
      final finalWordPath =
          resolvedWordPath ??
          (indexedDocument?.wordPath.isNotEmpty == true
              ? indexedDocument!.wordPath
              : null);
      final finalPdfPath =
          resolvedPdfPath ??
          (indexedDocument?.pdfPath.isNotEmpty == true
              ? indexedDocument!.pdfPath
              : null);

      var actionCount = 0;
      var riskCount = 0;
      var piuCount = 0;
      var diuCount = 0;
      var evidenceCount = 0;
      var piuCreated = false;
      var pgaCreated = false;
      if (resolveDocumentFamily(documentType) ==
          DocumentFamily.riskAssessment) {
        final extraction = extractFromRiskAssessment(
          documentType: documentType,
          markdown: markdown ?? '',
          formData: data,
          sourceDocumentId: documentId,
        );
        await _projectService.addRiskItemsToCurrentProject(
          extraction.riskItems,
        );
        await _projectService.addActionItemsToCurrentProject(
          extraction.actionItems,
        );
        await _projectService.addPiuItemsToCurrentProject(extraction.piuItems);
        await _projectService.addDiuItemsToCurrentProject(extraction.diuItems);
        await _projectService.addEvidenceItemsToCurrentProject(
          extraction.evidenceItems,
        );
        actionCount = extraction.paaPgpItems.length;
        riskCount = extraction.riskItems.length;
        piuCount = extraction.piuItems.length;
        diuCount = extraction.diuItems.length;
        evidenceCount = extraction.evidenceItems.length;
        final current = await _projectService.getCurrentProject();
        if (current != null) {
          piuCreated = (await _projectService.ensureBlankPiuExists(
            current,
          )).created;
          final refreshed =
              await _projectService.getCurrentProject() ?? current;
          pgaCreated = (await _projectService.ensureBlankPgaExists(
            refreshed,
          )).created;
        }
      }

      final result = PreventiaSavedDocument(
        documentId: documentId,
        folderPath: project.basePath,
        wordPath: finalWordPath,
        pdfPath: finalPdfPath,
        markdownPath: markdownPath,
        actionCount: actionCount,
        riskCount: riskCount,
        piuCount: piuCount,
        diuCount: diuCount,
        evidenceCount: evidenceCount,
        piuCreated: piuCreated,
        pgaCreated: pgaCreated,
      );
      await _restoreProjectAssociation(
        temporaryProject: temporaryProject,
        previousProject: previousProject,
      );
      return result;
    } on Object catch (error) {
      debugPrint('PreventIA document storage unavailable: $error');
      await _restoreProjectAssociation(
        temporaryProject: temporaryProject,
        previousProject: previousProject,
      );
      return PreventiaSavedDocument(
        documentId: documentId,
        folderPath: '',
        error: 'Document généré, mais l’enregistrement local a échoué.',
      );
    }
  }

  Future<void> _restoreProjectAssociation({
    required PreventiaProject? temporaryProject,
    required PreventiaProject? previousProject,
  }) async {
    if (temporaryProject == null) return;
    await _projectService.removeProjectFromList(temporaryProject);
    if (previousProject != null) {
      await _projectService.setCurrentProject(previousProject);
    }
  }

  Future<PreventiaProject?> _resolveProject({
    required String companyName,
    required String siteName,
    String? projectPath,
  }) async {
    if (projectPath != null && projectPath.trim().isNotEmpty) {
      if (!isValidClientProjectPath(projectPath)) return null;
      return _projectService.loadProject(
        path.join(projectPath, PreventiaProjectService.projectFileName),
      );
    }
    final company = companyName.trim();
    final site = siteName.trim();
    if (company.isNotEmpty) {
      final matching = await _projectService.findProject(
        companyName: company,
        siteName: site,
      );
      if (matching != null) return matching;
      return null;
    }
    final current = await _projectService.getCurrentProject();
    return current != null && isValidClientProjectPath(current.basePath)
        ? current
        : null;
  }

  static Future<String?> openFolder(String folderPath) async {
    if (folderPath.trim().isEmpty) return 'Aucun dossier à ouvrir.';
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
      return 'L’ouverture automatique du dossier est disponible sur macOS.';
    }
    try {
      final result = await Process.run('open', [folderPath]);
      return result.exitCode == 0
          ? null
          : 'Impossible d’ouvrir le dossier : ${result.stderr}';
    } on Object catch (error) {
      return 'Impossible d’ouvrir le dossier : $error';
    }
  }

  static Future<String?> _storeFile({
    required String? sourcePath,
    required Uint8List? bytes,
    required String targetPath,
  }) async {
    if (bytes != null) {
      await File(targetPath).writeAsBytes(bytes, flush: true);
      return targetPath;
    }
    if (sourcePath == null || sourcePath.trim().isEmpty) return null;
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Fichier source introuvable', sourcePath);
    }
    if (path.equals(source.absolute.path, File(targetPath).absolute.path)) {
      return targetPath;
    }
    await source.copy(targetPath);
    return targetPath;
  }

  static String _fileName(
    String? requestedName,
    String fallback,
    String extension,
  ) {
    final raw = requestedName?.trim().isNotEmpty == true
        ? path.basename(requestedName!.trim())
        : '$fallback$extension';
    final withoutExtension = raw.toLowerCase().endsWith(extension)
        ? raw.substring(0, raw.length - extension.length)
        : raw;
    return '${_safeFileName(withoutExtension)}$extension';
  }

  static String _safeFileName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[\x00-\x1F/\\:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'-+'), '-');
    return cleaned.isEmpty ? 'document' : cleaned;
  }

  static String _documentId(
    String documentType,
    String title,
    Map<String, dynamic>? formData,
  ) {
    final reference = _firstString(formData ?? const {}, const [
      'documentReference',
      'reference',
      'analysisNumber',
    ]);
    final value = '$documentType|$reference|$title';
    final hash = value.codeUnits.fold<int>(
      17,
      (result, unit) => (result * 37 + unit) & 0x7fffffff,
    );
    return 'document_$hash';
  }

  static String _firstString(
    Map<String, dynamic> data,
    List<String> keys, [
    String fallback = '',
  ]) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }
}
