import 'dart:convert';

class SavedDocument {
  const SavedDocument({
    required this.id,
    required this.title,
    required this.documentType,
    required this.content,
    required this.createdAt,
    this.modifiedAt,
    this.localDocumentType = SavedDocumentLocalType.riskAnalysis,
    this.sourceDocumentId,
    this.sourceDocumentTitle,
    this.sourceLabel,
    this.status,
    this.projectId,
  });

  final String id;
  final String title;
  final String documentType;
  final String content;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final SavedDocumentLocalType localDocumentType;
  final String? sourceDocumentId;
  final String? sourceDocumentTitle;
  final String? sourceLabel;
  final String? status;
  final String? projectId;

  bool get isModifiedLocally => modifiedAt != null;
  bool get isActionSummary =>
      localDocumentType == SavedDocumentLocalType.actionSummary;

  SavedDocument copyWith({
    String? title,
    String? documentType,
    String? content,
    DateTime? createdAt,
    DateTime? modifiedAt,
    SavedDocumentLocalType? localDocumentType,
    String? sourceDocumentId,
    String? sourceDocumentTitle,
    String? sourceLabel,
    String? status,
    String? projectId,
  }) {
    return SavedDocument(
      id: id,
      title: title ?? this.title,
      documentType: documentType ?? this.documentType,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      localDocumentType: localDocumentType ?? this.localDocumentType,
      sourceDocumentId: sourceDocumentId ?? this.sourceDocumentId,
      sourceDocumentTitle: sourceDocumentTitle ?? this.sourceDocumentTitle,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'documentType': documentType,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'localDocumentType': localDocumentType.storageValue,
      'sourceDocumentId': sourceDocumentId,
      'sourceDocumentTitle': sourceDocumentTitle,
      'sourceLabel': sourceLabel,
      'status': status,
      'projectId': projectId,
    };
  }

  factory SavedDocument.fromJson(Map<String, dynamic> json) {
    return SavedDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      documentType: json['documentType'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      localDocumentType: SavedDocumentLocalType.fromStorageValue(
        json['localDocumentType'] as String?,
      ),
      sourceDocumentId: json['sourceDocumentId'] as String?,
      sourceDocumentTitle: json['sourceDocumentTitle'] as String?,
      sourceLabel: json['sourceLabel'] as String?,
      status: json['status'] as String?,
      projectId: json['projectId'] as String?,
    );
  }

  String encode() => jsonEncode(toJson());

  static SavedDocument decode(String source) {
    return SavedDocument.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }
}

enum SavedDocumentLocalType {
  riskAnalysis('analyse_risques'),
  actionSummary('recapitulatif_actions'),
  preventionDocument('document_prevention'),
  linkedDocument('document_lie');

  const SavedDocumentLocalType(this.storageValue);

  final String storageValue;

  static SavedDocumentLocalType fromStorageValue(String? value) {
    return SavedDocumentLocalType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => SavedDocumentLocalType.riskAnalysis,
    );
  }
}
