import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/preventia_project.dart';

class PreventiaProjectException implements Exception {
  const PreventiaProjectException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PreventiaAutoDocumentResult {
  const PreventiaAutoDocumentResult({
    required this.created,
    required this.path,
  });

  final bool created;
  final String path;
}

class PreventiaProjectService {
  PreventiaProjectService({SharedPreferences? preferences})
    : _preferences = preferences;

  static const projectFileName = 'preventia_company.json';
  static const legacyProjectFileName = 'preventia_project.json';
  static const backupFileName = 'preventia_company.backup.json';
  static const _currentProjectPathKey = 'preventia_current_project_json_path';
  static const _rootDirectoryPathKey = 'preventia_root_directory_path';
  static const _rootDirectoryChoiceAskedKey =
      'preventia_root_directory_choice_asked';
  static const _knownProjectPathsKey = 'preventia_known_project_json_paths';
  static const _knownProjectsMetadataKey = 'preventia_known_projects_metadata';
  static const _uuid = Uuid();
  static const subdirectories = <String>[
    '01_Analyses_de_risques',
    '02_PIU',
    '03_DIU',
    '04_PGA_PAA_PGP',
    '05_Plans_actions',
    '06_Preuve_et_photos',
    '07_Annexes',
  ];

  final SharedPreferences? _preferences;
  String? lastError;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<PreventiaProject?> getCurrentProject() async {
    lastError = null;
    final projectPath = (await _prefs).getString(_currentProjectPathKey);
    if (projectPath == null || projectPath.trim().isEmpty) return null;
    try {
      return await loadProject(projectPath);
    } on Object catch (error) {
      lastError = error.toString();
      return null;
    }
  }

  Future<void> setCurrentProject(PreventiaProject project) async {
    await saveProject(project);
    final preferences = await _prefs;
    final projectPath = path.join(project.basePath, projectFileName);
    await preferences.setString(_currentProjectPathKey, projectPath);
    final knownPaths = preferences.getStringList(_knownProjectPathsKey) ?? [];
    if (!knownPaths.contains(projectPath)) {
      await preferences.setStringList(_knownProjectPathsKey, [
        ...knownPaths,
        projectPath,
      ]);
    }
    final metadata = preferences.getStringList(_knownProjectsMetadataKey) ?? [];
    final entries = metadata
        .map((item) {
          try {
            return jsonDecode(item);
          } on Object {
            return null;
          }
        })
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['projectPath'] != projectPath)
        .toList();
    entries.add({
      'projectKey': companyKey(project.companyName),
      'companyName': project.companyName,
      'siteName': project.siteName,
      'projectPath': project.basePath,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await preferences.setStringList(
      _knownProjectsMetadataKey,
      entries.map(jsonEncode).toList(),
    );
  }

  Future<void> clearCurrentProject() async {
    await (await _prefs).remove(_currentProjectPathKey);
  }

  Future<void> removeProjectFromList(PreventiaProject project) async {
    final preferences = await _prefs;
    final projectJsonPath = path.join(project.basePath, projectFileName);
    final knownPaths = preferences.getStringList(_knownProjectPathsKey) ?? [];
    await preferences.setStringList(
      _knownProjectPathsKey,
      knownPaths.where((item) => item != projectJsonPath).toList(),
    );
    final metadata = preferences.getStringList(_knownProjectsMetadataKey) ?? [];
    await preferences.setStringList(
      _knownProjectsMetadataKey,
      metadata.where((item) {
        try {
          final decoded = jsonDecode(item);
          return decoded is! Map || decoded['projectPath'] != project.basePath;
        } on Object {
          return false;
        }
      }).toList(),
    );
    if (preferences.getString(_currentProjectPathKey) == projectJsonPath) {
      await preferences.remove(_currentProjectPathKey);
    }
  }

  Future<void> deleteProjectPermanently(PreventiaProject project) async {
    final projectDirectory = Directory(project.basePath);
    final projectJson = File(path.join(project.basePath, projectFileName));
    if (!_isSafeProjectPath(project.basePath) ||
        !await projectDirectory.exists() ||
        !await projectJson.exists()) {
      throw const PreventiaProjectException(
        'Impossible de supprimer le dossier. Vérifiez les permissions ou supprimez-le manuellement.',
      );
    }
    try {
      await projectDirectory.delete(recursive: true);
      await removeProjectFromList(project);
    } on Object {
      throw const PreventiaProjectException(
        'Impossible de supprimer le dossier. Vérifiez les permissions ou supprimez-le manuellement.',
      );
    }
  }

  Future<String?> getRootDirectoryPath() async {
    final value = (await _prefs).getString(_rootDirectoryPathKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> setRootDirectoryPath(String rootPath) async {
    final preferences = await _prefs;
    await preferences.setString(_rootDirectoryPathKey, rootPath);
    await preferences.setBool(_rootDirectoryChoiceAskedKey, true);
  }

  Future<bool> hasAskedForRootDirectory() async =>
      (await _prefs).getBool(_rootDirectoryChoiceAskedKey) ?? false;

  Future<void> markRootDirectoryChoiceAsked() async {
    await (await _prefs).setBool(_rootDirectoryChoiceAskedKey, true);
  }

  Future<List<PreventiaProject>> getKnownProjects() async {
    final preferences = await _prefs;
    final knownPaths = preferences.getStringList(_knownProjectPathsKey) ?? [];
    final projects = <PreventiaProject>[];
    final accessiblePaths = <String>[];
    for (final projectPath in knownPaths) {
      try {
        final project = await loadProject(projectPath);
        if (isValidClientProjectPath(project.basePath)) {
          projects.add(project);
          accessiblePaths.add(projectPath);
        }
      } on Object {
        // Keep inaccessible projects out of selection without scanning the disk.
      }
    }
    if (accessiblePaths.length != knownPaths.length) {
      await preferences.setStringList(_knownProjectPathsKey, accessiblePaths);
    }
    return projects;
  }

  Future<PreventiaProject?> findProject({
    required String companyName,
    required String siteName,
  }) async {
    final key = companyKey(companyName);
    if (key.isEmpty) return null;
    final current = await getCurrentProject();
    if (current != null &&
        isValidClientProjectPath(current.basePath) &&
        companyKey(current.companyName) == key) {
      return current;
    }
    for (final project in await getKnownProjects()) {
      if (isValidClientProjectPath(project.basePath) &&
          companyKey(project.companyName) == key) {
        return project;
      }
    }
    return null;
  }

  Future<PreventiaProject> createProject({
    required String companyName,
    required String siteName,
    required String baseDirectoryPath,
    bool register = true,
  }) async {
    if (companyName.trim().isEmpty) {
      throw const PreventiaProjectException(
        'Le nom de la société est obligatoire.',
      );
    }
    final selectedBase = Directory(baseDirectoryPath);
    if (!await selectedBase.exists()) {
      throw const PreventiaProjectException(
        'Le dossier sélectionné n’est plus accessible.',
      );
    }

    final projectDirectory = Directory(
      path.join(
        selectedBase.path,
        'PreventIA',
        'Clients',
        normalizeFolderName(companyName),
      ),
    );
    final existingIndex = File(
      path.join(projectDirectory.path, projectFileName),
    );
    if (await existingIndex.exists()) {
      final existing = await loadProject(existingIndex.path);
      if (register) {
        await setCurrentProject(existing);
        await setRootDirectoryPath(baseDirectoryPath);
      }
      return existing;
    }
    await projectDirectory.create(recursive: true);
    await _ensureStructure(projectDirectory.path);
    final now = DateTime.now();
    final project = PreventiaProject(
      id: _uuid.v4(),
      companyName: companyName.trim(),
      siteName: siteName.trim(),
      basePath: projectDirectory.path,
      createdAt: now,
      updatedAt: now,
      sites: [if (siteName.trim().isNotEmpty) siteName.trim()],
    );
    if (register) {
      await setCurrentProject(project);
      await setRootDirectoryPath(baseDirectoryPath);
    } else {
      await saveProject(project);
    }
    return project;
  }

  Future<List<List<PreventiaProject>>> duplicateProjectGroups() async {
    final groups = <String, List<PreventiaProject>>{};
    for (final project in await getKnownProjects()) {
      groups
          .putIfAbsent(
            companyKey(project.companyName),
            () => <PreventiaProject>[],
          )
          .add(project);
    }
    return groups.values.where((projects) => projects.length > 1).toList();
  }

  Future<List<List<PreventiaProject>>> detectDuplicateProjects() =>
      duplicateProjectGroups();

  Future<PreventiaProject> mergeDuplicateProjectReferences(
    List<PreventiaProject> projects,
  ) async {
    if (projects.isEmpty) {
      throw const PreventiaProjectException('Aucun dossier à fusionner.');
    }
    final sorted = [...projects]
      ..sort((left, right) {
        final documentComparison = right.documents.length.compareTo(
          left.documents.length,
        );
        return documentComparison != 0
            ? documentComparison
            : left.createdAt.compareTo(right.createdAt);
      });
    final primary = sorted.first;
    for (final duplicate in sorted.skip(1)) {
      await removeProjectFromList(duplicate);
    }
    await setCurrentProject(primary);
    return primary;
  }

  Future<PreventiaProjectDocument?> findIndexedDocument({
    required String documentId,
    required String documentType,
    required String title,
  }) async {
    for (final project in await getKnownProjects()) {
      for (final document in project.documents) {
        if (_matchesDocument(document, documentId, documentType, title)) {
          return document;
        }
      }
    }
    return null;
  }

  Future<List<String>> removeIndexedDocument({
    required String documentId,
    required String documentType,
    required String title,
    required bool deleteFiles,
  }) async {
    final errors = <String>[];
    for (final project in await getKnownProjects()) {
      final matching = project.documents
          .where(
            (document) =>
                _matchesDocument(document, documentId, documentType, title),
          )
          .toList();
      if (matching.isEmpty) continue;
      if (deleteFiles) {
        for (final document in matching) {
          for (final filePath in [document.wordPath, document.pdfPath]) {
            if (filePath.trim().isEmpty) continue;
            if (!_isFileInsideProject(filePath, project.basePath)) {
              errors.add('Chemin de fichier non sécurisé : $filePath');
              continue;
            }
            final file = File(filePath);
            if (await file.exists()) {
              try {
                await file.delete();
              } on Object {
                errors.add('Impossible de supprimer : $filePath');
              }
            } else {
              errors.add('Fichier introuvable : $filePath');
            }
          }
        }
      }
      final matchingIds = matching.map((item) => item.id).toSet();
      await saveProject(
        project.copyWith(
          documents: project.documents
              .where((document) => !matchingIds.contains(document.id))
              .toList(),
        ),
      );
    }
    return errors;
  }

  Future<PreventiaProject> loadProject(String projectJsonPath) async {
    final jsonFile = File(projectJsonPath);
    final projectDirectory = jsonFile.parent;
    if (!await projectDirectory.exists()) {
      throw const PreventiaProjectException(
        'Le dossier PreventIA n’est plus accessible.',
      );
    }

    final legacyFile = File(
      path.join(projectDirectory.path, legacyProjectFileName),
    );
    if (!await jsonFile.exists() && !await legacyFile.exists()) {
      final now = DateTime.now();
      final project = PreventiaProject(
        id: _uuid.v4(),
        companyName: projectDirectory.path.split(path.separator).last,
        siteName: '',
        basePath: projectDirectory.path,
        createdAt: now,
        updatedAt: now,
      );
      await saveProject(project);
      return project;
    }

    try {
      var readableFile = jsonFile;
      if (!await readableFile.exists() && await legacyFile.exists()) {
        readableFile = legacyFile;
      }
      final decoded = jsonDecode(await readableFile.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Index JSON invalide.');
      }
      final project = PreventiaProject.fromJson(
        decoded,
      ).copyWith(basePath: projectDirectory.path);
      await _ensureStructure(project.basePath);
      return project;
    } on PreventiaProjectException {
      rethrow;
    } on Object catch (error) {
      throw PreventiaProjectException(
        'Impossible de lire le dossier PreventIA : $error',
      );
    }
  }

  Future<void> saveProject(PreventiaProject project) async {
    try {
      await _ensureStructure(project.basePath);
      final jsonFile = File(path.join(project.basePath, projectFileName));
      final backupFile = File(path.join(project.basePath, backupFileName));
      if (await jsonFile.exists()) {
        await jsonFile.copy(backupFile.path);
      }
      final updated = project.copyWith(updatedAt: DateTime.now());
      final temporaryFile = File('${jsonFile.path}.tmp');
      await temporaryFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(updated.toJson()),
        flush: true,
      );
      if (await jsonFile.exists()) await jsonFile.delete();
      await temporaryFile.rename(jsonFile.path);
    } on Object catch (error) {
      throw PreventiaProjectException(
        'Impossible d’enregistrer le dossier PreventIA : $error',
      );
    }
  }

  Future<PreventiaAutoDocumentResult> ensureBlankPiuExists(
    PreventiaProject project,
  ) async {
    return _ensureBlankDocument(
      project: project,
      documentType: 'Plan Interne d’Urgence',
      directoryName: '02_PIU',
      fileStem: 'PIU_${normalizeFolderName(project.companyName)}_modele_vierge',
      content:
          '# Plan Interne d’Urgence — ${project.companyName}\n\n'
          'Modèle vierge à compléter.\n\n'
          'Statut : à générer correctement et à valider.\n',
    );
  }

  Future<PreventiaAutoDocumentResult> ensureBlankPgaExists(
    PreventiaProject project,
  ) async {
    return _ensureBlankDocument(
      project: project,
      documentType: 'PGA/PAA/PGP',
      directoryName: '04_PGA_PAA_PGP',
      fileStem: 'PGA_PAA_PGP_${normalizeFolderName(project.companyName)}_auto',
      content:
          '# PGA / PAA / PGP — ${project.companyName}\n\n'
          '## Document alimenté par les analyses de risques\n\n'
          'Statut : Document de travail à compléter et valider\n\n'
          '## Actions issues des analyses de risques\n\n'
          '| Source | Action | Priorité | Responsable | Délai | Preuve attendue | Statut |\n'
          '|---|---|---|---|---|---|---|\n'
          '| | Aucune action validée issue des analyses de risques n’est encore disponible. | | | | | |\n',
    );
  }

  Future<String> regeneratePiuWithValidatedItems(PreventiaProject project) {
    final items = project.piuItems.where((item) => item.status == 'validé');
    final body = items.isEmpty
        ? 'Aucun élément PIU validé.'
        : items
              .map((item) => '- ${item.emergencyTopic}\n  ${item.information}')
              .join('\n');
    return _createVersion(
      project: project,
      documentType: 'Plan Interne d’Urgence',
      directoryName: '02_PIU',
      filePrefix: 'PIU_${normalizeFolderName(project.companyName)}',
      content:
          '# Plan Interne d’Urgence — ${project.companyName}\n\n'
          '## Informations issues des analyses de risques\n\n$body\n',
    );
  }

  Future<String> regeneratePgaWithValidatedItems(PreventiaProject project) {
    final items = project.actionItems.where((item) => item.status == 'validé');
    final rows = items.isEmpty
        ? '| | Aucune action validée issue des analyses de risques n’est encore disponible. | | | | | |'
        : items
              .map(
                (item) =>
                    '| ${item.sourceDocumentType} | ${item.action} | ${item.priority} | '
                    '${item.responsible} | ${item.deadline} | ${item.evidenceExpected} | ${item.status} |',
              )
              .join('\n');
    return _createVersion(
      project: project,
      documentType: 'PGA/PAA/PGP',
      directoryName: '04_PGA_PAA_PGP',
      filePrefix: 'PGA_PAA_PGP_${normalizeFolderName(project.companyName)}',
      content: _cleanLegacyPgaMarkdown(
        '# PGA / PAA / PGP — ${project.companyName}\n\n'
        '## Actions issues des analyses de risques\n\n'
        '| Source | Action | Priorité | Responsable | Délai | Preuve attendue | Statut |\n'
        '|---|---|---|---|---|---|---|\n$rows\n',
      ),
    );
  }

  Future<String> _createVersion({
    required PreventiaProject project,
    required String documentType,
    required String directoryName,
    required String filePrefix,
    required String content,
  }) async {
    final directory = Directory(path.join(project.basePath, directoryName));
    await directory.create(recursive: true);
    final existing = await directory
        .list()
        .where((item) => item is File)
        .length;
    final version = existing + 1;
    final target = File(
      path.join(directory.path, '${filePrefix}_v$version.md'),
    );
    await target.writeAsString(content, flush: true);
    await setCurrentProject(project);
    await addDocumentToCurrentProject(
      PreventiaProjectDocument(
        id: _documentId(documentType, 'v$version', target.path),
        documentType: documentType,
        title: '${filePrefix}_v$version',
        reference: 'v$version',
        language: 'fr',
        createdAt: DateTime.now(),
        wordPath: target.path,
        pdfPath: '',
        source: 'local-validated-company-items',
        companyName: project.companyName,
        siteName: project.siteName,
        folderPath: directory.path,
      ),
    );
    return target.path;
  }

  Future<PreventiaAutoDocumentResult> _ensureBlankDocument({
    required PreventiaProject project,
    required String documentType,
    required String directoryName,
    required String fileStem,
    required String content,
  }) async {
    final directory = Directory(path.join(project.basePath, directoryName));
    await directory.create(recursive: true);
    final existingFiles = await directory
        .list()
        .where((entity) => entity is File)
        .toList();
    if (existingFiles.isNotEmpty) {
      return PreventiaAutoDocumentResult(
        created: false,
        path: existingFiles.first.path,
      );
    }
    final target = File(path.join(directory.path, '$fileStem.md'));
    await target.writeAsString(content, flush: true);
    await setCurrentProject(project);
    await addDocumentToCurrentProject(
      PreventiaProjectDocument(
        id: _documentId(documentType, 'AUTO', fileStem),
        documentType: documentType,
        title: fileStem,
        reference: 'AUTO',
        language: 'fr',
        createdAt: DateTime.now(),
        wordPath: target.path,
        pdfPath: '',
        source: 'auto-created-from-risk-assessment',
        companyName: project.companyName,
        siteName: project.siteName,
        folderPath: directory.path,
        status: 'à générer correctement',
      ),
    );
    return PreventiaAutoDocumentResult(created: true, path: target.path);
  }

  Future<void> addDocumentToCurrentProject(
    PreventiaProjectDocument document,
  ) async {
    final project = await getCurrentProject();
    if (project == null) return;
    final documents = [...project.documents];
    final matchingIndex = documents.indexWhere(
      (item) =>
          item.id == document.id ||
          (item.documentType == document.documentType &&
              item.reference == document.reference &&
              item.title == document.title),
    );
    if (matchingIndex < 0) {
      documents.add(document);
    } else {
      final existing = documents[matchingIndex];
      documents[matchingIndex] = PreventiaProjectDocument(
        id: existing.id,
        documentType: document.documentType,
        title: document.title,
        reference: document.reference,
        language: document.language,
        createdAt: existing.createdAt,
        wordPath: document.wordPath.isEmpty
            ? existing.wordPath
            : document.wordPath,
        pdfPath: document.pdfPath.isEmpty ? existing.pdfPath : document.pdfPath,
        source: document.source,
        companyName: document.companyName.isEmpty
            ? existing.companyName
            : document.companyName,
        siteName: document.siteName.isEmpty
            ? existing.siteName
            : document.siteName,
        folderPath: document.folderPath.isEmpty
            ? existing.folderPath
            : document.folderPath,
        extractedToPiu: document.extractedToPiu || existing.extractedToPiu,
        extractedToPga: document.extractedToPga || existing.extractedToPga,
        extractedToDiu: document.extractedToDiu || existing.extractedToDiu,
        status: document.status.isEmpty ? existing.status : document.status,
      );
    }
    await saveProject(project.copyWith(documents: documents));
  }

  Future<void> addRiskItemsToCurrentProject(List<PreventiaRiskItem> items) =>
      _append(
        items,
        (project, values) => project.copyWith(
          riskItems: _mergeById(
            project.riskItems,
            values,
            (item) => item.id,
            merge: (existing, addition) =>
                addition.copyWith(status: existing.status),
          ),
        ),
      );

  Future<void> addActionItemsToCurrentProject(
    List<PreventiaActionItem> items,
  ) => _append(
    items,
    (project, values) => project.copyWith(
      actionItems: _mergeById(
        project.actionItems,
        values,
        (item) => item.id,
        merge: (existing, addition) => addition.copyWith(
          status: existing.status,
          updatedAt: existing.updatedAt,
        ),
      ),
    ),
  );

  Future<void> addDiuItemsToCurrentProject(List<PreventiaDiuItem> items) =>
      _append(
        items,
        (project, values) => project.copyWith(
          diuItems: _mergeById(
            project.diuItems,
            values,
            (item) => item.id,
            merge: (existing, addition) =>
                addition.copyWith(status: existing.status),
          ),
        ),
      );

  Future<void> addPiuItemsToCurrentProject(List<PreventiaPiuItem> items) =>
      _append(
        items,
        (project, values) => project.copyWith(
          piuItems: _mergeById(
            project.piuItems,
            values,
            (item) => item.id,
            merge: (existing, addition) =>
                addition.copyWith(status: existing.status),
          ),
        ),
      );

  Future<void> addEvidenceItemsToCurrentProject(
    List<PreventiaEvidenceItem> items,
  ) async {
    final project = await getCurrentProject();
    if (project == null || items.isEmpty) return;
    final photos = items
        .where((item) => item.type.toLowerCase().contains('photo'))
        .toList();
    final evidence = items
        .where((item) => !item.type.toLowerCase().contains('photo'))
        .toList();
    await saveProject(
      project.copyWith(
        photosToTake: _mergeById(
          project.photosToTake,
          photos,
          (item) => item.id,
          merge: (existing, addition) =>
              addition.copyWith(status: existing.status),
        ),
        evidenceToCollect: _mergeById(
          project.evidenceToCollect,
          evidence,
          (item) => item.id,
          merge: (existing, addition) =>
              addition.copyWith(status: existing.status),
        ),
      ),
    );
  }

  Future<List<PreventiaActionItem>> getValidatedActionsForPaaPgp() async {
    final items = (await getCurrentProject())?.actionItems ?? const [];
    return items
        .where(
          (item) =>
              item.status == 'validé' &&
              RegExp(
                r'PAA|PGP|PGAA',
                caseSensitive: false,
              ).hasMatch(item.destination),
        )
        .toList();
  }

  Future<List<PreventiaDiuItem>> getDiuCandidateItems() async =>
      (await getCurrentProject())?.diuItems ?? const [];

  Future<List<PreventiaPiuItem>> getPiuCandidateItems() async =>
      (await getCurrentProject())?.piuItems ?? const [];

  Future<List<PreventiaActionItem>> getOpenActions() async {
    final items = (await getCurrentProject())?.actionItems ?? const [];
    return items.where((item) => !_isClosed(item.status)).toList();
  }

  Future<List<PreventiaEvidenceItem>> getOpenEvidenceItems() async {
    final project = await getCurrentProject();
    if (project == null) return [];
    return [
      ...project.evidenceToCollect,
      ...project.photosToTake,
    ].where((item) => !_isClosed(item.status)).toList();
  }

  Future<String?> saveExportToCurrentProject({
    required Uint8List bytes,
    required String fileName,
    required String documentType,
    required String title,
    required String reference,
    required String language,
    required String source,
    required bool isPdf,
  }) async {
    final project = await getCurrentProject();
    if (project == null) {
      if (lastError != null) {
        throw const PreventiaProjectException(
          'Le dossier PreventIA actif n’est plus accessible. Sélectionnez-le à nouveau.',
        );
      }
      return null;
    }
    final targetDirectory = Directory(
      path.join(project.basePath, subdirectoryForDocumentType(documentType)),
    );
    await targetDirectory.create(recursive: true);
    final targetPath = path.join(targetDirectory.path, path.basename(fileName));
    await File(targetPath).writeAsBytes(bytes, flush: true);
    await addDocumentToCurrentProject(
      PreventiaProjectDocument(
        id: _documentId(documentType, reference, title),
        documentType: documentType,
        title: title,
        reference: reference,
        language: language,
        createdAt: DateTime.now(),
        wordPath: isPdf ? '' : targetPath,
        pdfPath: isPdf ? targetPath : '',
        source: source,
        companyName: project.companyName,
        siteName: project.siteName,
        folderPath: targetDirectory.path,
      ),
    );
    return targetPath;
  }

  Future<String?> saveGeneratedContentToCurrentProject({
    required String content,
    required String fileName,
    required String documentType,
    required String title,
    required String reference,
    required String language,
    required String source,
  }) async {
    final project = await getCurrentProject();
    if (project == null) return null;
    final targetDirectory = Directory(
      path.join(project.basePath, subdirectoryForDocumentType(documentType)),
    );
    await targetDirectory.create(recursive: true);
    final targetPath = path.join(
      targetDirectory.path,
      '${_safeFileName(fileName)}.md',
    );
    await File(targetPath).writeAsString(content, flush: true);
    await addDocumentToCurrentProject(
      PreventiaProjectDocument(
        id: _documentId(documentType, reference, title),
        documentType: documentType,
        title: title,
        reference: reference,
        language: language,
        createdAt: DateTime.now(),
        wordPath: '',
        pdfPath: '',
        source: source,
      ),
    );
    return targetPath;
  }

  static String subdirectoryForDocumentType(String documentType) {
    final normalized = _normalized(documentType);
    if (normalized.contains('revue') && normalized.contains('piu')) {
      return '02_PIU/00_A_valider';
    }
    if (normalized.contains('revue') &&
        (RegExp(r'\b(pgaa|paa|pgp)\b').hasMatch(normalized) ||
            normalized.contains('plan annuel') ||
            normalized.contains('plan global'))) {
      return '04_PGA_PAA_PGP/00_A_valider';
    }
    if (normalized.contains('analyse') && normalized.contains('risque')) {
      return '01_Analyses_de_risques';
    }
    if (normalized.contains('plan interne') || normalized.contains('piu')) {
      return '02_PIU';
    }
    if (RegExp(r'\bdiu\b').hasMatch(normalized) ||
        normalized.contains('dossier intervention ulterieure')) {
      return '03_DIU';
    }
    if (RegExp(r'\b(pgaa|paa|pgp)\b').hasMatch(normalized) ||
        normalized.contains('plan annuel') ||
        normalized.contains('plan global')) {
      return '04_PGA_PAA_PGP';
    }
    if (normalized.contains('plan') && normalized.contains('action')) {
      return '05_Plans_actions';
    }
    if (normalized.contains('photo') || normalized.contains('preuve')) {
      return '06_Preuve_et_photos';
    }
    return '07_Annexes';
  }

  Future<void> _append<T>(
    List<T> items,
    PreventiaProject Function(PreventiaProject, List<T>) update,
  ) async {
    final project = await getCurrentProject();
    if (project == null || items.isEmpty) return;
    await saveProject(update(project, items));
  }

  Future<void> _ensureStructure(String basePath) async {
    final projectDirectory = Directory(basePath);
    if (!await projectDirectory.exists()) {
      await projectDirectory.create(recursive: true);
    }
    for (final directory in subdirectories) {
      await Directory(path.join(basePath, directory)).create(recursive: true);
    }
  }

  static List<T> _mergeById<T>(
    List<T> existing,
    List<T> additions,
    String Function(T) id, {
    T Function(T existing, T addition)? merge,
  }) {
    final result = [...existing];
    for (final addition in additions) {
      final index = result.indexWhere((item) => id(item) == id(addition));
      if (index < 0) {
        result.add(addition);
      } else {
        result[index] = merge?.call(result[index], addition) ?? addition;
      }
    }
    return result;
  }

  static String _safeFileName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[\x00-\x1F/\\:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.isEmpty ? 'document' : cleaned;
  }

  static String _documentId(String type, String reference, String title) {
    final stablePart = '$type|$reference|$title'.codeUnits.fold<int>(
      17,
      (hash, value) => 37 * hash + value,
    );
    return 'document_${stablePart.abs()}';
  }

  static bool _isClosed(String status) {
    final normalized = _normalized(status);
    return normalized == 'valide' || normalized == 'ignore';
  }

  static bool _isSafeProjectPath(String projectPath) {
    if (projectPath.trim().isEmpty) return false;
    final absolute = path.normalize(path.absolute(projectPath));
    if (absolute == path.rootPrefix(absolute)) return false;
    final parts = path.split(absolute);
    for (var index = 0; index <= parts.length - 3; index++) {
      if (parts[index] == 'PreventIA' && parts[index + 1] == 'Clients') {
        final company = parts[index + 2].trim();
        return company.isNotEmpty && index + 3 == parts.length;
      }
    }
    return false;
  }

  static bool _matchesDocument(
    PreventiaProjectDocument document,
    String documentId,
    String documentType,
    String title,
  ) {
    if (document.id == documentId) return true;
    return _normalized(document.documentType) == _normalized(documentType) &&
        _normalized(document.title) == _normalized(title);
  }

  static bool _isFileInsideProject(String filePath, String projectPath) {
    final file = path.normalize(path.absolute(filePath));
    final project = path.normalize(path.absolute(projectPath));
    return path.isWithin(project, file) &&
        (file.toLowerCase().endsWith('.docx') ||
            file.toLowerCase().endsWith('.pdf'));
  }

  static String _normalized(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[àáâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool isValidClientProjectPath(String projectPath) {
  if (projectPath.trim().isEmpty) return false;
  final normalized = path
      .normalize(path.absolute(projectPath))
      .replaceAll('\\', '/')
      .toLowerCase();
  if (normalized.contains('/library/containers/') ||
      normalized.contains(
        '/com.example.preventiabelgiqueapp/data/documents/',
      )) {
    return false;
  }
  final marker = '/preventia/clients/';
  final markerIndex = normalized.lastIndexOf(marker);
  if (markerIndex < 0) return false;
  final relative = normalized.substring(markerIndex + marker.length);
  return relative.isNotEmpty && !relative.contains('/');
}

String normalizeProjectIdentity(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp('[àáâäãå]'), 'a')
    .replaceAll(RegExp('[ç]'), 'c')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îïíì]'), 'i')
    .replaceAll(RegExp('[ñ]'), 'n')
    .replaceAll(RegExp('[ôöóòõ]'), 'o')
    .replaceAll(RegExp('[ùûüú]'), 'u')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String projectKey(String companyName, String siteName) =>
    companyKey(companyName);

String companyKey(String companyName) => normalizeCompanyName(companyName);

String normalizeFolderName(String value) {
  final cleaned = value
      .trim()
      .replaceAll(RegExp(r'[\x00-\x1F\\:*?"<>|]'), '-')
      .replaceAll('/', '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^[ .-]+|[ .-]+$'), '');
  return cleaned.isEmpty ? 'Sans_nom' : cleaned;
}

String _cleanLegacyPgaMarkdown(String markdown) {
  return markdown
      .split('\n')
      .where((line) {
        final normalized = PreventiaProjectService._normalized(line);
        if (RegExp(
          r'\bpage\s+\d+\s*/\s*\d+\b',
          caseSensitive: false,
        ).hasMatch(line)) {
          return false;
        }
        return ![
          'additionalinformation',
          'documenttype',
          'activity',
          'concernedtasks',
        ].any(normalized.contains);
      })
      .join('\n')
      .trim();
}
