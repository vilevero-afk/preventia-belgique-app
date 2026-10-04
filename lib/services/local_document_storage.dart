import 'package:shared_preferences/shared_preferences.dart';

import '../models/analysis_project.dart';
import '../models/saved_document.dart';

class LocalDocumentStorage {
  static const _documentsKey = 'saved_documents';
  static const _projectsKey = 'analysis_projects';

  Future<List<SavedDocument>> loadDocuments() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedDocuments = preferences.getStringList(_documentsKey) ?? [];
    final documents = encodedDocuments.map(SavedDocument.decode).toList();
    documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return documents;
  }

  Future<void> saveDocument(SavedDocument document) async {
    final preferences = await SharedPreferences.getInstance();
    final documents = preferences.getStringList(_documentsKey) ?? [];
    documents.add(document.encode());
    await preferences.setStringList(_documentsKey, documents);
  }

  Future<void> updateDocument(SavedDocument document) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedDocuments = preferences.getStringList(_documentsKey) ?? [];
    final documents = encodedDocuments.map(SavedDocument.decode).toList();
    final index = documents.indexWhere((saved) => saved.id == document.id);

    if (index == -1) {
      documents.add(document);
    } else {
      documents[index] = document;
    }

    await preferences.setStringList(
      _documentsKey,
      documents.map((saved) => saved.encode()).toList(),
    );
  }

  Future<void> deleteDocument(String documentId) async {
    final preferences = await SharedPreferences.getInstance();
    final documents = (preferences.getStringList(_documentsKey) ?? [])
        .map(SavedDocument.decode)
        .where((document) => document.id != documentId)
        .toList();
    await preferences.setStringList(
      _documentsKey,
      documents.map((document) => document.encode()).toList(),
    );

    final projects = (preferences.getStringList(_projectsKey) ?? [])
        .map(AnalysisProject.decode)
        .toList();
    final updatedProjects = <AnalysisProject>[];
    for (final project in projects) {
      if (project.analysisDocumentId == documentId) continue;
      updatedProjects.add(
        AnalysisProject(
          id: project.id,
          name: project.name,
          createdAt: project.createdAt,
          modifiedAt: DateTime.now(),
          referenceNumber: project.referenceNumber,
          analysisTitle: project.analysisTitle,
          analysisDocumentId: project.analysisDocumentId,
          actionSummaryDocumentId: project.actionSummaryDocumentId == documentId
              ? null
              : project.actionSummaryDocumentId,
          linkedDocumentIds: project.linkedDocumentIds
              .where((id) => id != documentId)
              .toList(),
          folderType: project.folderType,
          status: project.status,
        ),
      );
    }
    await preferences.setStringList(
      _projectsKey,
      updatedProjects.map((project) => project.encode()).toList(),
    );
  }

  Future<List<AnalysisProject>> loadProjects() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedProjects = preferences.getStringList(_projectsKey) ?? [];
    final projects = encodedProjects.map(AnalysisProject.decode).toList();
    projects.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return projects;
  }

  Future<void> saveOrUpdateProject(AnalysisProject project) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedProjects = preferences.getStringList(_projectsKey) ?? [];
    final projects = encodedProjects.map(AnalysisProject.decode).toList();
    final index = projects.indexWhere((saved) => saved.id == project.id);

    if (index == -1) {
      projects.add(project);
    } else {
      projects[index] = project;
    }

    await preferences.setStringList(
      _projectsKey,
      projects.map((saved) => saved.encode()).toList(),
    );
  }

  Future<AnalysisProject?> findProjectById(String id) async {
    final projects = await loadProjects();
    for (final project in projects) {
      if (project.id == id) {
        return project;
      }
    }
    return null;
  }

  Future<SavedDocument?> findDocumentById(String id) async {
    final documents = await loadDocuments();
    for (final document in documents) {
      if (document.id == id) {
        return document;
      }
    }
    return null;
  }

  Future<SavedDocument?> findActionSummaryForAnalysis(String analysisId) async {
    final documents = await loadDocuments();
    for (final document in documents) {
      if (document.isActionSummary && document.sourceDocumentId == analysisId) {
        return document;
      }
    }
    return null;
  }
}
