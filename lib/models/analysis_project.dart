import 'dart:convert';

class AnalysisProject {
  const AnalysisProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    required this.referenceNumber,
    required this.analysisTitle,
    required this.analysisDocumentId,
    this.actionSummaryDocumentId,
    this.linkedDocumentIds = const [],
    this.folderType = 'Dossier d’analyse de risques',
    this.status = 'Projet à valider',
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String referenceNumber;
  final String analysisTitle;
  final String analysisDocumentId;
  final String? actionSummaryDocumentId;
  final List<String> linkedDocumentIds;
  final String folderType;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': 'Dossier d’analyse de risques',
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'referenceNumber': referenceNumber,
      'analysisTitle': analysisTitle,
      'analysisDocumentId': analysisDocumentId,
      'actionSummaryDocumentId': actionSummaryDocumentId,
      'linkedDocumentIds': linkedDocumentIds,
      'folderType': folderType,
      'status': status,
    };
  }

  factory AnalysisProject.fromJson(Map<String, dynamic> json) {
    return AnalysisProject(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      referenceNumber:
          json['referenceNumber'] as String? ?? _legacyReference(json),
      analysisTitle: json['analysisTitle'] as String,
      analysisDocumentId: json['analysisDocumentId'] as String,
      actionSummaryDocumentId: json['actionSummaryDocumentId'] as String?,
      linkedDocumentIds:
          (json['linkedDocumentIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      folderType:
          json['folderType'] as String? ?? 'Dossier d’analyse de risques',
      status: json['status'] as String? ?? 'Projet à valider',
    );
  }

  String encode() => jsonEncode(toJson());

  static AnalysisProject decode(String source) {
    return AnalysisProject.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  static String _legacyReference(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);
    return 'AR-${createdAt.year}-0000';
  }
}
